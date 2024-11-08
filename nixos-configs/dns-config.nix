{ pkgs, ... }:
{
  services.bind = {
    enable = true;
    zones = {
      "psa-team03.cit.tum.de" = {
        master = true;
        file = pkgs.writeText "zone-psa-team03.cit.tum.de" ''
          $ORIGIN psa-team03.cit.tum.de.
          $TTL    1h
          @            IN      SOA     router hostmaster (
                                           1    ; Serial
                                           3h   ; Refresh
                                           1h   ; Retry
                                           1w   ; Expire
                                           1h)  ; Negative Cache TTL
                       IN      NS      vm1
                       IN      NS      vm2

          @            IN      A       192.168.3.3

          router       IN      A       192.168.3.3

          vm1          IN      A       192.168.3.1

          vm2          IN      A       192.168.3.2
        '';
      };
    };
  };
}
