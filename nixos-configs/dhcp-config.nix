{ pkgs, ... }:
{
    services.dhcpd4 = {
    enable = true;
    interfaces = [ "lan" "iot" ];
    extraConfig = ''
        option domain-name psa-team03.cit.tum.de;
      
        option domain-name-servers 192.168.3.3, 1.1.1.1;
        option subnet-mask 255.255.255.0;
        option routers 192.168.3.3;
    '';
  };

}
