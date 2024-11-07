{config, pkgs, ... }: 
{
  networking = {
    useDHCP = false;
    nat.enable = false;
    firewall.enable = true;

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
        { address = "192.168.4.0"; prefixLength = 24; via = "192.168.43.4"; }
        { address = "192.168.5.0"; prefixLength = 24; via = "192.168.53.5"; }
        { address = "192.168.6.0"; prefixLength = 24; via = "192.168.63.6"; }
        { address = "192.168.7.0"; prefixLength = 24; via = "192.168.73.7"; }
        { address = "192.168.8.0"; prefixLength = 24; via = "192.168.83.8"; }
        { address = "192.168.9.0"; prefixLength = 24; via = "192.168.93.9"; }
        { address = "192.168.10.0"; prefixLength = 24; via = "192.168.103.10"; }
      ];
    };

    proxy.httpsProxy = "http://proxy.cit.tum.de:8080/"; 
    proxy.httpProxy = "http://proxy.cit.tum.de:8080/";

  };

  # Forwarding aktivieren, ICMP Redirects deaktivieren
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.enp0s8.forwarding" = true;
    "net.ipv4.conf.enp0s8.send_redirects" = false;
    "net.ipv4.conf.enp0s8.accept_redirects" = false;
    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.send_redirects" = false;
    "net.ipv6.conf.all.send_redirects" = false;
    "net.ipv6.conf.default.send_redirects" = false;
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;
  };
}
