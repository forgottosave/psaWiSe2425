# Aufgabenblatt 03

In diesem Blatt geht es darum DNS & DHCP einzurichten. Wir lassen beide services auf unserer Router-VM (VM 3, `198.162.3.3`) laufen.

## Teilaufgaben

### 1) DNS Server

**Gescheiterte Versuche:**
Wir haben lange Zeit versucht **bind** auf NixOS zum laufen zu bekommen. Ähnlich wie für viele Dinge ist hier der support leider sehr bedingt und der Großteil muss in `extraOptions`, oder `extraConfig` gelöst werden (manuelle Eintragungen in die config Dateien).
Nachdem alle Konfigurationen implementiert waren, lief leider das *forwarding* an andere Teams und das *default-forwarding* nicht. Anfragen mit `psa-team03.cit.tum.de` liefen einwandfrei. Nach sehr langem try-and-error mussten wir **bind** leider aufgeben und haben uns, inspiriert durch Team 06, **CoreDNS** zugewandt.

**CoreDNS:**
Der support für **CoreDNS** ist in NixOS ähnlich wie für **bind**, aber die Umsetzung lief, im Gegensatz dazu, einwandfrei:

1. Einrichten der Zone `psa-team03.cit.tum.de` in der Datei `psa-team03.zone`:
   Wir brauchen Einträge für unseren Nameserver (standardmäßig *ns1*), sowie unsere beiden VMs (*vm1* & *vm2*). Auch unsere "Nachbar-Teams" (*team02*, *team04*) bekommen Einträge.

    ```shell
    #psa-team03.zone
    $TTL    1h
    @       IN      SOA     ns1 admin (
                        24111901    ; Serial
                        3h   ; Refresh
                        1h   ; Retry
                        1w   ; Expire
                        1h)  ; Negative Cache TTL

    @       NS      ns1
    @       NS      ns1.psa-team02.cit.tum.de
    @       NS      ns1.psa-team04.cit.tum.de
    ns1     A       192.168.3.3

    vm1     A       192.168.3.1
    vm2     A       192.168.3.2
    ```

2. Einrichten der Reverse-Zone `3.168.192.in-addr.arpa` in der Datei `3.168.192.zone`:
   Wie eben brauchen wir Einträge für den Nameserver, vm1, vm2 und die "Nachbar-Teams".

    ```shell
    #3.168.192.in-addr.arpa
    $TTL    1h
    @            IN      SOA     psa-team03.cit.tum.de. admin.psa-team03.cit.tum.de. (
                                    24111901    ; Serial
                                    3h   ; Refresh
                                    1h   ; Retry
                                    1w   ; Expire
                                    1h)  ; Negative Cache TTL
    @       NS        ns1.psa-team03.cit.tum.de.
    @       NS        ns1.psa-team02.cit.tum.de.
    @       NS        ns1.psa-team04.cit.tum.de.

    3       PTR       ns1.psa-team03.cit.tum.de.
    1       PTR       vm1.psa-team03.cit.tum.de.
    2       PTR       vm2.psa-team03.cit.tum.de.
    ```

3. Beide Zone-Dateien müssen beim git-Synchronisieren an die richtige Stelle kopiert werden: `cp -a ${THIS_DIR}/../nixos-configs/bind-configs/. /etc/nixos/dns/` zu `sync-nixos-config.sh` hinzufügen.

4. Als nächstes wird die **DNS-config** in `dns-config.nix`, welche auch zu den imports für VM 3 in `vm-3.sh` hinzugefügt, erstellt:

5. Dafür aktivieren wir CoreDNS in einer neuen NixOS config (`dns-config.nix`) und konfigurieren es in den nächsten Schritten:

    ```nixos
    { ... }:
    {
      services.coredns = {
        enable = true;
        config = ''
          ...
        '';
      }
    }
    ```

6. Wir konfigurieren eine allgemeine Konfiguration (`default`) für unsere Zonen.
   - `bind` bestimmt die Netzwerkkarte
   - `root` bestimmt den Ordner, wo die `.zone` Dateien vorzufinden sind.
   - `log` activates logging

    ```nixos
    (default) {
      bind enp0s8
      root /etc/nixos/dns
      log
    }
    ```

7. **Default forwarding** (.) an die internen Nameserver, [chaos](https://coredns.io/plugins/chaos/) für Versions- & Autoren-Informationen

    ```nixos
    . {
      forward . 131.159.254.1 131.159.254.2
      chaos MayItFinallyWork Benni Timon
      import default
    }
    ```

8. Unsere Subnetze müssen eingerichtet werden und Transfers zu den "Nachbar-Teams" eingerichtet werden. Wir verwenden hierfür die eben errichteten jeweiligen `.zone` Dateien, sowie die oben definierte Konfiguration `default`.

    ```nixos
    psa-team03.cit.tum.de {
      file psa-team03.zone
      transfer {
        to 192.168.2.1
        to 192.168.32.2
        to 192.168.4.1
        to 192.168.43.4
      }
      import default
    }

    3.168.192.in-addr.arpa {
      file 3.168.192.zone
      transfer {
        to 192.168.2.1
        to 192.168.32.2
        to 192.168.4.1
        to 192.168.43.4
      }
      import default
    }
    ```
  
9. Zuletzt wird das Forwarding zu den anderen Teams (DNS-Servern) eingerichtet. Jedes Team bekommt hier eine weitere Zone mit forwarding an den jeweiligen Router. Unsere "Nachbar-Teams" werden als secondary Nameserver eingetragen.

    ```nixos
    psa-team01.cit.tum.de 1.168.192.in-addr.arpa {
      forward . 192.168.1.1
      import default
    }

    psa-team02.cit.tum.de 2.168.192.in-addr.arpa {
      secondary {
        transfer from 192.168.2.1
      }
      import default
    }

    psa-team04.cit.tum.de 4.168.192.in-addr.arpa {
      secondary {
        transfer from 192.168.4.1
      }
      import default
    }

    psa-team05.cit.tum.de 5.168.192.in-addr.arpa {
      forward . 192.168.5.1
      import default
    }

    psa-team06.cit.tum.de 6.168.192.in-addr.arpa {
      forward . 192.168.6.1
      import default
    }

    psa-team07.cit.tum.de 7.168.192.in-addr.arpa {
      forward . 192.168.7.1
      import default
    }

    psa-team08.cit.tum.de 8.168.192.in-addr.arpa {
      forward . 192.168.8.6
      import default
    }

    psa-team09.cit.tum.de 9.168.192.in-addr.arpa {
      forward . 192.168.9.1
      import default
    }

    psa-team10.cit.tum.de 10.168.192.in-addr.arpa {
      forward . 192.168.10.2
      import default
    }
    ```

10. Jetzt fehlt nur noch eine Freigabe in den Firewalls und unser DNS ist einsatz bereit

    ```nixos
    # router-network.nix
    # Allow: DNS
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
    iptables -A INPUT -p udp --dport 53 -j ACCEPT 
    iptables -A INPUT -p tcp --dport 53 -j ACCEPT
    ```

    ```nixos
    # vm-network-config.nix
    # Allow: DNS
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
    iptables -A INPUT -p udp --dport 53 -j ACCEPT 
    iptables -A INPUT -p tcp --dport 53 -j ACCEPT
    ```

Quellen:
- [coredns](https://coredns.io/2017/07/24/quick-start/)
- [psa wiki](https://psa.in.tum.de/xwiki/bin/download/PSA%20WiSe%202024%20%202025/Pr%C3%A4sentation%20der%20Aufgaben/WebHome/DNS_DHCP.pdf?rev=1.1)

### 2) DHCP Server

Um DHCP in NixOS zu ermöglichen lässt sich wieder eine simple nix-Config schreiben:

```nix
{ inputs, ... }:
let 
  overlay-kea-unstable = final: prev: {
    kea = inputs.unstable.legacyPackages."x86_64-linux".kea;
  };
in
{
  imports = [
    { nixpkgs.overlays = [ overlay-kea-unstable ]; }
  ];

  services.kea.dhcp4 = {
    enable = true;
    configFile = ./dhcp4-config.json;
  };
}
```

Nach dem importieren von kea (notwendig für dhcp4) und dem Aktivieren von DHCP müssen wir nurnoch die Konfiguration in `./dhcp4-config.json` bereitstellen. Viele der Konfigurationen sind selbsterklärend, oder default Empfehlungen, der Rest folgt in Kommentaren (`#`) in der folgenden Konfig:

```json
{
    "Dhcp4": {
        # DHCP Gültigkeit
        "valid-lifetime": 300,
        "renew-timer": 150,
        "rebind-timer": 240,

        "lease-database": {
            "type": "memfile",
            "persist": true,
            "name": "/var/lib/kea/dhcp4.leases",
            "lfc-interval": 1800
        },
        # Identifiziere Hosts anhand dessend Hardware Addresse
        "host-reservation-identifiers": [ "hw-address" ],

        "authoritative": false,

        # es wird nur auf Anfragen geantwortet, die aus dem Team-Netzwerk sind
        "interfaces-config": {
            "interfaces": ["enp0s8/192.168.3.3"],
            "dhcp-socket-type": "raw"
        },

        "control-socket": {
            "socket-type": "unix",
            "socket-name": "/run/kea/kea-dhcp4.socket"
        },

        # Unsere Subnet Konfiguration
        "subnet4": [
            {
                "id": 1,
                # In unserem Netzwerk
                "subnet": "192.168.3.0/24",
                "pools": [],
                "reservations-out-of-pool": true,
                # Trage hier reservierte Addressen ein
                "reservations" : [
                    # Hier nur ein Beispiel -> genauso für weitere VMs
                    # Vergabe von IP-Adressen und Hostnamen anhand der Hardware-Adresse
                    {
                        "hw-address": "08:00:27:4c:bb:84",
                        "ip-address": "192.168.3.1",
                        "hostname": "vm1"
                    },
                    ...
                ]
            }
        ],

        # custom option da per default option für wpad-proxy-url nicht existiert
        "option-def": [
            {
                "code": 252,
                "name": "wpad-proxy-url",
                "type": "string"
            }
        ],

        # übergabe von infos wie default gateway, nameserver, static routes, ...
        "option-data" : [
            {
                "name": "routers",
                "data": "192.168.3.3",
                "always-send": true
            },
            {
                "name": "domain-name-servers",
                "data": "192.168.3.3",
                "always-send": true
            },
            {
                "name": "domain-name",
                "data": "psa-team03.cit.tum.de.",
                "always-send": true
            },
            {
                "code": 121,
                "name": "classless-static-route",
                "data": "192.168.0.0/16 - 192.168.3.3",
                "always-send": true
            },
            {
                "name": "wpad-proxy-url",
                "data": "http://pac.lrz.de",
                "always-send": true
            }
        ],

        # Erstelle ein Log für Fehlerbehandlung
        "loggers": [
            {
                "name": "kea-dhcp4",
                "output-options": [
                    {
                        "output": "/home/kea.log"
                    }
                ],
                "severity": "DEBUG"
            }
        ]

    }
}
```

DHCP ist nun soweit konfiguriert, nun fehlt nur noch die Freigabe der Ports in der Firewall:

```nix
# router-network.nix
      # Allow: DHCP
      iptables -A INPUT -p udp --sport 68 --dport 67 -j ACCEPT
      iptables -A OUTPUT -p udp --sport 67 --dport 68 -j ACCEPT
```

als auch bei den client VMs:

```nix
# vm-network-config.nix
      # Allow: DHCP
      iptables -A INPUT -p udp --sport 68 --dport 67 -j ACCEPT
```

Nun fehlt nur noch ein switch rebuild und wir sind fertig :D

### 3) Testing

Das grundlegende Test-Setup bleibt identisch zu letzter Woche (siehe Blatt03).

1. Um DNS zu testen, nutzen wir `host -a` und `nslookup`.

2. Um DHCP zu testen, wird geschaut ob kea läuft und der inhalt von `/var/lib/kea/dhcp4.leases` überprüft.
