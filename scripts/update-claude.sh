#!/usr/bin/env bash
set -euo pipefail

NIX_FILE="pkgs/claude-desktop.nix"
INDEX_URL="https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages.gz"

latest="$(curl -fsSL "$INDEX_URL" | gzip -dc | awk '
  BEGIN { RS = ""; FS = "\n" }
  $1 == "Package: claude-desktop" {
    version = hash = filename = ""
    for (i = 1; i <= NF; i++) {
      if ($i ~ /^Version: /)  { sub(/^Version: /, "", $i); version = $i }
      if ($i ~ /^SHA256: /)   { sub(/^SHA256: /, "", $i); hash = $i }
      if ($i ~ /^Filename: /) { sub(/^Filename: /, "", $i); filename = $i }
    }
    if (version != "" && hash ~ /^[[:xdigit:]]{64}$/ && filename ~ /^pool\//)
      print version, hash, filename
  }
' | sort -V -k1,1 | tail -n 1)"

read -r new_version new_hash filename <<< "$latest"
if [[ ! "${new_version:-}" =~ ^[0-9]+(\.[0-9]+)+$ || ! "${new_hash:-}" =~ ^[[:xdigit:]]{64}$ || "${filename:-}" != "pool/main/c/claude-desktop/claude-desktop_${new_version}_amd64.deb" ]]; then
  echo "Could not parse latest Claude Desktop package metadata." >&2
  exit 1
fi
new_hash="$(nix hash convert --hash-algo sha256 --from base16 "$new_hash")"

current_version="$(sed -n 's/^[[:space:]]*version = "\([^"]*\)";.*/\1/p' "$NIX_FILE" | head -n1)"
current_hash="$(sed -n 's/^[[:space:]]*hash = "\([^"]*\)";.*/\1/p' "$NIX_FILE" | head -n1)"

if [[ "$current_version" == "$new_version" && "$current_hash" == "$new_hash" ]]; then
  echo "Claude Desktop is current ($current_version)."
  echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

sed -i -E \
  -e "s/(version = \")[^\"]*(\";)/\\1$new_version\\2/" \
  -e "s/(hash = \")[^\"]*(\";)/\\1$new_hash\\2/" \
  "$NIX_FILE"

echo "Updated Claude Desktop $current_version -> $new_version"
nix build .#claude-desktop --print-build-logs
echo "changed=true" >> "${GITHUB_OUTPUT:-/dev/null}"
