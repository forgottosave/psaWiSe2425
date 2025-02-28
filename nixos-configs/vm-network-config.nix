{config, pkgs, ... }:   
{
  networking = {
    #interfaces.enp0s8 = {
      #useDHCP = true;
      #ipv4.addresses = [
      #  { address = "192.168.3.%%vm%%"; prefixLength = 24; }
      #];
      #ipv4.routes = [
      #  { address = "192.168.0.0"; prefixLength = 16; via = "192.168.3.3"; }
      #];
    #};



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

      # Allow: DHCP
      iptables -A INPUT -p udp --sport 67 --dport 68 -j ACCEPT
      #iptables -A OUTPUT -p udp --sport 67 --dport 68 -j ACCEPT

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
      iptables -A OUTPUT -d 146.75.118.217 -j ACCEPT
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
      # allow clamav
      iptables -A OUTPUT -d 104.16.218.84 -j ACCEPT
      iptables -A OUTPUT -d 104.16.219.84 -j ACCEPT

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
    '';
  };  

  networking.useNetworkd = true;

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
    networks."external" = {
      name = "enp0s3";
      DHCP = "yes";
    };
  };
}
