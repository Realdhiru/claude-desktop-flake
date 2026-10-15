# claude-flake

Nix flake for Anthropic's official Claude Desktop Linux beta on NixOS. It
downloads Anthropic's published Debian package, verifies its pinned SHA256,
unpacks it without retaining its setuid sandbox helper, and runs it in an FHS
environment with native Wayland enabled.

The application is proprietary and remains subject to Anthropic's terms. This
repository contains packaging glue only and is not affiliated with Anthropic.

## Run

```sh
nix run github:Realdhiru/claude-flake
```

## Install on NixOS

Add the input and overlay to your flake:

```nix
inputs.claude-desktop = {
  url = "github:Realdhiru/claude-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

In the NixOS module list:

```nix
({ inputs, pkgs, ... }: {
  nixpkgs.overlays = [ inputs.claude-desktop.overlays.default ];
  environment.systemPackages = [ pkgs.claude-desktop ];
})
```

Or import `inputs.claude-desktop.nixosModules.default`, which installs the
default package and permits this one unfree package. For Home Manager, import
`inputs.claude-desktop.homeModules.default`.

On this system, the same setup uses `claudeDesktop.overlays.default` in
`flake.nix` and `claude-desktop` in `modules/system/packages.nix`.

## Cowork runtime

The default `claude-desktop` package is smaller. `claude-desktop-cowork` adds
QEMU, OVMF firmware, and `virtiofsd` to the app's FHS runtime for Claude Cowork.
This increases the runtime closure considerably. Cowork also needs KVM access;
see Anthropic's Linux requirements before enabling it. Install the variant with
`environment.systemPackages = [ pkgs.claude-desktop-cowork ];`.

Claude's Linux beta currently lacks Computer Use and Dictation. Quick Entry's
global shortcut on native Wayland depends on the desktop's GlobalShortcuts
portal.

## Updating

The source version, Debian filename, and SHA256 are pinned in
`pkgs/claude-desktop.nix`. GitHub Actions checks Anthropic's official APT index
every six hours and on manual dispatch. When a new version appears, it updates
the pin, builds `.#claude-desktop`, and opens an auto-merge pull request. The
build must succeed before the pull request is created. The updater validates
the APT metadata, reports the failing command and line, and avoids overlapping
scheduled runs. You can also run `scripts/update-claude.sh` locally to perform
the same check and build.

## License

The packaging code is MIT licensed. Claude Desktop itself is proprietary and is
fetched from Anthropic's official APT repository at build time.
