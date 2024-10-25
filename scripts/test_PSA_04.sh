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


## DNS Tests ####################################

web_domains=(
    web1.psa-team03.cit.tum.de
    web2.psa-team03.cit.tum.de
    web3.psa-team03.cit.tum.de
)

start_test "DNS Resolution for web1, web2, web3"
for domain in ${web_domains[@]}; do
    if host $domain &> /dev/null; then
        print_success "DNS lookup for $domain succeeded"
    else
        print_failed "DNS lookup for $domain failed"
    fi
done


## HTTP/HTTPS Availability Tests ################
start_test "HTTP access for website1, website2, website3"
for domain in ${web_domains[@]}; do
    HTTP_STATUS=$(curl -Lk -s -o /dev/null -w "%{http_code}" http://$domain/)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        print_success "HTTP access for $domain succeeded (status 200)"
    else
        print_failed "HTTP access for $domain failed (status $HTTP_STATUS)"
    fi
done

start_test "HTTPS access for website1, website2, website3"
for domain in ${web_domains[@]}; do
    HTTPS_STATUS=$(curl -Lk -s -o /dev/null -w "%{http_code}" https://$domain/)
    if [ "$HTTPS_STATUS" -eq 200 ]; then
        print_success "HTTPS access for $domain succeeded (status 200)"
    else
        print_failed "HTTPS access for $domain failed (status $HTTPS_STATUS)"
    fi
done


## User Homepages Tests ##########################
start_test "User static and dynamic homepage for user 'ge95vir'"
HTTPS_STATUS=$(curl -Lk -s -o /dev/null -w "%{http_code}" https://web1.psa-team03.cit.tum.de/~ge95vir)
if [ "$HTTPS_STATUS" -eq 200 ]; then
    print_success "User static homepage served correctly"
else
    print_failed "User static homepage not served (status $HTTP_STATUS)"
fi

HTTPS_STATUS=$(curl -Lk -s -o /dev/null -w "%{http_code}" https://web1.psa-team03.cit.tum.de/~ge95vir/cgi-bin/index.sh)
if [ "$HTTPS_STATUS" -eq 200 ]; then
    print_success "User CGI script executed correctly"
else
    print_failed "User CGI script failed to execute (status $HTTPS_STATUS)"
fi

CGI_OUTPUT=$(curl -Lk -s http://web1.psa-team03.cit.tum.de/~ge95vir/cgi-bin/index.sh)
if echo "$CGI_OUTPUT" | grep -q "ge95vir"; then
    print_success "CGI process is running as user 'ge95vir'"
else
    print_failed "CGI process did not run as user 'ge95vir' (output: $CGI_OUTPUT)"
fi


## Log Files Tests #########################
start_test "Access log files..."
if [ -s /var/log/nginx/access.log ]; then
    print_success "Access log file exists and is non-empty"
else
    print_failed "Access log file is missing or empty"
fi

if [ -f /var/log/nginx/error.log ]; then
    print_success "Error log file exists"
else
    print_failed "Error log file does not exist"
fi


## Final Summary ##################################
print_summary
