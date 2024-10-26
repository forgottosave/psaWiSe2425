## Team 03 - Praktikum Systemadministration
This repository contains all the [documentation](README.md#Wiki) & all [NixOS config files](README.md#Configs) of Team 3 of the "Praktikum Systemadministration".
We use currently use [obsidian](https://obsidian.md/) as the Markdown editor for everything.
### Wiki
The documentation of all projects can be found in `wiki/`.

### Configs
The config files are all partially generated using `scripts/sync-nixos-config.sh` to
1. update all NixOS configuration files (`nixos-configs/` -> `/etc/nixos/`)
2. and insert all correct values into those files
##### usage:
```
./scripts/sync-nixos-config.sh
```

The VM number is trying to be parsed from the hostname. Optionally it can be manually passed:
```
./scripts/sync-nixos-config.sh <vm-number>
```

| vm-number | explanation                     |
| --------- | ------------------------------- |
| 1         | Team-member 1 (Benjamin Liertz) |
| 2         | Team-member 2 (Timon Ensel)     |
| 3         | Router                          |
##### changing the config:
When editing the configs in `nixos-configs/`, configurations changing between VMs shouldn't be hard-coded, but rather replaced by a `sed`-able placeholder.

**placeholder structure:** `%%placeholdername%%`

Adding a new placeholder must be done in:

1. add an `sed` entry to `scripts/sync-nixos-config.sh` under `# 3. ...`
2. add the configurations to `scripts/vm-configs/vm-*.sh`
3. use the placeholder in the configs in `nixos-configs/`
