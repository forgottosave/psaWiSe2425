{
  config,
  lib,
  ...
}: let
  sssdConf = builtins.readFile ./sssd.conf;
  certFile = ./slapd.crt;
in {
    # System Security Services Daemon (SSSD) configuration
    services.sssd = {
      enable = true;
      config = sssdConf;
      environmentFile = "/etc/secrets/sssd.env";
    };

    security.pki.certificateFiles = [certFile];
}
