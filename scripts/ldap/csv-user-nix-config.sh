#!/usr/bin/env bash

## 0. configuration #######################################

THIS_DIR=$(dirname "$0")
## Defaults
INPUT_FILE="benutzerdaten.csv"
OUTPUT_DIR="nix-user-configs"
FILE="$OUTPUT_DIR/csv-users.nix"
GENERATE=false
APPLY=false
HELP="\033[0;1mNix user config generation for users from csv...
\033[0;1mUsage:\033[0;0m
$0 [OPTIONS]

\033[0;1mOptions:          Description:\033[0;0m
-h, --help        Display help page.
-g, --generate    Generate the .nix file from the csv, adding user and mount info.
-a, --apply       Move the .nix to nixos-configs/.

Warning: Only for fictional users, not PSA users!
"
## Argument Parsing
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
        printf "$HELP"
        exit 0
    ;;
    -g|--generate)
        GENERATE=true
        shift
    ;;
    -a|--apply)
        APPLY=true
        shift
    ;;
    *)
        echo "Unknown option: $1"
        exit 1
    ;;
  esac
done

## Generate ###############################################
if [ "$GENERATE" = true ] ; then

echo "Generate .nix file..."
rm $FILE
mkdir -p "$OUTPUT_DIR"

# File header
echo "{config, pkgs, ... }:" >> $FILE   
echo "{" >> $FILE
echo "  users.groups.students.gid = 1000;" >> $FILE

# Skipping header
TAIL_CMD="tail -n +2 $INPUT_FILE"
# Process all users
while IFS="," read -r Name Vorname Geschlecht Geburtsdatum Geburtsort Nationalitaet Strasse PLZ Ort Telefon Matrikelnummer UserId User; do
    
    if [[ $User =~ ^ge[0-9].* ]]; then
        echo "  Skipping PSA user $User"
        continue
    fi

    echo "  Processing $User..."
    # Create .nix entry for user
    echo "    Generating $User.ldif..."
    cat >> "$FILE" <<EOL  
  #users.users.$User = {  
  #  isNormalUser = true;  
  #  home = "/home/$User";  
  #  uid = $UserId;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/$User" = {
    device = "192.168.3.8:/home/$User";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
EOL

done < <(eval "$TAIL_CMD")

# File ending
echo "}" >> $FILE

fi
## Apply ##################################################
if [ "$APPLY" = true ] ; then

echo "Move to nixos-config..."
mv $FILE ../../nixos-config/

fi
###########################################################
