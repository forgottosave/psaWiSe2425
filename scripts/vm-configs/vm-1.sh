#!/usr/bin/env bash

# General configuration
vm=$VM_NUMBER
include_files=(
    configuration.nix
    user-config.nix
    vm-network-config.nix
)

# SED placeholders
declare -A sed_placeholders

sed_placeholders[vm]="$vm"

sed_placeholders[root_access]='
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp PraktikumSystemadministration"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM"
'
