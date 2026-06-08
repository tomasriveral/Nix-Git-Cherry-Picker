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
        text = builtins.readFile ./ngcp.sh;
        runtimeInputs = with pkgs; [
          git
          libnotify
          jq
        ];
      };
      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/ngcp";
      };
    });
}
