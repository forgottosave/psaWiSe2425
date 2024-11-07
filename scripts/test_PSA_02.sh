#!/usr/bin/env bash

## test setup ##################################

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
## connection to other teams
start_test "connection to other teams (min. 2 VMs per subnet)"
# TODO test team 10, where nmap seems to fail...
for i in $(seq 1 9); do
    ips=($(nmap -sn 192.168.$i.0/24 | grep for | cut -c 22-))
    if [[ ${#ips[@]} -ge 2 ]]; then
        print_success "found >=2 pingable VMs in 192.168.$i.0/24:"
        printf "         ${ips[*]}\n"
    else
        print_failed "found < 2 pingable VMs in 192.168.$i.0/24:"
        printf "         ${ips[*]}\n"
    fi
done

# old test, static search for .1 and .2 VMs
#for i in $(seq 1 10); do
#    for k in $(seq 1 2); do
#        ip="192.168.$i.$k"
#        if ping -c 1 $ip &> /dev/null; then
#            print_success "ping $ip"
#        else
#            print_failed "ping $ip"
#        fi
#    done
#done

## TEST #########################################
## check connection to allowed internal ip
start_test "check connection to allowed internal ip"
if ping -c 1 131.159.0.1 &> /dev/null; then
    print_success "ping fmi (131.159.0.1)"
else
    print_failed "ping fmi (131.159.0.1)"
fi

## TEST #########################################
## check not-allowed ports (TODO)
start_test "check incoming ssh connections (team internal)"
for i in $(seq 1 3); do
    if [[ $(nmap -p 22 192.168.3.$i | grep open) == *"open"* ]]; then
        print_success "192.168.3.$i ssh"
    else
        print_failed "192.168.3.$i ssh"
    fi
done

## TEST #########################################
## surfing through proxy
start_test "surfing through proxy"
test_addresses=(
    "https://www.google.com"
    "http://www.google.com"
)
for addr in ${test_addresses[@]}; do
    status=$(curl -o - -I $addr | head -n 1)
    if [[ $status =~ "200" ]]; then
        print_success "curl $addr"
    else
        print_failed "curl $addr"
    fi
done

## TEST #########################################
## TODO add tests

## summary ######################################
print_summary
