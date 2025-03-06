# Aufgabenblatt 08

In diesem Blatt geht es darum einen LDAP Server (VM 7) einzurichten und diesen von allen VMs für die Nutzer Authentifizierung zu nutzen.

## Teilaufgaben

**Alles noch TODO...**

### 0) Notizen

Lösungsansätze:

- [x] **SOLVED** Anleitung: Fehler bei Einlesen con base.ldif
    `sudo ldapadd -H ldapi:// -Y EXTERNAL -f base.ldif`

    ```shell
    adding new entry "dc=team03,dc=psa,dc=cit,dc=tum,dc=de"
    ldap_add: Invalid DN syntax (34)
           additional info: invalid DN
    ```

    ~~Schon 2-mal von vorne versucht...~~
    ~~Hab es nicht hinbekommen das Problem zu lösen, weiß nicht was schief läuft.~~
    ~~Wenn man das hinbekommen würde wäre das hier ein möglicher Lösungsansatz...~~
    ~~Optional auch erstmal ohne SSL. Schauen ob das klappt?~~

    Test Hat geklappt, nachdem

    1. SSL-Zeritifikat, custom.ldif & nix-config fertig waren
    2. ich dann nochmal `/etc/openldap/` und `/var/lib/openldap/` gelöscht habe
    3. und dann `openldap.enable` in der nix-config einmal deaktiviert und wieder aktivier habe

    Das hat anscheinend alles nochmal richtig geladen.
    Versuche es jetzt weiter...

    `rsync -avz -e "ssh" --progress ge96xok@psa.in.tum.de:/opt/psa/data/Aufgabe_8/benutzerdaten.csv scripts/ldap` + Benutzerdaten der Praktikumsteilnehmer hinzufügen (default Daten wo unbekannt)

    `=LOWER(LEFT(A22 & B22, 5))` für User ID Generierung der nicht-Praktikums-Nutzer
    -> fertige Tabelle mit allen (Praktikum & csv) Nutzern (vielleicht auch nochmal hochladen)
    -> nur ein Skript für alle :)

    generate config `./ldap-user-config.sh -g` & apply `-a`

    User erfolgreich durch Mega-Skript hinzugefügt -> Zertifikate & Passwörter aktuell in commit `b845478`, als Info falls das aus versehen geändert wird :)

    Nutzer-Verzeichnisse auf fileserver für neue csv Nutzer anlegen & mounten

    Zugriff auf LDAP Server einschränken -> nixos config

    Client: password authentication erlauben, `sssd.config` & `slapd.crt` jedem bereitstellen + `/etc/secrets/sssd.env` anlegen

- [ ] Dieser Arch-Linux LDAP Anleitung folgen: [wiki.archlinux.org](https://wiki.archlinux.org/title/OpenLDAP)
    Optional auch erstmal ohne SSL. Schauen ob das klappt?

- [ ] Einrichten auf einem nicht-NixOS System & hoffen dass man es da hinbekommt (mehr Anleitungen, Quellen, etc.)
    Benötigt allerdings das Einrichten einer neuen nicht NixOS-VM, mit samt Nutzern, DNS, etc.
    Wäre vermutlich mehr Aufwand als es irgendiwe auf NixOS hinzukommen. Wäre nur ne Notfall-Lösung...
