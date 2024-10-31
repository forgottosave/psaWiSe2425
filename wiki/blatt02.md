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
Gewünschte Firewall–Regeln:
- TCP Verbindungen von außen zur VM:
    - es sollen die folgender Verbindungen erlaubt sein (stateless!)
        - Port 22 (Secure Shell)
        - Port 80 (http) 
        - Port 443 (https)
    - alle anderen Ports sollen nicht erreichbar sein
- TCP Verbindungen von der VM nach außen
    - erlaubte Adressen:
        - 131.159.0.0/16
        - alle Subnetze (192.168.3.0/24, 192.168.31.0/24, ...)
        - updateserver OS
        - gitrepo
- ICMP uneingeschränkt möglich


#TODO

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