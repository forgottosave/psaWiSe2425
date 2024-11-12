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
          @            IN      SOA     psa-team03.cit.tum.de. hostmaster (
                                           1    ; Serial
                                           3h   ; Refresh
                                           1h   ; Retry
                                           1w   ; Expire
                                           1h)  ; Negative Cache TTL
                       IN      NS      router
      
          3          IN      A       router.psa-team03.cit.tum.de.
      
          1          IN      A       vm1.psa-team03.cit.tum.de.
      
          2          IN      A       vm2.psa-team03.cit.tum.de.
        '';
      };
    };
  };
}
