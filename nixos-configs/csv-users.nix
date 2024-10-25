{config, pkgs, ... }:
{
  users.groups.students.gid = 1000;
  #users.users.rimme = {  
  #  isNormalUser = true;  
  #  home = "/home/rimme";  
  #  uid = 10000;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/rimme" = {
    device = "192.168.3.8:/home/rimme";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.seide = {  
  #  isNormalUser = true;  
  #  home = "/home/seide";  
  #  uid = 10001;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/seide" = {
    device = "192.168.3.8:/home/seide";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.hegen = {  
  #  isNormalUser = true;  
  #  home = "/home/hegen";  
  #  uid = 10002;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/hegen" = {
    device = "192.168.3.8:/home/hegen";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.bruec = {  
  #  isNormalUser = true;  
  #  home = "/home/bruec";  
  #  uid = 10003;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/bruec" = {
    device = "192.168.3.8:/home/bruec";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.schra = {  
  #  isNormalUser = true;  
  #  home = "/home/schra";  
  #  uid = 10004;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/schra" = {
    device = "192.168.3.8:/home/schra";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.trayk = {  
  #  isNormalUser = true;  
  #  home = "/home/trayk";  
  #  uid = 10005;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/trayk" = {
    device = "192.168.3.8:/home/trayk";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.wangn = {  
  #  isNormalUser = true;  
  #  home = "/home/wangn";  
  #  uid = 10006;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/wangn" = {
    device = "192.168.3.8:/home/wangn";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.georg = {  
  #  isNormalUser = true;  
  #  home = "/home/georg";  
  #  uid = 10007;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/georg" = {
    device = "192.168.3.8:/home/georg";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.shulm = {  
  #  isNormalUser = true;  
  #  home = "/home/shulm";  
  #  uid = 10008;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/shulm" = {
    device = "192.168.3.8:/home/shulm";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.enges = {  
  #  isNormalUser = true;  
  #  home = "/home/enges";  
  #  uid = 10009;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/enges" = {
    device = "192.168.3.8:/home/enges";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.fengj = {  
  #  isNormalUser = true;  
  #  home = "/home/fengj";  
  #  uid = 10010;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/fengj" = {
    device = "192.168.3.8:/home/fengj";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.witte = {  
  #  isNormalUser = true;  
  #  home = "/home/witte";  
  #  uid = 10011;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/witte" = {
    device = "192.168.3.8:/home/witte";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.riedr = {  
  #  isNormalUser = true;  
  #  home = "/home/riedr";  
  #  uid = 10012;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/riedr" = {
    device = "192.168.3.8:/home/riedr";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.pluda = {  
  #  isNormalUser = true;  
  #  home = "/home/pluda";  
  #  uid = 10013;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/pluda" = {
    device = "192.168.3.8:/home/pluda";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.braun = {  
  #  isNormalUser = true;  
  #  home = "/home/braun";  
  #  uid = 10014;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/braun" = {
    device = "192.168.3.8:/home/braun";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.ottin = {  
  #  isNormalUser = true;  
  #  home = "/home/ottin";  
  #  uid = 10015;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/ottin" = {
    device = "192.168.3.8:/home/ottin";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.wiesn = {  
  #  isNormalUser = true;  
  #  home = "/home/wiesn";  
  #  uid = 10016;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/wiesn" = {
    device = "192.168.3.8:/home/wiesn";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.heusl = {  
  #  isNormalUser = true;  
  #  home = "/home/heusl";  
  #  uid = 10017;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/heusl" = {
    device = "192.168.3.8:/home/heusl";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.cebul = {  
  #  isNormalUser = true;  
  #  home = "/home/cebul";  
  #  uid = 10018;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/cebul" = {
    device = "192.168.3.8:/home/cebul";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.mitte = {  
  #  isNormalUser = true;  
  #  home = "/home/mitte";  
  #  uid = 10019;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/mitte" = {
    device = "192.168.3.8:/home/mitte";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.pfeff = {  
  #  isNormalUser = true;  
  #  home = "/home/pfeff";  
  #  uid = 10020;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/pfeff" = {
    device = "192.168.3.8:/home/pfeff";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.atten = {  
  #  isNormalUser = true;  
  #  home = "/home/atten";  
  #  uid = 10021;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/atten" = {
    device = "192.168.3.8:/home/atten";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.grotz = {  
  #  isNormalUser = true;  
  #  home = "/home/grotz";  
  #  uid = 10022;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/grotz" = {
    device = "192.168.3.8:/home/grotz";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.zinsl = {  
  #  isNormalUser = true;  
  #  home = "/home/zinsl";  
  #  uid = 10023;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/zinsl" = {
    device = "192.168.3.8:/home/zinsl";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.kochn = {  
  #  isNormalUser = true;  
  #  home = "/home/kochn";  
  #  uid = 10024;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/kochn" = {
    device = "192.168.3.8:/home/kochn";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.verik = {  
  #  isNormalUser = true;  
  #  home = "/home/verik";  
  #  uid = 10025;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/verik" = {
    device = "192.168.3.8:/home/verik";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.sieve = {  
  #  isNormalUser = true;  
  #  home = "/home/sieve";  
  #  uid = 10026;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/sieve" = {
    device = "192.168.3.8:/home/sieve";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.mehne = {  
  #  isNormalUser = true;  
  #  home = "/home/mehne";  
  #  uid = 10027;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/mehne" = {
    device = "192.168.3.8:/home/mehne";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.brand = {  
  #  isNormalUser = true;  
  #  home = "/home/brand";  
  #  uid = 10028;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/brand" = {
    device = "192.168.3.8:/home/brand";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.fisch = {  
  #  isNormalUser = true;  
  #  home = "/home/fisch";  
  #  uid = 10029;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/fisch" = {
    device = "192.168.3.8:/home/fisch";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.heinz = {  
  #  isNormalUser = true;  
  #  home = "/home/heinz";  
  #  uid = 10030;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/heinz" = {
    device = "192.168.3.8:/home/heinz";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.schmo = {  
  #  isNormalUser = true;  
  #  home = "/home/schmo";  
  #  uid = 10031;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/schmo" = {
    device = "192.168.3.8:/home/schmo";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.catom = {  
  #  isNormalUser = true;  
  #  home = "/home/catom";  
  #  uid = 10032;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/catom" = {
    device = "192.168.3.8:/home/catom";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.popee = {  
  #  isNormalUser = true;  
  #  home = "/home/popee";  
  #  uid = 10033;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/popee" = {
    device = "192.168.3.8:/home/popee";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.navar = {  
  #  isNormalUser = true;  
  #  home = "/home/navar";  
  #  uid = 10034;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/navar" = {
    device = "192.168.3.8:/home/navar";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.beckc = {  
  #  isNormalUser = true;  
  #  home = "/home/beckc";  
  #  uid = 10035;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/beckc" = {
    device = "192.168.3.8:/home/beckc";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.liuli = {  
  #  isNormalUser = true;  
  #  home = "/home/liuli";  
  #  uid = 10036;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/liuli" = {
    device = "192.168.3.8:/home/liuli";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.lindl = {  
  #  isNormalUser = true;  
  #  home = "/home/lindl";  
  #  uid = 10037;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/lindl" = {
    device = "192.168.3.8:/home/lindl";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.becke = {  
  #  isNormalUser = true;  
  #  home = "/home/becke";  
  #  uid = 10038;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/becke" = {
    device = "192.168.3.8:/home/becke";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.weinb = {  
  #  isNormalUser = true;  
  #  home = "/home/weinb";  
  #  uid = 10039;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/weinb" = {
    device = "192.168.3.8:/home/weinb";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.trana = {  
  #  isNormalUser = true;  
  #  home = "/home/trana";  
  #  uid = 10040;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/trana" = {
    device = "192.168.3.8:/home/trana";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.dobro = {  
  #  isNormalUser = true;  
  #  home = "/home/dobro";  
  #  uid = 10041;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/dobro" = {
    device = "192.168.3.8:/home/dobro";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.rooto = {  
  #  isNormalUser = true;  
  #  home = "/home/rooto";  
  #  uid = 10042;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/rooto" = {
    device = "192.168.3.8:/home/rooto";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.helle = {  
  #  isNormalUser = true;  
  #  home = "/home/helle";  
  #  uid = 10043;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/helle" = {
    device = "192.168.3.8:/home/helle";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.goelm = {  
  #  isNormalUser = true;  
  #  home = "/home/goelm";  
  #  uid = 10044;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/goelm" = {
    device = "192.168.3.8:/home/goelm";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.ruedi = {  
  #  isNormalUser = true;  
  #  home = "/home/ruedi";  
  #  uid = 10045;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/ruedi" = {
    device = "192.168.3.8:/home/ruedi";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.klein = {  
  #  isNormalUser = true;  
  #  home = "/home/klein";  
  #  uid = 10046;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/klein" = {
    device = "192.168.3.8:/home/klein";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.huber = {  
  #  isNormalUser = true;  
  #  home = "/home/huber";  
  #  uid = 10047;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/huber" = {
    device = "192.168.3.8:/home/huber";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.stein = {  
  #  isNormalUser = true;  
  #  home = "/home/stein";  
  #  uid = 10048;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/stein" = {
    device = "192.168.3.8:/home/stein";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.wuche = {  
  #  isNormalUser = true;  
  #  home = "/home/wuche";  
  #  uid = 10049;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/wuche" = {
    device = "192.168.3.8:/home/wuche";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.treml = {  
  #  isNormalUser = true;  
  #  home = "/home/treml";  
  #  uid = 10050;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/treml" = {
    device = "192.168.3.8:/home/treml";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.herzi = {  
  #  isNormalUser = true;  
  #  home = "/home/herzi";  
  #  uid = 10051;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/herzi" = {
    device = "192.168.3.8:/home/herzi";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.styna = {  
  #  isNormalUser = true;  
  #  home = "/home/styna";  
  #  uid = 10052;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/styna" = {
    device = "192.168.3.8:/home/styna";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.schmi = {  
  #  isNormalUser = true;  
  #  home = "/home/schmi";  
  #  uid = 10053;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/schmi" = {
    device = "192.168.3.8:/home/schmi";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.cruzc = {  
  #  isNormalUser = true;  
  #  home = "/home/cruzc";  
  #  uid = 10054;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/cruzc" = {
    device = "192.168.3.8:/home/cruzc";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.kentj = {  
  #  isNormalUser = true;  
  #  home = "/home/kentj";  
  #  uid = 10055;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/kentj" = {
    device = "192.168.3.8:/home/kentj";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.fache = {  
  #  isNormalUser = true;  
  #  home = "/home/fache";  
  #  uid = 10056;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/fache" = {
    device = "192.168.3.8:/home/fache";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.manov = {  
  #  isNormalUser = true;  
  #  home = "/home/manov";  
  #  uid = 10057;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/manov" = {
    device = "192.168.3.8:/home/manov";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.hanyt = {  
  #  isNormalUser = true;  
  #  home = "/home/hanyt";  
  #  uid = 10058;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/hanyt" = {
    device = "192.168.3.8:/home/hanyt";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.holst = {  
  #  isNormalUser = true;  
  #  home = "/home/holst";  
  #  uid = 10059;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/holst" = {
    device = "192.168.3.8:/home/holst";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.fuchs = {  
  #  isNormalUser = true;  
  #  home = "/home/fuchs";  
  #  uid = 10060;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/fuchs" = {
    device = "192.168.3.8:/home/fuchs";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.hausn = {  
  #  isNormalUser = true;  
  #  home = "/home/hausn";  
  #  uid = 10061;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/hausn" = {
    device = "192.168.3.8:/home/hausn";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.rempe = {  
  #  isNormalUser = true;  
  #  home = "/home/rempe";  
  #  uid = 10062;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/rempe" = {
    device = "192.168.3.8:/home/rempe";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.schlo = {  
  #  isNormalUser = true;  
  #  home = "/home/schlo";  
  #  uid = 10063;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/schlo" = {
    device = "192.168.3.8:/home/schlo";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.moell = {  
  #  isNormalUser = true;  
  #  home = "/home/moell";  
  #  uid = 10064;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/moell" = {
    device = "192.168.3.8:/home/moell";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.langi = {  
  #  isNormalUser = true;  
  #  home = "/home/langi";  
  #  uid = 10065;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/langi" = {
    device = "192.168.3.8:/home/langi";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.kollo = {  
  #  isNormalUser = true;  
  #  home = "/home/kollo";  
  #  uid = 10066;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/kollo" = {
    device = "192.168.3.8:/home/kollo";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.vossw = {  
  #  isNormalUser = true;  
  #  home = "/home/vossw";  
  #  uid = 10067;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/vossw" = {
    device = "192.168.3.8:/home/vossw";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.bader = {  
  #  isNormalUser = true;  
  #  home = "/home/bader";  
  #  uid = 10068;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/bader" = {
    device = "192.168.3.8:/home/bader";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.kilic = {  
  #  isNormalUser = true;  
  #  home = "/home/kilic";  
  #  uid = 10069;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/kilic" = {
    device = "192.168.3.8:/home/kilic";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.yorda = {  
  #  isNormalUser = true;  
  #  home = "/home/yorda";  
  #  uid = 10070;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/yorda" = {
    device = "192.168.3.8:/home/yorda";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.erdoe = {  
  #  isNormalUser = true;  
  #  home = "/home/erdoe";  
  #  uid = 10071;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/erdoe" = {
    device = "192.168.3.8:/home/erdoe";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.sandm = {  
  #  isNormalUser = true;  
  #  home = "/home/sandm";  
  #  uid = 10072;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/sandm" = {
    device = "192.168.3.8:/home/sandm";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.maier = {  
  #  isNormalUser = true;  
  #  home = "/home/maier";  
  #  uid = 10073;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/maier" = {
    device = "192.168.3.8:/home/maier";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.citom = {  
  #  isNormalUser = true;  
  #  home = "/home/citom";  
  #  uid = 10074;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/citom" = {
    device = "192.168.3.8:/home/citom";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.jiang = {  
  #  isNormalUser = true;  
  #  home = "/home/jiang";  
  #  uid = 10075;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/jiang" = {
    device = "192.168.3.8:/home/jiang";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.loehr = {  
  #  isNormalUser = true;  
  #  home = "/home/loehr";  
  #  uid = 10076;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/loehr" = {
    device = "192.168.3.8:/home/loehr";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.schle = {  
  #  isNormalUser = true;  
  #  home = "/home/schle";  
  #  uid = 10077;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/schle" = {
    device = "192.168.3.8:/home/schle";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.perro = {  
  #  isNormalUser = true;  
  #  home = "/home/perro";  
  #  uid = 10078;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/perro" = {
    device = "192.168.3.8:/home/perro";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.hallm = {  
  #  isNormalUser = true;  
  #  home = "/home/hallm";  
  #  uid = 10079;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/hallm" = {
    device = "192.168.3.8:/home/hallm";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.finis = {  
  #  isNormalUser = true;  
  #  home = "/home/finis";  
  #  uid = 10080;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/finis" = {
    device = "192.168.3.8:/home/finis";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.murat = {  
  #  isNormalUser = true;  
  #  home = "/home/murat";  
  #  uid = 10081;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/murat" = {
    device = "192.168.3.8:/home/murat";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.schne = {  
  #  isNormalUser = true;  
  #  home = "/home/schne";  
  #  uid = 10082;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/schne" = {
    device = "192.168.3.8:/home/schne";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.barza = {  
  #  isNormalUser = true;  
  #  home = "/home/barza";  
  #  uid = 10083;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/barza" = {
    device = "192.168.3.8:/home/barza";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.kaush = {  
  #  isNormalUser = true;  
  #  home = "/home/kaush";  
  #  uid = 10084;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/kaush" = {
    device = "192.168.3.8:/home/kaush";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.olsso = {  
  #  isNormalUser = true;  
  #  home = "/home/olsso";  
  #  uid = 10085;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/olsso" = {
    device = "192.168.3.8:/home/olsso";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
  #users.users.karsu = {  
  #  isNormalUser = true;  
  #  home = "/home/karsu";  
  #  uid = 10086;  
  #  group = "students";  
  #  homeMode = "701";
  #};
  fileSystems."/home/karsu" = {
    device = "192.168.3.8:/home/karsu";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600"];
  };
}
