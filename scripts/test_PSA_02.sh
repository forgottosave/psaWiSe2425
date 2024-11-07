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
    printf "\n${TEXT_BOLD}TEST: ${TEXT_CURSIVE}$1${TEXT_DEFAULT}\n"
}
function print_success {
    success_count=$((success_count + 1))
    printf "> $1: ${TEXT_GREEN}SUCCESS${TEXT_DEFAULT}\n"
}
function print_failed {
    failed_count=$((failed_count + 1))
    printf "> $1: ${TEXT_RED}FAILED${TEXT_DEFAULT}\n"
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
start_test "connection to other teams"
#declare -a ips
#printf "scan team sub-networks...\n  "
#for i in $(seq 1 10); do
#    printf "$i..."
#    ips+=($(nmap -sn 192.168.$i.0/24 | grep for | cut -c 22-))
#done
#echo
#for i in ${ips[@]}; do echo $i; done
for i in $(seq 1 10); do
    for k in $(seq 1 2); do
        ip="192.168.$i.$k"
        if ping -c 1 $ip &> /dev/null; then
            print_success "ping $ip"
        else
            print_failed "ping $ip"
        fi
    done
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
## check if connection is made through router
start_test "check if connection is made through router"
print_failed "TODO"

## TEST #########################################
## check not-allowed ports (TODO)
start_test "check not-allowed ports"
print_failed "TODO"

## TEST #########################################
## TODO add tests

## summary ######################################
print_summary
