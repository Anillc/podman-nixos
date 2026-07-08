{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = inputs@{
    self, nixpkgs, flake-parts,
  }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];
    flake.nixosModules.default = import ./module.nix;
    perSystem = { inputs', pkgs, ... }: {
      packages.default = self.nixosConfigurations.nixos.config.podman-nixos.image;
    };

    flake.nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.default
        {
          system.stateVersion = "26.05";
          services.getty.autologinUser = "root";
        }
      ];
    };
  };
}
