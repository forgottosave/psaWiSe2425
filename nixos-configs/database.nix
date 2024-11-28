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
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [ "rootdb" "team02db" ];
    enableTCPIP = true;
    # settings.port = 5432;
    # limit users from accessing databases
    identMap = ''
       # ArbitraryMapName systemUser DBUser
       superuser_map      root      postgres
       superuser_map      postgres  postgres
       # Let other names login as themselves
       #superuser_map      /^(.*)$   \1
    '';
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method                  optional_ident_map
      local all       all     trust                        #map=superuser_map
      host  team02    team02  127.0.0.1/32 scram-sha-256
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE nixcloud WITH LOGIN PASSWORD 'nixcloud' CREATEDB;
      CREATE ROLE team02 WITH LOGIN PASSWORD 'team02' CREATEDB;
      CREATE DATABASE nixcloud;
      GRANT ALL PRIVILEGES ON DATABASE nixcloud TO nixcloud;
      CREATE DATABASE team02;
      GRANT ALL PRIVILEGES ON DATABASE team02 TO nixcloud;
      GRANT ALL PRIVILEGES ON DATABASE team02 TO team02;
    '';
  };
}
