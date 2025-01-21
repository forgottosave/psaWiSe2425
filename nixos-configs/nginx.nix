# ngin.nix
{ config, lib, pkgs, ... }:
let 
  # allgemeine SSL Attribute
  sslAttr = {
    forceSSL = true;
    sslCertificateKey = "/etc/ssl/nginx/nginx.key";
    sslCertificate = "/etc/ssl/nginx/nginx.crt";
  };

  usernames = [
    "ge95vir" "ge43fim" "ge78nes" "ge96hoj" "ge78zig" "ge96xok"
    "ge87yen" "ge47sof" "ge47kut" "ge87liq" "ge59pib" "ge65peq"
    "ge63gut" "ge64baw" "ge84zoj" "ge94bob" "ge87huk" "ge64wug"
    "ge65hog" "ge38hoy"
  ];

  # Function to process each username
  forEachUsername = f: builtins.listToAttrs (map f usernames);

  # Function to process each user attribute set
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

      # exporter für Prometheus
      # Enable the Prometheus metrics module
      extraModules = [ pkgs.nginxModules.ngx_http_stub_status ];

      # Add a location block for metrics in each virtual host
      extraConfig = ''
        server {
          listen 127.0.0.1:8080;
          location /metrics {
            stub_status;
            allow 127.0.0.1;
            deny all;
          }
        }
      '';
    };

    # Logging
    commonHttpConfig =
    ''
      map $remote_addr $remote_addr_anon {
        ~(?P<ip>\d+\.\d+\.\d+)\.    $ip.0;
        default                     0.0.0.0;
      }

      log_format combined_anon '$remote_addr_anon - $remote_user [$time_local] '
                          '"$request" $status $body_bytes_sent '
                          '"$http_referer" "$http_user_agent"';

      # Log Locations spezifizieren
      # Access Log nimmt unser spezielles Log Format
      access_log /var/log/nginx/access.log combined_anon;
      error_log /var/log/nginx/error.log;
    '';
  };

  # Add Prometheus Nginx Exporter
  services.prometheus.exporters.nginx = {
    enable = true;
    listenAddress = ":9101"; # Default listen port for Prometheus Nginx Exporter
    scrapeUri = "http://127.0.0.1:8080/metrics";
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

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "logind"
      "systemd"
    ];
    disabledCollectors = [
      "textfile"
    ];
    openFirewall = true;
  };
}