#!/usr/bin/env bash

# Include Files
include_files=(
    configuration.nix
    vm-network-config.nix
    user-config.nix
    flake.nix
    ldap.nix
    ldap-prometheus.nix
    csv-users.nix
)

# SED placeholders
declare -A sed_placeholders

sed_placeholders[vm]="$VM_NUMBER"

sed_placeholders[imports]='
    ./hardware-configuration.nix
    ./vm-network-config.nix
    ./user-config.nix
    ./ldap.nix
    ./ldap-prometheus.nix
'

sed_placeholders[system_packages]='
    git
    nmap
    tcpdump
    traceroute
    dhcpdump
    mdadm
    openssl
    dhcping
'

sed_placeholders[root_access]='
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp PraktikumSystemadministration"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwkCLE+pDy8HvHy98MwsNH/sxPYmBRXuREOd2jTMXPV timon.ensel@tum.de"
'

sed_placeholders[firewall]='
      # --- LDAP (server) --- (only vm7)
      iptables -A INPUT -p tcp --dport 389 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 636 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
'
