{ config, lib, pkgs, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "logind"
      "systemd"
    ];
    disabledCollectors = [
      "textfile"
    ];
    openFirewall = true;
  };
  services.prometheus.exporters.kea = {
    enable = true;
    targets = ["/run/kea/kea-dhcp4.socket"];
    port = 9101;
  };
}