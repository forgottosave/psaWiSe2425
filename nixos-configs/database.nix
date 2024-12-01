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
    ensureDatabases = [ "team02db" ];
    enableTCPIP = true;
    #settings.port = 5432;
    # limit users from accessing databases
    identMap = ''
       # ArbitraryMapName systemUser DBUser
       superuser_map      root      postgres
       superuser_map      postgres  postgres
       superuser_map      root      team02
       superuser_map      team02    team02
       # Let other names login as themselves
       #superuser_map      /^(.*)$   \1
    '';
    # SysUser -> DBUser map
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method                  optional_ident_map
      local all       all     peer                         map=superuser_map
      host  all       replic  192.168.3.5/16   password
      host  team02db  team02  192.168.0.0/16   password
    '';
    # Users & Databases
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE team02 WITH LOGIN PASSWORD 'ohAfk6Bx';
      CREATE ROLE replic WITH REPLICATION WITH LOGIN PASSWORD 'r3pl1cpwd';
      CREATE DATABASE team02db;
      GRANT ALL PRIVILEGES ON DATABASE team02db TO team02;
    '';
  };
  ## BACKUP SETUP
  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 01:15:00";
    location = "/root/database_backups/";
    backupAll = true;
    compression = "gzip";
  };
  ## Should maybe be changed to more efficient backup using WAL...
  #services.postgresqlWalReceiver = {
  #  receivers = {
  #    main = {
  #      postgresqlPackage = pkgs.postgresql_17;
  #      directory = /mnt/pg_wal/main/;
  #      slot = "main_wal_receiver";
  #      connection = "postgresql://user@somehost";
  #    };
  #  };
  #};
}
