#!/usr/bin/env bash

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

## SCRIPT INFO ##################################
VM_NUMBER=$(hostname)
VM_NUMBER=${VM_NUMBER: -1}
echo "
Execute this test script on VM 2 (backup) & VM 4 (main database)..
This VM: VM ${VM_NUMBER}

Warning: VM 4 might expect a password input for remotusr."

## CHECK ROOT ###################################
if [ $(id -u) -ne 0 ]; then
    echo Please run this script as root or using sudo!
    exit 1
fi

## Test depending on VM
if [ $VM_NUMBER -eq 4 ]; then
    # main database:
    ## TEST #########################################
    ## check if database exists
    start_test "check if databases exist"
    databases=(
        postgres
        remotusrdb
        localusrdb
    )
    for db in ${databases[@]}; do
        psql -U postgres -c "\l" | grep "${db}" &> /dev/null
        if [ $? -eq 0 ]; then
            print_success "$db exists"
        else
            print_failed "$db not found"
        fi
    done

    ## TEST #########################################
    ## check database users
    start_test "check if users exist"
    users=(
        postgres
        remotusr
        localusr
        ronlyusr
    )
    for usr in ${users[@]}; do
        psql -U postgres -c "\du" | grep "${usr}" &> /dev/null
        if [ $? -eq 0 ]; then
            print_success "$usr exists"
        else
            print_failed "$usr not found"
        fi
    done

    ## TEST #########################################
    ## check WAL functionality
    start_test "check WAL functionality"
    # create table in remotusrdb
    sql_cmd="CREATE TABLE cpt_team (email text, vistor_id serial, date timestamp, message text);"
    expect="CREATE TABLE"
    psql -U postgres -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    if [ $? -eq 0 ]; then
        print_success "created table in remotusrdb"
    else
        print_failed "couldn't create table in remotusrdb"
    fi
    # change owner of this table
    sql_cmd="ALTER TABLE cpt_team OWNER TO remotusr;"
    expect="ALTER TABLE"
    psql -U postgres -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    if [ $? -eq 0 ]; then
        print_success "make remotusr owner of new table"
    else
        print_failed "couldn't make remotusr owner of new table"
    fi
    # create entry in remotusrdb table
    sql_cmd="INSERT INTO cpt_team (email, date, message) VALUES ( 'myoda@gmail.com', current_date, 'Now we are replicating.');"
    expect="INSERT 0 1"
    psql -U postgres -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    if [ $? -eq 0 ]; then
        print_success "created entry in remotusrdb table"
    else
        print_failed "couldn't create entry in remotusrdb table"
    fi
    # check if entry exists in WAL backup
    backup_addr="192.168.3.2"
    sql_cmd="SELECT * FROM cpt_team;"
    expect="Now we are replicating."
    psql -h "$backup_addr" -p 5432 -U remotusr -W -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null
    if [ $? -eq 0 ]; then
        print_success "table & entry exists at backup database ($backup_addr)"
    else
        print_failed "table or entry not found in backup database ($backup_addr)"
    fi
    # cleanup
    sql_cmd="DROP TABLE cpt_team;"
    expect="DROP TABLE"
    psql -U postgres -c "$sql_cmd" remotusrdb | grep "${expect}" &> /dev/null

else
    # backup database
    ## TEST #########################################
    ## check if backup script works
    start_test "check backup script"
    cd /root
    time=$(date +"%Y%m%d-%H%M%S")
    ./backup_postgres.sh
    if [ $? -eq 0 ]; then
        print_success "script returns success"
    else
        print_failed "script fails"
    fi
    if [ -f "/root/backup_postgres/backup_${time}.dump" ]; then
        print_success "backup exists"
    else
        print_failed "backup not found"
    fi
    if [ -f "/root/backup_postgres/backup_${time}.log" ]; then
        print_success "log exists"
    else
        print_failed "log not found"
    fi

fi

## summary ######################################
print_summary
