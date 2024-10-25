{ pkgs, ... }:

let
    openldap_exporter = pkgs.stdenv.mkDerivation {
        name = "openldap_exporter-2.3.2";
        pname = "openldap_exporter";
        version = "2.3.2";
        src = pkgs.fetchurl {
          url = "https://github.com/tomcz/openldap_exporter/releases/download/v2.3.2/openldap_exporter-linux-amd64.gz";
          sha256 = "dddd48d707a704e7ee54d70924edacca7f0eea7a54457a3b5078ac502c06b622";
        };
        nativeBuildInputs = [ pkgs.gzip pkgs.autoPatchelfHook ];
        buildInputs = [ pkgs.glibc ];

        unpackPhase = ''
          mkdir source
          gzip -d < $src > source/openldap_exporter
          chmod +x source/openldap_exporter
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp source/openldap_exporter $out/bin/
        '';

        meta = with pkgs.lib; {
          description = "Prometheus OpenLDAP Exporter";
          license = licenses.asl20;
          platforms = platforms.linux;
        };
    };
in
{
    environment.systemPackages = [ openldap_exporter ];

    systemd.services.openldap_exporter = {
        description = "Prometheus OpenLDAP Exporter";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            ExecStart = "${openldap_exporter}/bin/openldap_exporter --ldapUser admin --ldapPass ldapadmin123";
            Restart = "always";
        };
    };
}
