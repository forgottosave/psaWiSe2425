{ config, lib, pkgs, ... }:
let
  sender_canonical_file = let
    content = "@mail.psa-team03.cit.tum.de @cit.tum.de";
  in builtins.toFile "sender_canonical" content;
in
{
  services.postfix = {
    enable = true;                                    # postfix aktivieren
    domain = "psa-team03.cit.tum.de";                 # primäre domain von postfix
    networks = [ "127.0.0.0/8" "192.168.0.0/16" ];    # netzwerke, die postfix als trusted betrachtet
    hostname = "mail";                                # hostname von postfix -> mit domain ergibt mail.psa-team03.cit.tum.de
    destination = [ "mail" "mail.psa-team03.cit.tum.de" "psa-team03.cit.tum.de" "localhost.cit.tum.de" "localhost" ]; # liste an hostnamen und domainnamen, die als lokale ziele betrachtet werden
    origin = "psa-team03.cit.tum.de";                 # Ursprungsdomäne die in E-Mail-Headers verwendet wird
    postmasterAlias = "ge78zig@psa-team03.cit.tum.de";# Admin an den Fehlermeldungen gehen
    recipientDelimiter = "+";                         # Das Trennzeichen für Adresszusätze (z. B. benutzer+filter@domain)          

    # zuvor erzeugte Datei in config eingebunden -> im extra-configs wird diese später referenziert
    mapFiles."sender_canonical" = sender_canonical_file;

    # Konfiguration für den Milter (Mail Filter), der von rspamd bereitgestellt wird -> ermöglicht während der SMTP-Session zu überprüfen
    config = {
      smtpd_milters = [ "unix:/run/rspamd/rspamd-milter.sock" ];  # Pfad zum Socket von rspamd
      milter_protocol = "6";
    };

    extraConfig = ''
      smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_unverified_recipient
      unknown_local_recipient_reject_code = 550
      smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_unverified_recipient
      local_recipient_maps = proxy:unix:passwd.byname

      sender_canonical_maps = hash:/etc/postfix/sender_canonical
      relayhost = mailrelay.cit.tum.de

      mailbox_size_limit = 0
      inet_interfaces = all
      inet_protocols = ipv4
      home_mailbox = Maildir/

      masquerade_domains = psa-team03.cit.tum.de

      smtpd_sasl_type = dovecot
      smtpd_sasl_path = /run/dovecot2/auth
      smtpd_sasl_auth_enable = yes
      smtpd_tls_auth_only = yes
      smtpd_sasl_security_options = noanonymous
      smtpd_sasl_local_domain = $myhostname;
    '';
  };

  services.dovecot2 = {
    enable = true;

    extraConfig = ''
      listen = 0.0.0.0

      service auth {
        unix_listener auth {
          mode = 0666
          user = postfix
          group = postfix
        }
      }

      auth_mechanisms = plain login
      mail_location = maildir:~/Maildir
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
        count = 1;                                    # Anzahl der Worker-Instanzen (hier nur 1x)
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