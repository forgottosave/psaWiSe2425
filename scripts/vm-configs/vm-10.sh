#!/usr/bin/env bash

# Include Files
include_files=(
    configuration.nix
    vm-network-config.nix
    team02-vm-check-exporter.nix
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
    ./team02-vm-check-exporter.nix
    ./ldap-client.nix
    ./user-config.nix
    ./csv-users.nix
'

sed_placeholders[system_packages]='
    git
    nmap
    tcpdump
    traceroute
    docker-compose
    dhcpdump
'

sed_placeholders[root_access]='
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp PraktikumSystemadministration"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwkCLE+pDy8HvHy98MwsNH/sxPYmBRXuREOd2jTMXPV timon.ensel@tum.de"
'

sed_placeholders[firewall]='
      # --- prometheus (collector/client) --- (only vm10)
      iptables -A OUTPUT -p tcp --dport 9100 -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9101 -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9090 -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9330 -d 192.168.3.0/24 -j ACCEPT # ldap
      iptables -A OUTPUT -p tcp --dport 9153 -d 192.168.3.0/24 -j ACCEPT  # coredns
      iptables -A OUTPUT -p tcp --dport 8080 -d 192.168.3.0/24 -j ACCEPT  # cadvisor
      # interface for prometheus
      iptables -A INPUT -p tcp --dport 9090 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A INPUT -p tcp --dport 3000 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A INPUT -p tcp --dport 9093 -m conntrack --ctstate NEW -j ACCEPT
      # forwarding
      iptables -I DOCKER-USER -j ACCEPT
      iptables -I FORWARD 1 -j DOCKER-USER
'
