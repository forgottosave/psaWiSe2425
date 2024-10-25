{ inputs, ... }:
let 
  overlay-kea-unstable = final: prev: {
    kea = inputs.unstable.legacyPackages."x86_64-linux".kea;
  };
in
{
  imports = [
    { nixpkgs.overlays = [ overlay-kea-unstable ]; }
  ];

  services.kea.dhcp4 = {
    enable = true;
    configFile = ./dhcp4-config.json;
  };
}