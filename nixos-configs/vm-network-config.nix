{config, pkgs, ... }:   
{
  networking = {
    firewall.enable = false;

    interfaces.enp0s8 = {
      ipv4.addresses = [
        { address = "192.168.3.%%vm%%"; prefixLength = 24; }
      ];
      ipv4.routes = [
        { address = "192.168.0.0"; prefixLength = 16; via = "192.168.3.3"; }
      ];
    };
  };
}
