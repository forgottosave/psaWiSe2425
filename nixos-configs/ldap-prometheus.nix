{ pkgs, ... }:

let
  openldap_exporter = pkgs.stdenv.mkDerivation {
    pname = "openldap_exporter";
    src = pkgs.fetchurl {
      url = "https://github.com/tomcz/openldap_exporter/releases/download/v2.3.2/openldap_exporter-linux-amd64.gz";
      sha256 = "sha256-hash-of-the-tarball"; # Replace with the actual SHA256 hash
    };
    buildInputs = [ pkgs.go ];
    installPhase = ''
      mkdir -p $out/bin
      cp openldap_exporter $out/bin/
    '';
  };
in
{
  environment.systemPackages = [ openldap_exporter ];

  systemd.services.openldap_exporter = {
    description = "Prometheus OpenLDAP Exporter";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${openldap_exporter}/bin/openldap_exporter --ldap.addr=ldap://localhost:389";
      Restart = "always";
    };
  };

  # services.prometheus = {
  #   enable = true;
  #   scrapeConfigs = [
  #     {
  #       job_name = "openldap_exporter";
  #       static_configs = [
  #         {
  #           targets = [ "localhost:9330" ];
  #         }
  #       ];
  #     }
  #   ];
  # };
}
