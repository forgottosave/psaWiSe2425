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

    proxy.httpsProxy = "http://proxy.cit.tum.de:8080/"; 
    proxy.httpProxy = "http://proxy.cit.tum.de:8080/";

    firewall.extraCommands = '' 
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

      # Allow incoming HTTP, HTTPS, and responses to the requests
      iptables -A INPUT -p tcp --dport 80 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT
      iptables -A INPUT -p tcp --dport 443 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT

      # Outgoing only to specific IPs
      iptables -A OUTPUT -d 140.82.112.3 -j ACCEPT
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

      # Allow: Forrwarding between the networks
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.1.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.1.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.3.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.3.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.4.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.4.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.5.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.5.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.6.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.6.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.7.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.7.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.8.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.8.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.9.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.9.0/24 -d 192.168.2.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.2.0/24 -d 192.168.10.0/24 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -o enp0s8 -s 192.168.10.0/24 -d 192.168.2.0/24 -j ACCEPT

      # Allow: ICMP 
      iptables -A INPUT -p icmp -j ACCEPT
      iptables -A OUTPUT -p icmp -j ACCEPT
    '';
  };
}