{
description = "Nix Git Cherry Pick";

inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  flake-utils.url = "github:numtide/flake-utils";
};

outputs = { self, nixpkgs, flake-utils}:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.default = pkgs.writeShellApplication {
        name = "ngcp";
        text = ./ngcp.sh;
        runtimeInputs = with pkgs; [
          git
          libnotify
          jq
        ];
      };
      mainProgram = "ngpcp";
      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/ngcp";
      };
    });
}
