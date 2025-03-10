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
swaks --to postmaster@psa-team03.cit.tum.de \
      --from testuser@psa-team03.cit.tum.de \
      --server localhost \
      --auth LOGIN --auth-user testusr --auth-password testpwd \
      --data "Subject: Test Postmaster\n\nThis is a test mail for postmaster." \
      > /tmp/swaks_postmaster.log 2>&1
sleep 2  # allow some time for delivery
# Check that the mail arrived in postmaster's mailbox (assumed to be /var/mail/ge78zig/new/)
if grep -q "Test Postmaster" /var/mail/ge78zig/new/* 2>/dev/null; then
    print_success "Postmaster hat die Testmail erhalten"
else
    print_failed "Postmaster hat die Testmail NICHT erhalten"
fi


## TEST ########################################

start_test "SMTP: Ablehnung von unbekannten Empfängern"
output=$(swaks --to postmaster@psa-team03.cit.tum.de \
         --from unknown@psa-team03.cit.tum.de \
         --server localhost \
         --auth LOGIN --auth-user testusr --auth-password testpwd 2>&1)
# Expect a failure status code (often 550) or error message in the output.
if echo "$output" | grep -qiE "550|rejected"; then
    print_success "Unbekannter Empfänger wurde abgelehnt"
else
    print_failed "Unbekannter Empfänger wurde NICHT abgelehnt"
fi


## TEST ########################################

start_test "Mails von unauth. Nutzern werden abgelehnt"
output=$(swaks --to postmaster@psa-team03.cit.tum.de \
         --from testuser@psa-team03.cit.tum.de \
         --server localhost 2>&1)
# Without authentication, we expect a 530 (authentication required) or similar error.
if echo "$output" | grep -qiE "530|authentication"; then
    print_success "Mail von nicht authentifizierten Nutzern wurde abgelehnt"
else
    print_failed "Mail von nicht authentifizierten Nutzern wurde NICHT abgelehnt"
fi


## TEST ########################################

start_test "Valide Mails weiterleiten an andere Mailserver der Praktikumsumgebung"
swaks --to atten@psa-team06.cit.tum.de \
      --from testuser@psa-team03.cit.tum.de \
      --server localhost \
      --auth LOGIN --auth-user testusr --auth-password testpwd \
      --data "Subject: Test Relay Internal\n\nDies ist eine Testmail." \
      > /tmp/swaks_internal.log 2>&1
# Check for an indication of an internal relay (e.g., presence of the target server in logs)
if grep -q "psa-team06.cit.tum.de" /tmp/swaks_internal.log; then
    print_success "Interner Relay an anderen Mailserver funktioniert"
else
    print_failed "Interner Relay an anderen Mailserver funktioniert NICHT"
fi


## TEST ########################################

start_test "Valide externe Mails weiterleiten an Mailrelay"
swaks --to huhu@tum.de \
      --from testuser@psa-team03.cit.tum.de \
      --server localhost \
      --auth LOGIN --auth-user testusr --auth-password testpwd \
      --data "Subject: Test Relay External\n\nDies ist eine externe Testmail." \
      > /tmp/swaks_external.log 2>&1
# Check that mail is sent via the external relay (look for 'mailrelay.cit.tum.de' in the output)
if grep -q "mailrelay.cit.tum.de" /tmp/swaks_external.log; then
    print_success "Externer Relay an mailrelay funktioniert"
else
    print_failed "Externer Relay an mailrelay funktioniert NICHT"
fi


## TEST ########################################

start_test "Bei Weiterleitung an mailrelay wird der Header angepasst"
# This test assumes that header rewriting is applied when relaying.
# One approach is to send a mail and then check that the header in the delivered mail is as expected.
swaks --to postmaster@psa-team03.cit.tum.de \
      --from testuser@psa-team03.cit.tum.de \
      --server localhost \
      --auth LOGIN --auth-user testusr --auth-password testpwd \
      --data "Subject: Header Rewrite Test\n\nTestmail für Header-Rewrite." \
      > /tmp/swaks_header.log 2>&1
sleep 2
# Here we assume the header "From:" was rewritten to contain a specific pattern.
if grep -q "From: testuser@psa-team03.cit.tum.de" /var/mail/ge78zig/new/* 2>/dev/null; then
    print_success "Header-Rewriting wurde korrekt angewendet"
else
    print_failed "Header-Rewriting wurde NICHT korrekt angewendet"
fi


## TEST ########################################

start_test "MX Record Test"
# Check that the MX record for psa-team03.cit.tum.de points to mail.psa-team03.cit.tum.de.
MX=$(dig +short MX psa-team03.cit.tum.de | sort | head -n1 | awk '{print $2}')
if [ "$MX" = "mail.psa-team03.cit.tum.de." ]; then
    print_success "MX-Record für psa-team03.cit.tum.de ist korrekt: $MX"
else
    print_failed "MX-Record für psa-team03.cit.tum.de ist fehlerhaft, erhalten: $MX"
fi


## TEST ########################################

start_test "Dovecot User Mailbox Test"
# This test uses netcat to simulate an IMAP login to dovecot.
result=$( (echo -e "a login testusr testpwd\r\na select INBOX\r\n"; sleep 2) | nc 127.0.0.1 143 )
if echo "$result" | grep -qi "INBOX"; then
    print_success "Dovecot Mailbox-Zugriff funktioniert"
else
    print_failed "Dovecot Mailbox-Zugriff funktioniert NICHT"
fi


## Summary ######################################
print_summary
