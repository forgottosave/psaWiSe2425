{config, pkgs, ... }:   
{
  networking = {
   interfaces.enp0s8 = {
	ipv4.addresses = [
	  { address = "192.168.3.1"; prefixLength = 24; } #bzw .2 für vm2
	];
	ipv4.routes = [
	  { address = "192.168.1.0"; prefixLength = 24; via = "192.168.31.1"; }
	  { address = "192.168.2.0"; prefixLength = 24; via = "192.168.32.1"; }
	  { address = "192.168.4.0"; prefixLength = 24; via = "192.168.41.1"; }
	  { address = "192.168.5.0"; prefixLength = 24; via = "192.168.51.1"; }
	  { address = "192.168.6.0"; prefixLength = 24; via = "192.168.61.1"; }
	  { address = "192.168.7.0"; prefixLength = 24; via = "192.168.71.1"; }
	  { address = "192.168.8.0"; prefixLength = 24; via = "192.168.81.1"; }
	  { address = "192.168.9.0"; prefixLength = 24; via = "192.168.91.1"; }
	  { address = "192.168.10.0"; prefixLength = 24; via = "192.168.101.1"; }
	];
   };
  };
}