{
  description = "development shell for k8s";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  } @ inputs: (flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {};
        };

        ksops = pkgs.kustomize-sops.overrideAttrs (old: {
          installPhase = ''
            runHook preInstall

            mkdir -p $out
            dir="$GOPATH/bin"
            mv "$dir/kustomize-sops" "$dir/ksops"
            [ -e "$dir" ] && cp -r $dir $out

            runHook postInstall
          '';
        });
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.kustomize
            pkgs.helm
            pkgs.argocd
            ksops
          ];

          NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc
            pkgs.openssl
          ];

          NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";

          shellHook = ''
            ${pre-commit-check.shellHook}
          '';
        };
      }
    ));
}
