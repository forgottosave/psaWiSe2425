#!/bin/bash

## CONFIGURATION ################################

THIS_DIR=$(dirname "$0")
# try to find vm number, if not provided
VM_NUMBER=$(hostname)
VM_NUMBER=${VM_NUMBER: -1}
if [ -n "$1" ]; then
    VM_NUMBER=$1
fi
# paths
PATH_CONFIG_SRC="$THIS_DIR/../nixos-configs/"
PATH_CONFIG_DEST='/etc/nixos/' # ="$THIS_DIR/../test/"
# script configs
SYNC_GIT=false
SYNC_CONFIG=true


## 0. synchronize with git repository ###########

if [ "$SYNC_GIT" = true ] ; then
    echo 'synchronizing the git repository...'
    git stash
    git pull --rebase
fi


## 1. Set VM specific configuration #############

echo "setting configuration for VM ${VM_NUMBER}..."
declare -a include_files
source "${THIS_DIR}/vm-configs/vm-${VM_NUMBER}.sh"


## 2. synchronize configs #######################

if [ "$SYNC_CONFIG" = true ] ; then
    echo 'synchronizing the configs:'
    for file in ${include_files[@]}; do
        echo "  ${PATH_CONFIG_SRC}${file} -> ${PATH_CONFIG_DEST}${file}"
        backup_folder="${PATH_CONFIG_DEST}backup"
        [ -d "$backup_folder" ] || mkdir "$backup_folder"
        mv "${PATH_CONFIG_DEST}${file}" "$backup_folder"
        cp "${PATH_CONFIG_SRC}${file}" "${PATH_CONFIG_DEST}${file}"
    done
fi


## 3. enter vm specific configs #################

imports=''
for file in ${include_files[@]}; do
    imports+="
    ./$file"
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
