{ config, lib, pkgs, ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts = {
      "vm06.psa-team03.cit.tum.de" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; ssl = false; }
          { addr = "0.0.0.0"; port = 443; ssl = true; }
        ];
        root = "/var/www/html";
        enableACME = false; # Kein Let's Encrypt, da selbstsigniertes Zertifikat
        forceSSL = true;
        sslCertificate = "/etc/nginx/ssl/selfsigned.crt";
        sslCertificateKey = "/etc/nginx/ssl/selfsigned.key";
      };
    };
  };
}
