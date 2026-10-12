{
  description = "NixOS flake for Anthropic's official Claude Desktop Linux app";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" ];
      forAllSystems = f: lib.genAttrs systems (system: f system);
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [ "claude-desktop" ];
      };
    in {
      packages = forAllSystems (system:
        let pkgs = pkgsFor system; in {
          claude-desktop = pkgs.callPackage ./pkgs/claude-desktop.nix { };
          claude-desktop-cowork = pkgs.callPackage ./pkgs/claude-desktop.nix {
            withCowork = true;
          };
          default = self.packages.${system}.claude-desktop;
        });

      overlays.default = final: _prev: {
        claude-desktop = final.callPackage ./pkgs/claude-desktop.nix { };
        claude-desktop-cowork = final.callPackage ./pkgs/claude-desktop.nix {
          withCowork = true;
        };
      };

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/claude-desktop";
        };
      });

      nixosModules.default = { pkgs, lib, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
        nixpkgs.config.allowUnfreePredicate = lib.mkDefault (pkg:
          builtins.elem (lib.getName pkg) [ "claude-desktop" ]);
        environment.systemPackages = [ pkgs.claude-desktop ];
      };

      homeModules.default = { pkgs, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
        home.packages = [ pkgs.claude-desktop ];
      };
    };
}
