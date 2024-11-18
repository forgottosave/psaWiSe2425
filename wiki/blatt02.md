# Aufgabenblatt 02
In diesem Blatt geht es darum die Netzwerkkonfiguration zu erstellen und die VMs untereinander zu verbinden, als auch eine Firewall zu konfigurieren um die VMs zu schützen.

## Teilaufgaben:

### 1) Verbindung innerhalb des teams:
- zunächst muss der nicht konfigurierter Netzwerkadapter ermittelt werde, hierfür einfach `ifconfig` ausführen und den Adapter auswählen der nicht die IP `10.0.2.15` hat <br>-> `enp0s8`
- nun soll den VMs eine static IP nach dem Schema `192.168.<TeamNummer>.0/24` vergeben werden <br>->  `192.168.3.1/24` bzw `192.168.3.2/24`
- um dies umzusetzen muss die `configuration.nix` um folgenden Eintrag ergänzt werden:
    ```nixos
    networking = {
      interfaces.enp0s8 = {
        ipv4.addresses = [
          { address = "192.168.3.1"; prefixLength = 24; }
        ];
      };
    };
    ```
- IPs können für Testzwecke zunächst auch non persistant vergeben werden:
    ```shell
    sudo ip addr add 192.168.3.2/24 dev enp0s8
    sudo ip link set enp0s8 up
    ```

### 2) Verbindung zwischen den Teams
- für diese Teilaufgabe haben wir uns etnschieden einen Router VM zu erstellen, der die Verbindung zwischen den Teams herstellt (VM03)
- Worauf wir uns in Matrix geeinig haben:
    - mesh netzwerk (jeder mit jeden verbunden)
    - in TeamzuTeam Netzwerken hat die Router VM stets die ip:`192.168.<teamNr1><teamNr2>.<teamNr>` wobei teamNr1 > teamNr2
- dafür muss man den `enp0s8`-Adapter einer zusätzlichen, IP–Adresse aus dem Verbindungs–Subnetz vergeben
- das dadürch entstehende Netzwerk sieht wie folgt aus:
    ```shell       
                                           ┌───────────────┐
                                           │               │
                                           │      VM1      │
                ┌───────────────┐      ┌─► │  192.168.3.1  │
                │               │      │   │               │
                │     Router    │ ◄────┘   └───────────────┘
                │  192.168.3.3  │                           
                │  192.168.31.3 │ ◄────┐   ┌───────────────┐
                │      ...      │      │   │               │
                └───────────────┘      └─► │      VM2      │
                      ▲   ▲                │  192.168.3.2  │
            ┌─────────┘   └─────────┐      │               │
            │                       │      └───────────────┘
            ▼                       ▼                       
    ┌───────────────────┐   ┌───────────────────┐             
    │                   │   │                   │             
    │  Router VM Team1  │   │  Router VM TeamX  │             
    │   192.168.31.1    │   │       ...         │             
    │                   │   │                   │             
    └───────────────────┘   └───────────────────┘             
    ```

- um diese Änderungen um zu setzen muss bei der Router VM folgende Änderungen in der `configuration.nix` vorgenommen werden:
    ```nixos
    networking = {
    interfaces.enp0s8 = {
      ipv4.addresses = [
        { address = "192.168.3.3"; prefixLength = 24; }
        { address = "192.168.31.3"; prefixLength = 24; }
        { address = "192.168.32.3"; prefixLength = 24; }
        ...
      ];
      ipv4.routes = [
        { address = "192.168.1.0"; prefixLength = 24; via = "192.168.31.1"; } 
        { address = "192.168.2.0"; prefixLength = 24; via = "192.168.32.2"; }
        ...
      ];
    };
    ```

- und bei den anderen VMs z.B. bei VM1:
    ```nixos
    networking = {
    interfaces.enp0s8 = {
      ipv4.addresses = [
        { address = "192.168.3.1"; prefixLength = 24; }
      ];
      ipv4.routes = [
        { address = "192.168.0.0"; prefixLength = 16; via = "192.168.3.3"; }
      ];
    };
    ```

- auch hier gilt wieder dass die IPs und Routes für Testzwecke zunächst auch non persistant vergeben werden können:
    ```shell
    sudo ip addr add 192.168.31.3/24 dev enp0s8 
    sudo ip route add 192.168.1.0/24 via 192.168.31.1 dev enp0s8
    ```

### 3) Http(s) Proxy
- da das normale surfen im Netz nur über einen Proxy–Server möglich sein soll muss noch der `proxy.cit.tum.de` für alle VMs als systemweiten Proxy–Server gesetzt werden
    ```nixos
    networking.proxy.httpsProxy = "http://proxy.cit.tum.de:8080/";
    networking.proxy.httpProxy = "http://proxy.cit.tum.de:8080/";
    ```


### 4) Firewall
Die gewünschte Firewall–Regeln können unter NixOS als `firewall.extraCommands = ...` konfiguriert werden und die folgenden Einstellungen sind für alle VMs dieselben:

**nicht erlaubt seien soll**:
- "nichts" soll per default erlaubt sein also alle packets gedroppen:
  ```shell
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT DROP
  ```
- für alle http(s) Verbindungen soll "connection tracking" deaktiviert sein:
  ```shell
  iptables -t raw -A PREROUTING -p tcp --dport 80 -j NOTRACK  
  iptables -t raw -A OUTPUT -p tcp --sport 80 -j NOTRACK
  iptables -t raw -A PREROUTING -p tcp --dport 443 -j NOTRACK 
  iptables -t raw -A OUTPUT -p tcp --sport 443 -j NOTRACK
  ```
<br>

**erlaubt seien soll**:
- loopback Verbindungen:
  ```shell
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  ```
- bereits bestehende Verbindungen:
  ```shell
  iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT    
  iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  ```
- SSH Verbindungen:
  ```shell
	iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
  ```
- DNS requests und responses:
  ```shell
	iptables -A INPUT -p tcp --dport 80 -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT
	iptables -A INPUT -p tcp --dport 443 -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT
  ```
- git Verbindungen bzw. sodass alle nötigen [git-Befehle funktionieren](https://serverfault.com/questions/682373/setting-up-iptables-filter-to-allow-git):
  ```shell 
  iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
  iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
  iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
  ```
- eingehende HTTP(S) Verbindungen und responses:
  ```shell
  iptables -A INPUT -p tcp --dport 80 -j ACCEPT
  iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT
  iptables -A INPUT -p tcp --dport 443 -j ACCEPT
  iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT
  ```
- ICMP requests und responses:
  ```shell
  iptables -A INPUT -p icmp -j ACCEPT
  iptables -A OUTPUT -p icmp -j ACCEPT
  ```
- und nur bestimmte Verbindungen nach außen:
  ```shell
  # gitlab
  iptables -A OUTPUT -d 131.159.0.0/16 -j ACCEPT
  # nixos updater
  iptables -A OUTPUT -d 151.101.2.217 -j ACCEPT  
  iptables -A OUTPUT -d 151.101.130.217 -j ACCEPT
  iptables -A OUTPUT -d 151.101.66.217 -j ACCEPT
  iptables -A OUTPUT -d 151.101.194.217 -j ACCEPT
  # praktikum
  iptables -A OUTPUT -d 192.168.1.0/24 -j ACCEPT
  iptables -A OUTPUT -d 192.168.2.0/24 -j ACCEPT 
  iptables -A OUTPUT -d 192.168.3.0/24 -j ACCEPT
  iptables -A OUTPUT -d 192.168.4.0/24 -j ACCEPT
  iptables -A OUTPUT -d 192.168.5.0/24 -j ACCEPT
  iptables -A OUTPUT -d 192.168.6.0/24 -j ACCEPT
  iptables -A OUTPUT -d 192.168.7.0/24 -j ACCEPT
  iptables -A OUTPUT -d 192.168.8.0/24 -j ACCEPT
  iptables -A OUTPUT -d 192.168.9.0/24 -j ACCEPT
  iptables -A OUTPUT -d 192.168.10.0/24 -j ACCEPT
  ```

<hr>

für die Router VM muss zusätzlich noch folgendes hinzugefügt werden damit Forwarding erlaubt ist:
```shell
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.1.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.31.0/24 -d 192.168.3.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.2.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.32.0/24 -d 192.168.3.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.4.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.43.0/24 -d 192.168.3.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.5.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.53.0/24 -d 192.168.3.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.6.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.63.0/24 -d 192.168.3.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.7.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.73.0/24 -d 192.168.3.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.8.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.83.0/24 -d 192.168.3.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.9.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.93.0/24 -d 192.168.3.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.10.0/24 -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.103.0/24 -d 192.168.3.0/24 -j ACCEPT
```


### 5) Testing
Für das Testen der Netzwerk Verbindungen & Firewall soll (wie es die Aufgabe verlangt) ein bash script names `test_PSA_02.sh` in `/root` abgelegt werden.
Das Script behandelt die folgenden Test-Fälle, welche jeweils mit einem `SUCCESS`, oder `FAILED` enden:
1. **Verbindung zu anderen Teams**
   - `ping -c 1 <ip>` an alle anderen Team VMs (1 & 2)
2. **Surfen (über Proxy)**
   - `curl -o - -I <adresse>` an google.com (`http` & `https`)
   - prüfe ob Status `200` ausgegeben wird
3. **Erreichbarkeit von FMI**
   - `ping -c 1 131.159.0.1`
4. **ssh Verbindung zu Team-internen VMs möglich**
   - `nmap -p 22 192.168.3.x` an VMs 1-3

# Zusatz: automatische NixOS configuration sync
Wir haben diese Woche zudem die synchronisierte Aktualisierung der config Dateien über ein git repository ermöglicht. Das Repository ist [hier](https://github.com/forgottosave/psaWiSe2425) zu finden.
### sync-nixos-config.sh
Die Ausführung von [`scripts/sync-nixos-config.sh`](https://github.com/forgottosave/psaWiSe2425/blob/main/scripts/sync-nixos-config.sh) in NixOS übernimmt...
1. ...(optional) `git pull` zum Synchronisieren des Repos
2. ...das Kopieren der `.nix` Dateien an den richtigen Ort (`/etc/nixos/`).
3. ...das VM spezifische Konfigurieren der `.nix` Dateien (Einsetzen der richtigen root-ssh-keys, IP-Adressen, ...). Die VM spezifischen Konfigurationen können in `scripts/vm-configs/` gefunden werden. Das Erkennen, um welche VM es sich handelt, wird automatisch über den hostname versucht, kann aber auch manuell dem Skript übergeben werden.
4. ...`nixos-rebuild switch`.
### Einrichten
Auf einer fertigen NixOS Installation (siehe Blatt 1) muss zuerst der **Zugriff auf das GitHub Repository** ermöglicht werden:
1. Hinzufügen von `git` in `configurations.nix`:
```
   environment.systemPackages = with pkgs; [
     # default suggestions: vim wget
     [...]
     git
   ];
```
2. `nixos-rebuild switch` & `reboot`
3. Hinzufügen eines ssh-keys mit `ssh-keygen`
4. `cat ~/.ssh/<keyfile>.pub` in die GitHub Deployment-Keys für das Repository hinzufügen
![image](https://github.com/user-attachments/assets/384daea2-e412-4c3b-9352-6dd11002c83c)

5. `git clone git@github.com:forgottosave/psaWiSe2425.git`
### Benutzung
Nun stehen die Voraussetzungen für das Benutzen. Um die Konfigurationen mit dem git-repo zu **synchronisieren** und umzusetzen:
1. `cd psaWiSe2425`
2. `./scripts/sync-nixos-config.sh -p` führt die open beschriebenen Schritte aus
3. je nach Änderungen in der config: `reboot`

Das Skript stellt auch Hilfe unter `-h` / `--help` bereit:
```
PSA Team 03 - OS sync script performs...
...copy configs to /etc/nixos/
...replace placeholders
...nixos-rebuild switch

Usage:
./scripts/sync-nixos-config.sh [OPTIONS]

Options:          Description:
-h, --help        Display help page.
-n, --vm          Specify VM (automatically set from hostname if not provided).
-p, --pull        Pull latest changes from git repository before config changes.
-x, --no-rebuild  Don't perform nixos-rebuild switch after config changes.
```

Änderungen sollen jetzt nicht mehr direkt im `/etc/nixos/...` vorgenommen werden, sondern nur in den Dateien im git-Repository, unter `<path-to-repo>/nixos-configs`.
