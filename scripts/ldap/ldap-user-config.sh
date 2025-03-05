#!/usr/bin/env bash

## 0. configuration #######################################

THIS_DIR=$(dirname "$0")
## Defaults
INPUT_FILE="benutzerdaten.csv"
OUTPUT_DIR="ldap-user-configs"
ATTACH_DIR="ldap-user-attach" # for passwords and certificates
GENERATE=false
APPLY=false
HELP="\033[0;1mLDAP config generation for users from csv...
\033[0;1mUsage:\033[0;0m
$0 [OPTIONS]

\033[0;1mOptions:          Description:\033[0;0m
-h, --help        Display help page.
-g, --generate    Generate the .ldif files for each user in the input file.
-a, --apply       Apply all generated .ldif files to the LDAP server.
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

echo "Generate .ldif files..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$ATTACH_DIR"

# Skipping header
TAIL_CMD="tail -n +2 $INPUT_FILE"

# Process all users
while IFS="," read -r Name Vorname Geschlecht Geburtsdatum Geburtsort Nationalitaet Strasse PLZ Ort Telefon Matrikelnummer UserId User; do
    
    # .ldif file & user directory
    FILE="$OUTPUT_DIR/$User.ldif"
    echo "  Processing $User..."
    USER_DIR="$ATTACH_DIR/$User"
    rm -r "$USER_DIR"
    mkdir -p "$USER_DIR"

    # Generate password & hash; Provide $PasswordHash
    echo "    Generating password..."
    PWD_FILE="$USER_DIR/$User-ldap.password"
    Password=$(openssl rand -base64 16 | tr -d '/+=,' | cut -c1-16)
    echo "      Pwd:  $Password"
    touch "$PWD_FILE"
    echo "$Password" >> "$PWD_FILE"
    PasswordHash=$(slappasswd -h {SSHA} -s "$Password")
    echo "      Hash: $PasswordHash"

    # Generate certificate; Provide $Certificate
    echo "    Generating certificate..."
    CERT_FILE="$USER_DIR/$User.crt"
    KEY_FILE="$USER_DIR/$User.key"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $KEY_FILE -out $CERT_FILE -subj "/C=DE/ST=Bayern/L=München/O=TUM-PSA/OU=users/CN=$User/emailAddress=$User@psa-team03.cit.tum.de"
    # generate base64 binary to pass in .ldif
    openssl x509 -in $CERT_FILE -outform der -out $CERT_FILE.der
    base64 -w 0 $CERT_FILE.der > $CERT_FILE.b64
    Certificate=$(cat $CERT_FILE.b64)
    rm $CERT_FILE.der
    rm $CERT_FILE.b64
    #Certificate=$(openssl x509 -in $CERT_FILE -outform DER)

    # Create .ldif file for user
    echo "    Generating $User.ldif..."
    cat > "$FILE" <<EOL
dn: uid=$User,ou=users,dc=team03,dc=psa,dc=cit,dc=tum,dc=de
objectClass: posixAccount
objectClass: account
objectClass: pkiUser
objectClass: auxPerson
uid: $User
cn: $Vorname $Name
uidNumber: $UserId
gidNumber: 1000
homeDirectory: /home/$User
loginShell: /bin/bash
userPassword: $PasswordHash
userCertificate;binary:: $Certificate
givenName: $Name
sn: $User
sex: $Geschlecht
birthdate: $Geburtsdatum
birthplace: $Geburtsort
nationality: $Nationalitaet
street: $Strasse
postalCode: $PLZ
l: $Ort
telephoneNumber: $Telefon
matriculationNumber: $Matrikelnummer
description: User $Vorname $Name
EOL
done < <(eval "$TAIL_CMD")

echo "LDAP user files generated in $OUTPUT_DIR"

fi
## Apply ##################################################
if [ "$APPLY" = true ] ; then

echo "Apply .ldif files to LDAP server..."

for file in "$OUTPUT_DIR"/*.ldif; do
    [ -f "$file" ] || continue # Ensure file format
    
    User=$(basename "$file" .ldif)

    # check if user exists in LDAP already
    echo "  Warning: not checking if user exists already. Modifying users currently not supported."

    # apply new user
    echo "  Appling user $User from file $file..."
    sudo ldapmodify -ac -Y EXTERNAL -H ldapi:// -Q -f $file
done

fi
###########################################################
