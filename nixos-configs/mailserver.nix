{ config, lib, pkgs, ... }:
let
  sender_canonical_file = let
    content = "@mail.psa-team03.cit.tum.de @cit.tum.de";
  in builtins.toFile "sender_canonical" content;
in
{
  services.postfix = {
    enable = true;
    domain = "psa-team03.cit.tum.de";
    networks = [ "127.0.0.0/8" "192.168.0.0/16" ];
    hostname = "mail";
    destination = [ "mail" "mail.psa-team03.cit.tum.de" "psa-team03.cit.tum.de" "localhost.cit.tum.de" "localhost" ];
    origin = "psa-team03.cit.tum.de";
    postmasterAlias = "ge78zig@psa-team03.cit.tum.de";
    recipientDelimiter = "+";

    mapFiles."sender_canonical" = sender_canonical_file;

    config = {
      smtpd_milters = [ "unix:/run/rspamd/rspamd-milter.sock" ];
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
      inet_protocols = all
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

  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;

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
        type = "rspamd_proxy";
        bindSockets = [{
          socket = "/run/rspamd/rspamd-milter.sock";
          mode = "0664";
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

  systemd.services = {
    rspamd = {
      requires = [ "clamav-daemon.service" ];
      after = [ "clamav-daemon.service" ];
    };
    postfix = {
      after = [ "rspamd.service" ];
      requires = [ "rspamd.service" ];
    };
  };

  users.extraUsers."postfix".extraGroups = [ "rspamd" ];

}