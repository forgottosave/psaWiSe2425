{ config, lib, pkgs, ... }:
{
  ## DOCKER
  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "root" ];
  
  ## PROMETHEUS EXPORT
  #  Warning: Make sure that nc is installed on the VM, as it is not checked here!
  services.prometheus.exporters.script = {
    enable = true;
    port = 9100;
    settings.scripts = [
      # { name = "db-check"; script = "mysql -u team3 -p$mysqlRootPassword"; }
      { name = "db-check"; script = "nc -zv 192.168.4.5 3306"; }
    ];
  };
}
