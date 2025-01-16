# Aufgabenblatt 04

Aufgaben:

1. erstellen eines Webservers mittels nginx über das Interface `enp0s8`
2. erstellen eines selbst signierten Zertifikats für ssl
3. Webseiten erstellen:
    website1:
    - erreichbar über web1.psa-team03.cit.tum.de (sowohl http als auch https über 443)
    - dazu individuellen homepages für alle nutzer erreichbar über web1.psa-team03.cit.tum.de/~<login>  
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

Nun brauchen wir neben dem Webserver auch 3 Websiten die wir über den Webserver bereitstellen wollen. Hierfür haben wir für jede Website eine eigene Konfigurationsdatei erstellt. Diese Konfigurationsdateien werden in der `nginx.nix` Datei eingebunden. Die Websiten sind dummy html Seiten die in den jeweiligen Ordnern `/etc/nixos/sites/web1`, `/etc/nixos/sites/web2` und `/etc/nixos/sites/web3` abgelegt werden. Die Konfigurationen `ginx.nix` sehen wie folgt aus:

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

Hierbei wurde auch gleich ssl aktiviert, indem die `sslAttr` Variable in die Konfigurationen eingebunden wurde.

#### 3.0 Netzwerk Konfiguration

Damit die Seiten auch erreichbar sind müssen noch änderungen an der Netzwerkkonfiguration vorgenommen werden. Einmal am Webserver selber der auf dem interface `enp0s8` eine weitere IP Adresse erhält `192.168.3.66` und einmal am DNS Server der die Domains auf die IP Adressen mapped. Hierfür haben wir die folgenden Änderungen vorgenommen:

```nix
# nginx.nix
...
  # IP Adresse hinzufügen
  systemd.network.networks."psa-internal".address = [ "192.168.3.66" ];
...
```

```nix
# psa-team03.zone
...
; VM 6
vm6             A       192.168.3.6
web1            A       192.168.3.6
web2            CNAME   web1
web3            A       192.168.3.66
...
```

Nun sollten alle Webseiten über die Domains `web1.psa-team03.cit.tum.de`, `web2.psa-team03.cit.tum.de` und `web3.psa-team03.cit.tum.de` erreichbar sein.

#### 3.1 Website1

Für die web1 soll es nun noch möglich sein über `web1.psa-team03.cit.tum.de/~<login>` auf die jeweiligen Homepages der Nutzer zuzugreifen. Diese soll dazu dann jeweils in den Ordnern `$HOME/.html-data/` abgelegt werden. Hierfür haben wir die folgenden Änderungen vorgenommen:

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

  # Liste aller Nutzernamen
  usernames = [
    "ge95vir" "ge43fim" "ge78nes" "ge96hoj" "ge78zig" "ge96xok"
    "ge87yen" "ge47sof" "ge47kut" "ge87liq" "ge59pib" "ge65peq"
    "ge63gut" "ge64baw" "ge84zoj" "ge94bob" "ge87huk" "ge64wug"
    "ge65hog" "ge38hoy"
  ];

  # Funktion um alle Nutzernamen zu verarbeiten
  forEachUsername = f: builtins.listToAttrs (map f usernames);

  # Funktion um alle Nutzer in ein Set zu verarbeiten
  forEachUser = f: builtins.listToAttrs (map (username:
    f (builtins.getAttr username config.users.users)
  ) usernames);

in
{
  # IP Adresse hinzufügen
  systemd.network.networks."psa-internal".address = [ "192.168.3.66" ];

  systemd.services = {
    # Normalerweise darf Nginx nicht auf Home Ordner lesend zugreifen.
    nginx.serviceConfig.ProtectHome = "read-only";
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    virtualHosts = {
      "web1.psa-team03.cit.tum.de" = {
        root = ./sites/web1;
        # http://.../~<login> -> ~<login>/.html-data
        locations."~ ^/~(\\w+?)(?:/(.*))?$" = {
          priority = 2;
          alias = "/home/$1/.html-data/$2";
        };
      } // sslAttr;

      "web2.psa-team03.cit.tum.de" = {
        root = ./sites/web2;
      } // sslAttr;

      "web3.psa-team03.cit.tum.de" = {
        root = ./sites/web3;
      } // sslAttr;
    };
  };  

  # Activation Script um automatisch .html-data und .cgi-bin Ordner für jeden User zu erstellen
  system.activationScripts = forEachUser (user:
    {
      name = "webserver-user-${user.name}";
      value = {
        text =
          ''
            html_data_dir="${user.home}/.html-data"
            cgi_bin_dir="${user.home}/.cgi-bin"

            if [ ! -d "$html_data_dir" ]; then
              mkdir -p "$html_data_dir"
              echo "Hello statically from ${user.name}" > "$html_data_dir/index.html"
              chown -R ${user.name}:${user.group} "$html_data_dir"
            fi

            if [ ! -d "$cgi_bin_dir" ]; then
              mkdir -p "$cgi_bin_dir"
              cat > "$cgi_bin_dir/index.sh" << 'EOF'
            #!/usr/bin/env bash
            echo "Content-type: text/html"
            echo ""
            echo "Hello dynamically from $(whoami)"
            EOF
              chmod +x "$cgi_bin_dir/index.sh"
              chown -R ${user.name}:${user.group} "$cgi_bin_dir"
            fi
          '';
        deps = [ "users" ];
      };
    }
  );

}
```

Dazu würde noch die user.nix angepasst und dort bei Jedem Nutzer noch der homeMode auf x+o gesetzt damit der Webserver auf die Dateien zugreifen kann:

```nix
# user-config.nix
...
users.users.ge87huk = {
  ...
  homeMode = "701";
  ...
};
...
```

#### 3.2 Website2

#### 3.3 Website3

### 4. Logfiles

### 5. Testskript


