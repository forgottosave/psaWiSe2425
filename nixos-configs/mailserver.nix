{ config, lib, pkgs, ... }:
let
  smtp_generic_maps_file = let
    content = "/^(.*)@(.*\.)?psa-team([0-9]+)\.cit\.tum\.de$/  \$1@cit\.tum\.de";
  in builtins.toFile "smtp_generic" content;
in
{
  services.postfix = {
    enable = true;                                    # postfix aktivieren
    origin = "psa-team03.cit.tum.de";                 # Ursprungsdomäne die in E-Mail-Headers verwendet wird
    domain = "psa-team03.cit.tum.de";                 # primäre domain von postfix
    hostname = "mail.psa-team03.cit.tum.de";          # hostname von postfix -> mit domain ergibt mail.psa-team03.cit.tum.de
    networks = [ "127.0.0.0/8" "192.168.0.0/16" ];    # netzwerke die postfix als trusted betrachtet
    destination = [ "mail.psa-team03.cit.tum.de" "psa-team03.cit.tum.de" "localhost.cit.tum.de" "localhost" ]; # liste an hostnamen und domainnamen, die als lokale ziele betrachtet werden
    postmasterAlias = "ge78zig";                       # Admin an die Fehlermeldungen gehen
    
    relayHost = "mailrelay.cit.tum.de";  # Relayhost für ausgehende E-Mails
    relayDomains = [
      "psa-team01.cit.tum.de"
      "psa-team02.cit.tum.de"
      "psa-team06.cit.tum.de"
      "psa-team04.cit.tum.de"
      "psa-team05.cit.tum.de"
      "psa-team07.cit.tum.de"
      "psa-team08.cit.tum.de"
      "psa-team09.cit.tum.de"
      "psa-team10.cit.tum.de"
    ];
    # Domains die gesondert vom relay host weitergeleitet werden sollen
    transport = ''
      psa-team01.cit.tum.de smtp:
      psa-team02.cit.tum.de smtp:
      psa-team06.cit.tum.de smtp:
      psa-team04.cit.tum.de smtp:
      psa-team05.cit.tum.de smtp:
      psa-team07.cit.tum.de smtp:
      psa-team08.cit.tum.de smtp:
      psa-team09.cit.tum.de smtp:
      psa-team10.cit.tum.de smtp:
    '';

    extraConfig = ''
      masquerade_domains = psa-team03.cit.tum.de
    '';

    # smtp_generic_maps file anlegen
    mapFiles = {
      generic = smtp_generic_maps_file;
    };

    # main.cf anpassen
    config = {
      smtp_generic_maps = "regexp:/etc/postfix/generic";

      smtpd_helo_required = "yes";
      smtpd_helo_restrictions = [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject_invalid_helo_hostname"
        "reject_unknown_helo_hostname"
      ];
      # um unbekannte Empfänger bereits im SMTP-Dialog abzulehnen
      smtpd_recipient_restrictions = [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject_unknown_recipient_domain"
        "reject_unauth_destination"
        "reject"
      ];
      # um open relay zu verhindern
      smtpd_relay_restrictions = [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject"
      ];

      # mails nur von bekannten nutzern annehmen
      smtpd_sender_restrictions = [
        "permit_sasl_authenticated"
        "reject"
      ];

      # als auth bei smtp dovecot2 verwenden
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_local_domain = "$myhostname";
      smtpd_sasl_security_options = "noanonymous";
      smtpd_sasl_path = "/run/dovecot2/auth";
    };
  };

  services.dovecot2 = {
    enable = true;
    enableImap = true;
    enablePop3 = true;

    extraConfig = ''
      listen = 0.0.0.0
      service auth {
        unix_listener auth {
          mode = 0666
          user = postfix
          group = postfix
        }
      }
    '';
  };


  services.clamav.daemon.enable = true;   # Aktiviert den ClamAV-Daemon, der E-Mails auf Viren untersucht
  services.clamav.updater.enable = true;  # Sorgt dafür, dass die Virensignaturen regelmäßig aktualisiert werden

  services.rspamd = {
    enable = true;
    locals = {
      "milter_headers.conf" = { text = ''
        extended_spam_headers = true;
        use = ["x-spam-header", "subject"];
        subject = "[SPAM] %s";
      ''; };
      "actions.conf" = { text = ''
        reject = null;
        greylist = null;
        add_header = 5.0;
        rewrite_subject = 5.0;
      ''; };
      "antivirus.conf" = { text = ''
        clamav {
          action = "reject";
          symbol = "CLAM_VIRUS";
          type = "clamav";
          log_clean = true;
          servers = "/run/clamav/clamd.ctl";
          scan_mime_parts = false;
        }
      ''; };
      "options.inc" = { text = ''
        gtube_patterns = "all";
      ''; };
    };

    workers.rspamd_proxy = {
        type = "rspamd_proxy";                        # Worker vom Typ rspamd_proxy, der als Milter für Postfix fungiert
        bindSockets = [{
          socket = "/run/rspamd/rspamd-milter.sock";  # Bindet den Worker an den Unix-Socket /run/rspamd/rspamd-milter.sock (entsprechend der Postfix-Konfiguration)
          mode = "0664";                              # Zugriffsrechte, sodass Postfix auf den Socket zugreifen kann
        }];
        count = 1;
        extraConfig = ''
          milter = yes;
          timeout = 120s;

          upstream "local" {
            default = yes;
            self_scan = yes;
          }
        '';
    };

  };

  # Systemd Service Abhängigkeiten (Postfix benötigt rspamd und rspamd clamav)
  systemd.services = {
    # rspamd benötigt diesen den clamav-daemon -> wird erst dnaach gestartet
    rspamd = {
      requires = [ "clamav-daemon.service" ];
      after = [ "clamav-daemon.service" ];
    };
    # postfix benötigt rspamd -> wird erst danach gestartet
    postfix = {
      after = [ "rspamd.service" ];
      requires = [ "rspamd.service" ];
    };
  };

  users.extraUsers."postfix".extraGroups = [ "rspamd" ];    # postfix wird der Gruppe rspamd hinzugefügt, um auf den rspamd-Socket zugreifen zu können

  # Konfiguration für den Prometheus Exporter für Postfix
  services.prometheus.exporters.postfix = {
    enable = true;
    port = 9154;
    telemetryPath = "/metrics";
    openFirewall = true;
  };
}