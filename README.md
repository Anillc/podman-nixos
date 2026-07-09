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

# As base image

```Dockerfile
FROM anillc/nixos:latest

# Run activate to create /bin/sh.
RUN --mount=type=tmpfs,target=/run ["/sbin/activate"]

RUN --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp <<EOF
    set -e

    /sbin/activate && . /etc/profile
    export NIX_REMOTE=local

    nix-store --load-db < /nix-path-registration && rm /nix-path-registration
    nix-env -p /nix/var/nix/profiles/system --set /run/current-system
    nix-channel --add https://github.com/Anillc/podman-nixos/archive/master.tar.gz podman-nixos
    nix-channel --update podman-nixos

    # You can update the system configuration here.
    # To use sudo, you need to pass `--tmpfs /run:exec,suid` to the `podman run` command.
    mkdir -p /etc/nixos
    cat > /etc/nixos/configuration.nix <<'    CONFIG'
        { pkgs, ... }: {
          imports = [ "${<podman-nixos>}/module.nix" ];
          system.stateVersion = "26.05";
          programs.nix-ld.enable = true;
          environment.systemPackages = with pkgs; [ git ];
          users.users.user = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
          security.sudo.wheelNeedsPassword = false;
          services.getty.autologinUser = "user";
        }
    CONFIG

    nixos-rebuild boot -I nixos-config=/etc/nixos/configuration.nix
    nix-collect-garbage -d
EOF

RUN --mount=type=tmpfs,target=/run --mount=type=tmpfs,target=/tmp <<EOF
    set -e

    /nix/var/nix/profiles/system/activate && . /etc/profile
    export NIX_REMOTE=local

    # Do some thing like caching your development environment here. For example:
    nix develop nixpkgs#hello --command true
EOF
```

# docker

You can also use docker to run the image. It should work after you pass `--security-opt writable-cgroups=true --tmpfs /run:exec,suid` to the `docker run` command.
