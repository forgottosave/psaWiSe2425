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
if [ $VM_NUMBER -eq 7 ]; then
    # LDAP VM:
    users=(
        cruzc ge95vir heusl liuli pluda schra wiesn
        atten dobro ge63gut ge96hoj holst loehr popee seide witte
        bader enges ge64baw ge96xok huber maier rempe shulm wuche
        barza erdoe ge64wug georg jiang manov riedr sieve yorda
        beckc fache ge65hog goelm karsu mehne rimme stein zinsl
        becke fengj ge65peq grotz kaush mitte rooto styna
        brand finis ge78nes hallm kentj moell ruedi trana
        braun fisch ge78zig hanyt kilic murat sandm trayk
        bruec fuchs ge84zoj hausn klein navar schle treml
        catom ge38hoy ge87huk hegen kochn olsso schlo verik
        cebul ge43fim ge87liq heinz kollo ottin schmi vossw
        citom ge47kut ge87yen helle langi perro schmo wangn
        ge47sof ge94bob herzi lindl pfeff schne weinb
    )
    
    ## TEST #########################################
    ## check if LDAP is running
    start_test "check if LDAP is running"
    systemctl is-active --quiet "openldap"
    if [[ $? -eq 0 ]]; then
        print_success "LDAP running"
    else
        print_failed "LDAP currently not running"
    fi

    ## TEST #########################################
    ## check if LDAPS is reachable
    start_test "check if LDAPS is reachable"
    nc -z -w2 ldap.psa-team03.cit.tum.de 636 &>/dev/null
    if [[ $? -eq 0 ]]; then
        print_success "LDAPS reachable"
    else
        print_failed "LDAPS (:636) isn't reachable"
    fi

    ## TEST #########################################
    ## check if we can log into LDAP
    start_test "check LDAP users"
    start_test "Warning: If users changed their password in the meantime this test might fail"
    for user in "${users[@]}"; do
        ldapwhoami -H ldapi:// -x -D "uid=$user,ou=users,dc=team03,dc=psa,dc=cit,dc=tum,dc=de" -w "$(cat ~/ldap/ldap-user-attach/$user/$user-ldap.password)"
        if [[ $? -eq 0 ]]; then
            print_success "user $user found"
        else
            print_failed "failed to lookup user $user"
        fi
    done

else
    echo "please run this script on VM 7"
fi

## summary ######################################
print_summary
