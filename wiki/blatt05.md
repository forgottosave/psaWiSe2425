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
    Zunächst erstellen wir eine neue `database.nix` Konfiguration. Diese wird auch in `scripts/vm-configs/vm-4.sh` zu den `include_files` hinzugefügt.
    Das aktivieren von PostgreSQL wird dann wie folgt eingetragen:

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

    Alle weiteren Konfigurationen werden hier in `services.postgresql = {...}` vorgenommen.

3. **User & Datenbanken:**
    In den nächsten Schritten werden die 2 geforderten Datenbanken und 3 geforderten User eingerichtet.

    | Nutzer | Datenbank | Beschreibung |
    |--------|-----------|--------------|
    | localusr | localusrdb | Nutzer, der auf seine Datenbank nur durch localhost Zugriff hat |
    | remotusr | localusrdb | Nutzer, der auf seine Datenbank nur remote-Zugriff hat |
    | ronlyusr |            | Nutzer, der nur read-only Zugriff auf alle Datenbanken hat |

4. **TCP Verbindungen erlauben**
    Nachdem wir mit mindestens einem Nutzer remote-Zugriff benötigen aktivieren wir zunächst TCP/IP für unsere Datenbank:

    ```nixos
    enableTCPIP = true;
    ```

5. **Nutzer einrichten**
    Die 3 Nutzer werden wie folgt eingerichtet:

    ```nixos
    initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE localusr WITH LOGIN PASSWORD '%%localusrpwd%%';
        CREATE ROLE remotusr WITH LOGIN PASSWORD '%%remotusrpwd%%';
        CREATE ROLE ronlyusr WITH LOGIN PASSWORD '%%ronlyusrpwd%%';
    '';
    ```

    Da wir die vergebenen Passwörter nicht auf das git-Repository pushen wollen, nutzen wir hier Wildcards, die bei der Ausführung des Skripes durch die eigentlichen Passwörter ersetzt werden (siehe Blatt 2). Die Passwörter werden aus einem nur für root lesbaren directory unter `/root/db-user-pwds/<Nutzer>.pwd` erwartet.

    Die Wildcards tragen wir in `scripts/vm-configs/vm-4.sh` als Wildcards ein:

    ```shell
    postgrespwd=`cat /root/db-user-pwds/postgres.pwd`
    localusrpwd=`cat /root/db-user-pwds/localusr.pwd`
    remotusrpwd=`cat /root/db-user-pwds/remotusr.pwd`
    ronlyusrpwd=`cat /root/db-user-pwds/ronlyusr.pwd`

    sed_placeholders[postgrespwd]="$postgrespwd"
    sed_placeholders[localusrpwd]="$localusrpwd"
    sed_placeholders[remotusrpwd]="$remotusrpwd"
    sed_placeholders[ronlyusrpwd]="$ronlyusrpwd"
    ```

    Dem per default erstellen Nutzer `postgres` vergeben wir ebenfalls ein Passwort mit Wildcard:

    ```nixos
    initialScript = pkgs.writeText "backend-initScript" ''
        ...
        ALTER USER postgres WITH PASSWORD '%%postgrespwd%%';
    '';
    ```

    NAls nächstes schränken wir den Zugriff auf die Datenbanken jedes Nutzers ein. Dies geschieht in `authentication = ...` indem für jede Verbindung erst der Verbindungs-Typ, die Datenbank auf die zugegriffen werden soll, der Nutzer, optional die host-IP und die Authentifizierung-Methode eingegeben werden soll. Wie oben beschrieben sollen die Nutzer `localusr` und `ronlyusr` nur lokal zugreifen, der `remotusr` nur von einer anderen VM in unserem Team-Netzwerk auf die Datenbanken, bzw. nur seine Datenbank, zugreifen können.

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

    *Achtung:*
    Zur Einrichtung der Datenbank benötigt NixOS Vollzugriff auf den Nutzer postgres, *OHNE* Passwort, deshalb erlaubt hier der Einfachheit halber die erste Zeile Zugriff von root auf dieser Machiene auf alle Nutzer. Die Authentifizierung kann später manuell in `/var/postgresql/17/main/pg_hba.conf` geändert werden und erfordert einen Neustart des postgres services.
    Wir haben zudem die identMap `superuser_map` angelegt, um den Zugriff auf die Datenbank-Nutzer explizit nur mit root zu ermöglichen.

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

    Als letztes kümmern wir uns um den Read-Only-Nutzer `ronlyusr` und geben ihm lese (`SELECT`) Rechte auf allen Datenbanken, sowie default-lese Rechte für später erstellte Datenbanken. Die existierenden Schemata können mit`\du *.*` abgerufen werden.

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
    Als letztes müssen wir nurnoch die Datenbanken `localusrdb` und `remotusrdb` anlegen. Ihre jeweiligen Nutzer sollen Voll-Zugriff auf die Datenbanken erhalten. Nachdem die Datenbanken in unserem Scenario logisch gesehen den Nutzern gehören, setzen wir das auch hier um. Dies ermöglicht auch den Vollzugriff.

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

#### Erste Lösung: Dump

```nixos
services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 01:15:00";
    location = "/var/backup/postgresql";
    compression = "gzip";
};
```

#### Verbesserung: Write-Ahead-Log

1. Master DB

    ```bash
    sudo -u postgres createuser -U postgres replic -P -c 5 --replication
    ```

    default wal_level is already replica -> nothing to change

    ```bash
    sudo -u postgres psql postgres
    ALTER SYSTEM SET archive_mode to 'ON';
    ALTER SYSTEM SET archive_mode to 'cp %p /scratch/postgres/backup/archive/archive%f';
    ALTER SYSTEM SET archive_command to 'test ! -f /var/lib/postgresql/pg_log_archive/main/%f && cp %p /var/lib/postgresql/pg_log_archive/main/%f';
    ```

    ```bash
    mkdir /var/lib/postgresql/pg_log_archive/main
    chown postgres:postgres -R /var/lib/postgresql/pg_log_archive/main/
    ```

    we have to restart the postgres service for these changes to apply

    ```bash
    systemctl restart postgresql.service
    ```

2. Slave DB

    ```bash
    ./script/sync-nixos-config.sh
    ```

    ```bash
    sudo -u postgres postgres
    ALTER SYSTEM SET hot_standby to 'on';
    ALTER SYSTEM SET primary_conninfo to 'host=192.168.3.4 port=5432 user=replic password=<password>';
    ALTER SYSTEM SET data_sync_retry to 'on';
    ```

    ```bash
    systemctl restart postgresql.service
    ```

    ```bash
    mv /var/lib/postgresql/17 /var/lib/postgresql/17_old
    ```

    ```bash
    sudo -u postgres pg_basebackup -h 192.168.3.4 -D /var/lib/postgresql/17 -U replic -v -P --wal-method=stream -R
    ```

    ```bash
    systemctl restart postgresql.service
    ```

3. Test backup

    ```bash
    # master-db
    psql -U localusr localusrdb
    CREATE TABLE cpt_team (email text, vistor_id serial, date timestamp, message text);
    INSERT INTO cpt_team (email, date, message) VALUES ( 'myoda@gmail.com', current_date, 'Now we are replicating.');
    INSERT INTO cpt_team (email, date, message) VALUES ( 'myfingworking@gmail.com', current_date, 'Now we are replicating AND IT WORKS.');
    ```

    ```bash
    # slave-db
    psql -U localusr localusrdb
    \dt
    SELECT * FROM cpt_team;
    ```

Quellen:

- [nixos.org postgres options](https://search.nixos.org/options?channel=24.11&show=services.postgresqlBackup.pgdumpOptions&from=0&size=50&sort=relevance&type=packages&query=services.postgresql)
- [postgresql.org backup-dump](https://www.postgresql.org/docs/current/backup-dump.html)
- [postgresql.org WAL](https://www.postgresql.org/docs/current/runtime-config-wal.html#RUNTIME-CONFIG-WAL-SUMMARIZATION)

### 3) Testing

Das grundlegende Test-Setup bleibt identisch zu den vorherigen Wochen (siehe Blatt03).

1. #TODO

2. #TODO
