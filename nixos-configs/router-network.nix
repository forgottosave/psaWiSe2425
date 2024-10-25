{config, pkgs, ... }: 
{
  networking = {
   interfaces.enp0s8 = {
    ipv4.addresses = [
      { address = "192.168.3.3"; prefixLength = 24; }
      { address = "192.168.31.3"; prefixLength = 24; }
      { address = "192.168.32.3"; prefixLength = 24; }
      { address = "192.168.43.3"; prefixLength = 24; }
      { address = "192.168.53.3"; prefixLength = 24; }
      { address = "192.168.63.3"; prefixLength = 24; }
      { address = "192.168.73.3"; prefixLength = 24; }
      { address = "192.168.83.3"; prefixLength = 24; }
      { address = "192.168.93.3"; prefixLength = 24; }
      { address = "192.168.103.3"; prefixLength = 24; }
    ];
    ipv4.routes = [
      { address = "192.168.1.0"; prefixLength = 24; via = "192.168.31.1"; } # ids der anderen router vms
      { address = "192.168.2.0"; prefixLength = 24; via = "192.168.32.2"; }
      { address = "192.168.4.0"; prefixLength = 24; via = "192.168.41.4"; }
      { address = "192.168.5.0"; prefixLength = 24; via = "192.168.51.5"; }
      { address = "192.168.6.0"; prefixLength = 24; via = "192.168.61.6"; }
      { address = "192.168.7.0"; prefixLength = 24; via = "192.168.71.7"; }
      { address = "192.168.8.0"; prefixLength = 24; via = "192.168.81.8"; }
      { address = "192.168.9.0"; prefixLength = 24; via = "192.168.91.8"; }
      { address = "192.168.10.0"; prefixLength = 24; via = "192.168.101.9"; }
    ];
   };
  };
}