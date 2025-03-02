#!/usr/bin/env bash

## TEST SETUP ###################################

# Text Styling
TEXT_DEFAULT='\033[0;0m'
TEXT_BOLD='\033[0;1m'
TEXT_CURSIVE='\033[0;3m'
TEXT_RED='\033[0;31m'
TEXT_GREEN='\033[0;32m'

# Statuszähler & allgemeine Testfunktionen
success_count=0
failed_count=0
function start_test {
    printf "\n> ${TEXT_BOLD}TEST: ${TEXT_CURSIVE}$1${TEXT_DEFAULT}\n"
    printf "Result:  Description:\n"
}
function print_success {
    success_count=$((success_count + 1))
    printf "${TEXT_GREEN}SUCCESS${TEXT_DEFAULT}  $1\n"
}
function print_failed {
    failed_count=$((failed_count + 1))
    printf "${TEXT_RED}FAILED${TEXT_DEFAULT}   $1\n"
}
function print_summary {
    printf "\n${TEXT_BOLD}______________________________________\n"
    printf "${TEXT_BOLD}Summary:${TEXT_DEFAULT}\n"
    printf "> ${TEXT_GREEN}SUCCESS: ${TEXT_DEFAULT}$success_count\n"
    printf "> ${TEXT_RED} FAILED: ${TEXT_DEFAULT}$failed_count\n"
    success_count=0
    failed_count=0
}


## TEST ########################################

start_test "Überprüfe, ob alle Services laufen"
if systemctl is-active --quiet postfix; then
    print_success "Postfix-Service ist aktiv"
else
    print_failed "Postfix-Service läuft nicht"
fi

if systemctl is-active --quiet dovecot; then
    print_success "Dovecot-Service ist aktiv"
else
    print_failed "Dovecot-Service läuft nicht"
fi

if systemctl is-active --quiet clamav-daemon; then
    print_success "ClamAV-Daemon ist aktiv"
else
    print_failed "ClamAV-Daemon läuft nicht"
fi

if systemctl is-active --quiet rspamd; then
    print_success "Rspamd-Service ist aktiv"
else
    print_failed "Rspamd-Service läuft nicht"
fi


## TEST ########################################

start_test "SMTP: Unbekannten Empfänger ablehnen (Erwarteter Fehlercode 550)"
smtp_response=$( ( 
    echo "EHLO localhost"
    echo "MAIL FROM:<test@localhost>"
    echo "RCPT TO:<unknown@psa-team03.cit.tum.de>"
    echo "QUIT"
) | nc -w 5 localhost 25 2>/dev/null )

if echo "$smtp_response" | grep -q "550"; then
    print_success "Unbekannter Empfänger wird mit 550 abgelehnt"
else
    print_failed "Unbekannter Empfänger wurde nicht korrekt abgelehnt"
fi


## TEST ########################################

start_test "Postfix Relayhost-Konfiguration überprüfen"
relayhost=$(postconf -h relayhost 2>/dev/null)
if [ "$relayhost" = "mailrelay.cit.tum.de" ]; then
    print_success "Relayhost ist korrekt auf mailrelay.cit.tum.de gesetzt"
else
    print_failed "Relayhost falsch konfiguriert (gefunden: $relayhost)"
fi


## TEST ########################################

start_test "Sender-Canonical Map und Datei überprüfen"
scm=$(postconf -h sender_canonical_maps 2>/dev/null)
if echo "$scm" | grep -q "hash:/etc/postfix/sender_canonical"; then
    print_success "Sender-Canonical Map ist in Postfix konfiguriert"
else
    print_failed "Sender-Canonical Map fehlt oder ist falsch konfiguriert"
fi

if [ -f /etc/postfix/sender_canonical ]; then
   if grep -q "mail.psa-team03.cit.tum.de" /etc/postfix/sender_canonical && grep -q "cit.tum.de" /etc/postfix/sender_canonical; then
      print_success "Inhalt der Sender-Canonical Datei ist korrekt"
   else
      print_failed "Inhalt der Sender-Canonical Datei entspricht nicht den Erwartungen"
   fi
else
   print_failed "Sender-Canonical Datei /etc/postfix/sender_canonical existiert nicht"
fi

## TEST ########################################

start_test "Prüfe, ob alle Sockets vorhanden ist"
if [ -S /run/clamav/clamd.ctl ]; then
    print_success "ClamAV-Socket existiert"
else
    print_failed "ClamAV-Socket (/run/clamav/clamd.ctl) wurde nicht gefunden"
fi

if [ -S /run/rspamd/rspamd-milter.sock ]; then
    print_success "Rspamd Milter-Socket existiert"
else
    print_failed "Rspamd Milter-Socket (/run/rspamd/rspamd-milter.sock) wurde nicht gefunden"
fi

if [ -S /run/dovecot/auth ]; then
    print_success "Dovecot Auth-Socket existiert"
else
    print_failed "Dovecot Auth-Socket (/run/dovecot/auth) wurde nicht gefunden"
fi

## summary ######################################
print_summary
