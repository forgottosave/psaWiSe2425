# NixOS Configuration - Team 03 - Praktikum Systemadministration

## Adding a new VM config

Default configuration:

```bash
#!/usr/bin/env bash

# Include Files
include_files=(
    <all files to include in this configuration (located in nixos-configs)>
)

# SED placeholders
sed_placeholders[vm]="$VM_NUMBER"

sed_placeholders[imports]='
    <files to import in the configuration.nix>
'

sed_placeholders[system_packages]='
    <system packages to be installed on this VM>
'

sed_placeholders[root_access]='
    <ssh-public keys with root access>
'
```

## Synchronizing & Updating the configs to VMs

We set up [deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys) for the VMs to be able to connect to the [Github repository](https://github.com/forgottosave/psaWiSe2425/). Just enter the public key in Github and clone the repo.

## changing the configs

The config files on the VMs are all partially generated using `scripts/sync-nixos-config.sh` to

1. update all NixOS configuration files (`nixos-configs/` -> `/etc/nixos/`)
2. and insert all correct values into those files (see chapter *placeholder*)

```text
  ┌───────────────────────────┐               
  │ ./nixos-configs/          │               
  │     configuration.nix     │               
  │     router-network.nix    │               
  │     user-config.nix       │               
  │     vm-network-config.nix │               
  └────────┬──────────────────┘               
           │                                  
           │ change config                    
           │ git push                         
           ▼                                  
       ┌─────────────────┐                    
       │ Virtual Machine │                    
       │      (ssh)      │                    
       │                 │                    
       └───┬─────────────┘                    
           │                                  
           │ git pull                         
           │ ./scripts/sync-nixos-config      
           ▼                                  
    ┌────────────────────────┐                
    │   VM sets new config   │                
    │  nixos-rebuild switch  │                
    │                        │                
    │ Everything up to date! │                
    └────────────────────────┘ 
```

## placeholder `%%placeholdername%%`

When editing the configs in `nixos-configs/`, configurations changing between VMs shouldn't be hard-coded, but rather replaced by a placeholder. New placeholder must be added to the VM-specific configurations in `scripts/vm-configs/vm-*.sh`.
