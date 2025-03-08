# Aufgabenblatt 08

In diesem Blatt geht es darum einen LDAP Server (VM 7) einzurichten und diesen von allen VMs für die Nutzer Authentifizierung zu nutzen.

## Teilaufgaben

### 1) LDAP Server

#### 1.1) Vorbereitung

Bevor wir mit dem Konfigurieren des Servers beginnen, müssen wir noch...

1. ein neues SSL Zertifikat vorbereiten.
2. ein eigenes LDAP Schema anlegen, was die Daten in der `benutzerdaten.csv` unterstützt.
3. die grundlegende Struktur, Nutzergruppe und SSSD-Nutzer in `base.ldif` anlegen.

Gehen wir detaillierter auf die Schritte ein:

1. **SSL Zertifikat**
    Mit...

    ```shell
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/openldap/slapd.key -out /etc/ssl/openldap/slapd.crt -subj "/C=DE/ST=Bayern/L=München/O=TUM-PSA/CN=ldap.psa-team03.cit.tum.de"
    ```

    legen wir ein neues Zetifikat und einen zugehörigen Schlüssel in `/etc/ssl/openldap` an (**Achtung:** der Pfad muss bereits existieren).
    Nun stellen wir noch sicher, dass die erstellent Dateien die richtigen owner und Zugriffsrechte haben:

    ```shell
    chown root:openldap /etc/ssl/openldap/slapd.*
    chmod 644 /etc/ssl/openldap/slapd.crt
    chmod 640 /etc/ssl/openldap/slapd.key
    ```

2. **LDAP Custom Nutzer Schema**
    Um Attribute wie die Matrikelnummre zu unterstützen müssen wir ein eigenes LDAP Schema anlegen, wleches eine neue `objectClass` definiert, welche all diese Attribute unterstützt.

    An dieser Stelle ein Danke an [Team 6](https://psa.in.tum.de/xwiki/bin/view/PSA%20WiSe%202024%20%202025/Dokumentation%20der%20Aufgaben/PSAwise2425Team6Aufgabe08/), welches solch ein vorgefertigtes Schema bereitgestellt hat. Hier wird eine Matrikelnummer, Geburtsdatum, Geburtsort, Nationalität und Geschlecht als zusätzliche Attribute in einer neuen Objekt-Klasse namens `auxPerson` bereitgestellt.

    ```ldif
    dn: cn=custom,cn=schema,cn=config
    objectClass: olcSchemaConfig
    cn: custom
    #
    # Attribute definitions
    #
    olcAttributeTypes: ( 2.25.86903029773847608291162177362021851782.1
      NAME 'matriculationnumber'
      DESC 'Matriculation number (10 digits)'
      EQUALITY numericStringMatch
      SUBSTR numericStringSubstringsMatch
      SYNTAX 1.3.6.1.4.1.1466.115.121.1.36{10}
      SINGLE-VALUE )
    olcAttributeTypes: ( 2.25.86903029773847608291162177362021851782.2
      NAME 'birthdate'
      DESC 'Date of birth (YYYY-MM-DD)'
      EQUALITY caseExactMatch
      ORDERING caseExactOrderingMatch
      SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{10}
      SINGLE-VALUE )
    olcAttributeTypes: ( 2.25.86903029773847608291162177362021851782.3
      NAME 'birthplace'
      DESC 'Place of birth'
      EQUALITY caseIgnoreMatch
      SUP name
      SINGLE-VALUE )
    olcAttributeTypes: ( 2.25.86903029773847608291162177362021851782.4
      NAME 'nationality'
      DESC 'Nationality'
      SUP name )
    olcAttributeTypes: ( 2.25.86903029773847608291162177362021851782.5
      NAME 'sex'
      DESC 'Sex (e.g., m, f, or o)'
      EQUALITY caseIgnoreMatch
      SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{1}
      SINGLE-VALUE )
    #
    # ObjectClass definitions
    #
    olcObjectClasses: ( 2.25.86903029773847608291162177362021851782.6
      NAME 'auxPerson'
      DESC 'Auxiliary object class with extra attributes'
      SUP top AUXILIARY
      MUST ( matriculationnumber $ birthdate $ birthplace )
      MAY ( nationality $ sex $ givenName $ sn $ street $ postalCode $ l $ telephoneNumber ) )
    ```

3. **grundlegende Struktur**

    Wir definieren hier die geforderte Struktur des LDAP Servers: Die beiden Gruppen `users` und `groups`, die jeweils die Nutzer und Nutzer-Gruppen speichern, alles unter der Base-Domain `team03.psa.cit.tum.de`.

    ```ldif
    dn: dc=team03,dc=psa,dc=cit,dc=tum,dc=de
    objectClass: dcObject
    objectClass: organization
    dc: team03
    o: TUM-PSA
    description: Team03 base directory

    dn: ou=users,dc=team03,dc=psa,dc=cit,dc=tum,dc=de
    objectClass: organizationalUnit
    ou: users

    dn: ou=groups,dc=team03,dc=psa,dc=cit,dc=tum,dc=de
    objectClass: organizationalUnit
    ou: groups
    ```

    Zudem legen wir direkt die einzige Nutzer-Gruppe an, die wir später brauchen.

    ```ldif
    dn: cn=psa,ou=groups,dc=team03,dc=psa,dc=cit,dc=tum,dc=de
    objectClass: posixGroup
    cn: psa
    gidNumber: 1000
    description: PSA main group
    ```

    Sowie einen SSSD Nutzer, um den Zugriff für den Authentifizierungs-Service SSSD zu ermöglichen.

    ```ldif
    dn: cn=sssd,dc=team03,dc=psa,dc=cit,dc=tum,dc=de
    objectClass: simpleSecurityObject
    objectClass: organizationalRole
    cn: sssd
    userPassword: {SSHA}TT4tqbhhjh7qOFoScy1PwcS4UII6mCDt
    ```

    Wir speichern alles in der Datei `baseconfig.ldif`, welche wir in 2.3 einlesen werden. Die übrigen Nutzer (Praktikum und `benutzerdaten.csv`) werden später automatisiert mit einem Skript angelegt.

Quellen:

- [brennan.id LDAP Basic Configuratoin](https://www.brennan.id.au/20-Shared_Address_Book_LDAP.html)
- [ArchLinux LDAP Documentation](https://wiki.archlinux.org/title/OpenLDAP)
- [Team06 LDAP Documentation](https://psa.in.tum.de/xwiki/bin/view/PSA%20WiSe%202024%20%202025/Dokumentation%20der%20Aufgaben/PSAwise2425Team6Aufgabe08/)

#### 1.2) NixOS Konfigurieren & Aktivieren

Unsere gesamte Nix Konfiguration kann in der `ldap.nix` eingesehen werden. Hier werden wir von oben nach unten alle wichtigen Schritte erklären:

1. Zunächst definieren wir ein paar Abkürzungen, welche wir in der Konfiguration verwenden wollen. Wir setzen hier
  
    1. unsere Team-spezifische LDAP Domäne
    2. unter welcher Domäne der Server erreichbar ist
    3. die Anmeldedaten für den LDAP Administrator (das Passwort wird mit `slappasswd -h {SSHA} -p <Passwort>` verschlüsselt abgelegt)
    4. sowie der Pfad zu dem eben generierten SSL Zertifikat und dessen privatem Schlüssel.

    ```nix
    { config, pkgs, ... }:
    let
        baseDN = "dc=team03,dc=psa,dc=cit,dc=tum,dc=de";
        domain = "ldap.team03.psa.cit.tum.de";

        rootName = "admin";
        rootPw = "{SSHA}2z9hw3YwUr94eBUdGhUmcnZht0TyF7VW";

        ssl.crtFile = "/etc/ssl/openldap/slapd.crt";
        ssl.keyFile = "/etc/ssl/openldap/slapd.key";
    in
    {
    ```

2. Nun kann die eigentliche NixOS Konfiguration beginnen. Wir Definieren hier folgende Dinge:

    1. Aktivieren des `openldap` Services (enable)
    2. Welches NixOS-Paket wir genau haben wollen (optional)
    3. Welche LDAP-Verbindungen erreichbar sein sollen (in unserem Fall nur die lokal verfügbare interaktive Schnittstelle `ldapi` und die auch extern erreichbare sichere LDAPS Schnittstelle `ldaps`)
    4. Außerdem wollen wir den LDAP Server nach Aktivierung auch manuell noch verändern können (`mutableConfig`)

    ```nix
        services.openldap = {
            enable = true;
            package = pkgs.openldap;
            urlList = ["ldapi:///" "ldaps:///"];
            mutableConfig = true;
    ```

3. In den `settings` unter `attrs` setzen wir das log-level, sowie ein paar Sicherheitsrelevante Einstellungen:

    1. Wir geben hier das zu nutzende (oben generierte) Zertifikat und dessen Schlüssel an
    2. Wir setzen eine minimale Protokoll Version um mögliche Angriffe auf älteren Protokollversionen zu mitigieren

    ```nix
            settings = {
                attrs = {
                    olcLogLevel = ["stats" "conns" "config" "acl"];
                    olcTLSCertificateFile = ssl.crtFile;
                    olcTLSCertificateKeyFile = ssl.keyFile;
                    olcTLSProtocolMin = "3.3";
                    olcTLSCipherSuite = "DEFAULT:!kRSA:!kDHE";
                };
    ```

4. In den `settings` unter `children` werden Einstellungen für die LDAP Datenbank vorgenommen. Die oberen Konfigurationen sind recht selbst-Erklärend, wir werden hier genauer auf die Daten im `olcAccess` eingehen. Wir richten hier 5 Zugriffsregeln auf die Datenbank ein:

    0. Der `root` Nutzer soll vollen Zugriff bekommen, um mögliche Konfigurationen oder Daten ändern zu können.
    1. Der LDAP Nutzer SSSD bekommt volle Lese-Rechte. Mit diesem Nutzer meldet sich der SSSD Service von Clients an, um Nutzerdaten abzufragen und diese zu authentifizieren.
    2. Auf die Nutzer-Passwörter soll jeder (`anonymous`) Lese-Rechte bekommen (Passwörter werden nur gehashed gespeichert!), aber nur der zugehörige Nutzer (`self`) soll dieses ändern können.
    3. Jeder soll die verfügbaren UIDs browsen können.
    4. Die Zertifikate der Nutzer sollen an alle bereit gestellt werden.
    5. Jeder Nutzer soll seine eigenen Daten alle auslesen können

    ```nix
                children = {
                    "olcDatabase={1}mdb".attrs = {
                        objectClass = ["olcDatabaseConfig" "olcMdbConfig"];
                        olcDatabase = "{1}mdb";
                        olcSuffix = baseDN;
                        olcRootDN = "cn=${rootName},${baseDN}";
                        olcRootPW = rootPw;
                        olcDbDirectory = "/var/lib/openldap/data";
                        olcAccess = [
                            ''
                              {0}to *
                               by dn.exact=uidNumber=0+gidNumber=0,cn=peercred,cn=external,cn=auth manage
                               by * break
                            ''
                            
                            ''
                             {1}to *
                              by dn.exact=cn=sssd,${baseDN} read
                              by * break
                            ''
                            
                            ''
                             {2}to attrs=userPassword
                              by anonymous auth
                              by self write
                              by * none
                            ''
                            
                            ''
                             {3}to attrs=entry,uid
                              by * read
                            ''

                            ''
                             {4}to attrs=userCertificate
                              by users read
                              by * none
                            ''
                            
                            ''
                             {5}to *
                              by self read
                              by * none
                            ''
                        ];
                    };
    ```

5. Zum Abschluss der NixOS Konfiguration geben wir noch die benötigten LDAP Schemata an.

    ```nix
                    "cn=schema".includes = [
                        "${pkgs.openldap}/etc/schema/core.ldif"
                        "${pkgs.openldap}/etc/schema/cosine.ldif"
                        "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
                        "${pkgs.openldap}/etc/schema/nis.ldif"
                        ./user-schema.ldif
                    ];
                };  
            };
        };
    }
    ```

6. Wir tragen nun diese `ldap.nix` wie gewohnt in unsere `configuration.nix` ein. Mit einem `nixos-rebuild switch` wenden wir die Konfiguration an, der LDAP Service wird automatisch gestartet.

**Achtung:** Es ist wichtig, dass der `nixos-rebuild switch` erst nach dem Anlegen dieser vollständigen Konfiguration erfolgt. Unerwarteter Weise führt ein nachträgliches Ändern der NixOS Konfiguratoin **nicht** zu einem Ändern der LDAP Konfiguration. Nachträgliche Änderungen müssen mit `ldapmodify`, oder durch ein erneutes Aufsetzen des Servers umgesetzt werden.

1. Existierende configs entfernen: `rm -r /var/lib/openldap/ /etc/openldap/`
2. LDAP deaktivieren: `nano /etc/nixos/ldap.nix` (`enable = false;`) & `nixos-rebuild switch`
3. LDAP re-aktivieren: `nano /etc/nixos/ldap.nix` (`enable = true;`) & `nixos-rebuild switch`
4. Die folgenden Schitte aus 2.3 neu anwenden

Quellen:

- [brennan.id LDAP Basic Configuratoin](https://www.brennan.id.au/20-Shared_Address_Book_LDAP.html)
- [ArchLinux LDAP Documentation](https://wiki.archlinux.org/title/OpenLDAP)
- [Team06 LDAP Documentation](https://psa.in.tum.de/xwiki/bin/view/PSA%20WiSe%202024%20%202025/Dokumentation%20der%20Aufgaben/PSAwise2425Team6Aufgabe08/)

#### 1.3) Dynamisches Einrichten

Nach der grundlegenden Konfiguration unseres LDAP Servers können wir nun alle Nutzerdaten anlegen. Dies erfordert 2 Schritte:

1. Einlesen der anfangs definierten grundlegenden Struktur, sowie der einzigen Nutzergruppe und dem SSSD Nutzer aus `baseconfig.ldif` mit `sudo ldapadd -H ldapi:// -Y EXTERNAL -f baseconfig.ldif`
2. Generieren der Nutzer-Konfigurationen durch ein Shell-Skript.

Auf den letzen Punkt gehen wir genauer ein:

1. Als erstes müssen wir die `benutzerdaten.csv` leicht anpassen. Dies ermöglicht eine einfachere Verarbetung mit dem Skript. Wir fügen alle Praktikumsnutzer (`ge*****`) hinzu und füllen unbekannte Felder mit einem default-Wert aus. So können wir diese Nutzer im selben Schwung mit verarbeiten. Wir fügen außerdem 2 neue Spalten ein: `UID` & `User`. In LibreOfficeCalc lassen sich folgende Schritte in Sekunden eintragen:

    1. `UID` beinhaltet für die Praktikumsnutzer die vorherigen UIDs (`1<TeamNummer><TeamMitglied>`) und für die ursprünglichen csv-Nutzer aufsteigende UIDs ab `10000`.
    2. `User` beinhaltet die Nutzerkennung. Für die Praktikumsnutzer ist dies `ge*****`, für die ursprünglichen csv-Nutzer die ersten 5 Zeichen von Vorname+Nachname (automatisch mit `=LOWER(LEFT(A22 & B22, 5))` generiert)

2. Mit `ldap-user-config.sh -g` generiert das Skript die `.ldif` Konfigurationen für jeden Nutzer nach dem folgenden Schema:

    ```shell
    dn: uid=$User,ou=users,dc=team03,dc=psa,dc=cit,dc=tum,dc=de
    objectClass: posixAccount
    objectClass: account
    objectClass: pkiUser
    objectClass: auxPerson
    uid: $User
    cn: $Vorname $Name
    uidNumber: $UserID
    gidNumber: 1000
    homeDirectory: /home/$User
    loginShell: /bin/bash
    userPassword: $PasswordHash
    userCertificate;binary:: $Certificate
    givenName: $Name
    sn: $User
    sex: $Geschlecht
    birthdate: $Geburtsdatum
    birthplace: $Geburtsort
    nationality: $Nationalitaet
    street: $Strasse
    postalCode: $PLZ
    l: $Ort
    telephoneNumber: $Telefon
    matriculationNumber: $Matrikelnummer
    description: User $Vorname $Name
    ```

    Alle Daten bis auf `$PasswordHash` und `$Certificate` werden 1-zu-1 aus der `csv` übernommen. Das Passwort wird zufällig gewählt, unter `ldap-user-attach/$User/$User-ldap.passwort` abgelegt, per `slappassword` gehasht und hier in die `.ldif` eingefügt. Das Zertifikat wird ebenfalls neu generiert (`openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $KEY_FILE -out $CERT_FILE -subj "/C=DE/ST=Bayern/L=München/O=TUM-PSA/OU=users/CN=$User/emailAddress=$User@psa-team03.cit.tum.de"`) und in dem Nutzer-Verzeichnis `ldap-user-attach/$User` abgelegt und base64 kodiert in der `.ldif` Konfiguration abgelegt.

    ```shell
    # Zertifikat Konvertierung
    openssl x509 -in $CERT_FILE -outform der -out $CERT_FILE.der
    base64 -w 0 $CERT_FILE.der > $CERT_FILE.b64
    Certificate=$(cat $CERT_FILE.b64)
    ```

3. Mit `ldap-user-config.sh -a` werden diese mit `sudo ldapmodify -ac -Y EXTERNAL -H ldapi:// -Q -f $file` angewandt. Die "Start-Passwörter" können übrigens unter `/root/ldap/ldap-user-attach/` gefunden werden.

Somit ist die Server Seite fertig und wir können uns dem Client widmen.

### 2) LDAP Clients

Wir wollen nun auf allen VMs die Nutzung des LDAP Servers zur Authenifizierung einrichten. Dies benötigt 4 Schritte:

1. Passwort-Authentication erlauben
2. Nutzer entfernen & Automounts hinzufügen
3. `sssd.config` & `slapd.crt` anlegen
4. Auf SSSD Fehler prüfen: `journalctl -u sssd.service --no-pager --since "10 minutes ago"`

Im Detail:

1. **Passwort Authentifizierung** wurde für SSH anfangs nicht erlaubt, da Nutzer nur per ssh-key Zugriff hatten. Dies müssen wir für alle VMs ändern:

    ```nix
    # configuratoin.nix
    services.openssh.settings.PasswordAuthentication = true;
    ```

2. **Nutzer** wurden bisher in der `user-config.nix` angelegt, sowie deren Homeverzeichnisse auf Automount gestellt. Wir entfernen hier alle Nutzer, und fügen in der `csv-users.nix` noch die Automounts für die Homeverzeichnisse der anderen Nutzer hinzu. Dies erfolgt automatisiert über das `home-create-csv-users.sh` Skript.

3. **SSSD** muss konfiguriert und aktiviert werden. Hierfür legen wir eine Konfiguration an (Quelle Team06):

    ```config
    [sssd]
    config_file_version = 2
    services = nss, pam
    domains = LDAP

    [domain/LDAP]
    cache_credentials = true
    enumerate = false
    
    id_provider = ldap

    ldap_uri = ldaps://ldap.psa-team03.cit.tum.de
    ldap_search_base = dc=team03,dc=psa,dc=cit,dc=tum,dc=de
    #set following line to demand
    ldap_tls_reqcert = allow
    ldap_default_bind_dn = cn=sssd,dc=team03,dc=psa,dc=cit,dc=tum,dc=de
    ldap_default_authtok_type = password
    ldap_default_authtok = $SSSD_LDAP_DEFAULT_AUTHTOK
    ```

    Das Passwort speichern wir an dieser Stelle nicht Plaintext, sondern als Umgebungsvariable in `/etc/secrets/sssd.env` mit dem Inhalt `SSSD_LDAP_DEFAULT_AUTHTOK=<Passwort>` und den Rechten `600`. Als ein Kommando zum anlegen:

    ```shell
    mkdir -p /etc/secrets && echo "SSSD_LDAP_DEFAULT_AUTHTOK=<Passwort>" >> /etc/secrets/sssd.env && chmod 600 /etc/secrets/sssd.env
    ```

    und stellen das Server Zertifikat bereit. Beides geben wir in der NixOS Konfiguration `ldap-client.nix` an, welche wir auf allen Client-VMs einbinden. Hier aktivieren wir SSSD direkt:

    ```nix
    {
      config,
      lib,
      ...
    }: let
      sssdConf = builtins.readFile ./sssd.conf;
    in {
        services.sssd = {
          enable = true;
          config = sssdConf;
          environmentFile = "/etc/secrets/sssd.env";
        };
        security.pki.certificateFiles = [./slapd.crt];
    }
    ```

4. **Prüfen** können wir den SSSD Status nach einem `nixos-rebuild switch` mit `journalctl -u sssd.service --no-pager --since "10 minutes ago"`.

Quellen:

- [brennan.id LDAP Basic Configuratoin](https://www.brennan.id.au/20-Shared_Address_Book_LDAP.html)
- [ArchLinux LDAP Documentation](https://wiki.archlinux.org/title/OpenLDAP)
- [Team06 LDAP Documentation](https://psa.in.tum.de/xwiki/bin/view/PSA%20WiSe%202024%20%202025/Dokumentation%20der%20Aufgaben/PSAwise2425Team6Aufgabe08/)

### 3) Extra: Portunus

Wir haben uns zwar dagegen entschieden dieses Tool zu benutzen, aber wollten es hier dennoch kurz erwähnen: Portunus ist eine graphische Schnittstelle die einen openldap-Server im Hintergrund handhabt und auch nativ auf NixOS verfügbar ist.
Es lohnt sich da mal einen Blick rein zu werfen: [Github Portunus](https://github.com/majewsky/portunus)

Quellen:

- [Github Portunus](https://github.com/majewsky/portunus)
