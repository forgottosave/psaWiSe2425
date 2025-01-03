{ config, lib, pkgs, ... }:
{
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      ARRAY /dev/md127 metadata=1.2 UUID=d6e68de0:d5c8423f:715c48b0:f61316f8
    '';
  };

  fileSystems."/export" = {
    device = "/dev/md127";
    fsType = "ext4";
  };
}
