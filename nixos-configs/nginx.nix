{ config, lib, pkgs, ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts = {
      "vm06.psa-team03.cit.tum.de" = {
        listen = [ 80 ];
        root = "/var/www/html";
        enableACME = false; # Kein Let's Encrypt, da selbstsigniertes Zertifikat
      };
    };
  };
}
