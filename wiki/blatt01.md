# Aufgabenblatt 01

in diesem Blatt geht es darum eine VM aufzusetzen und die User zu konfigurieren.
Wir haben uns für NIXOS entschieden, da hier mit der zentralen Konfigurationsdatei eine einfache reproduzierbarkeit gegeben ist.

## Teiaufgaben

### 1) Öffnen einer neuen vnc-Verbindung

Um nix os zu installiert muss man zu beginn sich einmal mit vnc auf den server verbinden um die installation zu starten oder temporär ssh zu akivieren um die installation per ssh durchzuführen.

- per ssh mit psa server verbinden: `ge78zig@psa.in.tum.de`  
- prüfen ob ein vnc-server mit eigener Nutzerkennung (ge78zig) bereits läuft: `ps -ef | grep vnc`
  -> vnc-Adresse gegeben durch `psa.in.tum.de:<nummer nach vnc:>`  
- falls nicht starten einen vnc-Server mit: `vncserver`  
- falls mehrere laufen, überflüssige mit `kill <pid>` beenden  
- dann vnc-Client der wahl öffnen z.B. KRDC und mit Adresse verbinden (ggf bei anzeigefehlern "scale"-button drücken)

### 2) VM Setup

Zum erstellen einer VM gibt es ein [skript](https://github.com/forgottosave/psaWiSe2425/blob/main/scripts/create_vm.sh) welches eine nixos VM nach dem PSA-Template erstellt und startet.

- Skript herunterladen und ausführen:  # FIXME

  ```shell  
  curl https://github.com/forgottosave/psaWiSe2425/blob/main/scripts/create_vm.sh 
  chmod +x create_vm.sh  
  ./create_vm.sh 03 01  # 03 01 -> Team 03, VM 01
  ```

- dann via der vnc-Verbindung ein Passwort erstellen damit SSH nutzbar wird:

  ```shell
  passwd
  ```

  -> vnc viewer kann geschlossen werden
- terminal öffnen und per ssh mit der VM verbinden (user hier noch `nixos` während der installation):

  ```shell
  ssh -p 60301 nixos@psa.in.tum.de
  ```

### 3) Speicher anpassen

#### alte Partition verkleinern

- zunächst müssen wir herausfinden welche BlockDevices vorhanden sind und welche Partitionen auf diesen vorhanden sind:  

  ```shell  
  lsblk -f  
  ```
  
  ->  die Festplatte `/dev/sda` hat einer Partition `/dev/sda1` mit ~7GB

- die vorhandene Partition wird nun verkleinert damit wir für die neuen Partitionen fürs OS wieder Platz haben:

  ```shell  
  sudo ntfsresize --size 64M /dev/sda1  
  ```

- nun die VM herunterfahren und die Festplatte vergrößern in VirtualBox (Tools->Media->Properties) und dort die Size der ensprechenden Platte auf 32GB erhöhen. Nun die VM wieder starten und die Partitionen neu erstellen. Dieser Schritt ist nötig da bei der verwendung von nix flake stets die Partition zu klein war um alle temporären Dateien zu speichern. Da bei der Vergrößerung der Disk leider aber der Partitiontable kaputt geht, muss dieser zunächst die alte Partition verkleinert werden bevor die disk vergrößert werden kann.

#### neue Partitionen erstellen  

- Zunächst ist wichtig von vorhandenen Partitionsschema MBR zu GPT für EFI suport zu wechseln daher ferwenden wir `gdisk`bei welchem dies automatisch der Fall ist. Dann müsses nur noch die neuen partitionen erstellt werden (swap nötig sonnst hängt sich der installer bei 1G Ram auf): 

  ```shell  
  sudo gdisk /dev/sda  
  ```  

  in diesen tool git es nun folgende grundliegende Befehle:  
  - `p` - print -> listet alle aktuellen partitionen  
  - `d` - delete -> löscht der Partition mit der angegebenen Nummer  
  - `n` - new -> erstellt eine neue Partition  
  - `w` - write -> schreibt alle Änderungen und beendet das Tool

- um die Partitionen zu erstellen folgende Befehle ausführen:  
  `n` -> \\n -> 63 -> `+64M` -> `0700`
  `n` -> \\n -> \\n -> `+512M` -> `ef00`
  `n` -> \\n -> \\n -> `+1G` -> `8200`
  `n` -> \\n -> \\n -> \\n -> `8300`
  `w` -> `y`  

#### Partitionen formatieren  

- zunächst müssen die Partitionen formatiert werden:  

  ```bash  
  sudo mkfs.fat -F 32 -n boot /dev/sda2 &&  
  sudo mkswap -L swap /dev/sda3 &&  
  sudo mkfs.ext4 -L nixos /dev/sda4  
  ```

- und dann die swap-Partition aktiviert und die andere partitionen gemounten werden:  

  ```shell  
  sudo swapon /dev/sda3 &&  
  sudo mount /dev/disk/by-label/nixos /mnt &&  
  sudo mkdir /mnt/boot &&
  sudo mount -o umask=077 /dev/disk/by-label/boot /mnt/boot  
  ```

- nun kann die nixos Config-Datein generrieren werden:

  ```shell  
  sudo nixos-generate-config --root /mnt  
  ```

- befor nun nixos installiert wird is es wichtig die Config anzupassen damit nach einen neustart gleich ssh und z.B. auch git funktioniert. Dafür nun `sudo nano /mnt/etc/nixos/configuration.nix` und die alte Konfig durch die folgende temporäre Config ersetzen:

  ```nix
  { config, lib, pkgs, ... }:
  {
    imports = [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # https://nixos.wiki/wiki/SSH_public_key_authentication
    services.sshd.enable = true;
    services.openssh = {
      enable = true;                                  # Enable the OpenSSH daemon
      PermitRootLogin = "prohibit-password";          # Disable root passwd login
      PasswordAuthentication = false;                 # Disable password authentication
      settings.KbdInteractiveAuthentication = false;  # Disable keyboard-interactive authentication
      settings.PermitRootLogin = "yes";               # Enable root login
    };

    networking.firewall.allowedTCPPorts = [ 22 ];
    networking.hostName = "vmpsateam03-03";           # change accordingly to vm number
    networking.networkmanager.enable = true;
    time.timeZone = "Europe/Amsterdam";

    # all keys for ssh access
    users.users."root".openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1bL8aC20ERDdJE2NqzIBvs8zXmCbFZ7fh5qXyqGNF7XfdfbsPBfQBSeJoncVfTJRFNYF4E+1Me918QMIpqa9XR4nJYOdOzff1JLYp1Z1X28Dx3//aOir8ziPCvGZShFDXoxLp6MNFIiEpI/IEW9OqxLhKj6YWVEDwK1ons7+pXnPM6Nd9lPd2UeqWWRpuuf9sa2AimQ1ZBJlnp7xHFTxvxdWMkTu6aH0j+aTT1w1+UDN2laS4nsmAJOO2KjeZq6xpbdmj9cjuxBJtM3Dsoq4ZJGdzez7XYhvCTQoQFl/5G0+4FBZeAgL/4ov12flGijZIIaXvmMBkLZRYg3E2m1Rp PraktikumSystemadministration"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwkCLE+pDy8HvHy98MwsNH/sxPYmBRXuREOd2jTMXPV timon.ensel@tum.de"
    ];

    # to install git
    environment.systemPackages = with pkgs; [
      git
    ];

    # to enable nix-command and flakes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    system.stateVersion = "24.05";
  }
  ```

- nun ist alles fertig konfiguriert um nixos zu installieren und neu zu starten:  

  ```shell  
  sudo nixos-install --no-root-passwd &&
  sudo reboot  
  ```

- nun wird noch eine flake Config angelegt um bei pkgs auch die unstable Version verwenden zu können:  

  ```shell
  cd /etc/nixos/ &&
  nano flake.nix
  ```

- und die folgende Config einfügen:

  ```nix
  {
    inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
      unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    };

    outputs = inputs@{ nixpkgs, ... }:
    {
      nixosConfigurations = {
        "vmpsateam03-03" = nixpkgs.lib.nixosSystem { # change accordingly to vm number
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./configuration.nix
          ];
        };
      };
    };
  }
  ```

- nun noch flake update und nixos neu starten:

  ```shell
  nix flake update &&
  sudo nixos-rebuild switch --flake .#vmpsateam03-03 
  ```

- die VM sollte nun fertig installiert sein und per ssh erreichbar sein.

## Aktive Dienste

nun kann noch getetstet werden welche Dienste auf der VM laufen per default laufen:

```shell
sudo systemctl list-units --type=service --state=running
```

wie zu sehen ist, sind nur die nötigsten Dienste aktiviert, da die minimal version von nixos installiert wurde.

## Konfiguration der VM

in diesen Aufgabenblatt war nun nur noch die Aufgabe einen ssh Zugang für root einzurichten.
Da bereits in unserer temporären Config ssh nur per key für root aktiviert wurde und auch alle nötigen keys bereits hinterlegt sind, ist dies bereits erfüllt.

Auch soll für alle Praktikumteilnehmer:innen einen User erstellt werden wobei auch diese sich über ssh einloggen können sollen. Dafür haben wir die folgende [zusätzliche Config](https://github.com/forgottosave/psaWiSe2425/blob/main/nixos-configs/user-config.nix) erstellt wobei die gid und uids dem davor festgelegten Schema folgen:

```nix
{config, pkgs, ... }:
{
  users.groups.students.gid = 1000;

  #Team1  
  users.users.ge95vir = {  
    isNormalUser = true;  
    home = "/home/ge95vir";  
    uid = 1010;  
    group = "students";  
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXPasCKmYHeTJ06DBWXCaYYUVM/Euo+X5tU0WpGWxRt gedeon.lenz@tum.de" ];  
  };  
  users.users.ge43fim = {  
    isNormalUser = true;  
    home = "/home/ge43fim";  
    uid = 1011;  
    group = "students";  
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJxRi9ByDSdft3zbasPq04DvoDHZDKHLzg5vtP+Caii andrey.maleev@tum.de" ];  
  };  
  #Team2 
...
```

diese Config wird dann in die `configuration.nix` importiert wie auch bereits die `hardware-configuration.nix` und dann ein nixos rebuild durchgeführt.

```shell
sudo nixos-rebuild switch
```

Hiermit ist die Konfiguration der VM abgeschlossen und alle User können sich per ssh einloggen.