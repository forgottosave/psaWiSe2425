{ config, lib, pkgs, ... }:
{
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "SambaFilesharingTeam03";
        "netbios name" = "SambaFilesharingTeam03";
        "security" = "user";
        #"use sendfile" = "yes";
        #"max protocol" = "smb2";
        # note: localhost is the ipv6 localhost ::1
        #"hosts deny" = "0.0.0.0/0";
        "hosts allow" = "192.168.0.0/16 127.0.0.1 localhost";
        "guest ok" = "no";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "read only" = "no";
        "inherit owner" = "yes";
      };
      "public" = {
        "path" = "/export/home";
        "browseable" = "yes";
      };
    };
  };
}
