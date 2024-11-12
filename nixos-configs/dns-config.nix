{ pkgs, ... }:
{
  services.bind = {
    enable = true;
    zones = {
      # OUR TEAM
      "psa-team03.cit.tum.de" = {
        master = true;
        file = pkgs.writeText "zone-psa-team03.cit.tum.de" ''
          $ORIGIN psa-team03.cit.tum.de.
          $TTL    1h
          @            IN      SOA     psa-team03.cit.tum.de. hostmaster (
                                           1    ; Serial
                                           3h   ; Refresh
                                           1h   ; Retry
                                           1w   ; Expire
                                           1h)  ; Negative Cache TTL
                       IN      NS      router
          
          router       IN      A       192.168.3.3
          
          vm1          IN      A       192.168.3.1
          
          vm2          IN      A       192.168.3.2
        '';
      };
      # OUR TEAM - reverse
      "3.168.192.in-addr.arpa" = {
        master = true;
        file = pkgs.writeText "zone-3.168.192.in-addr.arpa" ''
          $TTL    1h
          @            IN      SOA     psa-team03.cit.tum.de. hostmaster.psa-team03.cit.tum.de. (
                                           1    ; Serial
                                           3h   ; Refresh
                                           1h   ; Retry
                                           1w   ; Expire
                                           1h)  ; Negative Cache TTL
                       IN      NS      router.psa-team03.cit.tum.de.
      
          3          IN      PTR       router.psa-team03.cit.tum.de.
      
          1          IN      PTR       vm1.psa-team03.cit.tum.de.
      
          2          IN      PTR       vm2.psa-team03.cit.tum.de.
        '';
      };
      # OTHER TEAMS
      #"psa-team01.cit.tum.de" = {
      #  master = true;
      #  file = "";
      #  extraConfig = "forward only;\nforwarders { 192.168.1.1; };";
      #};
    };
    extraConfig = ''
      zone "psa-team01.cit.tum.de" {
        type forward;
        forward only;
        forwarders { 192.168.1.1; };
      };
      '';
  };
}
