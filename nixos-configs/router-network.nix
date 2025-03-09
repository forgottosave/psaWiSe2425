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

      # --- DNS (server) --- 
      iptables -A INPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A INPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

      # --- DNS (client) --- 
      #iptables -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
      #iptables -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

      # --- DHCP (server) ---
      iptables -A INPUT -p udp --dport 67 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A INPUT -p udp --dport 68 -m conntrack --ctstate NEW -j ACCEPT

      # --- HTTP/HTTPS (client) ---       
      iptables -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

      # --- Forwarding between networks ---
      iptables -A FORWARD -i enp0s8 -s 192.168.3.0/24 -d 192.168.0.0/16 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -s 192.168.0.0/16 -d 192.168.3.0/24 -j ACCEPT 
   

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
      # git (https://serverfault.com/questions/682373/setting-up-iptables-filter-to-allow-git)
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT


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
