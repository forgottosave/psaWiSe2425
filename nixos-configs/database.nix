{ inputs, pkgs, ... }:
let
  overlay-pg-unstable = final: prev: {
    postgresql = inputs.unstable.legacyPackages."x86_64-linux".postgresql_17;
  };
in
{
  nixpkgs.overlays = [ overlay-pg-unstable ];

  services.postgresql = {
    enable = true;
    dataDir = "/var/lib/postgresql/data";
    ensureDatabases = [ "mydatabase" ];
  };
}