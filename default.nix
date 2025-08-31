{
  config,
  pkgs,
  lib,
  ...
}:
let
  flake = import ./flake.nix;
  flakeOutputs = flake.outputs {
    self = flake;
    nixpkgs = pkgs.path;
    inherit config;
    inherit lib;
  };
in


rec {
  imports = [
    flakeOutputs.nixosModules.default
    flakeOutputs.nixosProfiles.default
  ];

  nixpkgs.overlays = [
    flakeOutputs.overlays.default
  ];

}
