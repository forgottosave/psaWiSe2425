# Aufgabenblatt 02

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
  ```psa-team03.zone
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
```3.168.192.in-addr.arpa
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

5. Wir konfigurieren eine allgemeine Konfiguration für unsere Zonen.
   - `bind` bestimmt die Netzwerkkarte
   - `root` bestimmt den Ordner, wo die `.zone` Dateien vorzufinden sind.
   - #TODO maybe brauchen wir den Rest gar nicht mehr
```nixos
  (common) {
    bind enp0s8
    root ${zones}
    log
    errors
    nsid https://youtu.be/xvFZjo5PgG0
  }
  ```

6. **Default forwarding** (.) an die internen Nameserver, [chaos](https://coredns.io/plugins/chaos/) für Versions- & Autoren-Informationen
```nixos
  . {
    forward . 131.159.254.1 131.159.254.2
    chaos MayItFinallyWork Benni Timon
    import common
  }
  ```

7. Unsere Subnetze müssen eingerichtet werden und Transfers zu den "Nachbar-Teams" eingerichtet werden. Wir verwenden hierfür die eben errichteten jeweiligen `.zone` Dateien, sowie die oben definierte Konfiguration `common`.
```nixos
  psa-team03.cit.tum.de {
    file psa-team03.zone
    transfer {
      to 192.168.2.1
      to 192.168.32.2
      to 192.168.4.1
      to 192.168.43.4
    }
    import common
  }

  3.168.192.in-addr.arpa {
    file 3.168.192.zone
    transfer {
      to 192.168.2.1
      to 192.168.32.2
      to 192.168.4.1
      to 192.168.43.4
    }
    import common
  }
  ```
  
8. Zuletzt wird das Forwarding zu den anderen Teams (DNS-Servern) eingerichtet. Jedes Team bekommt hier eine weitere Zone mit forwarding an den jeweiligen Router. Unsere "Nachbar-Teams" werden als secondary Nameserver eingetragen.
```nixos
  psa-team01.cit.tum.de 1.168.192.in-addr.arpa {
    forward . 192.168.1.1
    import common
  }

  psa-team02.cit.tum.de 2.168.192.in-addr.arpa {
    secondary {
      transfer from 192.168.2.1
    }
    import common
  }

  psa-team04.cit.tum.de 4.168.192.in-addr.arpa {
    secondary {
      transfer from 192.168.4.1
    }
    import common
  }

  psa-team05.cit.tum.de 5.168.192.in-addr.arpa {
    forward . 192.168.5.1
    import common
  }

  psa-team06.cit.tum.de 6.168.192.in-addr.arpa {
    forward . 192.168.6.1
    import common
  }

  psa-team07.cit.tum.de 7.168.192.in-addr.arpa {
    forward . 192.168.7.1
    import common
  }

  psa-team08.cit.tum.de 8.168.192.in-addr.arpa {
    forward . 192.168.8.6
    import common
  }

  psa-team09.cit.tum.de 9.168.192.in-addr.arpa {
    forward . 192.168.9.1
    import common
  }

  psa-team10.cit.tum.de 10.168.192.in-addr.arpa {
    forward . 192.168.10.2
    import common
  }
  ```

Quellen:
- https://coredns.io/2017/07/24/quick-start/
- https://psa.in.tum.de/xwiki/bin/download/PSA%20WiSe%202024%20%202025/Pr%C3%A4sentation%20der%20Aufgaben/WebHome/DNS_DHCP.pdf?rev=1.1
### 2) DHCP Server

#TODO

### 3) Testing

#TODO
