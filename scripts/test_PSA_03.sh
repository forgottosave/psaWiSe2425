#!/usr/bin/env bash

## SCRIPT INFO ##################################


## TEST SETUP ###################################

# text styling
TEXT_DEFAULT='\033[0;0m'
TEXT_BOLD='\033[0;1m'
TEXT_CURSIVE='\033[0;3m'
TEXT_RED='\033[0;31m'
TEXT_GREEN='\033[0;32m'
# state & general test functions
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

## TEST #########################################
## check DNS to Team-internal VMs
start_test "check DNS to Team-internal VMs"
if host -a psa-team03.cit.tum.de 192.168.3.3 &> /dev/null; then
    print_success "host -a psa-team03.cit.tum.de"
else
    print_failed "host -a psa-team03.cit.tum.de"
fi
internal_addresses=(
    ns1.psa-team03.cit.tum.de
    vm1.psa-team03.cit.tum.de
    vm2.psa-team03.cit.tum.de
)
for addr in ${internal_addresses[@]}; do
    if nslookup ${addr} 192.168.3.3 &> /dev/null; then
        print_success "nslookup ${addr}"
    else
        print_failed "nslookup ${addr}"
    fi
done

## TEST #########################################
## check DNS to other Team VMs
start_test "check DNS to other Team VMs (warning: other DNS might not run)"
external_DNS=(
    psa-team01.cit.tum.de
    psa-team02.cit.tum.de
    psa-team04.cit.tum.de
    psa-team05.cit.tum.de
    psa-team06.cit.tum.de
    psa-team07.cit.tum.de
    psa-team08.cit.tum.de
    psa-team09.cit.tum.de
    psa-team10.cit.tum.de
)
for addr in ${external_DNS[@]}; do
    if host -a ${addr} 192.168.3.3 &> /dev/null; then
        print_success "host -a ${addr}"
    else
        print_failed "host -a ${addr}"
    fi
done

## TEST #########################################
## check DHCP
start_test "check DHCP"
print_failed "test not implemented yet"

## summary ######################################
print_summary
