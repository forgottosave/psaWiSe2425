{ config, pkgs, ... }:

{
  services.openldap = {
    enable = true;
    package = pkgs.openldap;
    mutableConfig = true;
    settings = {
    };
  };
}
