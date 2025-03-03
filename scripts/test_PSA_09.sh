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

if systemctl is-active --quiet dovecot2; then
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

if [ -S /run/dovecot2/auth ]; then
    print_success "Dovecot Auth-Socket existiert"
else
    print_failed "Dovecot Auth-Socket (/run/dovecot2/auth) wurde nicht gefunden"
fi


## Test ########################################

start_test "teste ob postemaster funktioniert"

## TEST ########################################

start_test "SMTP: Ablehnung von unbekannten Empfängern"

## TEST ########################################

start_test "testen ob kein open relay"

## TEST ########################################

start_test "mails von unauth. Nutzern werden abgelehnt"

## TEST ########################################

start_test "mails von auth. Nutzern werden akzeptiert"

## TEST ########################################

start_test "valide mails weiterleiten an andere mailserver der Praktikumsumgebung"
#echo "Testnachricht" |mail -s "Testbetreff" -r "benjamin.liertz@psa-team03.cit.tum.de" gedeon.lenz@psa-team01.cit.tum.de

## TEST ########################################

start_test "valide externe mails weiterleiten an mailrelay"
#echo "Testnachricht" |mail -s "Testbetreff" -r "benjamin.liertz@psa-team03.cit.tum.de" benjamin.liertz@tum.de

start_test "bei weiterleitung an mailrelay anpassen des headers"

## TEST ########################################

start_test "bei allen mails header umschreiben zu @psa-team##.cit.tum.de"
# senden email mit nullmail mit from "benjamin.liertz@vmpsateam03-01.psa-team03.cit.tum.de"
# prüfen von /var/log/mail.log

## TEST ########################################

start_test "vierenscan test"
# echo "Test email with EICAR" | mail -s "Test Email" -A eicar.txt benjamin.liertz@psa-team03.cit.tum.de
# prüfen von /var/log/mail.log

## TEST ########################################

start_test "spamscan test"

## TEST ########################################

start_test "mx record test"

## TEST ########################################

start_test "dovecot user mailbox test"
# elnet 127.0.0.1 143 -> a login benjamin.liertz <password> -> a select INBOX


## summary ######################################
print_summary
