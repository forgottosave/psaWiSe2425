{config, pkgs, ... }:   
{
  users.groups.students.gid = 1000;

  #Team1  
  users.users.ge95vir = {  
    isNormalUser = true;  
    home = "/home/ge95vir";  
    uid = 1010;  
    group = "students";  
    homeMode = "701";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXPasCKmYHeTJ06DBWXCaYYUVM/Euo+X5tU0WpGWxRt gedeon.lenz@tum.de" ];  
  };

  # Mount filesystems from NFS
  # Team 01
  fileSystems."/home/ge95vir" = {
    #device = "fileserver.psa-team01.cit.tum.de:/raid/psaraid/userdata/home/ge95vir";
    device = "192.168.3.8:/home/ge95vir";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
}
