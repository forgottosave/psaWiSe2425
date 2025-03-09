#!/usr/bin/env bash

# Include Files
include_files=(
    configuration.nix
    vm-network-config.nix
    flake.nix
    fileserver.nix
    samba.nix
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
    ./fileserver.nix
    ./samba.nix
    ./ldap-client.nix
    ./user-config.nix
    ./csv-users.nix
'

sed_placeholders[system_packages]='
    git
    mdadm
    nmap
    tcpdump
    traceroute
    dhcpdump
    openssl
'

sed_placeholders[root_access]='
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp PraktikumSystemadministration"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwkCLE+pDy8HvHy98MwsNH/sxPYmBRXuREOd2jTMXPV timon.ensel@tum.de"
'

sed_placeholders[firewall]='
      # --- NFS (server) --- (only vm8)
      # Allow rpcbind
      iptables -A INPUT -p tcp --dport 111 -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p udp --dport 111 -s 192.168.0.0/16 -j ACCEPT
      # Allow mountd (fixed to port 20048)
      iptables -A INPUT -p tcp --dport 20048 -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p udp --dport 20048 -s 192.168.0.0/16 -j ACCEPT
      # Allow NFS itself
      iptables -A INPUT -p tcp --dport 2049 -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p udp --dport 2049 -s 192.168.0.0/16 -j ACCEPT
      # Allow NLM (nlockmgr) for file locking if needed
      iptables -A INPUT -p udp --dport 37373 -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 43027 -s 192.168.0.0/16 -j ACCEPT

      
      # --- Samba (server) --- (only vm8)
      iptables -A INPUT -p udp --dport 137 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p udp --dport 138 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 139 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 445 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
'
