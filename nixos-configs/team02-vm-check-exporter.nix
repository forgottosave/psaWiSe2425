# TODO probably rename this file to `monitoring-config.nix`

{ config, lib, pkgs, ... }:
{
  ## DOCKER
  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "root" ];
  
  ## ALERT MANAGER
  #services.prometheus.alertmanager = {
  #  enable = true;
  #  port = 9093;
  #  configText = ''                                              
  #    route:
  #      receiver: tutorial-alert-manager
  #      repeat_interval: 1m
  #    receivers:
  #      - name: 'tutorial-alert-manager'
  #        email_configs:
  #          - to: 'tutorial.inbox@gmail.com'
  #            from: 'tutorial.outbox@gmail.com'
  #            smarthost: 'smtp.gmail.com:587'
  #            auth_username: 'username'
  #            auth_password: 'password'
  #  '';
  #}

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
