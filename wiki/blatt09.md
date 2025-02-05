# Aufgabenblatt 07

In diesem Blatt geht es darum einen Mailserver einzurichten. Dieser wird bei uns auf VM 9 gehostet.

Aufgaben:

1) MTA (Mail Transfer Agent) unter der subdomain `psa-team03.cit.tum.de` aufsetzen -> `postfix`
   - unter keinen umständen als open relay konfigurieren
   - Mails für unbekannte Empfänger bereits im SMTP-Dialog ablehnen
   - von auth. Nutzern alle Mails annehmen falls nicht lokal oder in Praktikumsumgebung zustellbar an Server `mailrelay.cit.tum.de` weiterleiten (ggf. header überschreiben da mailrelay nichts von der Praktikumsumgebung weiß)
   - alle versendeten oder zugestellten Mails mittels Virenscanner (clamav) prüfen -> geeignete Maßnahmen bei Fund
   - alle versendeten oder zugestellten Mails mittels Spamfilter (spamassassin) prüfen-> geeignete Maßnahmen bei Fund
   - bei alle versendeten oder zugestellten Mails From:-Header prüfen -> falls die Form `@irgendeinhostname.psa-team##.cit.tum.de` Header umschreiben und `irgendeinhostname.` löschen
   - Adresse `postmaster@...` muss existieren und soll an die Mail–Adresse des zuständigen Administrators weitergeleitet werden
2) Netzwerk konfigurieren:
   - DNS-Server: den MX-Record für alle Team-VMs aif den des Mail-Servers
   - Alle anderen Team-VMs: Mails über den Mail-Server versenden
3) IMAP/POP3 -> `dovecot`
   - für alle Benutzer der Team-VMs eine Mailbox bereitstellen
   - MTA muss an die jeweiligen Mailboxen zustellen
4) Testen der Konfig


## Teilaufgaben

### 1) 