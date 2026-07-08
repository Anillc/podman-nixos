# podman-nixos

Run nixos in podman. There is an option `--systemd` of `podman run` to run systemd inside the container. We can use this to run a nixos with systemd.

# usage

```bash
podman run -it --name=nixos docker.io/anillc/nixos
podman exec -it nixos /run/current-system/sw/bin/bash
```

# NixOS module

You can import the NixOS module to build your own NixOS image. You can switch your configuration in the container or build a new image with `nix build .#nixosConfigurations.nixos.config.podman-nixos.image`. It's also possible to use deploy-rs to deploy your configuration when openssh is enabled.

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.podman-nixos.url = "github:Anillc/podman-nixos";
  outputs = inputs@{
    self, nixpkgs, flake-parts, podman-nixos,
  }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];
    flake.nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        podman-nixos.nixosModules.default
        { system.stateVersion = "26.05"; }
      ];
    };
  };
}
```
