#!/usr/bin/env bash

# Include Files
include_files=(
    configuration.nix
    vm-network-config.nix
    database.nix
    flake.nix
    ldap-client.nix
    slapd.crt
    sssd.conf
    user-config.nix
    csv-users.nix
)

# SED placeholders
declare -A sed_placeholders

sed_placeholders[vm]="$VM_NUMBER"

sed_placeholders[imports]='
    ./hardware-configuration.nix
    ./vm-network-config.nix
    ./database.nix
    ./ldap-client.nix
    ./user-config.nix
    ./csv-users.nix
'

sed_placeholders[system_packages]='
    git
    nmap
    tcpdump
    traceroute
    tcptraceroute
    bind
    dhcpdump
    dhcping
    postgresql_17
'

sed_placeholders[root_access]='
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp PraktikumSystemadministration"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwkCLE+pDy8HvHy98MwsNH/sxPYmBRXuREOd2jTMXPV timon.ensel@tum.de"
'

sed_placeholders[firewall]='
      # --- Database (server) --- (only vm4)
      iptables -A INPUT -p tcp --dport 5432 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 5432 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
'

# WARNGING:
# The passwords are obviously not placed in this repositoy.
# Insert all passwords into the according files in /root/db-user-pwds manually.
# database passwords are stored in a file only accessable by root
# get those passwords and insert them into the database setup process
postgrespwd=`cat /root/db-user-pwds/postgres.pwd`
localusrpwd=`cat /root/db-user-pwds/localusr.pwd`
remotusrpwd=`cat /root/db-user-pwds/remotusr.pwd`
ronlyusrpwd=`cat /root/db-user-pwds/ronlyusr.pwd`
replicpwd=`cat /root/db-user-pwds/replic.pwd`
team02pwd=`cat /root/db-user-pwds/team02.pwd`

sed_placeholders[postgrespwd]="$postgrespwd"
sed_placeholders[localusrpwd]="$localusrpwd"
sed_placeholders[remotusrpwd]="$remotusrpwd"
sed_placeholders[ronlyusrpwd]="$ronlyusrpwd"
sed_placeholders[replicpwd]="$replicpwd"
sed_placeholders[team02pwd]="$team02pwd"
