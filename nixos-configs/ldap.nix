{ config, pkgs, ... }:

{
  services.openldap = {
    enable = true;
    package = pkgs.openldap;
    settings = {
    };
  };
}
