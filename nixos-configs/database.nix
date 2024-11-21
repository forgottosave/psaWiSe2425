{ inputs, ... }:
let 
  overlay-pgsql-unstable = final: prev: {
    pgsql = inputs.unstable.legacyPackages."x86_64-linux".postgresql;
  };
in
{
  imports = [
    { nixpkgs.overlays = [ overlay-pgsql-unstable ]; }
  ];
  
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [ "mydatabase" ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };
}