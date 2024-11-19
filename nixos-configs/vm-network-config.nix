{config, pkgs, ... }:   
{
  environment.etc = {
    "resolv.conf".text = "nameserver 192.168.3.3\nnameserver 8.8.8.8";
  };

  networking = {
    interfaces.enp0s8 = {
      #useDHCP = true;
      #ipv4.addresses = [
      #  { address = "192.168.3.%%vm%%"; prefixLength = 24; }
      #];
      #ipv4.routes = [
      #  { address = "192.168.0.0"; prefixLength = 16; via = "192.168.3.3"; }
      #];
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
      
      # Allow: git (https://serverfault.com/questions/682373/setting-up-iptables-filter-to-allow-git)
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

      # Allow: DNS
      iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
      iptables -A INPUT -p udp --dport 53 -j ACCEPT 
      iptables -A INPUT -p tcp --dport 53 -j ACCEPT

      # Allow: incoming HTTP, HTTPS, and responses to the requests
      iptables -A INPUT -p tcp --dport 80 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT
      iptables -A INPUT -p tcp --dport 443 -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT

      # Outgoing only to specific IPs
      # gitlab
      iptables -A OUTPUT -d 131.159.0.0/16 -j ACCEPT
      # nixos updater
      iptables -A OUTPUT -d 151.101.2.217 -j ACCEPT  
      iptables -A OUTPUT -d 151.101.130.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.66.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.194.217 -j ACCEPT
      # praktikum
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

      # Allow: ICMP 
      iptables -A INPUT -p icmp -j ACCEPT
      iptables -A OUTPUT -p icmp -j ACCEPT
    '';
  };  

  systemd.network = {
    enable = true;
    networks."psa-internal" = {
      name = "enp0s8";
      DHCP = "yes";
      dhcpV4Config = {
        UseDNS = true;
        UseRoutes = true;
        ClientIdentifier = "mac";
        UseDomains = true;
        BlackList = [
          "192.168.56.100"
          "192.168.1.53"
          "192.168.2.2"
          "192.168.4.10"
          "192.168.6.1"
          "192.168.7.2"
          "192.168.8.7"
          "192.168.9.1"
          "192.168.10.2"
        ];
      };
    };
  };
}
