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

# Teilaufgaben

## Aufgabe 1: MTA aufsetzen (Postfix)

### 1.1 Basis-Konfiguration

Um den Mailserver unter der Subdomain `psa-team03.cit.tum.de` aufzusetzen, aktivieren wir Postfix und legen grundlegende Parameter fest. Damit stellen wir sicher, dass Postfix als MTA seine Identität kennt, nur vertrauenswürdige Netzwerke Mails direkt versenden dürfen und dass E-Mails an lokale Adressen korrekt verarbeitet werden. Außerdem wird der Postmaster (z. B. `postmaster@psa-team03.cit.tum.de`) definiert, sodass Fehlermeldungen an den zuständigen Administrator geleitet werden.
Da nixos bereits nativen support für postfix hat, ist es sehr einfach postfix zu konfigurieren. Hierfür wird einfach ein neues Modul erstellt, welches postfix wie folgt konfiguriert:

```nix
{ config, lib, pkgs, ... }:
{
  services.postfix = {
    enable = true;                                    # Postfix wird aktiviert.
    domain = "psa-team03.cit.tum.de";                 # Der Server arbeitet unter dieser Subdomain.
    networks = [ "127.0.0.0/8" "192.168.0.0/16" ];    # Nur Mails aus diesen vertrauenswürdigen Netzwerken werden ohne Authentifizierung akzeptiert.
    hostname = "mail";                                # Der lokale Hostname; zusammen mit der Domain ergibt sich mail.psa-team03.cit.tum.de.
    destination = [ "mail" "mail.psa-team03.cit.tum.de" "psa-team03.cit.tum.de" "localhost.cit.tum.de" "localhost" ];
                                                      # Legt fest, welche Ziele als lokal betrachtet werden.
    origin = "psa-team03.cit.tum.de";                 # Bestimmt die Absenderdomäne in den E-Mail-Headern.
    postmasterAlias = "ge78zig@psa-team03.cit.tum.de";# Leitet Fehlermeldungen an den Administrator weiter.
    recipientDelimiter = "+";                         # Ermöglicht Adresszusätze, z. B. benutzer+filter@domain.
  };
}
```

Mit diesen Einstellungen wird Postfix korrekt initialisiert, und die grundlegenden Identitäts- und Zustellparameter sind gesetzt.

---

### 1.2 Sicherheitseinstellungen: Kein Open Relay & Ablehnung unbekannter Empfänger

Um zu verhindern, dass unser Server als Open Relay missbraucht wird, und um E-Mails an unbekannte Empfänger direkt im SMTP-Dialog abzulehnen, nehmen wir folgende Einstellungen vor. Dadurch dürfen nur E-Mails von authentifizierten Nutzern oder aus definierten Netzwerken versendet werden.  

```nix
{
  services.postfix.extraConfig = ''
    smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_unverified_recipient
    unknown_local_recipient_reject_code = 550
    smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_unverified_recipient
  '';
}
```

Durch diese Konfiguration wird sichergestellt, dass:

- **Nur vertrauenswürdige Quellen:** E-Mails aus den definierten Netzwerken oder von authentifizierten Nutzern akzeptiert werden.  
- **Abweisungen:** Mails an Empfänger, die nicht bekannt sind, werden mit dem Fehlercode 550 abgelehnt.  
- **Kein Relay:** Der Server verweigert das Weiterleiten von E-Mails an externe Domains, wenn keine gültige Authentifizierung vorliegt.

---

### 1.3 Weiterleitung an externen Relay (mailrelay.cit.tum.de)

Damit authentifizierte Nutzer auch dann E-Mails versenden können, wenn eine direkte lokale Zustellung nicht möglich ist (z. B. in einer Praktikumsumgebung), leiten wir die ausgehenden Mails über den Relay-Server `mailrelay.cit.tum.de` weiter.  

```nix
{
  services.postfix.extraConfig = ''
    relayhost = mailrelay.cit.tum.de
  '';
}
```

Diese Einstellung bewirkt, dass alle E-Mails, die nicht an lokale Empfänger zugestellt werden können, an den externen Relay übergeben werden. So wird sichergestellt, dass auch in einer Umgebung mit internen Adressen der Versand nach außen möglich ist.

---

### 1.4 From-Header-Umformatierung

Um zu vermeiden, dass interne Hostnamen (z. B. `mail.psa-team03.cit.tum.de`) im From:-Header erscheinen, nutzen wir eine Sender-Canonical Map. Dies ist wichtig, da der Relay-Server keine Informationen über die interne Namenskonvention hat und externe Empfänger korrekte Absenderadressen erwarten.

```nix
{
  let
    sender_canonical_file = let
      content = "@mail.psa-team03.cit.tum.de @cit.tum.de";
    in builtins.toFile "sender_canonical" content;
  in {
    services.postfix.mapFiles."sender_canonical" = sender_canonical_file;
    services.postfix.extraConfig = ''
      sender_canonical_maps = hash:/etc/postfix/sender_canonical
    '';
  }
}
```

Hier wird eine Datei erstellt, in der definiert wird, dass der Teil `mail.psa-team03.cit.tum.de` durch `cit.tum.de` ersetzt wird. Dadurch erscheinen alle versendeten E-Mails mit der öffentlichen Domäne.

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

      auth_mechanisms = plain login
      mail_location = maildir:~/Maildir
    '';
  };
}
```

Diese Einstellungen bewirken, dass:

- **Mailboxen:** Für jeden Benutzer eine Mailbox im Maildir-Format bereitgestellt wird.
- **Authentifizierung:** Ein Unix-Socket (mit den entsprechenden Rechten) zwischen Dovecot und Postfix eingerichtet wird, sodass die Authentifizierung über die folgende Kette erfolgt: Postfix -> Dovecot SASL -> PAM -> SSSD -> LDAP. Auth also mit den LDAP Credentials.
- **IMAP/POP3-Zugriff:** Benutzer über IMAP/POP3 auf ihre E-Mails zugreifen können.
