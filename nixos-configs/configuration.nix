# GNU nano 8.0                                                                                                                                                                                                                                                                                                                                                                                                                                                                  configuration.nix                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    %%imports%%
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # https://nixos.wiki/wiki/SSH_public_key_authentication
  services.sshd.enable = true;
  services.openssh = {
      enable = true;                                  # Enable the OpenSSH daemon
      PermitRootLogin = "prohibit-password";          # Disable root passwd login
      PasswordAuthentication = false;                 # Disable password authentication
      settings.KbdInteractiveAuthentication = false;  # Disable keyboard-interactive authentication
      settings.PermitRootLogin = "yes";               # Enable root login
  };

  #networking.firewall.allowedTCPPorts = [ 22 ];
  networking.hostName = "vmpsateam03-0%%vm%%";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Amsterdam";

  users.users."root".openssh.authorizedKeys.keys = [
    %%root_access%%
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # default suggestions: vim wget
    git
    # network tools
    nmap
    tcpdump
    traceroute
    tcptraceroute
    bind
    dhcping
  ];
  programs.mtr.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05"; # Did you read the comment?

}
