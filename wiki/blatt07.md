# Aufgabenblatt 07

In diesem Blatt geht es darum einen Fileserver für alle Daten einzurichten. Dieser wird bei uns auf VM 8 gehostet.

## Teilaufgaben

### 1) Hardware Konfiguration

#### 1.1) Einrichten der neuen VM mit extra Festplatten

Für die benötigte Ausfallsicherheit reicht RAID 5 aus und hat zudem eine vergleichsweise gute Disk-Space-Efficiency. Die Anforderung, 10GB an Speicher bei 2GB Festplatten zu haben wird laut [Online RAID Rechner](https://www.gigacalculator.com/calculators/raid-calculator.php) mit 6 Festplatten erreicht. Nur um sicher zu gehen werden wir im folgenden 7 Festplatten verwenden.

1. Erstellen der VM
   Wie bei vorherigen VMs durch Ausführung von `./create_vm 03 08`, jedoch wird der letzte Schritt, das Starten der VM ausgesetzt.

2. Hinzufügen der Festplatten
   In VirtualBox können diese unter `Settings > Storage > Devices` graphisch angelegt werden. Hierfür einen neuen SATA Controller anlegen und diesem 7 Festplatten (`.vdi`) mit je 2GB anhängen.

   ![image](https://github.com/user-attachments/assets/91df6a54-8cbd-4fb0-8d3a-041a3e59ca51)

3. Mit der Installation von NixOS fortfahren (siehe [Blatt 01](blatt01.md)).

#### 1.2) RAID mit `mdadm`

Aufgrund des guten Supports haben wir uns für `mdadm` entschieden. Eine angestrebte Alternative, `zraid` auf `ZFS`, können wir leider aufgrund einer zu neuen Kernel Version (siehe [nixos.wiki](https://nixos.wiki/wiki/ZFS#ZFS_support_for_newer_kernel_versions)) nicht nutzen.  Wir fügen `mdadm` zunächst zur VM hinzu:

```shell
# vm-8.sh
sed_placeholders[system_packages]='
 ...
 mdadm
'
```

Mit `lsblk` sehen wir unsere 7 Festplatten `sdb-h`.

```shell
[root@vmpsateam03-08:~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   32G  0 disk 
├─sda1   8:1    0   64M  0 part 
├─sda2   8:2    0  512M  0 part /boot
├─sda3   8:3    0    1G  0 part [SWAP]
└─sda4   8:4    0 30.4G  0 part /nix/store
                                /
sdb      8:16   0    2G  0 disk 
sdc      8:32   0    2G  0 disk 
sdd      8:48   0    2G  0 disk 
sde      8:64   0    2G  0 disk 
sdf      8:80   0    2G  0 disk 
sdg      8:96   0    2G  0 disk 
sdh      8:112  0    2G  0 disk 
sr0     11:0    1    1G  0 rom
```

Mit `mdadm` können wir diese einfach zu einem RAID Verbund zusammenfassen Wir spezifizieren das Raid-Level und alle zugehörigen Festplatten:

```shell
mdadm --create /dev/md/md_1 --level=raid5 --raid-devices=7 /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh
```

Um zu überprüfen, ob alles funktioniert hat, kann der RAID-Verbund gequerried werden:

```shell
[root@vmpsateam03-08:~]# mdadm -Q /dev/md127
/dev/md127: 11.98GiB raid5 7 devices, 0 spares. Use mdadm --detail for more detail.
```

Nun lässt sich ein Filesystem darauf anlegen und mounten:

```shell
mkfs.ext4 /dev/md127 && mkdir /raided_fs && mount /dev/md127 /raided_fs
```

`df -h` zeigt und nun das Filesystem, das wie erwartet 12 GB zur Verfügung stellt:

```shell
[root@vmpsateam03-08:~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/md127       12G  2.1M   12G   1% /raided_fs
```

Quellen:

- [RAID calculator](https://www.gigacalculator.com/calculators/raid-calculator.php)
- [RAID with mdadm](https://www.golinuxcloud.com/configure-software-linear-raid-linux/#Partitioning_with_fdisk)

### 2) Datenmigration

Als nächstes folgt die manuelle Datenmigration aller VMs auf **VM 8**. Unter `/export` (unserem RAID Festplattenverbund) legen wir alle Home-Verzeichnisse, sowie die Main-Datenbank ab. Die Backup-Datenbank lassen wir auf der anderen VM, da in einem realistischen Usecase nicht beide Instanzen auf dem selben System liegen sollten. In einem echten Szenario würden wir dieser dementsprechend auch einen größeren Fileserver aufsetzen.

Das Migrieren der Daten erfolgt wie folgt:

#### 2.1) `rsync`

Mit `rsync` können wir einfach alle Verzeichnisse synchronizieren (wir nutzen hierfür als "Zwschenstopp" einen lokalen Rechner, da dieser bereits alle ssh Zugriffe besitzt). Um sie auf die VM 8 zu bekommen, können wir dann wieder rsync nutzen.
*Achtung: Wir legen tatsächlich auch die Homeverzeichnisse anderer Teams an, damit wir diese von unserem Fileserver mounten können, solange andere Fileserver noch nicht errecihbar sind.* 

```ascii
┌────────────────────────┐                                               
│          VM 01         │                                               
│       192.168.3.1      │                                               
│------------------------│                                               
│ /home                  ├──┐                                            
│                        │  │                                            
└────────────────────────┘  │                                            
           o o o            │                                            
┌────────────────────────┐  │                                            
│          VM 04         │  │                                            
│       192.168.3.4      │  │                                            
│------------------------│  │                                            
│ /home                  ├──┤       ┌─────────────┐       ┌─────────────┐
│ /var/lib/postgresql/17 │  │       │local machine│       │    VM 08    │
│                        │  │       │             │       │ 192.168.3.8 │
└────────────────────────┘  │ rsync │-------------│ rsync │-------------│
           o o o            ├──────►│ /some/dir   ├──────►│   /export   │
┌────────────────────────┐  │       │             │       │             │
│          VM 06         │  │       └─────────────┘       └─────────────┘
│       192.168.3.6      │  │                                            
│------------------------│  │                                            
│ /home                  ├──┘                                             
│ /etc/nixos/sites       │                                           
│                        │                                               
└────────────────────────┘                                                
          o o o
```

1. "Mergen" aller Daten auf den lokalen Rechner
   Mit einem einfachen Script können wir uns alle Homeverzeichnisse der VMs holen. Hierbei gehen wir einfach alle Ports von 60301 - 60308 durch, um alle VMs abzudecken.

   ```shell
   for i in {1..8}; do
     printf "\n|| Synchronizing VM 0${i}...\n\n"
     rsync -avz -e "ssh -p 6030${i}" --progress root@psa.in.tum.de:/home .
   done
   ```

   Lediglich der Webserver DocumentRoot auf **VM 6** und das Datenbank-Verzeichnis von **VM 4** fehlen noch:

   ```shell
   rsync -avz -e "ssh -p 60306" --progress root@psa.in.tum.de:/etc/nixos/sites .
   rsync -avz -e "ssh -p 60304" --progress root@psa.in.tum.de:/var/lib/postgresql .
   ```

2. Kopieren auf **VM 8**
  
   ```shell
   rsync -avz -e "ssh -p 60308" --progress . root@psa.in.tum.de:/export
   ```

   Nun liegen alle benötigten Daten auf dem RAID-Verbund auf VM 8.

#### 2.2) Rechtevergabe

Damit alle Nutzer auf ihre Dateien zugreifen können wie gewohnt, müssen wir noch die Rechte wieder anpassen.
Für alle Home-Verzeichnisse geschieht das wie folgt:

```shell
cd /export/home
for dir in *; do
  chown -R "$dir:students" "$dir"
done
```

Für den Datenbank-Nutzer müssen wir zunächst den entsprechenden Nutzer anlegen, da dieser auf der **VM 8** nicht existieren:

```nix
# fileserver.nix
users.groups.postgres.gid = 71;
users.users.postgres = {
  isSystemUser = true;
  home = "/home/postgres";
  uid = 71; # according to VM 4 postgres user id
  group = "postgres"; 
};
```

Quellen:

- [rsync](https://thelinuxcode.com/rsync-examples-rsync-options-and-how-to-copy-files-over-ssh/)

### 3) NFS

Anschließend müssen die jeweiligen Home-Verzeichnisse, sowie die Datenbanken von der **VM 8** aus gemountet werden. Hierfür muss zuerst File-Sharing aktiviert werden.

```nix
# fileserver.nix
services.nfs.server = {
  enable = true;
  createMountPoints = true;
  exports = ''
    /export                 192.168.0.0/16(rw,fsid=0,no_subtree_check)
    /export/home            192.168.0.0/16(rw,sync)
    /export/postgresql      192.168.3.4(rw,sync)
    /export/sites           192.168.3.6(rw,sync)
  '';
};
```

und in der Firewall erlabt werden:

```shell
# vm-network-config.nix & router-network.nix
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 111 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 111 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 2049 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 32803 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 32769 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 892 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 892 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 875 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 875 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 662 -j ACCEPT
iptables -A RH-Firewall-1-INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 662 -j ACCEPT
```

Quellen:

- [NixOS NFS](https://nixos.wiki/wiki/NFS)
- [NFS iptables settings](https://www.cyberciti.biz/faq/centos-fedora-rhel-iptables-open-nfs-server-ports/)

### 4) Mounten von File-Systemen

Die User Home-Verzeichnisse auf allen anderen VMs werden nun von dem NFS gemountet, wobei wir jeweils den fileserver des Teams angeben, sowie den Pfad zum jeweiligen exporteten Verzeichnis. Auch setzen wir die automount option (nach 10 Minuten idle wird es wieder unmounted).

```nix
# user-config.nix
# wird für jeden User wiederholt
fileSystems."/home/ge65peq" = {
  device = "fileserver.psa-team<nr>.cit.tum.de:/<path/to/home>/<user>";
  fsType = "nfs";
  options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
};
```

*Achtung: nicht alle Fileserver sind erreichbar, weshalb wir einige der Verzeichnisse als Ersatz von unserem Server mounten.*

Auch das Datenbank-Verzeichnis wird von dem NFS gemountet. Die default-location ist `/var/lib/postgresql/17/`. Wir behalten diesen Pfad bei, mounten ab `postgresql` jedoch vom NFS:

```nix
# database.nix
# Mount database from NFS
fileSystems."/var/lib/postgresql" = {
  device = "192.168.3.8:/postgresql";
  fsType = "nfs";
  options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
};
```

Als letztes wird noch der Webserver Root vom NFS gemountet:

```nix
# nginx.nix
# Mount webserver root from NFS
fileSystems."/etc/nixos/sites" = {
  device = "192.168.3.8:/sites";
  fsType = "nfs";
  options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
};
```

### 5) Samba

Als letzten Schritt vor dem Testen richten wir noch wie gefordert **Samba-Filesharing** ein. Unter NixOS ist das wieder eine einfach Konfiguration, die wir der VM 8 hinzufügen können:

```nix
# samba.nix
services.samba = {
  enable = true;
  securityType = "user";
  openFirewall = true;
  settings = {
    global = {
      "workgroup" = "WORKGROUP";
      "server string" = "SambaFilesharingTeam03";
      "netbios name" = "SambaFilesharingTeam03";
      "security" = "user";
      "map to guest" = "never";                             # Kein Gastzugang
      "passdb backend" = "tdbsam";                          # Nutze Samba Authentication
      "log file" = "/var/log/samba/log.%m";                 # Log Datei
      "max log size" = "50";
      "hosts allow" = "192.168.0.0/16 127.0.0.1 localhost"; # Eingeschränkter Zugang
    };
    "homes" = {                                             # Samba Share für Home Directories
      "path" = "/export/home/%S";                           # %S = username
      "browseable" = "no";
      "read only" = "no";
      "valid users" = "%S";                                 # Nur Nutzer hat Zugang
      "create mask" = "0700";
      "directory mask" = "0700";
    };
  };
};
```

Damit die Nutzer als username-password Kombination zugreifen können, müssen wir diese noch hinzufügen. Das bedeutet für jeden Nutzer das Ausführen von:

```shell
sudo smbpasswd -a <username>
sudo smbpasswd -e <username>
```

Wir können das um Zeit zu sparen automatisieren. Hierfür iterieren wir über jeden Nutzer, setzen das Passwort auf ein zufällig generiertes, welches wir unter `/root/smb-passwords/` speichern, und aktivieren diesen Nutzer für Samba:

```shell
#!/usr/bin/env bash

# ausgeführt in /export/home
for user in *; do
    echo "Processing user $user"

    # Generate password & hash; Provide $PasswordHash
    echo "Generating password..."
    PWD_FILE="/root/smb-passwords/$user.password"
    Password=$(openssl rand -base64 16 | tr -d '/+=,' | cut -c1-16)
    echo "  Pwd:  $Password"
    touch "$PWD_FILE"
    echo "$Password" >> "$PWD_FILE"

    (echo "${Password}"; echo "${Password}") | smbpasswd -a -s "$user"
    smbpasswd -e "$user"
done
```

Auch hier passen wir nochmal explizit die Firewall an:

```shell
# vm-network-config.nix & router-network.nix
iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 137 -j ACCEPT
iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 138 -j ACCEPT
iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 139 -j ACCEPT
iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 445 -j ACCEPT
```

Nach einem `nixos-rebuid switch` steht nun auch Samba bereit.

Quellen:

- [NixOS Samba](https://nixos.wiki/wiki/Samba)
- [Samba iptables Einstellungen](https://www.cyberciti.biz/faq/configure-iptables-to-allow-deny-access-to-samba/)

### 6) Testen

- Das Testskript ist [`test_PSA_07.sh`](../scripts/test_PSA_07.sh).
- Das grundlegende Test-Setup bleibt identisch zu den vorherigen Wochen (siehe [Blatt03](./blatt02.md)).
- Das Skipt kann sowohl auf der Fileserver-VM, als auch auf jeder andern VM ausgeführt werden und ändert die zu laufenden Tests automatisch für die jeweilige VM.

Auf allen VMs können wir folgende Punkte testen:

1. Ist der NFS Port auf der Fileserver VM erreichbar?

   ```shell
   nc -z 192.168.3.8 2049
   ```

2. Können wir die Verzeichnisse auch wirklich mounten?
  
   ```shell
   mkdir "$TEST_DIR"
   mount -t nfs "192.168.3.8:$REMOTE_DIR" "$TEST_DIR"
   umount "$TEST_DIR"
   rm -r "$TEST_DIR"
   ```

3. Kann die Samba Verbindung genutzt werden?

   ```shell
   for user in "${users[@]}"; do
      mkdir "$TEST_DIR"
      mount -t cifs //192.168.3.8/${user} $TEST_DIR -o username=${user},password=$(cat ~/smb-passwords/$user.password)
        if [ $? -eq 0 ]; then
   ```

Zudem können wir zusätzliche Tests auf der Fileserver VM ausführen, wie:

1. Läuft der NFS Prozess?

   ```shell
   ps aux | grep nfsd
   ```

2. Läuft der Samba Prozess?

   ```shell
   ps aux | grep samba
   ```
