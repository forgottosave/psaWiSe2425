{ config, pkgs, ... }:

{
  services.openldap = {
    enable = true;
    package = pkgs.openldap;
    mutableConfig = true;
    settings = {
        attrs = {
            olcLogLevel = "conns config";
            olcTLSCACertificateFile = "/etc/ssl/certs/ldap_ca.crt";
            olcTLSCertificateFile = "/etc/ssl/team03-ldap.crt";
            olcTLSCertificateKeyFile = "/etc/ssl/team03-ldap.key";
            olcTLSCipherSuite = "HIGH:MEDIUM"; #:+3DES:+RC4";
            olcTLSCRLCheck = "none";
            olcTLSVerifyClient = "never";
            olcTLSProtocolMin = "3.1";
        };
        children = {
            "cn=schema".includes = [
                "${pkgs.openldap}/etc/schema/core.ldif"
                "${pkgs.openldap}/etc/schema/cosine.ldif"
                "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
                "${pkgs.openldap}/etc/schema/nis.ldif"
            ];
        };
        children."olcDatabase={1}mdb".attrs = {
            objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];
            olcDatabase = {1}mdb;
            olcDbDirectory = "/var/lib/openldap/data";
            olcSuffix = "dc=team05,dc=psa,dc=cit,dc=tum,dc=de";

            olcRootDN = "cn=admin,dc=team03,dc=psa,dc=cit,dc=tum,dc=de";
            olcRootPW.path = /root/secrets/olcRootPW

            olcAccess = [
                ''{0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage by * none''
                ''{1}to attrs=sshPublicKey by self write by anonymous auth by * none''
                ''{2} to dn.children="ou=Users,dc=team03,dc=psa,dc=cit,dc=tum,dc=de" attrs=entry,uid by * read''
                ''{3}to * by users read by * search'' ];
        };
    };
  };
}
