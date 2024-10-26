
# Aufgabenblatt 01
in diesem Blatt geht es darum eine VM aufzusetzen und die User zu konfigurieren.
Wir haben uns für NIXOS entschieden, da hier mit der zentralen Konfigurationsdatei eine einfache reproduzierbarkeit gegeben ist.


## Teiaufgaben
### 1) Öffnen einer neuen vnc-Verbindung 
Um nix os zu installiert muss man zu beginn sich einmal mit vnc auf den server verbinden um die installation zu starten oder temporär ssh zu akivieren um die installation per ssh durchzuführen.
- per ssh mit psa server verbinden: `ge78zig@psa.in.tum.de`  
- prüfen ob ein vnc-server mit eigener Nutzerkennung (ge78zig) bereits läuft: `ps -ef | grep vnc` <br>-> vnc-Adresse gegeben durch `psa.in.tum.de:<nummer nach vnc:>`  
- falls nicht starten einen vnc-Server mit: `vncserver`  
- falls mehrere laufen, überflüssige mit `kill <pid>` beenden  
- dann vnc-Client der wahl öffnen z.B. KRDC und mit adresse verbinden (ggf bei anzeigefehlern "scale"-button drücken)


### 2) VM Setup
Zum erstellen einer VM gibt es ein [skript](https://github.com/forgottosave/psaWiSe2425/blob/main/scripts/create_vm.sh) welches eine nixos VM nach dem PSA-Template erstellt und startet.
- Skript herunterladen und ausführen:  
    ```shell  
    curl https://github.com/forgottosave/psaWiSe2425/blob/main/scripts/create_vm.sh 
    chmod +x create_vm.sh  
    ./create_vm.sh 03 01  
    ```
- dann via der vnc-Verbindung ein Passwort erstellen damit SSH nutzbar wird: `passwd` <br>-> vnc viewer kann geschlossen werden
- terminal öffnenssh und per ssh mit vm verbinden: `ssh -p 60301 nixos@psa.in.tum.de`


### 3) Speicher anpassen
#### alte Partition verkleinern  
zunächst müssen wir herausfinden welche BlockDevices vorhanden sind und welche partitionen auf diesen vorhanden sind:  
```shell  
lsblk -f  
```  
->  die festplatte `/dev/sda` hat einer Partition `/dev/sda1` mit ~7GB

die vorhandene Partition wird nun verkleinert damit wir für die neuen Partitionen fürs OS wieder Platz haben:  
```shell  
sudo ntfsresize --size 64M /dev/sda1  
```

#### neue Partitionen erstellen  
Zunächst ist wichtig von vorhandenen Partitionsschema MBR zu GPT für EFI suport zu wechseln. Dann muss die alte Partition noch verkleinert und die Neuen erstellt werden:  
```shell  
sudo gdisk /dev/sda  
```  
in diesen tool git es nun folgende grundliegende Befehle:  
- `p` - print -> listet alle aktuellen partitionen  
- `d` - delete -> löscht der Partition mit der angegebenen Nummer  
- `n` - new -> erstellt eine neue Partition  
- `w` - write -> schreibt alle Änderungen und beendet das Tool

o -> y  
n -> \\n -> 63 -> +64M -> 0700  
n -> \\n -> \\n -> +512M -> ef00  
n -> \\n -> \\n -> +1G -> 8200  
n -> \\n -> \\n -> \\n -> 8300  
w -> y

#### Partitionen formatieren  
(swap nötig sonnst hängt sich der installer bei 1G Ram auf)

formatieren der Partitionen:  
```bash  
sudo mkfs.fat -F 32 -n boot /dev/sda2 &&  
sudo mkswap -L swap /dev/sda3 &&  
sudo mkfs.ext4 -L nixos /dev/sda4 &&  
sudo mkdir -p /mnt/boot  
```

enable swap und partitionen mounten:  
```shell  
sudo swapon /dev/sda3 &&  
sudo mount /dev/disk/by-label/nixos /mnt &&  
sudo mount -o umask=077 /dev/disk/by-label/boot /mnt/boot  
```

generrieren der nixos configs + installieren  
```shell  
sudo nixos-generate-config --root /mnt  
sudo nixos-install  
```

edit config `/mnt/etc/nixos/configuration.nix`  
```shell  
{ config, lib, pkgs, ... }:

{  
  imports =  
    [ # Include the results of the hardware scan.  
      ./hardware-configuration.nix  
    ];

  # Use the systemd-boot EFI boot loader.  
  boot.loader.systemd-boot.enable = true;  
  boot.loader.efi.canTouchEfiVariables = true;

  # https://nixos.wiki/wiki/SSH_public_key_authentication  
  services.openssh = {  
    enable = true;  
    settings.PasswordAuthentication = false;  
    settings.KbdInteractiveAuthentication = false;  
    settings.PermitRootLogin = "yes";  
  };

  networking.firewall.allowedTCPPorts = [22];  
  networking.hostName = "vmpsateam03-01";  
  time.timeZone = "Europe/Amsterdam";

  users.users."root".openssh.authorizedKeys.keys = [  
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp PraktikumSystemadministration"  
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM psa-24"  
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwkCLE+pDy8HvHy98MwsNH/sxPYmBRXuREOd2jTMXPV timon.ensel@tum.de"  
  ];

```

reboot:  
```shell  
sudo reboot  
```



## User konfigurieren

config file für alle user erstellen: `nano /etc/nixos/user-config.nix`


