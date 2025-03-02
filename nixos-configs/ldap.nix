{ config, pkgs, ... }:

{
  services.openldap = {
    enable = true;
    package = pkgs.openldap;
    settings = {
      # Define the base domain
      "olcSuffix" = "dc=psa-team03,dc=in,dc=tum,dc=de";
      "olcRootDN" = "cn=admin,dc=psa-team03,dc=in,dc=tum,dc=de";
      "olcRootPW" = "{SSHA}your_encrypted_password";
    };
  };
}
