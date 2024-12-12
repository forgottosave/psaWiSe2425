# Aufgabenblatt 06

In diesem Blatt geht es darum Webanwendung zu installieren und dabei eine Datenbank eines anderen Teams zu nutzen. Wir haben uns für die Smart Home Webanwendung Homeassistant entschieden welche auf unserer VM 5 (VM 5 `198.162.3.5`)  mit der Datenbank des Teams 04 läuft.

## Teilaufgaben

### 1) Installation und einrichten von Docker

#### 1.1) Konfiguaration von Nixos

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

Hiernach ist Docker fertig zur Verfügung und wir können das homeassistant image von dockerhub pullen dafür müssen wir aber zuvor noch in der Firewall vom der router-vm (VM 3) die IPs von `https://registry-1.docker.io` freigeben und können dabei auch gleich in der Firewall die Ports für homeassistant freigeben:

```nix
# router-network.nix 
...
firewall.extraCommands = ''
    ...
    iptables -A OUTPUT -d 54.227.20.253 -j ACCEPT
    iptables -A OUTPUT -d 54.236.113.205 -j ACCEPT
    iptables -A OUTPUT -d 54.198.86.24 -j ACCEPT

    # Allow: homeassistant
    iptables -A INPUT -p tcp --dport 8123 -j ACCEPT
    iptables -A OUTPUT -p tcp --sport 8123 -j ACCEPT
    ...
```

#### 1.2) Konfiguaration von Docker

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
      - /root/homeassistant_config:/config
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

#### 1.3) Konfiguaration von VirtualBox

Um homeassistant auch erreichen zu können müssen wir noch in VirtualBox eine Portweiterleitung einrichten:

```shell
VBoxManage modifyvm "vmpsateam03-05" --nat-pf1 "ssh,tcp,,60351,,8123"
```

Nun sollte Homeassistant unter `http://http://131.159.74.56:60351` erreichbar sein.

### 2) Einrichten von Homeassistant

#### 2.1) Konfiguaration der Datenbank

Nachdem wir Homeassistant erfolgreich installiert haben, können wir uns nun an die Konfiguration machen. Dafür müssen wir zunächst ein Admin-Konto erstellen und uns einloggen. Anschließend können wir die Datenbank des Teams 04 hinzufügen. Dafür müssen wir in der `configuration.yaml` folgende Zeilen hinzufügen:

```yaml
recorder:
  purge_keep_days: 30
  db_url: mysql://team3:DT7q2K1@192.168.4.5/databaseTeam3
```

([Quelle](https://kevinfronczak.com/blog/mysql-with-homeassistant))

#### 2.2) Konfiguaration der User

Zusätzlich müssen wir noch für alle Praktikums Teilnehmer:inen ein User Account erstellen:

settings -> People -> add Person -> <name> und "allow login" -> set passwd -> create

##### Passwörter

- admins:
  - ge78zig | 9E56XY
  - ge96xok | w8yN11Vr6Wjn
  - sysAdmin | 6gXFy11JdcSO
- normal users:
  - ge95vir | 8qM08hZWZXkG
  - ge43fim | 8qM08hZWZXkG
  - ge78nes | 8qM08hZWZXkG
  - ge96hoj | 8qM08hZWZXkG
  - ge87yen | 8qM08hZWZXkG
  - ge47sof | 8qM08hZWZXkG
  - ge47kut | 8qM08hZWZXkG
  - ge87liq | 8qM08hZWZXkG
  - ge59pib | 8qM08hZWZXkG
  - ge65peq | 8qM08hZWZXkG
  - ge63gut | 8qM08hZWZXkG
  - ge64baw | 8qM08hZWZXkG
  - ge84zoj | 8qM08hZWZXkG
  - ge94bob | 8qM08hZWZXkG
  - ge87huk | 8qM08hZWZXkG
  - ge64wug | 8qM08hZWZXkG
  - ge65hog | 8qM08hZWZXkG
  - ge38hoy | 8qM08hZWZXkG