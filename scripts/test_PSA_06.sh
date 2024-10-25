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

## Test depending on VM
# hosting VM: check all
# non-hosting VM: only check access to Home Assistant
VM_NUMBER=$(hostname)
VM_NUMBER=${VM_NUMBER: -1}
if [ $VM_NUMBER -eq 5 ]; then
    # hosting VM:
    ## TEST #########################################
    ## check docker installed
    start_test "check docker installed"
    if command -v docker 2>&1 >/dev/null; then
        print_success "docker installed"
    else
        print_failed "docker could not be found"
    fi

    ## TEST #########################################
    ## check docker config exists
    start_test "check docker config exists"
    if [ -f /root/compose.yml ]; then
        print_success "config exitst"
    else
        print_failed "config couldn't be found"
    fi

    ## TEST #########################################
    ## check docker running
    start_test "check docker running"
    container_name="homeassistant"
    if [ "$( docker container inspect -f '{{.State.Status}}' $container_name )" = "running" ]; then
        print_success "$container_name is running"
    else
        print_failed "$container_name isn't running"
    fi

fi

## TEST #########################################
## check home assistant reachable
start_test "check home assistant reachable (curl)"
status=$(curl --insecure -X GET -o - -I https://131.159.74.56:60351/ | head -n 1)
if [[ $status =~ "200" ]]; then
    print_success "curl $addr"
else
    print_failed "curl $addr"
fi

## summary ######################################
print_summary
