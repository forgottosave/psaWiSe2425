{config, pkgs, ... }:   
{
  users.groups.students.gid = 1000;

  #Team1  
  users.users.ge95vir = {  
    isNormalUser  = true;  
    home  = "/home/ge95vir";  
    uid = 1010;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXPasCKmYHeTJ06DBWXCaYYUVM/Euo+X5tU0WpGWxRt gedeon.lenz@tum.de" ];  
  };  
  users.users.ge43fim = {  
    isNormalUser  = true;  
    home  = "/home/ge43fim";  
    uid = 1011;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "" ];  
  };  
  #Team2  
  users.users.ge78nes = {  
    isNormalUser  = true;  
    home  = "/home/ge78nes";  
    uid = 1020;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8UlkVfMHSKssjMGGDOi79yNQC1OT81XB8fMk8EE9Mb nastja@w205-2c-v4.eduroam.dynamic.rbg.tum.de" ];  
  };  
  users.users.ge96hoj = {  
    isNormalUser  = true;  
    home  = "/home/ge96hoj";  
    uid = 1021;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJUNGYlJSPF3pallfNKZoalknfH2Ep115DAJ0rxgqO6P louis@louis-ubuntu-2024" ];  
  };  
  #Team3  
  users.users.ge78zig = {  
    isNormalUser  = true;  
    home  = "/home/ge78zig";  
    uid = 1030;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFKywkjovjz87VQHeNVSGUlc/5Nl4eH4Hj1SrYHIeqM" ];  
  };  
  users.users.ge96xok = {  
    isNormalUser  = true;  
    home  = "/home/ge96xok";  
    uid = 1031;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwkCLE+pDy8HvHy98MwsNH/sxPYmBRXuREOd2jTMXPV timon.ensel@tum.de" ];  
  };  
  #Team4  
  users.users.ge87yen = {  
    isNormalUser  = true;  
    home  = "/home/ge87yen";  
    uid = 1040;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNOSacJR2QmqoyuTLVb7HMNceyZ1iJMysrLelGbKdt2 joana.arguirova@tum.de" ];  
  };  
  users.users.ge47sof = {  
    isNormalUser  = true;  
    home  = "/home/ge47sof";  
    uid = 1041;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH28yN3KD2y7WNss5Kko8C8t0JShA2fMaFuqA4SD0xKB manuela.rosenlehner@tum.de" ];  
  };  
  #Team5  
  users.users.ge47kut = {  
    isNormalUser  = true;  
    home  = "/home/ge47kut";  
    uid = 1050;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAF16c1yC1VO+Y3edoOpRGMnPTbwXnhQC3IFyT+8Rrvl oliver.duerer@tum.de" ];  
  };  
  users.users.ge87liq = {  
    isNormalUser  = true;  
    home  = "/home/ge87liq";  
    uid = 1051;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqLECy9QVF4zJsPg/EqwHjDfBI1cid5XQquwCVf2xcR christian.krinitsin@tum.de" ];  
  };  
  #Team6  
  users.users.ge59pib = {  
    isNormalUser  = true;  
    home  = "/home/ge59pib";  
    uid = 1060;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTyrsqSn9oAlqyThh1VoIqLoOzNV5a9IAeERC09fAFU im-in-your-walls" ];  
  };  
  users.users.ge65peq = {  
    isNormalUser  = true;  
    home  = "/home/ge65peq";  
    uid = 1061;  
    group = "students";  
    openssh.authorizedKeys.keys  = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBKmGZBpo2o5HMwSCOLVuznuaZ0ZdJgedaRyTYFxJzEK christian.sommer@tum.de" ];  
  };
 #Team7  
  users.users.ge63gut = {    
    isNormalUser = true;    
    home = "/home/ge63gut";    
    uid = 1070;  
    group = "students";  
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqGJj/qaJn7hULwBvUBdxwSij5dJ1l1ErFmYj8b7aVh sina.mozaffari-tabar@tum.de" ];  
  };  
  users.users.ge64baw = {    
    isNormalUser = true;    
    home = "/home/ge64baw";    
    uid = 1071;    
    group = "students";    
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID74Bxdsa6oQATpMu6sPJ/49J8KcG3wHDz2Wsgk8n+ZE mostafa.nejati.hatamian@tum.de" ];  
  };  
  #Team8  
  users.users.ge84zoj = {    
    isNormalUser = true;    
    home = "/home/ge84zoj";    
    uid = 1080;  
    group = "students";    
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP11LUlgDrjK7Bf3jwmQuuUKkWLRgDXNPx9g4sn1+iC7 bjarne.hansen@proton.me" ];  
  };  
  users.users.ge94bob = {    
    isNormalUser = true;    
    home = "/home/ge94bob";    
    uid = 1081;  
    group = "students";    
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIgT4clpBTjp7UeMqP/Qy1mchYBYAZPWuZ0xr9ZOiviG fabianluca.schulz@tum.de" ];  
  };  
  #Team9    
  users.users.ge87huk = {    
    isNormalUser = true;    
    home = "/home/ge87huk";    
    uid = 1090;  
    group = "students";    
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGeIYnWtdhXEbQ+ZxiEd9Ad5/C4BdK60G8k7fJ4XAu34 ge87huk@mytum.de" ];  
  };  
  users.users.ge64wug = {    
    isNormalUser = true;    
    home = "/home/ge64wug";    
    uid = 1091;  
    group = "students";  
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEN53t0LaDrA2zQtW6jIk5xAndloBe09rXfbaS6QwXq+ sophie@Sophies-Mac.fritz.box" ];  
  };  
  #Team10  
  users.users.ge65hog = {    
    isNormalUser = true;  
    home = "/home/ge65hog";  
    uid = 1100;  
    group = "students";  
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeWH4TQsfrcYjQWCylMHqOy3y/RsaahdAI0QdkiyUXJ katharina.schmenn@tum.de" ];  
  };  
  users.users.ge38hoy = {  
    isNormalUser = true;  
    home = "/home/ge38hoy";  
    uid = 1101;  
    group = "students";  
    openssh.authorizedKeys.keys = [ "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK4f12ldfJGJhMUbAYOz5E3aXc+F6SScLb2n2KdVfqu4AAAAC3NzaDp0ZXJtaXVz" ];  
  };  
}