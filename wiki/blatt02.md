# Aufgabenblatt 02
In diesem Blatt geht es darum die Netzwerkkonfiguration zu erstellen und die VMs untereinander zu verbinden, als auch eine Firewall zu konfigurieren um die VMs zu schützen.

## Teilaufgaben:

### 1) Verbindung innerhalb des teams:
- zunächst muss der nicht konfigurierter Netzwerkadapter ermittelt werde, hierfür einfach `ifconfig` ausführen und den Adapter auswählen der nicht die IP `10.0.2.15` hat <br>-> `enp0s8`
- nun soll den VMs eine static IP nach dem Schema `192.168.<TeamNummer>.0/24` vergeben werden <br>->  `192.168.3.1/24` bzw `192.168.3.2/24`
- um dies umzusetzen muss die `configuration.nix` um folgenden Eintrag ergänzt werden:
    ```shell
    networking = {
      interfaces.enp0s8 = {
        ipv4.addresses = [
          { address = "192.168.3.1"; prefixLength = 24; }
        ];
      };
    };
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
    ```shell
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

- und bei den anderen VMs:
    ```shell
    networking = {
    interfaces.enp0s8 = {
      ipv4.addresses = [
        { address = "192.168.3.%%vm%%"; prefixLength = 24; }
      ];
      ipv4.routes = [
        { address = "192.168.1.0"; prefixLength = 24; via = "192.168.31.3"; }
        { address = "192.168.2.0"; prefixLength = 24; via = "192.168.32.3"; }
        ...
      ];
    };
    ```


### 3) Http(s) Proxy
- da das normale surfen im Netz nur über einen Proxy–Server möglich sein soll muss noch der `proxy.cit.tum.de` für alle VMs als systemweiten Proxy–Server gesetzt werden
    ```
    networking.proxy.httpsProxy = "http://proxy.cit.tum.de:8080/";
    networking.proxy.httpProxy = "http://proxy.cit.tum.de:8080/";
    ```


### 4) Firewall
Die gewünschte Firewall–Regeln können unter NixOS als `firewall.extraCommands = ...` konfiguriert werden:
#TODO -> ping von anderen auf unsere VM 1 & 2 funktioniert noch nicht!!!

- **per default** soll "nichts" erlaubt sein:
  ```
	iptables -P INPUT DROP
	iptables -P FORWARD DROP
	iptables -P OUTPUT DROP
	```

- **TCP Verbindungen** zur VM (stateless!) sollen nur auf folgenden Ports möglich sein:
    - Port 22 (Secure Shell & Git)
    - Port 80 (http) 
    - Port 443 (https)
```
	# Allow: SSH
	iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
	# Allow: git (https://serverfault.com/questions/682373/setting-up-iptables-filter-to-allow-git)
	iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	# Allow: incoming HTTP, HTTPS, and responses to the requests
	iptables -A INPUT -p tcp --dport 80 -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT
	iptables -A INPUT -p tcp --dport 443 -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT
```

- **Erlaubte Adressen** von der VM nach außen:
    - Gitlab ( #TODO wieso?)
    - alle Team-Subnetze (192.168.3.0/24, 192.168.31.0/24, ...)
    - NixOS-Update-Server
```
	# Gitlab
	iptables -A OUTPUT -d 131.159.0.0/16 -j ACCEPT
	# NixOS (context switch)
	iptables -A OUTPUT -d 151.101.2.217 -j ACCEPT
	iptables -A OUTPUT -d 151.101.130.217 -j ACCEPT
	iptables -A OUTPUT -d 151.101.66.217 -j ACCEPT
	iptables -A OUTPUT -d 151.101.194.217 -j ACCEPT
	# andere Teams
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

- **ICMP** uneingeschränkt möglich
```
	# Allow: ICMP
	iptables -A INPUT -p icmp -j ACCEPT
	iptables -A OUTPUT -p icmp -j ACCEPT  
```

- **Router**: zudem braucht der Router Konfigurationen für das Forwarding zwischen unseren Team-Subnetzen:
```
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.31.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.31.0/24 -d 192.168.3.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.32.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.32.0/24 -d 192.168.3.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.43.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.43.0/24 -d 192.168.3.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.53.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.53.0/24 -d 192.168.3.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.63.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.63.0/24 -d 192.168.3.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.73.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.73.0/24 -d 192.168.3.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.83.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.83.0/24 -d 192.168.3.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.93.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.93.0/24 -d 192.168.3.0/24 -j ACCEPT
	iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.103.0/24 -j ACCEPT
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
3. **Stichproben Check, ob andere Ports wirklich "verboten" sind**
   - #TODO
4. #TODO mehr Tests?

## Zusatz:
Wir haben diese Woche zudem die synchronisierte Aktualisierung der config Dateien über ein git repository ermöglicht. Die Ausführung von [`scripts/sync-nixos-config.sh`](https://github.com/forgottosave/psaWiSe2425/blob/main/scripts/sync-nixos-config.sh) übernimmt...
1. ...das Kopieren der `.nix` Dateien an den richtigen Ort (`/etc/nixos/`).
2. ...das VM spezifische konfigurieren der `.nix` Dateien (Einsetzen der richtigen root-ssh-keys, IP-Adressen, ...). Die VM spezifischen Konfigurationen können in `scripts/vm-configs/` gefunden werden.
3. ...`nixos-rebuild switch`.

Details zur Benutzung können zudem in der repository [README](../README.md) gefunden werden.