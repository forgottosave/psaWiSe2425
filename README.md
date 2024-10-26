## Team 03 - Praktikum Systemadministration
This repository contains all the [documentation](README.md#Wiki) & all [NixOS config files](README.md#Configs) of Team 3 of the "Praktikum Systemadministration".
We use currently use [obsidian](https://obsidian.md/) as the Markdown editor for everything.
### Wiki
The documentation of all projects can be found in `wiki/`.

### Configs
The config files are all partially generated using `scripts/sync-nixos-config.sh` to
1. update all NixOS configuration files (`nixos-configs/` -> `/etc/nixos/`)
2. and insert all correct values into those files
##### cloning the configs to VMs:
We set up [deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys) for the VMs to be able to connect to the [Github repository](https://github.com/forgottosave/psaWiSe2425/). Just enter the public key in Github and clone the repo.
##### usage:
```
./scripts/sync-nixos-config.sh
```

The VM number is trying to be parsed from the `hostname`. Optionally it can be manually passed:
```
./scripts/sync-nixos-config.sh <vm-number>
```

| vm-number | explanation                     |
| --------- | ------------------------------- |
| 1         | Team-member 1 (Benjamin Liertz) |
| 2         | Team-member 2 (Timon Ensel)     |
| 3         | Router                          |
##### changing the config:
When editing the configs in `nixos-configs/`, configurations changing between VMs shouldn't be hard-coded, but rather replaced by a placeholder.

**placeholder structure:** `%%placeholdername%%`

New placeholder must be added to the VM-specific configurations in `scripts/vm-configs/vm-*.sh`.