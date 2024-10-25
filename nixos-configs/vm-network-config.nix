{config, pkgs, ... }:   
{
  networking = {
    firewall.extraCommands = '' 
      # by default: Drop all packages (in and outgoing) 
      iptables -P INPUT DROP 
      iptables -P FORWARD DROP 
      iptables -P OUTPUT DROP

      # by default: Disable connection tracking for HTTP and HTTPS
      iptables -t raw -A PREROUTING -p tcp --dport 80 -j NOTRACK  
      iptables -t raw -A OUTPUT -p tcp --sport 80 -j NOTRACK
      iptables -t raw -A PREROUTING -p tcp --dport 443 -j NOTRACK 
      iptables -t raw -A OUTPUT -p tcp --sport 443 -j NOTRACK

      # Allow: loopback
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A OUTPUT -o lo -j ACCEPT

      # Allow established/related connections
      iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


      # --- SSH (access to the router) ---
      iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

      # --- ICMP --- 
      iptables -A INPUT -p icmp -j ACCEPT
      iptables -A OUTPUT -p icmp -j ACCEPT

      # --- DNS (client) ---
      iptables -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

      # --- DHCP (client) ---
      iptables -A OUTPUT -p udp --dport 67 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 68 -m conntrack --ctstate NEW -j ACCEPT

      # --- HTTP/HTTPS (client) ---       
      iptables -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT


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
      # wpad proxy
      iptables -A OUTPUT -d 129.187.254.50 -j ACCEPT
      iptables -A OUTPUT -d 129.187.254.49 -j ACCEPT 
      # git (https://serverfault.com/questions/682373/setting-up-iptables-filter-to-allow-git)
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

      %%firewall%%

      # --- Database (client) ---
      iptables -A OUTPUT -p tcp --sport 5432 -m conntrack --ctstate NEW -j ACCEPT

      # --- NFS (client) ---
      iptables -A OUTPUT -p tcp --dport 111 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 111 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 2049 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 2049 -m conntrack --ctstate NEW -j ACCEPT

      # --- Samba (client) ---
      iptables -A OUTPUT -p udp --dport 137 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 138 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 139 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 445 -m conntrack --ctstate NEW -j ACCEPT

      # --- Mail (client) ---
      # sending of mail
      iptables -A OUTPUT -p tcp --dport 25 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 587 -m conntrack --ctstate NEW -j ACCEPT
      # retrieval of mail
      iptables -A OUTPUT -p tcp --dport 143 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 993 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 110 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 995 -m conntrack --ctstate NEW -j ACCEPT

      # --- LDAP (client) ---
      iptables -A OUTPUT -p tcp --dport 389 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 636 -m conntrack --ctstate NEW -j ACCEPT

      # --- prometheus (exporter/server) ---
      iptables -A INPUT -p tcp --dport 9100 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9101 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9090 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9330 -s 192.168.3.10 -j ACCEPT  # ldap
      iptables -A INPUT -p tcp --dport 9153 -s 192.168.3.10 -j ACCEPT  # coredns
      iptables -A INPUT -p tcp --dport 8080 -s 192.168.3.10 -j ACCEPT  # cadvisor
    '';
  };  

  networking.useNetworkd = true;
  networking.proxy.noProxy = "localhost,127.0.0.1,192.168.0.0/16,.cit.tum.de";

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
