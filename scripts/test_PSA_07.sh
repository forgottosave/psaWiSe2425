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
if [ $VM_NUMBER -eq 8 ]; then
    # Fileserver VM:
    ## TEST #########################################
    ## check TODO
    start_test "TODO"
    print_failed "TODO"

    ## TEST #########################################
    ## check TODO
    start_test "TODO"
    print_failed "TODO"

else
    # jede andere VM

fi

## TEST #########################################
## check TODO
start_test "TODO"
print_failed "TODO"

## summary ######################################
print_summary
