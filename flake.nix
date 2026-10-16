{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # One entry per machine, named user@hostname: `home-manager switch`
      # without `--flake .#name` picks the entry for the current user and
      # host. `system` is x86_64-linux, aarch64-linux, aarch64-darwin, ...
      hosts = {
        "aram@arch-aram" = {
          system = "x86_64-linux";
          module = ./hosts/dell-7786.nix;
        };
      };

      mkHome = { system, module }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ module ];
        };
    in
    {
      homeConfigurations = builtins.mapAttrs (_: mkHome) hosts // {
        # Short name used in the docs: `--flake ~/dotfiles#aram`
        aram = self.homeConfigurations."aram@arch-aram";
      };
    };
}
