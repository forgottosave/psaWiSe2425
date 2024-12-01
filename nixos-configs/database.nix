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
  # DATABASE SETUP
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [ "team03db" "team02db" ];
    enableTCPIP = true;
    #settings.port = 5432;
    ## limit users from accessing databases
    #identMap = ''
    #   # ArbitraryMapName systemUser DBUser
    #   superuser_map      root      postgres
    #   superuser_map      postgres  postgres
    #   superuser_map      root      team02
    #   superuser_map      team02    team02
    #   # Let other names login as themselves
    #   #superuser_map      /^(.*)$   \1
    #'';
    # SysUser -> DBUser map
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser    host            auth-method
      host  all       postgres  localhost       password
      host  team02db  team02    192.168.0.0/32  password
    '';
    # Users & Databases
    initialScript = pkgs.writeText "backend-initScript" ''
      ALTER USER postgres WITH PASSWORD 'postgrespwd';

      CREATE ROLE team02 WITH LOGIN PASSWORD 'team02pwd' CREATEDB;
      CREATE DATABASE team02db;
      
      GRANT ALL ON DATABASE team02db TO team02;
      GRANT ALL PRIVILEGES ON SCHEMA public TO team02;
    '';
  };
  ## BACKUP SETUP
  #services.postgresqlBackup = {
  #  enable = true;
  #  startAt = "*-*-* 01:15:00";
  #  location = "/root/database_backups/";
  #  backupAll = true;
  #  compression = "gzip";
  #};
}
