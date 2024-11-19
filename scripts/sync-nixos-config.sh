#!/usr/bin/env bash

## 0. configuration ##################################

THIS_DIR=$(dirname "$0")
## Defaults
VM_NUMBER=$(hostname)
VM_NUMBER=${VM_NUMBER: -1}
PATH_CONFIG_SRC="$THIS_DIR/../nixos-configs/"
PATH_CONFIG_DEST='/etc/nixos/'
SYNC_GIT=false
NIXOS_REBUILD=true
# help page
HELP="\033[0;1mPSA Team 03 - OS sync script\033[0;0m performs...
...copy configs to $PATH_CONFIG_DEST
...replace placeholders
...nixos-rebuild switch

\033[0;1mUsage:\033[0;0m
$0 [OPTIONS]

\033[0;1mOptions:          Description:\033[0;0m
-h, --help        Display help page.
-n, --vm          Specify VM (automatically set from hostname if not provided).
-p, --pull        Pull latest changes from git repository before config changes.
-x, --no-rebuild  Don't perform nixos-rebuild switch after config changes.
"
## Argument Parsing
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
        printf "$HELP"
        exit 0
    ;;
    -p|--pull)
        SYNC_GIT=true
        shift
    ;;
    -n|--vm)
        VM_NUMBER="$2"
        shift
        shift
    ;;
    -x|--no-rebuild)
        NIXOS_REBUILD=false
        shift
    ;;
    *)
        echo "Unknown option: $1"
        exit 1
    ;;
  esac
done


## 1. synchronize with git repository ################

if [ "$SYNC_GIT" = true ] ; then
    echo 'synchronizing the git repository...'
    git stash
    git pull --rebase
fi


## 2. read vm specific configuration #################

echo "setting configuration for VM ${VM_NUMBER}..."
declare -a include_files
source "${THIS_DIR}/vm-configs/vm-${VM_NUMBER}.sh"


## 3. synchronize .nix configs #######################

echo 'synchronizing the configs:'
for file in ${include_files[@]}; do
    echo "  ${PATH_CONFIG_SRC}${file} -> ${PATH_CONFIG_DEST}${file}"
    backup_folder="${PATH_CONFIG_DEST}backup"
    [ -d "$backup_folder" ] || mkdir "$backup_folder"
    mv "${PATH_CONFIG_DEST}${file}" "$backup_folder"
    cp "${PATH_CONFIG_SRC}${file}" "${PATH_CONFIG_DEST}${file}"
done


## 4. edit vm specific placeholders ##################

imports='
        ./hardware-configuration.nix'
for file in ${include_files[@]}; do
    if ! [ "$file" = "configuration.nix" ] && ! [ "$file" = "flake.nix" ] && ! [ "$file" = "dhcp-config.nix" ] && ! [ "$file" = "dhcp4-config.json" ]; then
        imports+="
        ./$file"
    fi
done
gawk -i inplace -v r="$imports" '{gsub(/%%imports%%/,r)}1' "${PATH_CONFIG_DEST}configuration.nix"

for file in ${include_files[@]}; do
    path="${PATH_CONFIG_DEST}${file}"
    echo "edit placeholders in $path..."
    for placeholder in "${!sed_placeholders[@]}"; do
        replacement="${sed_placeholders[$placeholder]}"
        echo "  replace $placeholder"
        gawk -i inplace -v r="$replacement" "{gsub(/%%$placeholder%%/,r)}1" "$path"
    done
done


## (EXERCISE SHEET SPECIFIC REQUIREMENTS) ##############

# Week 02
cp ${THIS_DIR}/test_PSA_02.sh /root/
# Week 03
cp -a ${THIS_DIR}/../nixos-configs/bind-configs/. /etc/nixos/dns/


## 5. reload config ##################################

if [ "$NIXOS_REBUILD" = true ] ; then
    sudo nixos-rebuild switch
fi
