# Aufgabenblatt 09

In diesem Blatt geht es darum einen Mailserver einzurichten. Dieser wird bei uns auf VM 9 gehostet.

Aufgaben:

1) MTA (Mail Transfer Agent) unter der subdomain `psa-team03.cit.tum.de` aufsetzen -> `postfix`
   - Adresse `postmaster@...` muss existieren und soll an die Mail–Adresse des zuständigen Administrators weitergeleitet werden
   - unter keinen Umständen als open relay konfigurieren
   - Mails für unbekannte Empfänger bereits im SMTP-Dialog ablehnen
   - von auth. Nutzern alle Mails annehmen falls nicht lokal oder in Praktikumsumgebung zustellbar an Server `mailrelay.cit.tum.de` weiterleiten (ggf. header überschreiben da mailrelay nichts von der Praktikumsumgebung weiß)
   - bei alle versendeten oder zugestellten Mails From:-Header prüfen -> falls die Form `@irgendeinhostname.psa-team##.cit.tum.de` Header umschreiben und `irgendeinhostname.` löschen
   - alle versendeten oder zugestellten Mails mittels Virenscanner (clamav) prüfen -> geeignete Maßnahmen bei Fund
   - alle versendeten oder zugestellten Mails mittels Spamfilter (spamassassin) prüfen-> geeignete Maßnahmen bei Fund
2) Netzwerk konfigurieren:
   - DNS-Server: den MX-Record für alle Team-VMs auf den des Mail-Servers
   - Alle anderen Team-VMs: Mails über den Mail-Server versenden
3) IMAP/POP3 -> `dovecot`
   - für alle Benutzer der Team-VMs eine Mailbox bereitstellen
   - MTA muss an die jeweiligen Mailboxen zustellen
4) Testen der config

## Aufgabe 1: MTA aufsetzen (Postfix)

### 1.1 Basis-Konfiguration

Um den Mailserver unter der Subdomain `psa-team03.cit.tum.de` aufzusetzen, aktivieren wir Postfix und legen grundlegende Parameter fest. Damit stellen wir sicher, dass Postfix als MTA seine Identität kennt, nur vertrauenswürdige Netzwerke Mails direkt versenden dürfen und dass E-Mails an lokale Adressen korrekt verarbeitet werden. Außerdem wird der Postmaster (z. B. `postmaster@psa-team03.cit.tum.de`) definiert, sodass Fehlermeldungen an den zuständigen Administrator geleitet werden.
Da nixos bereits nativen support für postfix hat, ist es sehr einfach postfix zu konfigurieren. Hierfür wird einfach ein neues Modul erstellt, welches postfix wie folgt konfiguriert:

```nix
{ config, lib, pkgs, ... }:
let
  smtp_generic_maps_file = let
    content = "/^(.*)@(.*\\.)?psa-team([0-9]+)\\.cit\\.tum\\.de$/  \$1@cit.tum.de";
  in builtins.toFile "smtp_generic" content;
in
{
  services.postfix = {
    enable = true;                                    # postfix aktivieren
    origin = "psa-team03.cit.tum.de";                 # Ursprungsdomäne in E-Mail-Headers
    domain = "psa-team03.cit.tum.de";                 # primäre Domain von Postfix
    hostname = "mail.psa-team03.cit.tum.de";          # Hostname: ergibt mail.psa-team03.cit.tum.de
    networks = [ "127.0.0.0/8" "192.168.0.0/16" ];    # Vertrauenswürdige Netzwerke
    destination = [ "mail.psa-team03.cit.tum.de" "psa-team03.cit.tum.de" "localhost.cit.tum.de" "localhost" ];
    postmasterAlias = "ge78zig";                       # Admin für Fehlermeldungen
    ...
  };
}
```

Mit diesen Einstellungen wird Postfix korrekt initialisiert, und die grundlegenden Identitäts- und Zustellparameter sind gesetzt.

---

### 1.2 Sicherheitseinstellungen: Kein Open Relay & Ablehnung unbekannter Empfänger

Um zu verhindern, dass unser Server als Open Relay missbraucht wird, und um E-Mails an unbekannte Empfänger direkt im SMTP-Dialog abzulehnen, nehmen wir folgende Einstellungen vor. Dadurch dürfen nur E-Mails von authentifizierten Nutzern oder aus definierten Netzwerken versendet werden.  

```nix
{
  services.postfix = {
    ...
    # main.cf anpassen
    config = {
      smtp_generic_maps = "regexp:/etc/postfix/generic";

      smtpd_helo_required = "yes";
      smtpd_helo_restrictions = [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject_invalid_helo_hostname"
        "reject_unknown_helo_hostname"
      ];
      # um unbekannte Empfänger bereits im SMTP-Dialog abzulehnen
      smtpd_recipient_restrictions = [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject_unknown_recipient_domain"
        "reject_unauth_destination"
        "reject"
      ];
      # um open relay zu verhindern
      smtpd_relay_restrictions = [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject"
      ];

      # mails nur von bekannten nutzern annehmen
      smtpd_sender_restrictions = [
        "permit_sasl_authenticated"
        "reject"
      ];

      # als auth bei smtp dovecot2 verwenden
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_local_domain = "$myhostname";
      smtpd_sasl_security_options = "noanonymous";
      smtpd_sasl_path = "/run/dovecot2/auth";
    };
  };
}
```

Durch diese Konfiguration wird sichergestellt, dass:

- **Nur vertrauenswürdige Quellen:** E-Mails aus den definierten Netzwerken oder von authentifizierten Nutzern akzeptiert werden.  
- **Abweisungen:** Mails an Empfänger, die nicht bekannt sind, werden mit dem Fehlercode 550 abgelehnt.  
- **Kein Relay:** Der Server verweigert das Weiterleiten von E-Mails an externe Domains, wenn keine gültige Authentifizierung vorliegt.
- **Authentifizierung:** Postfix nutzt Dovecot für die Authentifizierung von Nutzern.

---

### 1.3 Weiterleitung an externen Relay (mailrelay.cit.tum.de)

Damit authentifizierte Nutzer auch dann E-Mails versenden können, wenn eine direkte lokale Zustellung nicht möglich ist (z. B. in einer Praktikumsumgebung), leiten wir die ausgehenden Mails über den Relay-Server `mailrelay.cit.tum.de` weiter.  

```nix
  services.postfix = {
    ...
    relayHost = "mailrelay.cit.tum.de";  # Relayhost für ausgehende E-Mails
    relayDomains = [
      "psa-team01.cit.tum.de"
      "psa-team02.cit.tum.de"
      "psa-team06.cit.tum.de"
      "psa-team04.cit.tum.de"
      "psa-team05.cit.tum.de"
      "psa-team07.cit.tum.de"
      "psa-team08.cit.tum.de"
      "psa-team09.cit.tum.de"
      "psa-team10.cit.tum.de"
    ];
    # Domains die gesondert vom relay host weitergeleitet werden sollen
    transport = ''
      psa-team01.cit.tum.de smtp:
      psa-team02.cit.tum.de smtp:
      psa-team06.cit.tum.de smtp:
      psa-team04.cit.tum.de smtp:
      psa-team05.cit.tum.de smtp:
      psa-team07.cit.tum.de smtp:
      psa-team08.cit.tum.de smtp:
      psa-team09.cit.tum.de smtp:
      psa-team10.cit.tum.de smtp:
    '';
    ...
  };
```

Diese Einstellung bewirkt, dass alle E-Mails, die nicht an lokale Empfänger oder anderen Teams zugestellt werden können, an den externen Relay übergeben werden. So wird sichergestellt, dass auch in einer Umgebung mit internen Adressen der Versand nach außen möglich ist.

Nun fehlt noch das bei einer weiterleitung die Domain im Header überschrieben wird, da der relay host nichts von der internen Domain weiß. Dies kann durch folgende Konfiguration erreicht werden:

```nix
{ config, lib, pkgs, ... }:
let
  smtp_generic_maps_file = let
    content = "/^(.*)@(.*\.)?psa-team([0-9]+)\.cit\.tum\.de$/  \$1@cit\.tum\.de";
  in builtins.toFile "smtp_generic" content;
in
{
  services.postfix = {
    ...
    extraConfig = ''
      smtp_generic_maps = regexp:/etc/postfix/smtp_generic
    '';
    ...
    # smtp_generic_maps file anlegen
    mapFiles = {
      generic = smtp_generic_maps_file;
    };

    # main.cf anpassen
    config = {
      smtp_generic_maps = "regexp:/etc/postfix/generic";
      ...
    };
  };
}
```

Hier wird ein neues File `smtp_generic` erstellt, welches die Domain zu `cit.tum.de` abändert. Dieses File wird dann in der `main.cf` eingebunden.

---

### 1.4 From-Header-Umformatierung

Um zu vermeiden, dass interne Hostnamen (z. B. `@mail.psa-team03.cit.tum.de`) im From:-Header erscheinen, nutzen wir die `masquerade_domains`-Option von Postfix. Damit wird der Hostname entfernt und die E-Mail-Adresse erscheint als `@psa-team03.cit.tum.de`.

```nix
  services.postfix = {
    ... 
    extraConfig = ''
      masquerade_domains = psa-team03.cit.tum.de
    '';
    ...
  };
```

---

### 1.5 Viren- und Spamfilter

Um den Mailverkehr abzusichern, werden alle ein- und ausgehenden E-Mails sowohl auf Viren als auch auf Spam geprüft.

**Virenprüfung mit ClamAV:**  
Um einen Virenscan durchzuführen, aktivieren wir den ClamAV-Daemon sowie den Updater, der die Signaturen aktuell hält.

```nix
{
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;
}
```

da diese Daemons aber auch Zugang zum Internet benötigen um die Signaturen zu aktualisieren, müssen wir noch Zugriff auf die clamav Server erlauben. Dies kann durch folgende Firewall regel erreicht werden:

```nix
# vm-network-config.nix
      # allow clamav
      iptables -A OUTPUT -d 104.16.218.84 -j ACCEPT
      iptables -A OUTPUT -d 104.16.219.84 -j ACCEPT
```

**Integration von Rspamd als Spamfilter und zur Antivirus-Kontrolle:**  
Rspamd wird als Milter in den SMTP-Flow eingebunden, um sowohl Spam als auch Viren zu erkennen. Wird ein Virus gefunden, lehnt Rspamd die E-Mail ab. Bei Spam fügt Rspamd zusätzliche Header oder verändert den Betreff, um den Empfänger zu warnen.

```nix
{
  services.rspamd.locals."antivirus.conf" = { text = ''
    clamav {
      action = "reject";
      symbol = "CLAM_VIRUS";
      type = "clamav";
      log_clean = true;
      servers = "/run/clamav/clamd.ctl";
      scan_mime_parts = false;
    }
  ''; };

  services.rspamd.locals."milter_headers.conf" = { text = ''
    extended_spam_headers = true;
    use = ["x-spam-header", "subject"];
    subject = "[SPAM] %s";
  ''; };

  services.rspamd.locals."actions.conf" = { text = ''
    reject = null;
    greylist = null;
    add_header = 5.0;
    rewrite_subject = 5.0;
  ''; };

  services.rspamd.workers.rspamd_proxy = {
      type = "rspamd_proxy";
      bindSockets = [{
        socket = "/run/rspamd/rspamd-milter.sock";
        mode = "0664";
      }];
      count = 1;
      extraConfig = ''
        milter = yes;
        timeout = 120s;

        upstream "local" {
          default = yes;
          self_scan = yes;
        }
      '';
  };
}
```

Diese Einstellungen bewirken, dass:

- **Viren:** Mit Hilfe von ClamAV alle Mails gescannt werden und bei einem Virenbefund die E-Mail abgelehnt wird.
- **Spam:** Rspamd erkennt Spam anhand definierter Schwellenwerte und markiert die E-Mails

---

## Aufgabe 2: Netzwerk konfigurieren

Zuerst müssen nur zwei Änderungen an der Firewall vorgenommen werden:

```nix
      # Allow: SMTP
      iptables -A INPUT -p tcp --dport 25 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 25 -j ACCEPT

      # Allow: traffic to the mail relay
      iptables -A OUTPUT -d 131.159.254.10 -j ACCEPT
```

Nun fehlt noch der MX Record für die DNS Konfiguration. Dadurch wird sichergestellt, dass alle Team VMs von den Mailserver wissen und ihre Mails an diesen senden.

```shell
# psa-team03.zone
@          MX  10  mail
```

---

## Aufgabe 3: IMAP/POP3 bereitstellen (Dovecot)

Um Benutzern den Zugriff auf ihre Mailboxen zu ermöglichen, konfigurieren wir Dovecot. Dies erlaubt es, dass die vom MTA (Postfix) zugestellten E-Mails in den jeweiligen Mailboxen (im Maildir-Format) abgelegt werden und per IMAP/POP3 abgerufen werden können. Außerdem stellen wir einen Authentifizierungs-Socket bereit, über den Postfix mit Dovecot kommunizieren kann.

```nix
{
  services.dovecot2 = {
    enable = true;  # Dovecot wird aktiviert, um IMAP/POP3-Dienste bereitzustellen.
    extraConfig = ''
      service auth {
        unix_listener auth {
          mode = 0666
          user = postfix
          group = postfix
        }
      }
    '';
  };
}
```

Diese Einstellungen bewirken, dass:

- **Mailboxen:** Für jeden Benutzer eine Mailbox im Maildir-Format bereitgestellt wird.
- **Authentifizierung:** Ein Unix-Socket (mit den entsprechenden Rechten) zwischen Dovecot und Postfix eingerichtet wird, sodass die Authentifizierung über die folgende Kette erfolgt: Postfix -> Dovecot SASL -> PAM -> SSSD -> LDAP. Auth also mit den LDAP Credentials.
- **IMAP/POP3-Zugriff:** Benutzer über IMAP/POP3 auf ihre E-Mails zugreifen können.

Jetzt sollte der Mailserver vollständig konfiguriert sein. Und empfangene Mails sollten jeweils in `/var/mail/username/new` abgelegt werden.
