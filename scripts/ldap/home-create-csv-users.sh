#!/usr/bin/env bash

## 0. configuration #######################################

THIS_DIR=$(dirname "$0")
## Defaults
INPUT_FILE="benutzerdaten.csv"
OUTPUT_DIR="/export/home"
GENERATE=false
DELETE=false
HELP="\033[0;1mCreate home directories for csv users...
\033[0;1mUsage:\033[0;0m
$0 [OPTIONS]

\033[0;1mOptions:          Description:\033[0;0m
-h, --help        Display help page.
-g, --generate    Generate the home directories.
-d, --delete      Delete the home directories

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
    -d|--delete)
        DELETE=true
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

# Skipping header
TAIL_CMD="tail -n +2 $INPUT_FILE"
# Process all users
while IFS="," read -r Name Vorname Geschlecht Geburtsdatum Geburtsort Nationalitaet Strasse PLZ Ort Telefon Matrikelnummer UserId User; do
    
    if [[ $User =~ ^ge[0-9].* ]]; then
        echo "  Skipping PSA user $User"
        continue
    fi

    echo "  Processing $User..."
    # Create home dir for user
    USER_DIR="$OUTPUT_DIR/$User"
    mkdir -p "$USER_DIR"
    chmod 701 "$USER_DIR"
    chown $UserId:1000 "$USER_DIR"

done < <(eval "$TAIL_CMD")

fi
## Delete #################################################
if [ "$DELETE" = true ] ; then

# Skipping header
TAIL_CMD="tail -n +2 $INPUT_FILE"
# Process all users
while IFS="," read -r Name Vorname Geschlecht Geburtsdatum Geburtsort Nationalitaet Strasse PLZ Ort Telefon Matrikelnummer UserId User; do
    
    if [[ $User =~ ^ge[0-9].* ]]; then
        echo "  Skipping PSA user $User"
        continue
    fi

    echo "  Deleting $User's home directory..."
    # Create home dir for user
    USER_DIR="$OUTPUT_DIR/$User"
    rm -r "$USER_DIR"

done < <(eval "$TAIL_CMD")

fi
###########################################################
