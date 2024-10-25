{ config, lib, pkgs, ... }:
{
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixSamba Server";
        "netbios name" = "NixSamba";
        "security" = "user";
        "map to guest" = "never";  # Do not allow guest access
        "passdb backend" = "tdbsam";  # Use Samba's built-in authentication
        "log file" = "/var/log/samba/log.%m";
        "max log size" = "50";
      };
      "homes" = {  # Special Samba share for user home directories
        "path" = "/export/home/%S";  # %S = username
        "browseable" = "no";  # Hide the home share list
        "read only" = "no";
        "valid users" = "%S root";  # Allow only the owner access
        "admin users" = "root";
        "create mask" = "0700";
        "directory mask" = "0700";
      };
    };
  };
}
