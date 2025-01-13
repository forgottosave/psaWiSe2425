# ngin.nix
{ config, lib, pkgs, ... }:
let 
  # allgemeine SSL Attribute
  sslAttr = {
    forceSSL = true;
    sslCertificateKey = "/etc/ssl/nginx/nginx.key";
    sslCertificate = "/etc/ssl/nginx/nginx.crt";
  };

  # Execute function for each user(name), returning attrSet
  forEachUsername = f: builtins.listToAttrs (map f config.psa.users.psa);
  forEachUser = f: forEachUsername (u:
    f (builtins.getAttr u config.users.users)
  );

in
{
  systemd.services = {
    # Normalerweise darf Nginx nicht auf Home Ordner lesend zugreifen.
    nginx.serviceConfig.ProtectHome = "read-only";
  }
  //
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

      "web2.psa-team03.cit.tum.de" = {
        root = ./sites/web2;
      } // sslAttr;

      "web3.psa-team03.cit.tum.de" = {
        root = ./sites/web3;
      } // sslAttr;
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

  # Für jeden User erlauben wir o+x Permissions auf dem Home Directory
  users.users = forEachUsername (u:
    {
      name = u;
      value = { homeMode = "701"; };
    }
  );

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
              echo "👋 Hello statically from ${user.name}" > "$html_data_dir/index.html"
              chown -R ${user.name}:${user.group} "$html_data_dir"
            fi

            if [ ! -d "$cgi_bin_dir" ]; then
              mkdir -p "$cgi_bin_dir"
              cat > "$cgi_bin_dir/index.sh" << 'EOF'
            #!/usr/bin/env bash
            echo "Content-type: text/html"
            echo ""
            echo "👋 Hello dynamically from $(whoami)"
            EOF
              chmod +x "$cgi_bin_dir/index.sh"
              chown -R ${user.name}:${user.group} "$cgi_bin_dir"
            fi
          '';
        deps = [ "users" ];
      };
    }
  );

  # Log Rotation
  # Default deaktivieren
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

}