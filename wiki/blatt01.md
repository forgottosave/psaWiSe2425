
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
    `n` -> \\n -> \\n -> `+64M` -> `ef00`  
    `n` -> \\n -> \\n -> `+1G` -> `8200`  
    `n` -> \\n -> \\n -> \\n -> `8300`  
    `w` -> `y`  
   

#### Partitionen formatieren  
(swap nötig sonnst hängt sich der installer bei 1G Ram auf)

- formatieren der Partitionen:  
    ```bash  
    sudo mkfs.fat -F 32 -n boot /dev/sda2 &&  
    sudo mkswap -L swap /dev/sda3 &&  
    sudo mkfs.ext4 -L nixos /dev/sda4 &&  
    sudo mkdir -p /mnt/boot  
    ```

- enable swap und partitionen mounten:  
    ```shell  
    sudo swapon /dev/sda3 &&  
    sudo mount /dev/disk/by-label/nixos /mnt &&  
    sudo mount -o umask=077 /dev/disk/by-label/boot /mnt/boot  
    ```

- generrieren der nixos configs + installieren  
    ```shell  
    sudo nixos-generate-config --root /mnt  
    sudo nixos-install  
    ```

- edit config `/mnt/etc/nixos/configuration.nix`  
    TODO: use skript

- reboot:  
    ```shell  
    sudo reboot  
    ```



## User konfigurieren

TODO: use skript


