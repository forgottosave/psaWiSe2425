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
    ## check if NFS is running
    start_test "check if NFS is running"
    ps aux | grep nfsd
    if [ $? -eq 0 ]; then
        print_success "nfsd is running"
    else
        print_failed "no nfsd process found"
    fi

    ## TEST #########################################
    ## check if NFS is running
    start_test "check if Samba is running"
    ps aux | grep samba
    if [ $? -eq 0 ]; then
        print_success "samba is running"
    else
        print_failed "no samba process found"
    fi

fi

## TEST #########################################
## check if NFS port is reachable
start_test "check if NFS port is reachable"
nc -z 192.168.3.8 2049
if [ $? -eq 0 ]; then
    print_success "port 2049 is reachable"
else
    print_failed "port 2049 not reachable"
fi

## TEST #########################################
## check if remote NFS directories can be mounted
start_test "check NFS directory mount"
TEST_DIR="tmp_test_nfs"

for REMOTE_DIR in /home/*; do
    mkdir "$TEST_DIR"
    mount -t nfs "192.168.3.8:$REMOTE_DIR" "$TEST_DIR"
    if [ $? -eq 0 ]; then
        print_success "$REMOTE_DIR could be mounted (nfs)"
        umount "$TEST_DIR"
    else
        print_failed "failed to mount $REMOTE_DIR (smb)"
    fi
    rm -r "$TEST_DIR"
done

## TEST #########################################
## check Samba
start_test "check Samba directory mount"
TEST_DIR="tmp_test_smb"
users=(
    cruzc ge95vir heusl liuli pluda schra wiesn
    dobro ge63gut ge96hoj holst loehr popee seide witte
    enges ge64baw ge96xok huber maier rempe shulm wuche
    erdoe ge64wug georg jiang manov riedr sieve yorda
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

for user in "${users[@]}"; do
    mkdir "$TEST_DIR"
    mount -t cifs //192.168.3.8/${user} $TEST_DIR -o username=${user},password=$(cat ~/smb-passwords/$user.password)
    if [ $? -eq 0 ]; then
        print_success "$user home could be mounted (smb)"
        umount "$TEST_DIR"
    else
        print_failed "failed to mount $user home (smb)"
    fi
    rm -r "$TEST_DIR"
done

## summary ######################################
print_summary
