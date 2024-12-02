# Aufgabenblatt 05

In diesem Blatt geht es darum eine Datenbank einzurichten. Wir hosten sie auf der neuen VM 4 (`198.162.3.4`).

## Teilaufgaben

## 1) Datenbanken

1. **Voraussetzungen:**
    Zunächst war die Aufgabe eine beliebigen Datenbank-Server zu installieren solange er auf er aktuellsten stabilen Version läuft.
    Wir haben uns für **PostgreSQL** entschieden, da diese Datenbank von NixOS nativ unterstützt wird.
    Da unsere NixOS Version (`24.05`) nur PostgeSQL 16 unterstützt, musste zunächst die NixOS Version auf die im November 2024 erschienene `24.11` geupgradet werden.
    Nachdem wir den Speicher auf 32GB erhöht haben, fügen wir den aktuellsten NixOS channel hinzu und upgraden die Version.

    ```shell
    nix-channel --add https://nixos.org/channels/nixos-24.11 nixos
    nixos-rebuild switch --upgrade
    ```

    Wir fügen zudem die PostgreSQL tools in der `configuration.nix` hinzu.

    ```shell
    ...
    environment.systemPackages = with pkgs; [
        ...
        postgresql_17
    ];
    ...
    ```

2. **Einrichten von PostgreSQL:**

    ```nixos
    { config, lib, pkgs, ... }:
    {
        # DATABASE SETUP
        services.postgresql = {
            enable = true;
            package = pkgs.postgresql_17;
        };
    }
    ```

    Alle weiteren Konfigurationen werden in `services.postgresql` vorgenommen.

3. **User & Datenbanken:**
    In den nächsten Schritten werden die 2 geforderten Datenbanken und 3 geforderten User eingerichtet.

    | Nutzer | Datenbank | Beschreibung |
    |--------|-----------|--------------|
    | localusr | localusrdb | Nutzer, der auf seine Datenbank nur durch localhost Zugriff hat |
    | remotusr | localusrdb | Nutzer, der auf seine Datenbank nur remote-Zugriff hat |
    | ronlyusr |            | Nutzer, der nur read-only Zugriff auf alle Datenbanken hat |

4. **TCP Verbindungen erlauben**

    ```nixos
    enableTCPIP = true;
    ```

5. **Nutzer einrichten**

    ```nixos
    initialScript = pkgs.writeText "backend-initScript" ''
        ALTER USER postgres WITH PASSWORD '%%postgrespwd%%';
        CREATE ROLE localusr WITH LOGIN PASSWORD '%%localusrpwd%%';
        CREATE ROLE remotusr WITH LOGIN PASSWORD '%%remotusrpwd%%';
        CREATE ROLE ronlyusr WITH LOGIN PASSWORD '%%ronlyusrpwd%%';
    '';
    ```

    ```nixos
    authentication = pkgs.lib.mkOverride 10 ''
        #type database    DBuser    host            auth-method optional_ident_map
        local all         all                       peer        map=superuser_map
        local localusrdb  localusr                  password
        local all         ronlyusr                  password
        host  remotusrdb  remotusr  192.168.3.0/24  password
        host  all         replic    192.168.3.0/24  password
        host  team02db    team02    192.168.0.0/16  password
    '';
    ```

    ```nixos
    identMap = ''
       # ArbitraryMapName systemUser DBUser
       superuser_map      root      postgres
       superuser_map      root      localusr
       superuser_map      root      replic
       superuser_map      root      team02
       superuser_map      postgres  postgres
    '';
    ```

    ```nixos
    initialScript = pkgs.writeText "backend-initScript" ''
        ...
        ALTER DEFAULT PRIVILEGES GRANT SELECT ON TABLES TO ronlyusr;
        GRANT SELECT ON ALL TABLE IN SCHEMA public TO ronlyusr;
        GRANT SELECT ON ALL TABLE IN SCHEMA information_schema TO ronlyusr;
        GRANT SELECT ON ALL TABLE IN SCHEMA pg_catalog TO ronlyusr;
        GRANT SELECT ON ALL TABLE IN SCHEMA pg_toast TO ronlyusr;
    '';
    ```

6. **Datenbanken einrichten**

    ```nixos
    initialScript = pkgs.writeText "backend-initScript" ''
        ...
        CREATE DATABASE localusrdb;
        CREATE DATABASE remotusrdb;
        ALTER DATABASE localusrdb OWNER TO localusr;
        ALTER DATABASE remotusrdb OWNER TO remotusr;
    '';
    ```

Quellen:

- [nixos-manual upgrading](https://nlewo.github.io/nixos-manual-sphinx/installation/upgrading.xml.html)
- [nixos.org postgres options](https://search.nixos.org/options?channel=24.11&show=services.postgresqlBackup.pgdumpOptions&from=0&size=50&sort=relevance&type=packages&query=services.postgresql)

### 2) Backup

#TODO

1. **Erste Lösung: Dump**

    ```nixos
    services.postgresqlBackup = {
        enable = true;
        startAt = "*-*-* 01:15:00";
        location = "/var/backup/postgresql";
        compression = "gzip";
    };
    ```

2. **Verbesserung: Write-Ahead-Log**
    #TODO

Quellen:

- [nixos.org postgres options](https://search.nixos.org/options?channel=24.11&show=services.postgresqlBackup.pgdumpOptions&from=0&size=50&sort=relevance&type=packages&query=services.postgresql)
- [postgresql.org backup-dump](https://www.postgresql.org/docs/current/backup-dump.html)
- [postgresql.org WAL](https://www.postgresql.org/docs/current/runtime-config-wal.html#RUNTIME-CONFIG-WAL-SUMMARIZATION)

### 3) Testing

Das grundlegende Test-Setup bleibt identisch zu den vorherigen Wochen (siehe Blatt03).

1. #TODO

2. #TODO
