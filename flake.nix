{
  description = "teamsnelgrove.com static site";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zig2nix = {
      url = "github:Cloudef/zig2nix/4cba116e74f5a9c9295c6e11a40baed18214d744";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zine = {
      url = "github:teamsnelgrove/zine/fix-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig2nix.follows = "zig2nix";
    };
  };

  outputs = {
    nixpkgs,
    zine,
    ...
  }: let
    systems = ["x86_64-linux" "x86_64-darwin"];
    forAllSystems = f: builtins.listToAttrs (map (system: {name = system; value = f system;}) systems);
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      zine-pkg =
        if system == "x86_64-darwin"
        then
          zine.packages.${system}.default.overrideAttrs {
            dontAutoPatchelf = true;
          }
        else zine.packages.${system}.zine;
    in {
      default = pkgs.mkShell {
        packages = [zine-pkg];
      };
    });

    packages.x86_64-linux.default = let
      pkgs = import nixpkgs {system = "x86_64-linux";};
    in
      pkgs.stdenv.mkDerivation {
        name = "teamsnelgrove-site";
        src = ./.;
        nativeBuildInputs = [zine.packages.x86_64-linux.zine];
        buildPhase = ''
          mkdir -p $out
          zine release --output $out
        '';
        dontInstall = true;
      };

    packages.x86_64-darwin.default = let
      pkgs = import nixpkgs {system = "x86_64-darwin";};
    in
      pkgs.stdenv.mkDerivation {
        name = "teamsnelgrove-site";
        src = ./.;
        nativeBuildInputs = [
          (zine.packages.x86_64-darwin.default.overrideAttrs {
            dontAutoPatchelf = true;
          })
        ];
        buildPhase = ''
          mkdir -p $out
          zine release --output $out
        '';
        dontInstall = true;
      };
  };
}
