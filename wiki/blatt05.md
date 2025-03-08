# Aufgabenblatt 05

In diesem Blatt geht es darum eine Datenbank einzurichten. Wir hosten sie auf der neuen VM 4 (`198.162.3.4`). Das Backup wird auf einer separaten VM (VM 2, `192.168.3.2`) gehostet.

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

    *Hinweis: Falls der postgresql.service nach dem rebuild failt, Schritte [hier](https://github.com/NixOS/nixpkgs/issues/74357) befolgen und danach die Datenbank wiederherstellen*

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

    Als nächstes schränken wir den Zugriff auf die Datenbanken jedes Nutzers ein. Dies geschieht in `authentication = ...` indem für jede Verbindung erst der Verbindungs-Typ, die Datenbank auf die zugegriffen werden soll, der Nutzer, optional die host-IP und die Authentifizierung-Methode eingegeben werden soll. Wie oben beschrieben sollen die Nutzer `localusr` und `ronlyusr` nur lokal zugreifen, der `remotusr` nur von einer anderen VM in unserem Team-Netzwerk auf die Datenbanken, bzw. nur seine Datenbank, zugreifen können.

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

## 2) Backup

### Erste Lösung: Dump

Nativ unterstützt NixOS 2 Arten von postgresql backups, eine davon ist durch naive dumps der Datenbank. In `location` definieren wir den Pfad zum backup-Verzeichniss.

```nixos
services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 01:15:00";
    location = "/var/backup/postgresql";
    compression = "gzip";
};
```

Nachdem das Backup allerdings auch für viel größere Datenbanken ohne große Einschränkungen skalierbar sein muss, ist einen kompletten dump zu erstellen keine ausreichende Lösung. Mittels eines Write-Ahead-Logs können lange Pausen eines dumps umgangen werden. Diese Lösung ist im folgenden Abschnitt beschrieben:

### Verbesserung: Write-Ahead-Log (WAL)

Für die WAL Lösung setzen wir eine weitere Datenbank auf (auf VM 2), identisch zur ersten Datenbank. Nun haben wir 2 Datenbanken, wir nennen sie in dieser Anleitung *Master DB* und *Backup DB*.

```ascii
┌─────────────┐         ┌───────────────┐
│  Master DB  │         │   Backup DB   │
│ 192.168.3.4 │         │  192.168.3.2  │
│             │         │               │
│   ┌────┐    │         │┌────┐ ┌──────┐│
│   │ DB │    │   WAL   ││ DB │ │Backup││
│   │  ──┼────┼─────────┼┼─►  │ │      ││
│   │    │    │         ││  ──┼─┼─►    ││
│   └────┘    │         │└────┘ └──────┘│
└─────────────┘         └───────────────┘
```

Zwischen beiden VMs findet das WAL von der DB in die *Backup DB* statt. Von der *Backup DB* können dann zusätzlich ganze Zwischenzustände in ein Backup gespeichert werden, da hier die Datenbank Verfügbarkeit der *Master DB* nicht beeinträchtigt wird.

1. *Master DB*
    Wir benötigen zunächst einen neuen Nutzer mit `replikation` Rechten. Wir tragen diesen in der config ein und fügen (ähnlich wie mit den anderen Nutzern) diesen direkt auch in der authentication ein, um den remote-Zugriff zu ermöglichen:

    ```nixos
    # database.nix
    authentication = pkgs.lib.mkOverride 10 ''
        ..
        host  all,replication replic    192.168.3.0/24  password
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
        ...
        CREATE ROLE replic WITH REPLICATION WITH LOGIN PASSWORD '%%replicpwd%%';
    '';
    ```

    Aufgrund eines bugs wird der Nutzer leider nicht ganz richtig erstellt, weshalb wir diesen nach dem Neustart erneut manuell hinzufügen müssen:

    ```bash
    sudo -u postgres createuser -U postgres replic -P -c 5 --replication
    ```

    Zusätzlich zu diesem Nutzer wird Archiving und das WAL aktiviert:

    ```bash
    sudo -u postgres psql postgres
    ALTER SYSTEM SET archive_mode to 'ON';
    ALTER SYSTEM SET archive_mode to 'cp %p /scratch/postgres/backup/archive/archive%f';
    ALTER SYSTEM SET archive_command to 'test ! -f /var/lib/postgresql/pg_log_archive/main/%f && cp %p /var/lib/postgresql/pg_log_archive/main/%f';
    ```

    Der Ordner für das Archive muss bei der Ausführung des `archive_command` bereits exisiteren und `postgres` gehören, weshalb dieser jetzt noch erstellt werden muss:

    ```bash
    mkdir /var/lib/postgresql/pg_log_archive/main
    chown postgres:postgres -R /var/lib/postgresql/pg_log_archive/main/
    ```

    Um die Änderungen anzuwenden, muss zuletzt der `postgresql.service` neu gestartet werden:

    ```bash
    systemctl restart postgresql.service
    ```

2. *Backup DB*
    Mit `./script/sync-nixos-config.sh` laden wir die neue Datenbank.
    Nun muss der Backup-Mechanismus eingerichtet werden. Wir definieren hierfür diese *Backup DB* als standby-server und definieren die primäre Datenbank (*Master DB*) samt Zugang.

    ```bash
    sudo -u postgres postgres
    ALTER SYSTEM SET hot_standby to 'on';
    ALTER SYSTEM SET primary_conninfo to 'host=192.168.3.4 port=5432 user=replic password=<password>';
    ALTER SYSTEM SET data_sync_retry to 'on';
    ```

    Wieder wird `postgresql.service` neu gestartet, um Änderungen anzuwenden:

    ```bash
    systemctl restart postgresql.service
    ```

    Als zweiten Schritt setzen wir noch die Datenbank auf den Stand der *Master DB* und richten die Backup-Funktion ein. Hierfür löschen (bzw. verschieben) wir bisherige Teile der DB...

    ```bash
    mv /var/lib/postgresql/17 /var/lib/postgresql/17_old
    ```

    ...und wenden `pg_basebackup` an.

    ```bash
    sudo -u postgres pg_basebackup -h 192.168.3.4 -D /var/lib/postgresql/17 -U replic -v -P --wal-method=stream -R
    ```

    Nach einem weiteren Neustart von `postgresql.service` ist das WAL fertig eingerichtet:

    ```bash
    systemctl restart postgresql.service
    ```

3. Test WAL
    Um das WAL zu testen, können wir testweise eine Tabelle und ein paar Einträge auf der *Master DB* anlegen. Hier beispielsweise mit dem Nutzer `localusr` und seiner Datenbank:

    ```bash
    # master-db
    psql -U localusr localusrdb
    CREATE TABLE cpt_team (email text, vistor_id serial, date timestamp, message text);
    INSERT INTO cpt_team (email, date, message) VALUES ( 'myoda@gmail.com', current_date, 'Now we are replicating.');
    INSERT INTO cpt_team (email, date, message) VALUES ( 'myfingworking@gmail.com', current_date, 'Now we are replicating AND IT WORKS.');
    ```

    Auf der *Backup DB* können wir mit `\dt` nun die neue Tabelle einsehen, sowie mit `SELECT * FROM cpt_team;` die erstellten Einträge ansehen.

    ```bash
    # backup-db
    psql -U localusr localusrdb
    \dt
    SELECT * FROM cpt_team;
    ```

4. Backup Skript
    Zusätzlich können wir den oben Erwähnten `dump` nutzen, um Backups von bestimmten Zeitpunkten zu haben. Wenn diese auf der *Backup DB* ausgeführt werden wird die Datenbank Funktionalität / Erreichbarkeit der *Master DB* nicht eingeschränkt.
    Nachdem die Aufgabenstellung ein Skipt mit `crontab` fordert, können wir die von NixOS bereitgestellte Backup-Funktion von oben nicht nutzen, sondern erstellen ein separates Skript.

    Nachdem wir `user` (postgres), sowie die Pfade zum backup- und zum log-file definieren, können wir mit `pg_dumpall` ein einfaches Backup erstellen, ähnlich zum `services.postgresqlBackup`. Wir erstellen hierbei lokal ein Backup con wirklich allem und Nutzen deshalb den postgres Nutzer:

    ```bash
    # backup_postgres.sh
    pg_dumpall -U "$user" --verbose > "$backup" 2> "$log"
    ```

    NixOS unterstütz crontabs nativ. Somit können wir sehr einfach crontab aktivieren und dann mit `crontab -e` einen neuen cronjob anlegen, der jeden Tag das eben erstelle Skript ausführt. Mit `15 01 * * *` können wir das jeden Tag einmal um 01:15 geschehen lassen. Mit `MAILTO` könnte man zusätzlich eine Mail mit dem output verschicken.

    ```nixos
    # database-backup.nix
    services.cron = {
        enable = true;
    };
    ```

    ```crontab
    # crontab -e
    15 01 * * * ./root/backup_postgres.sh
    ```

    Mit `crontab -l` können wir verifizieren, dass der Cronjob wirklich läuft.

Quellen:

- [ibrahimhkoyuncu.medium.com high-availability read replica](https://ibrahimhkoyuncu.medium.com/postgresql-high-availability-read-replica-methodology-streaming-replication-and-replica-75f9067326e5)
- [nixos.org postgres options](https://search.nixos.org/options?channel=24.11&show=services.postgresqlBackup.pgdumpOptions&from=0&size=50&sort=relevance&type=packages&query=services.postgresql)
- [postgresql.org backup-dump](https://www.postgresql.org/docs/current/backup-dump.html)
- [postgresql.org WAL](https://www.postgresql.org/docs/current/runtime-config-wal.html#RUNTIME-CONFIG-WAL-SUMMARIZATION)
- [phoenixnap.com setup cron job](https://phoenixnap.com/kb/set-up-cron-job-linux)
- [nixos.org cron](https://nixos.wiki/wiki/Cron)

## 3) Testing

Das grundlegende Test-Setup bleibt identisch zu den vorherigen Wochen (siehe Blatt03).
Das Skipt kann sowohl auf der *Master DB*, als auch der *Backup DB* VM ausgeführt werden und ändert die zu laufenden Tests automatisch für die jeweilige VM.

1. *Master DB VM*
    Zunächst prüfen wir, ob alle geforderten Datanbanken verfügbar sind.
    Alle Tests werden ähnlich ablaufen:
    1. mit `psql -U ... -c "..." | grep "..." &> /dev/null` prüfen, ob der jeweilige Befehl erfolgreich ausgeführt werden kann.
    2. mit `if [ $? -eq 0 ]; then` Ergebniss prüfen.
    3. bei manchen Tests kann dies über eine Reihe an Inputs erfolgen. Mit `for ... in ${...[@]}; do ...` kann hierbei über eine Liste an Inputs iteriert werden.

    ```bash
    # test_PSA_05.sh
    start_test "check if databases exist"
    databases=(
        postgres
        remotusrdb
        localusrdb
    )
    for db in ${databases[@]}; do
        psql -U postgres -c "\l" | grep "${db}" &> /dev/null
        if [ $? -eq 0 ]; then
            print_success "$db exists"
        else
            print_failed "$db not found"
        fi
    done
    ```

    Ähnlich können wir testen, ob alle geforderten Nutzer verfügbar sind:

    ```bash
    # test_PSA_05.sh
    start_test "check if users exist"
    users=(
        postgres
        remotusr
        localusr
        ronlyusr
    )
    for usr in ${users[@]}; do
        psql -U postgres -c "\du" | grep "${usr}" &> /dev/null
        if [ $? -eq 0 ]; then
            print_success "$usr exists"
        else
            print_failed "$usr not found"
        fi
    done
    ```

    Zuletzt können wir überprüfen, ob das WAL funktioniert. Hierfür benötigt es mehrere Schritte, jeder Schritt wird hierbei als Test ausgegeben, um mögliche Fehler einfacher zu finden:
    Mit dem Nutzer `postgres` haben wir Zugriff auf alle Datenbanken. Mit diesem können wir einfach eine Test-Tabelle für den Nutzer `remotusr` erstellen, diesen als `OWNER` eintragen und einen simplen Eintrag erstellen:

    ```bash
    # test_PSA_05.sh
    # create table in remotusrdb
    sql_cmd="CREATE TABLE cpt_team (email text, vistor_id serial, date timestamp, message text);"
    expect="CREATE TABLE"
    psql -U postgres -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    if [ $? -eq 0 ]; then
        print_success "created table in remotusrdb"
    else
        print_failed "couldn't create table in remotusrdb"
    fi
    # change owner of this table
    sql_cmd="ALTER TABLE cpt_team OWNER TO remotusr;"
    expect="ALTER TABLE"
    psql -U postgres -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    if [ $? -eq 0 ]; then
        print_success "make remotusr owner of new table"
    else
        print_failed "couldn't make remotusr owner of new table"
    fi
    # create entry in remotusrdb table
    sql_cmd="INSERT INTO cpt_team (email, date, message) VALUES ( 'myoda@gmail.com', current_date, 'Now we are replicating.');"
    expect="INSERT 0 1"
    psql -U postgres -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    if [ $? -eq 0 ]; then
        print_success "created entry in remotusrdb table"
    else
        print_failed "couldn't create entry in remotusrdb table"
    fi
    ```

    Danach können wir uns remote auf die backup database einloggen. Der Nutzer `remotusr` hat remote Zugriff. Hier prüfen wir, ob die eben lokal erstellten Einträge auch auf der *Backup DB VM* vorhanden sind:

    ```bash
    # test_PSA_05.sh
    backup_addr="192.168.3.2"
    sql_cmd="SELECT * FROM cpt_team;"
    expect="Now we are replicating."
    psql -h "$backup_addr" -p 5432 -U remotusr -W -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    if [ $? -eq 0 ]; then
        print_success "table & entry exists at backup database ($backup_addr)"
    else
        print_failed "table or entry not found in backup database ($backup_addr)"
    fi
    ```

    Mit einem kleinen cleanup des Tests sind die Tests für diese VM fertig:

    ```bash
    sql_cmd="DROP TABLE cpt_team;"
    expect="DROP TABLE"
    psql -U postgres -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    ```

2. *Backup DB VM*
    Auf der Backup VM werden wir nurnoch das Backup-Skript `backup_postgres.sh` überprüfen.
    Hierfür merken wir uns die aktuelle Zeit `time=$(date +"%Y%m%d-%H%M%S")` und führen dann das Skript aus. Wir können überprüfen, ob das Skript den richtigen Rückgabewert hat, ein neues Backup existiert und ob ein zugehöriges log existiert:

    ```bash
    ./backup_postgres.sh
    if [ $? -eq 0 ]; then
        ...
    if [ -f "/root/backup_postgres/backup_${time}.dump" ]; then
        ...
    if [ -f "/root/backup_postgres/backup_${time}.log" ]; then
        ...
    ```
