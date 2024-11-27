#{ inputs, ... }:
#let
#  # Overlay to use PostgreSQL 17 from the unstable channel
#  overlay-pg-unstable = final: prev: {
#    postgresql = inputs.unstable.legacyPackages."x86_64-linux".postgresql_17;
#  };
#in
#{
#  # Add the PostgreSQL overlay
#  nixpkgs.overlays = [ overlay-pg-unstable ];
#
#  # Enable the PostgreSQL service
#  services.postgresql = {
#    enable = true;
#    #package = pkgs.postgresql; # Use the PostgreSQL package from the overlay
#    dataDir = "/var/lib/postgresql"; # Default data directory for PostgreSQL
#    # Initialize with a simple configuration
#    #initialScript = ''
#    #  CREATE USER admin WITH PASSWORD 'admin_password';
#    #  CREATE DATABASE example_db OWNER admin;
#    #'';
#  };
#}

{ config, lib, pkgs, ... }:
{
  config.services.postgresql = {
    enable = true;
    ensureDatabases = [ "mydatabase" ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };
}
