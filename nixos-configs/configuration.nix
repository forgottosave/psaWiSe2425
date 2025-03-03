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
  boot.kernelParams = ["ipv6.disable=1"]; # Disable ipv6

  # https://nixos.wiki/wiki/SSH_public_key_authentication
  services.openssh = {
    enable = true;                                  # Enable the OpenSSH daemon
    settings.PermitRootLogin = "prohibit-password";          # Disable root passwd login
    settings.PasswordAuthentication = false;                 # Disable password authentication
    # settings.PermitRootLogin = "yes";               # Enable root login
  };

  #networking.firewall.allowedTCPPorts = [ 22 ];
  networking.hostName = "vmpsateam03-%%vm%%";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Amsterdam";

  users.users."root".openssh.authorizedKeys.keys = [
    %%root_access%%
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    %%system_packages%%
  ];
  programs.mtr.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # accept our custom LDAP certificate
  security.pki.certificates = [''-----BEGIN CERTIFICATE-----
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
RSYoXOqWJ79mGqUfEOu/DVWZhC7Ystc=
-----END CERTIFICATE-----''];

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}
