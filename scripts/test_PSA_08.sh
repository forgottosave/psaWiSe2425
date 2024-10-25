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

# selection of users to test with
users=(
    cruzc ge95vir heusl liuli pluda wiesn
    atten dobro ge63gut ge96hoj holst witte
    bader enges ge96xok huber maier wuche
    barza erdoe ge64wug georg manov yorda
    beckc fache ge65hog karsu mehne zinsl
    becke fengj ge65peq grotz kaush styna
    brand finis ge78nes kentj moell trana
    braun ge78zig hanyt kilic murat trayk
    bruec fuchs ge84zoj klein navar treml
    catom ge38hoy hegen kochn olsso verik
    cebul ge43fim ge87liq heinz schmi vossw
    citom ge47kut ge87yen helle schmo wangn
    ge47sof ge94bob lindl pfeff weinb
)

## Test depending on VM
# hosting VM: check all
# non-hosting VM: only check access to Home Assistant
VM_NUMBER=$(hostname)
VM_NUMBER=${VM_NUMBER: -1}
if [ $VM_NUMBER -eq 7 ]; then
    # LDAP VM:
    
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

    ## TEST #########################################
    ## check LDAP user logins
    start_test "check LDAP user logins"
    for user in "${users[@]}"; do
        if su -c "whoami" "$user" &>/dev/null; then
            print_success "user $user can log in"
        else
            print_failed "failed user login for $user"
        fi
    done

    ## TEST #########################################
    ## check if user ge96xok can change their password
    start_test "check password changing rights"
    user="ge96xok"
    old_pwd="2IRR7iiMqxImTYmY"
    new_pwd="tmppwd123"
    echo -e "$old_pwd\n$old_pwd\n$new_pwd\n$new_pwd\n$new_pwd\n$new_pwd" | su -c "passwd" "$user" &>/dev/null
    if [[ $? -eq 0 ]]; then
        # change back
        echo -e "$new_pwd\n$new_pwd\n$old_pwd\n$old_pwd\n$old_pwd\n$old_pwd" | su -c "passwd" "$user" &>/dev/null
        print_success "could change password"
    else
        print_failed "couldn't change user password"
    fi

fi

## summary ######################################
print_summary
