#!/bin/bash

# Variables passed as parameters  
TEAM_NUMBER=$1    # e.g., 03  
VM_NUMBER=$2      # e.g., 01

# ISO and OVA paths (edit these paths based on your setup)  
ISO_PATH="/opt/psa/data/ISOs_VMs/nixos-minimal-24.05.5744.dc2e0028d274-x86_64-linux.iso"  
OVA_PATH="/opt/psa/data/ISOs_VMs/PSA_Template.1GB.ova"

# VM name format (customize if needed)  
VM_NAME="vmpsateam${TEAM_NUMBER}-${VM_NUMBER}"

# NAT port forwarding for SSH  
HOST_PORT=$((60000 + 100 * TEAM_NUMBER + VM_NUMBER))

# Import the VM from the OVA template  
VBoxManage import "${OVA_PATH}" --vsys 0 --ostype "${OS_TYPE}" --vmname "${VM_NAME}"

# Attach the ISO file to the VM's IDE controller  
VBoxManage storageattach "${VM_NAME}" --storagectl IDE --port 1 --device 0 --type dvddrive --medium "${ISO_PATH}"

# Remove existing NAT port forwarding for SSH (if any)  
VBoxManage modifyvm "${VM_NAME}" --nat-pf1 delete "ssh"

# Create a new NAT port forwarding rule for SSH  
VBoxManage modifyvm "${VM_NAME}" --nat-pf1 "ssh,tcp,,${HOST_PORT},,22"

# Start the VM in headless mode  
VBoxManage startvm "${VM_NAME}" --type headless

echo "VM '${VM_NAME}' has been created and started. SSH is available on port ${HOST_PORT}."  