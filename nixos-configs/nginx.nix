# ngin.nix
{ config, lib, pkgs, ... }:
let 
  # allgemeine SSL Attribute
  sslAttr = {
    forceSSL = true;
    sslCertificateKey = "/etc/ssl/nginx/nginx.key";
    sslCertificate = "/etc/ssl/nginx/nginx.crt";
  };
in
{
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    virtualHosts = {
      "web1.psa-team03.cit.tum.de" = {
        root = ./sites/web1;
      } // sslAttr;

      "web2.psa-team03.cit.tum.de" = {
        root = ./sites/web2;
      } // sslAttr;

      "web3.psa-team03.cit.tum.de" = {
        root = ./sites/web3;
      } // sslAttr;
    };
  };
}