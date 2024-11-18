
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
- Skript herunterladen und ausführen:  # FIXME
    ```shell  
    curl https://github.com/forgottosave/psaWiSe2425/blob/main/scripts/create_vm.sh 
    chmod +x create_vm.sh  
    ./create_vm.sh 03 01  
    ```
- dann via der vnc-Verbindung ein Passwort erstellen damit SSH nutzbar wird: 
    ```shell
    passwd
    ```
    -> vnc viewer kann geschlossen werden
- terminal öffnenssh und per ssh mit vm verbinden: 
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

- nun die VM herunterfahren und die Festplatte vergrößern in VirtualBox (Tools->Media->Properties) und dort die Size der ensprechenden Platte auf 32GB erhöhen. Nun die VM wieder starten und die Partitionen neu erstellen.

#### neue Partitionen erstellen  
- Zunächst ist wichtig von vorhandenen Partitionsschema MBR zu GPT für EFI suport zu wechseln. Dann muss die alte Partition noch verkleinert und die Neuen erstellt werden:  
    ```shell  
    sudo gdisk /dev/sda  
    ```  
    in diesen tool git es nun folgende grundliegende Befehle:  
    - `p` - print -> listet alle aktuellen partitionen  
    - `d` - delete -> löscht der Partition mit der angegebenen Nummer  
    - `n` - new -> erstellt eine neue Partition  
    - `w` - write -> schreibt alle Änderungen und beendet das Tool

- um die Partitionen zu erstellen folgende Befehle ausführen:  
    `n` -> \\n -> 63 -> `+64M` -> `0700` <br>
    `n` -> \\n -> \\n -> `+512M` -> `ef00` <br>
    `n` -> \\n -> \\n -> `+1G` -> `8200` <br>
    `n` -> \\n -> \\n -> \\n -> `8300` <br> 
    `w` -> `y`  
   

#### Partitionen formatieren  
(swap nötig sonnst hängt sich der installer bei 1G Ram auf)

- formatieren der Partitionen:  
    ```bash  
    sudo mkfs.fat -F 32 -n boot /dev/sda2 &&  
    sudo mkswap -L swap /dev/sda3 &&  
    sudo mkfs.ext4 -L nixos /dev/sda4  
    ```

- enable swap und partitionen mounten:  
    ```shell  
    sudo swapon /dev/sda3 &&  
    sudo mount /dev/disk/by-label/nixos /mnt &&  
    sudo mkdir /mnt/boot &&
    sudo mount -o umask=077 /dev/disk/by-label/boot /mnt/boot  
    ```

- generrieren der nixos configs + installieren  
    ```shell  
    sudo nixos-generate-config --root /mnt  
    ```

- edit config `/mnt/etc/nixos/configuration.nix`  
    Temp config for enabeling ssh and git:
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
				enable = true;
				settings.PasswordAuthentication = true;
				settings.KbdInteractiveAuthentication = false;
				settings.PermitRootLogin = "yes";
		};

		networking.firewall.allowedTCPPorts = [ 22 ];
		networking.hostName = "vmpsateam03-03"; # change accordingly to vm number
		networking.networkmanager.enable = true;
		time.timeZone = "Europe/Amsterdam";

		users.users."root".openssh.authorizedKeys.keys = [
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM"
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwkCLE+pDy8HvHy98MwsNH/sxPYmBRXuREOd2jTMXPV timon.ensel@tum.de"
		];

		environment.systemPackages = with pkgs; [
				git
		];

		nix.settings.experimental-features = [ "nix-command" "flakes" ];

		system.stateVersion = "24.05";
    }
    ```


- reboot:  
		```shell  
		sudo nixos-install --no-root-passwd &&
		sudo reboot  
		```

- nixos rebuild um die erstellte config zu laden:  
    ```shell  
		#nix store gc
		#nix-collect-garbage -d
		cd /etc/nixos/ &&
		nano flake.nix
		```

- flake cinfig:
	```nix
	{
		inputs = {
			nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
			unstable.url = "github:nixos/nixpkgs/nixos-unstable";
		};

		outputs = inputs@{ nixpkgs, ... }:
		{
			nixosConfigurations = {
				"vmpsateam03-03" = nixpkgs.lib.nixosSystem {
					system = "x86_64-linux";
					specialArgs = {
						inherit inputs;
					};
					modules = [
						{ networking.hostName = "vmpsateam03-03"; }
						./configuration.nix
					];
				};
			};
		};
	}
	```

- lock und rebuild:
		```shell
		nix flake lock &&
    sudo nixos-rebuild switch --flake .#vmpsateam03-03 
    ```



## User konfigurieren

TODO: use skript


