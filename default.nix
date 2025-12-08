{
  pkgs ? import <nixpkgs> { },
}:

let
  unstable =
    import (fetchTarball "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz")
      { };
in

pkgs.mkShell {
  nativeBuildInputs =
    with pkgs.buildPackages;
    [
      just
      python313Packages.rope
      ruff
    ]
    ++ (with unstable.buildPackages; [
      texliveFull
      texlab
    ]);
  shellHook = ''
    zsh
  '';
}
