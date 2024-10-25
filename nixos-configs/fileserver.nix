{ config, lib, pkgs, ... }:
{
  # TODO ?
  #boot.swraid = {
  #  enable = true;
  #  mdadmConf = ''
  #    ARRAY /dev/md127 metadata=1.2 UUID=d6e68de0:d5c8423f:715c48b0:f61316f8
  #  '';
  #};
  
  # Mount RAID-group at /export
  fileSystems."/export" = {
    device = "/dev/md127";
    fsType = "ext4";
  };

  # add postgres user manually
  users.groups.postgres.gid = 71;
  users.users.postgres = {
    isSystemUser = true;
    home = "/home/postgres";
    uid = 71; # according to VM 4 postgres user id
    group = "postgres"; 
  };

  # enable nfs server
  services.nfs.server = {
    enable = true;
    createMountPoints = true;
    exports = ''
      /export                 192.168.0.0/16(rw,fsid=0,no_subtree_check)
      /export/home            192.168.0.0/16(rw,sync)
      /export/postgresql      192.168.3.4(rw,sync)
      /export/sites           192.168.3.6(rw,sync)
    '';
  };

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
}
