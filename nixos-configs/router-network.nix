{config, pkgs, ... }: 
{
  networking = {
    useDHCP = false;
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

    proxy.noProxy = "localhost,127.0.0.1,192.168.0.0/16,.cit.tum.de";

    nameservers = [ "127.0.0.1" "192.168.2.1" "9.9.9.9" ];

    nat = {
      enable = true;
      internalInterfaces = [ "enp0s8" ];
      externalInterface = "enp0s8";
      forwardPorts = [
        {
          sourcePort = 8123;
          proto = "tcp";
          destination = "192.168.3.5:8123";
        }
      ];
    };

    firewall.extraCommands = '' 
      #iptables -P INPUT ACCEPT
      #iptables -P OUTPUT ACCEPT
      #iptables -P FORWARD ACCEPT
      #iptables -F
      
      # by default: Disable connection tracking
      iptables -t raw -A PREROUTING -p tcp --dport 80 -j NOTRACK  
      iptables -t raw -A OUTPUT -p tcp --sport 80 -j NOTRACK
      iptables -t raw -A PREROUTING -p tcp --dport 443 -j NOTRACK 
      iptables -t raw -A OUTPUT -p tcp --sport 443 -j NOTRACK

      # by default: Drop all packages (in and outgoing) 
      iptables -P INPUT DROP 
      iptables -P FORWARD DROP 
      iptables -P OUTPUT DROP

      # Allow: loopback
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A OUTPUT -o lo -j ACCEPT

      # Allow: established connections
      iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT    
      iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

      # Allow: SSH
      iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

      # Allow: DNS
      iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
      iptables -A INPUT -p udp --dport 53 -j ACCEPT 
      iptables -A INPUT -p tcp --dport 53 -j ACCEPT

      # Allow: DHCP
      iptables -A INPUT -p udp --sport 68 --dport 67 -j ACCEPT
      iptables -A OUTPUT -p udp --sport 67 --dport 68 -j ACCEPT

      # Allow: git (https://serverfault.com/questions/682373/setting-up-iptables-filter-to-allow-git)
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

      # Allow incoming HTTP, HTTPS, and responses to the requests
      iptables -A INPUT -p tcp --dport 80 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT
      iptables -A INPUT -p tcp --dport 443 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT

      # Outgoing only to specific IPs
      iptables -A OUTPUT -d 146.75.118.217 -j ACCEPT # nixos cache
      iptables -A OUTPUT -d 151.101.2.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.130.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.66.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.194.217 -j ACCEPT
      iptables -A OUTPUT -d 131.159.0.0/16 -j ACCEPT
      iptables -A OUTPUT -d 192.168.1.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.2.0/24 -j ACCEPT 
      iptables -A OUTPUT -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.4.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.5.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.6.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.7.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.8.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.9.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.10.0/24 -j ACCEPT
      # docker compose
      iptables -A OUTPUT -d 54.227.20.253 -j ACCEPT
      iptables -A OUTPUT -d 54.236.113.205 -j ACCEPT
      iptables -A OUTPUT -d 54.198.86.24 -j ACCEPT
      # wpad proxy
      iptables -A OUTPUT -d 129.187.254.50 -j ACCEPT
      iptables -A OUTPUT -d 129.187.254.49 -j ACCEPT 

      # Allow: Forrwarding between the networks
      # intern->extern
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.1.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.4.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.5.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.6.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.7.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.8.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.9.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.10.0/24 -j ACCEPT
      # extern->intern (subnets & router)
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.1.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.31.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.32.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.4.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.43.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.5.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.53.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.6.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.63.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.7.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.73.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.8.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.83.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.9.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.93.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.10.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.103.0/24 -d 192.168.3.0/24 -j ACCEPT

      # Allow: ICMP 
      iptables -A INPUT -p icmp -j ACCEPT
      iptables -A OUTPUT -p icmp -j ACCEPT

      # Allow: database access
      iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 5432 -j ACCEPT

      # Allow: homeassistant
      iptables -A INPUT -p tcp --dport 8123 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 8123 -j ACCEPT

      # Allow: NFS
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 111 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 111 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 2049 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 32803 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 32769 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 892 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 892 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 875 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 875 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 662 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 662 -j ACCEPT

      # Allow: Samba
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 137 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p udp --dport 138 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 139 -j ACCEPT
      iptables -A INPUT -s 192.168.3.0/16 -m state --state NEW -p tcp --dport 445 -j ACCEPT
    
      # Allow: prometheus exporter
      iptables -A INPUT -p tcp --dport 9100 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9101 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9100 -j ACCEPT 
      iptables -A OUTPUT -p tcp --dport 9090 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9101 -j ACCEPT

      # Allow: SMTP
      iptables -A INPUT -p tcp --dport 25 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 25 -j ACCEPT

      # Allow LDAP
      iptables -A INPUT -p tcp --dport 389 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 389 -j ACCEPT

      # Allow: traffic to the mail relay
      iptables -A INPUT -d 131.159.254.10 -j ACCEPT
      iptables -A OUTPUT -d 131.159.254.10 -j ACCEPT
    '';
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
