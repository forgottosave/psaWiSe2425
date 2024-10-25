#!/usr/bin/env bash

## TEST SETUP ###################################

# Text Styling
TEXT_DEFAULT='\033[0;0m'
TEXT_BOLD='\033[0;1m'
TEXT_CURSIVE='\033[0;3m'
TEXT_RED='\033[0;31m'
TEXT_GREEN='\033[0;32m'

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

start_test "Prüfe, ob alle Sockets vorhanden sind"
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


## TEST ########################################

start_test "Teste, ob Postmaster funktioniert"
# Send a test mail to postmaster using swaks.
output=$(swaks --to postmaster@psa-team03.cit.tum.de \
      --from testuser@psa-team03.cit.tum.de \
      --server localhost \
      --auth LOGIN --auth-user testusr --auth-password testpwd \
      --data "Subject: Test Postmaster\n\nThis is a test mail for postmaster." 2>&1)
if echo "$output" | grep -q "Test Postmaster"; then
    print_success "Postmaster hat die Testmail erhalten"
else
    print_failed "Postmaster hat die Testmail NICHT erhalten"
fi


## TEST ########################################

start_test "SMTP: Ablehnung von unbekannten Empfängern"
output=$(swaks --to unknown@psa-team03.cit.tum.de \
         --from testusr@psa-team03.cit.tum.de \
         --server localhost \
         --auth LOGIN --auth-user testusr --auth-password testpwd 2>&1)
if echo "$output" | grep -q "550"; then
    print_success "Unbekannter Empfänger wurde abgelehnt"
else
    print_failed "Unbekannter Empfänger wurde NICHT abgelehnt"
fi


## TEST ########################################

start_test "Mails von unauth. Nutzern werden abgelehnt"
output=$(swaks --to postmaster@psa-team03.cit.tum.de \
         --from testuser@psa-team03.cit.tum.de \
         --server localhost 2>&1)
if echo "$output" | grep -q "554"; then
    print_success "Mail von nicht authentifizierten Nutzern wurde abgelehnt"
else
    print_failed "Mail von nicht authentifizierten Nutzern wurde NICHT abgelehnt"
fi


## TEST ########################################

start_test "Valide Mails weiterleiten an andere Mailserver der Praktikumsumgebung"
output=$(swaks --to atten@psa-team06.cit.tum.de \
      --from testuser@psa-team03.cit.tum.de \
      --server localhost \
      --auth LOGIN --auth-user testusr --auth-password testpwd \
      --data "Subject: Test Relay Internal\n\nDies ist eine Testmail." 2>&1)
if echo "$output" | grep -q "psa-team06.cit.tum.de"; then
    print_success "Interner Relay an anderen Mailserver funktioniert"
else
    print_failed "Interner Relay an anderen Mailserver funktioniert NICHT"
fi


## TEST ########################################

start_test "Test der Headeranpassung"

swaks --to testusr@psa-team03.cit.tum.de \
      --from ge78zig@blub.psa-team03.cit.tum.de \
      --server localhost \
      --auth LOGIN --auth-user testusr --auth-password testpwd \
      --data "Subject: Test der Headeranpassung\n\nDies ist eine Testmail."
sleep 2  # Allow time for delivery
mailfile=$(find /var/mail/testusr/new -type f -printf "%T@ %p\n" \
           | sort -n | tail -1 | awk '{print $2}')

if [ -z "$mailfile" ]; then
    print_failed "Keine neue Mail in /var/mail/testusr/new gefunden"
else
    if grep -q "From: ge78zig@psa-team03.cit.tum.de" "$mailfile"; then
        print_success "Header-Rewrite: Der From-Header wurde korrekt angepasst"
    else
        print_failed "Header-Rewrite: Der From-Header wurde NICHT korrekt angepasst"
    fi
fi


## TEST ########################################

start_test "MX Record Test"
MX=$(dig +short MX psa-team03.cit.tum.de | sort | head -n1 | awk '{print $2}')
if [ "$MX" = "mail.psa-team03.cit.tum.de." ]; then
    print_success "MX-Record für psa-team03.cit.tum.de ist korrekt: $MX"
else
    print_failed "MX-Record für psa-team03.cit.tum.de ist fehlerhaft, erhalten: $MX"
fi


## Summary ######################################
print_summary
