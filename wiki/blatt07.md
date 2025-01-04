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
│          VM 08         │  │                                            
│       192.168.3.8      │  │                                            
│------------------------│  │                                            
│ /home                  ├──┤       ┌─────────────┐       ┌─────────────┐
│                        │  │       │local machine│       │    VM 08    │
└────────────────────────┘  │       │             │       │ 192.168.3.8 │
                            │ rsync │-------------│ rsync │-------------│
                            ├──────►│ /some/dir   ├──────►│   /export   │
                            │       │             │       │             │
┌────────────────────────┐  │       │             │       │             │
│          VM 04         │  │       └─────────────┘       └─────────────┘
│       192.168.3.4      │  │                                            
│------------------------│  │                                            
│ /home                  ├──┤                                            
│ /var/lib/postgresql/17 ├──┘                                            
│                        │                                               
└────────────────────────┘                                                
```

1. "Mergen" aller Daten auf den lokalen Rechner
  Mit einem einfachen Script können wir uns alle Homeverzeichnisse der VMs holen. Hierbei gehen wir einfach alle Ports von 60301 - 60308 durch, um alle VMs abzudecken.
  
  ```shell
  for i in {1..8}; do
    printf "\n|| Synchronizing VM 0${i}...\n\n"
    rsync -avz -e "ssh -p 6030${i}" --progress root@psa.in.tum.de:/home .
  done
  ```
  
  Lediglich das Datenbank-Verzeichnis von **VM 4** fehlt noch:
  
  ```shell
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

Für die Datenbank-Nutzer müssen wir zunächst die entsprechenden Nutzer anlegen, da diese auf **VM 8** nicht existieren:

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

### 3) Dienste (NFS, SMB/CIFS)

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
  '';
};
```

und in der Firewall enablen:

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

### 5) Testen

Das grundlegende Test-Setup bleibt identisch zu den vorherigen Wochen (siehe Blatt03).
Das Skipt kann sowohl auf der Host-VM, als auch auf jeder andern VM mit Verbingung zur Host-VM ausgeführt werden und ändert die zu laufenden Tests automatisch für die jeweilige VM.

#TODO
