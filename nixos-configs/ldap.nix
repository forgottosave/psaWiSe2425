{ config, pkgs, ... }:

{
  services.openldap = {
    enable = true;
    package = pkgs.openldap;
    mutableConfig = true;
    settings = {
        "olcSuffix" = "dc=psa-team03,dc=in,dc=tum,dc=de";
    };
  };
}
