# Team 03 - Praktikum Systemadministration
<p align="center">
  <a href="mailto:ge71zig@tum.de"><img src="https://img.shields.io/badge/-ge71zig%40tum.de-red?logo=mail.ru&logoColor=white"></img></a>
  <a href="https://github.com/forgodtosave/"><img src="https://img.shields.io/badge/-Benjamin Liertz-gray?logo=github&logoColor=white"></img></a>
  <a href="[https://director.net.in.tum.de/](https://director.net.in.tum.de/teaching/ws2425/psa.html)"><img src="https://img.shields.io/badge/-https://director.net.in.tum.de/-blue?logo=onnx&logoColor=white"></img></a>
  <a href="https://github.com/forgottosave/"><img src="https://img.shields.io/badge/-Timon Ensel-gray?logo=github&logoColor=white"></img></a>
  <a href="mailto:timon.ensel@tum.de"><img src="https://img.shields.io/badge/-timon.ensel%40tum.de-red?logo=mail.ru&logoColor=white"></img></a>
</p>

This repository contains all the [documentation](README.md#Wiki) & all [NixOS config files](README.md#Configs) of Team 3 of the "Praktikum Systemadministration".
We use currently use [obsidian](https://obsidian.md/) as the Markdown editor for everything.

## Wiki
The documentation of all projects can be found in `wiki/`.
- [x] [`Blatt 01`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt01.md)
- [ ] [`Blatt 02`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt02.md)

## Team
| VM | explanation                     |
| -- | ------------------------------- |
| 1  | Team-member 1 (Benjamin Liertz) |
| 2  | Team-member 2 (Timon Ensel)     |
| 3  | Router                          |

## Configs
##### Synchronizing & Updating the configs to VMs:
We set up [deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys) for the VMs to be able to connect to the [Github repository](https://github.com/forgottosave/psaWiSe2425/). Just enter the public key in Github and clone the repo.

##### changing the configs
The config files on the VMs are all partially generated using `scripts/sync-nixos-config.sh` to
1. update all NixOS configuration files (`nixos-configs/` -> `/etc/nixos/`)
2. and insert all correct values into those files (see chapter *placeholder*)
```                 
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

##### placeholder `%%placeholdername%%`
When editing the configs in `nixos-configs/`, configurations changing between VMs shouldn't be hard-coded, but rather replaced by a placeholder. New placeholder must be added to the VM-specific configurations in `scripts/vm-configs/vm-*.sh`.
