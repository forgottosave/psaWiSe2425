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

  # Available script packages
  scriptPkgs = with pkgs; [ bash php python3Minimal ];

in
{
  fileSystems."/etc/nixos/sites" = {
    device = "192.168.3.8:/sites";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  # IP Adresse hinzufügen
  systemd.network.networks."psa-internal".address = [ "192.168.3.66" ];

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
    enable = true;
    recommendedOptimisation = true;
    virtualHosts = {
      "web1.psa-team03.cit.tum.de" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; }
          { addr = "0.0.0.0"; port = 443; ssl = true; }
        ];
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
        locations."/metrics" = {
          extraConfig = ''
            stub_status on;
            allow 127.0.0.1;
            deny all;
          '';
        };
      } // sslAttr;

      "web2.psa-team03.cit.tum.de" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; }
          { addr = "0.0.0.0"; port = 443; ssl = true; }
        ];
        root = ./sites/web2;
        locations."/metrics" = {
          extraConfig = ''
            stub_status on;
            allow 127.0.0.1;
            deny all;
          '';
        };
      } // sslAttr;

      "web3.psa-team03.cit.tum.de" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; }
          { addr = "0.0.0.0"; port = 443; ssl = true; }
        ];
        root = ./sites/web3;
        locations."/metrics" = {
          extraConfig = ''
            stub_status on;
            allow 127.0.0.1;
            deny all;
          '';
        };
      } // sslAttr;
    };

    # Enable the Prometheus metrics module
    #extraModules = [ pkgs.nginxModules.ngx_http_stub_status ];

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
    appendHttpConfig = 
    ''
      add_header X-Frame-Options "SAMEORIGIN";
      add_header X-Content-Type-Options "nosniff";
    '';
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


  # Add Prometheus Nginx Exporter
  services.prometheus.exporters.nginx = {
    enable = true;
    port = 9101;
    scrapeUri = "http://127.0.0.1:8080/metrics";
  };

  services.prometheus.exporters.blackbox = {
    enable = true;
    port = 9102;
    openFirewall = true;
    configFile = ./blackbox.yml;
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