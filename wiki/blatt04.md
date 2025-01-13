# Aufgabenblatt 04

Aufgaben:

1. erstellen eines Webservers mittels nginx über das Interface `enp0s8`
2. erstellen eines selbst signierten Zertifikats für ssl
3. Webseiten erstellen:
    website1:
    - erreichbar über psa-team03.cit.tum.de (sowohl http als auch https über 443)
    - dazu individuellen homepages für alle nutzer erreichbar über psa-team03.cit.tum.de/~<login>  
        - statische homepages sollen in $HOME/.html-data/ liegen
        - dynamische homepages sollen in $HOME/.cgi-bin/ liegen (erreichbar über psa-team03.cit.tum.de/~<login>/cgi-bin/)
        - bei erzeugung dyn Inhalte sollen diese Prozesse unter der Kennung des jeweiligen Nutzers laufen

    website2:
    - erstellen eines alternativen CNAME für die VM
    - unabhängige webseite auf http(s)://cname/ bereitstellen

    website3:
    - zusätzliche ip für das Interface enp0s8
    - DNS Server um einen Namen für diese Adresse in Form eines A-Records ergänzen
    - unabhängige website auf dieser IP bereitstellen

4. logfiles:
    - Log-funktion so konfigurieren das IP-Adressen im Zugriffs-Log nicht/teilweise protokoliert werden
    - im Fehler-Log sollen hingegen die IP-Adressen vollständig protokolliert werden
    - tägliche rotation der Logfiles
        - zugriffslog nach 5 tagen löschen
        - fehlerlog nach 1 tagen löschen

5. test skript


## Teilaufgaben

### 1) nginx Webserver aktivieren

Da nixos nativen support für nginx hat, kann dieser einfach über die Konfiguration aktiviert werden. Hierfür haben wir wieder eine neue `nginx.nix` datei angelegt in welcher im Folgenden der nginx server konfiguriert wird:

```nix
# ngin.nix
{ config, lib, pkgs, ... }:
{
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    virtualHosts = {
      ...
    };
  };
}
```

### 2) Zertifikat erstellen

Um auch `https` für die folgenden Webseiten bereitszustellen benötigen wir zunächst noch ein ein selbst signiertes Zertifikat. Dieses wird in den Ordner `/etc/ssl/nginx` abgelegt. Hierfür daktivieren wir zunächst die Firewall und erstellen dann das Zertifikat:

Firewall deaktivieren:

```shell
firewall deaktivieren

```shell
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
```

Zertifikat erstellen und die Zugangsrechte anpassen:

```shell
sudo mkdir -p /etc/ssl/nginx

sudo nix run nixpkgs#openssl -- req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/nginx/nginx.key -out /etc/ssl/nginx/nginx.crt -subj "/C=DE/ST=Bayern/L=München/O=UwU Corp./CN=*.psa-team03.cit.tum.de"

sudo chown root:nginx /etc/ssl/nginx/nginx.* # owner is root, group is nginx
sudo chmod 644 /etc/ssl/nginx/nginx.crt      # read-only for everyone (not a secret)
sudo chmod 640 /etc/ssl/nginx/nginx.key      # read-only for nginx, no access for others (must be kept secret)
```

### 3. Webseiten erstellen

```nix
# ngin.nix
{ config, lib, pkgs, ... }:
let 
  # allgemeine SSL Attribute
  sslAttr = {
    forceSSL = true;
    sslCertificateKey = "/etc/ssl/nginx/nginx.key";
    sslCertificate = "/etc/ssl/nginx/nginx.crt";
  };
in
{
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    virtualHosts = {
      "web1.psa-team03.cit.tum.de" = {
        root = ./sites/web1;
      } // sslAttr;

      "web2.psa-team03.cit.tum.de" = {
        root = ./sites/web2;
      } // sslAttr;

      "web3.psa-team03.cit.tum.de" = {
        root = ./sites/web3;
      } // sslAttr;
    };
  };
}
```

#### 3.0 Netzwerk Konfiguration

#### 3.1 Website1

```nix
# ngin.nix
{ config, lib, pkgs, ... }:
let 
  # allgemeine SSL Attribute
  sslAttr = {
    forceSSL = true;
    sslCertificateKey = "/etc/ssl/nginx/nginx.key";
    sslCertificate = "/etc/ssl/nginx/nginx.crt";
  };
in
{
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    virtualHosts = {
      "web1.psa-team03.cit.tum.de" = {
        root = ./sites/web1;
      } // sslAttr;

      "web2.psa-team03.cit.tum.de" = {
        root = ./sites/web2;
      } // sslAttr;

      "web3.psa-team03.cit.tum.de" = {
        root = ./sites/web3;
      } // sslAttr;
    };
  };
}
```

#### 3.2 Website2

#### 3.3 Website3

### 4. Logfiles

### 5. Testskript


