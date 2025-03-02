# Aufgabenblatt 04

Aufgaben:

1. erstellen eines Webservers mittels nginx erreichbar über das Interface `enp0s8`
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
    - zusätzliche IP für das Interface enp0s8 anlegen
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

Firewall deaktivieren damit es nachher keine Porbleme gibt wenn nix temporär das openssl pkgs installiert um mit diesen ein Zertifikat zu erstellen:

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

Nun brauchen wir neben dem Webserver auch 3 Websiten die wir über den Webserver bereitstellen wollen. Hierfür haben wir für jede Website eine eigene Konfigurationsdatei erstellt. Diese Konfigurationsdateien werden in der `nginx.nix` Datei eingebunden. Die Websiten sind dummy html Seiten die in den jeweiligen Ordnern `/etc/nixos/sites/web1`, `/etc/nixos/sites/web2` und `/etc/nixos/sites/web3` abgelegt werden. Die Konfigurationen `nginx.nix` sehen wie folgt aus:

```nix
# ngin.nix
{ config, lib, pkgs, ... }:
let 
  # allgemeine SSL Attribute (von allen Webseiten genutzt)
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
        listen = [
          { addr = "0.0.0.0"; port = 80; }
          { addr = "0.0.0.0"; port = 443; ssl = true; }
        ];
        root = ./sites/web1;
      } // sslAttr;

      "web2.psa-team03.cit.tum.de" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; }
          { addr = "0.0.0.0"; port = 443; ssl = true; }
        ];
        root = ./sites/web2;
      } // sslAttr;

      "web3.psa-team03.cit.tum.de" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; }
          { addr = "0.0.0.0"; port = 443; ssl = true; }
        ];
        root = ./sites/web3;
      } // sslAttr;
    };
  };
}
```

Hierbei wurde auch gleich ssl aktiviert, indem die `sslAttr` Variable in die Konfigurationen eingebunden wurde.

#### 3.0 Netzwerk Konfiguration

Damit die Seiten auch erreichbar sind müssen noch Änderungen an der Netzwerkkonfiguration vorgenommen werden. Einmal am Webserver selber der auf dem interface `enp0s8` eine weitere IP Adresse erhält `192.168.3.66` und einmal am DNS Server der den Domains die die jeweilige IP Adresse zuweißt. Hierfür haben wir die folgenden Änderungen vorgenommen:

```nix
# nginx.nix
...
  # IP Adresse hinzufügen für web3
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
Dies Kann mit den folgenden Befehlen getestet werden:

```shell
curl -Lk http://web1.psa-team03.cit.tum.de
curl -Lk http://web2.psa-team03.cit.tum.de
curl -Lk https://web1.psa-team03.cit.tum.de
curl -Lk https://web2.psa-team03.cit.tum.de
curl -Lk https://web3.psa-team03.cit.tum.de
```

Hiermit sind auch beraits Webseite2 und Webseite3 fertiggestellt :D

#### 3.1 Website1

Für die web1 soll es nun noch möglich sein über `web1.psa-team03.cit.tum.de/~<login>` auf die jeweiligen Homepages der Nutzer zuzugreifen. Diese soll dazu dann jeweils in den Ordnern `$HOME/.html-data/` abgelegt werden. Hierfür haben wir die folgenden Änderungen vorgenommen:

```nix
# ngin.nix
{ config, lib, pkgs, ... }:
let 
  ...
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
  ...
  systemd.services = {
    # Normalerweise darf Nginx nicht auf Home Ordner lesend zugreifen.
    nginx.serviceConfig.ProtectHome = "read-only";
  };

  services.nginx = {
    ...
    virtualHosts = {
      "web1.psa-team03.cit.tum.de" = {
        root = ./sites/web1;
        # http://.../~<login> -> ~<login>/.html-data
        locations."~ ^/~(\\w+?)(?:/(.*))?$" = {
          priority = 2;
          alias = "/home/$1/.html-data/$2";
        };
      } // sslAttr;
      ...
    };
  };  
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

Zuletztmüssen nur noch beispielwebsiten für die Nutzer erstellt werden:

```shell
#!/usr/bin/env bash
for dir in *; do

html_data_dir="${dir}/.html-data"

echo "doing ${dir} now, in $html_data_dir and $cgi_bin_dir"

if [ ! -d "$html_data_dir" ]; then
  mkdir -p "$html_data_dir"
  echo "This is some *STATIC* content, directly from ${dir} :)" > "$html_data_dir/index.html"
  chown -R "${dir}:students" "$html_data_dir"
fi

done
```

Hierauf sollte nun über `web1.psa-team03.cit.tum.de/~<login>` auf die jeweiligen Homepages der Nutzer zugegriffen werden können was z.B. mit dem folgenden Befehl getestet werden kann:

```shell
curl -Lk http://web1.psa-team03.cit.tum.de/~ge78zig
```

<hr>

Nun Fehlen nur noch die dynamischen Homepages für alle Nutzer die in den Ordnern `$HOME/.cgi-bin/` abgelegt werden sollen. Hierfür haben wir die folgenden Änderungen vorgenommen:

```nix
# ngin.nix
{ config, lib, pkgs, ... }:
let 
  ...
  # Available script packages
  scriptPkgs = with pkgs; [ bash php python3Minimal ];

in
{
  ...
  systemd.services = {
    # Normalerweise darf Nginx nicht auf Home Ordner lesend zugreifen.
    nginx.serviceConfig.ProtectHome = "read-only";
  } //
  # fcgiwrap systemd service packages zum path hinzufügen
  forEachUsername (u:
    {
      name = "fcgiwrap-${u}";
      value = {
        path = scriptPkgs;
      };
    }
  );

  services.nginx = {
    ...
    virtualHosts = {
      "web1.psa-team03.cit.tum.de" = {
        ...

        # http://.../~<login>/cgi-bin -> ~<login>/.cgi-bin
        locations."~ ^/~(\\w+?)/cgi-bin(?:/(.*))?$" = {
          priority = 1;
          fastcgiParams.SCRIPT_FILENAME = "/home/$1/.cgi-bin/$2";
          extraConfig =
            ''
              fastcgi_pass unix:/run/fcgiwrap-$1.sock;
            '';
        };
      } // sslAttr;
      ...
    };
  };

  # Für jeden User wird eine fcgiwrap Service Instanz erzeugt
  services.fcgiwrap.instances = forEachUser (user:
    {
      name = user.name;
      value = {
        process = {
          user = user.name;
          group = user.group;
        };
        socket = {
          user = user.name;
          group = config.services.nginx.group;
          mode = "0660";
        };
      };
    }
  );
}
```

Um nun auch noch eine Testseite für hier bash haben wir das vorherige Skript wie folgt erweitert, wobei im dynamischen Inhalt der Nutzername (whoami) angezeigt wird:

```shell
#!/usr/bin/env bash

for dir in *; do

  html_data_dir="${dir}/.html-data"
  cgi_bin_dir="${dir}/.cgi-bin"

  echo "doing ${dir} now, in $html_data_dir and $cgi_bin_dir"

  rm -r "$html_data_dir"
  if [ ! -d "$html_data_dir" ]; then
    mkdir -p "$html_data_dir"
    echo "This is some *STATIC* content, directly from ${dir} :)" > "$html_data_dir/index.html"
    chown -R "${dir}:students" "$html_data_dir"
  fi

  rm -r "$cgi_bin_dir"
  if [ ! -d "$cgi_bin_dir" ]; then
    mkdir -p "$cgi_bin_dir"

    cat <<< '#!/usr/bin/env bash
    echo "Content-type: text/html"
    echo ""
    echo "This is some *DYNAMIC* content, directly from $(whoami) :)"' > "$cgi_bin_dir/index.sh"

    chmod +x "$cgi_bin_dir/index.sh"
    chown -R "${dir}:students" "$cgi_bin_dir"
  fi

done
```

Nun sollte über `web1.psa-team03.cit.tum.de/~<login>/cgi-bin` auf die dynamischen Homepages zugegriffen werden können was z.B. mit dem folgenden Befehl getestet werden kann:

```shell
curl -Lk http://web1.psa-team03.cit.tum.de/~ge59pib/cgi-bin/index.sh
```

Damit ist nun auch die Website1 fertig :D

### 4. Logfiles

Beim Logging bestand die Aufgabe darin die IP-Adressen im Zugriffs-Log nicht/teilweise zu protokollieren und im Fehler-Log hingegen die IP-Adressen vollständig zu protokollieren. Hierfür haben wir im nginx service die `commonHttpConfig` wie folgt definiert:

```nix
# ngin.nix
...
  services.nginx = {
    ...
    # Logging
    commonHttpConfig =
    ''
      # Anonymize IP addresses in access log
      map $remote_addr $remote_addr_anon {
        ~(?P<ip>\d+\.\d+\.\d+)\.    $ip.0;
        default                     0.0.0.0;
      }

      # specify log format for access log
      log_format combined_anon '$remote_addr_anon - $remote_user [$time_local] '
                          '"$request" $status $body_bytes_sent '
                          '"$http_referer" "$http_user_agent"';

      # set Log Locations
      access_log /var/log/nginx/access.log combined_anon;
      error_log /var/log/nginx/error.log;
    '';
  };
...
```

Nun werden alle Daten wie gewünscht in den Logfiles protokolliert. Als näcshtes muss die Rotation der Logfiles konfiguriert werden. Zunächst muss dafür die default Einstellung für die Logrotation deaktiviert werden. Anschließend können die Einstellungen für die Logrotation der Zugriffs- und Fehlerlogs definiert werden:

```nix
# ngin.nix
...
  # Log Rotation
  # disable default settings for logrotate
  services.logrotate.settings.nginx.enable = lib.mkForce false;
  # Access Log
  services.logrotate.settings.nginxaccess = {
    files = "/var/log/nginx/access.log";
    frequency = "daily";
    su = "${config.services.nginx.user} ${config.services.nginx.group}";
    rotate = 5;
    compress = true;
    delaycompress = true;
    postrotate = "[ ! -f /var/run/nginx/nginx.pid ] || kill -USR1 `cat /var/run/nginx/nginx.pid`";
  };
  # Error Log
  services.logrotate.settings.nginxerror = {
    files = "/var/log/nginx/error.log";
    frequency = "daily";
    su = "${config.services.nginx.user} ${config.services.nginx.group}";
    rotate = 1;
    compress = true;
    delaycompress = true;
    postrotate = "[ ! -f /var/run/nginx/nginx.pid ] || kill -USR1 `cat /var/run/nginx/nginx.pid`";
  };
...
```

Nun sollten die Logfiles täglich rotiert werden und die Zugriffslogs nach 5 Tagen und die Fehlerlogs nach 1 Tag gelöscht werden.
