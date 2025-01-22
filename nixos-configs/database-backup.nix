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
  # cronjob for database backup
  services.cron = {
    enable = true;
  };
  
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
       superuser_map      root      localusr
       superuser_map      root      replic
       superuser_map      root      team02
       superuser_map      postgres  postgres
    '';
    # SysUser -> DBUser map
    authentication = pkgs.lib.mkOverride 10 ''
      #type database    DBuser    host            auth-method optional_ident_map
      local all         all                       peer        map=superuser_map
      local localusrdb  localusr                  password
      local all         ronlyusr                  password
      host  remotusrdb  remotusr  192.168.3.0/24  password
      host  all         replic    192.168.3.0/24  password
      host  team02db    team02    192.168.0.0/16  password
    '';
    # Users & Databases
    initialScript = pkgs.writeText "backend-initScript" ''
      ALTER USER postgres WITH PASSWORD '%%postgrespwd%%';
      CREATE ROLE localusr WITH LOGIN PASSWORD '%%localusrpwd%%';
      CREATE ROLE remotusr WITH LOGIN PASSWORD '%%remotusrpwd%%';
      CREATE ROLE ronlyusr WITH LOGIN PASSWORD '%%ronlyusrpwd%%';
      ALTER DEFAULT PRIVILEGES GRANT SELECT ON TABLES TO ronlyusr;
      GRANT SELECT ON ALL TABLE IN SCHEMA public TO ronlyusr;
      GRANT SELECT ON ALL TABLE IN SCHEMA information_schema TO ronlyusr;
      GRANT SELECT ON ALL TABLE IN SCHEMA pg_catalog TO ronlyusr;
      GRANT SELECT ON ALL TABLE IN SCHEMA pg_toast TO ronlyusr;
      CREATE DATABASE localusrdb;
      CREATE DATABASE remotusrdb;
      ALTER DATABASE localusrdb OWNER TO localusr;
      ALTER DATABASE remotusrdb OWNER TO remotusr;

      CREATE ROLE team02 WITH LOGIN PASSWORD '%%team02pwd%%';
      CREATE ROLE replic WITH REPLICATION WITH LOGIN PASSWORD '%%replicpwd%%';
      CREATE DATABASE team02db;
      ALTER DATABASE team02db OWNER TO team02;
    '';
  };

  ## BACKUP SETUP
  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 01:15:00";
    location = "/var/backup/postgresql";
    compression = "gzip";
  };
  
  ## PROMETHEUS EXPORT
  services.prometheus.exporters.postgres = {
    enable = true;
    port = 9101;
    runAsLocalSuperUser = true;
  };
}
