#!/usr/bin/env bash

## test sertup ##################################

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
for i in $(seq 1 10); do
    ip="192.168.$i.1"
    if ping -c 1 $ip &> /dev/null; then
        print_success "ping $ip"
    else
        print_failed "ping $ip"
    fi
done


## TEST #########################################
## TODO TODO TODO

start_test "some test description"
print_success "test something else 1"
print_success "test something else 2"
print_failed "test something else 3"

## summary ######################################
print_summary
