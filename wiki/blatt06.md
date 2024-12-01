# Aufgabenblatt 06

In diesem Blatt geht es darum Webanwendung zu installieren und dabei eine Datenbank eines anderen Teams zu nutzen. Wir haben uns für die Smart Home Webanwendung Homeassistant entschieden welche auf unserer VM 5 (VM 5 `198.162.3.5`)  mit der Datenbank des Teams 04 läuft.

## Teilaufgaben

### 1) Installation und einrichten von Docker

Hierfür haben wir uns zunächst eine neue VM erstellt mit den empfohlenen Ressourcen (2 CPUs, 2GB RAM, 32GB Speicher). Wir haben uns gegen HomeassistantOS entschieden und lassen stattdesen Homeassistant in einem Docker Container auf Nixos laufen. Dadurch stehen in Homeassistant zwar leider keine Addons zur Verfügung, aber können wir weiterhin Nixos nutzen ;D
Dafür haben wir zunächst das `docker-compose` pkg zur `configuration.nix` hinzugefügt und dann eine neue nixos-config `homeassistant-config.nix` erstellt und in der `configuration.nix` importiert.

```shell
# homeassistant-config.nix
{ config, lib, pkgs, ... }:
{
    virtualisation.docker.enable = true;
    users.extraGroups.docker.members = [ "root" ];
}
```

Hiernach ist Docker fertig konfiguriert und wir können das homeassistant image von dockerhub pullen dafür müssen wir aber zuvor noch in der Firewall vom der router-vm (VM 3) die IPs von `https://registry-1.docker.io` freigeben:

```nix
# router-network.nix 
...
firewall.extraCommands = ''
    ...
    iptables -A OUTPUT -d 54.227.20.253 -j ACCEPT
    iptables -A OUTPUT -d 54.236.113.205 -j ACCEPT
    iptables -A OUTPUT -d 54.198.86.24 -j ACCEPT
    ...
```

Nun können wir das homeassistant image pullen:

```shell
docker pull homeassistant/home-assistant
```

Und ein config file für den docker container erstellen:

```yml
# compose.yml
services:
  homeassistant:
    container_name: homeassistant
    image: "ghcr.io/home-assistant/home-assistant:stable"
    volumes:
      - /home/root/homeassistant_config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
```

Hierbei ist zu beachten das wir vorm starten des containers noch das Verzeichnis `/home/root/homeassistant_config` erstellen müssen.
Darauf kann der Container gestartet werden:

```shell
docker compose up -d
```

### 2) Einrichten von Homeassistant
