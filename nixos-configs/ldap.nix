{ config, pkgs, ... }:
let
    baseDN = "dc=team03,dc=psa,dc=cit,dc=tum,dc=de";
    domain = "ldap.team03.psa.cit.tum.de";

    rootName = "admin";
    rootPw = "{SSHA}2z9hw3YwUr94eBUdGhUmcnZht0TyF7VW"; # ldapadmin123

    ssl.crtFile = "/etc/ssl/openldap/slapd.crt";
    ssl.keyFile = "/etc/ssl/openldap/slapd.key";
in
{
    services.openldap = {
        enable = true;
        package = pkgs.openldap;
        urlList = ["ldapi:///" "ldaps:///"];
        mutableConfig = true;
        settings = {
            attrs = {
                olcLogLevel = ["stats" "conns" "config" "acl"];
                olcTLSCertificateFile = ssl.crtFile;
                olcTLSCertificateKeyFile = ssl.keyFile;
                olcTLSProtocolMin = "3.3";
                olcTLSCipherSuite = "DEFAULT:!kRSA:!kDHE";
            };
            children = {
                "olcDatabase={1}mdb".attrs = {
                    objectClass = ["olcDatabaseConfig" "olcMdbConfig"];
                    olcDatabase = "{1}mdb";
                    olcSuffix = baseDN;
                    olcRootDN = "cn=${rootName},${baseDN}";
                    olcRootPW = rootPw;
                    olcDbDirectory = "/var/lib/openldap/data";
                    olcAccess = [
                        # root access
                        ''
                          {0}to *
                           by dn.exact=uidNumber=0+gidNumber=0,cn=peercred,cn=external,cn=auth manage
                           by * break
                        ''
                        # sssd
                        ''
                         {1}to *
                          by dn.exact=cn=sssd,${baseDN} read
                          by * break
                        ''
                        # bind and change password
                        ''
                         {2}to attrs=userPassword
                          by anonymous auth
                          by self write
                          by * none
                        ''
                        # anonymous UID search access
                        ''
                         {3}to attrs=entry,uid
                          by * read
                        ''
                        # share certificates
                        ''
                         {4}to attrs=userCertificate
                          by users read
                          by * none
                        ''
                        # self access
                        ''
                         {5}to *
                          by self read
                          by * none
                        ''
                    ];
                };
                "cn=schema".includes = [
                    # required
                    "${pkgs.openldap}/etc/schema/core.ldif"
                    # NIS
                    "${pkgs.openldap}/etc/schema/cosine.ldif"
                    "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
                    # posixAccount & posixGroup
                    "${pkgs.openldap}/etc/schema/nis.ldif"
                    # custom users
                    ./user-schema.ldif
                ];
            };  
        };

        #settings = {
        #    attrs = {
        #        olcLogLevel = "conns config";
        #        olcTLSCACertificateFile = "/etc/ssl/certs/ldap_ca.crt";
        #        olcTLSCertificateFile = "/etc/ssl/team03-ldap.crt";
        #        olcTLSCertificateKeyFile = "/etc/ssl/team03-ldap.key";
        #        olcTLSCipherSuite = "HIGH:MEDIUM"; #:+3DES:+RC4";
        #        olcTLSCRLCheck = "none";
        #        olcTLSVerifyClient = "never";
        #        olcTLSProtocolMin = "3.1";
        #    };
        #    children = {
        #        "cn=schema".includes = [
        #            "${pkgs.openldap}/etc/schema/core.ldif"
        #            "${pkgs.openldap}/etc/schema/cosine.ldif"
        #            "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
        #            "${pkgs.openldap}/etc/schema/nis.ldif"
        #        ];
        #    };
        #    children."olcDatabase={1}mdb".attrs = {
        #        objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];
        #        olcDatabase = "{1}mdb";
        #        olcDbDirectory = "/var/lib/openldap/data";
        #        olcSuffix = "dc=team03,dc=psa,dc=cit,dc=tum,dc=de";
        #
        #        olcRootDN = "cn=admin,dc=team03,dc=psa,dc=cit,dc=tum,dc=de";
        #        olcRootPW.path = "/root/secrets/olcRootPW";
        #
        #        olcAccess = [
        #            ''{0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth,cn=config" manage by * none''
        #            ''{1}to attrs=sshPublicKey by self write by anonymous auth by * none''
        #            ''{2} to dn.children="ou=Users,dc=team03,dc=psa,dc=cit,dc=tum,dc=de" attrs=entry,uid by * read''
        #            ''{3}to * by users read by * search'' ];
        #    };
        #};
    };

    #services.portunus = {
    #    enable = true;
    #    user = "root";
    #    group = "root";
    #    domain = "portunus.team03.psa.cit.tum.de";
    #    # TODO seedPath = ... (create users)
    #    ldap.tls = true;
    #    ldap.suffix = "dc=team03,dc=psa,dc=cit,dc=tum,dc=de";
    #    ldap.searchUserName = "admin";
    #};
}

#{
#  config,
#  lib,
#  pkgs,
# ...
#}: let
# # suffix for the database carrying all data entries
# baseDN = "dc=team03,dc=psa,dc=cit,dc=tum,dc=de";
# domain = "ldap.team03.psa.cit.tum.de";
#in {
# options = {
#    psa.ldap.server = {
#     enable = lib.mkEnableOption "OpenLDAP server";
#     baseDN = lib.mkOption {
#       type = lib.types.str;
#       default = baseDN;
#       description = "Base DN for the LDAP server";
#      };
#     serverDomain = lib.mkOption {
#       type = lib.types.str;
#       default = domain;
#       description = "URL for the LDAP server";
#      };
#    };
#  };
#
# config = lib.mkIf config.psa.ldap.server.enable {
#    services.openldap = {
#     enable = true;
#
#     # Only allow secure connections
#     urlList = ["ldapi:///" "ldaps:///"];
#
#     # ...
#    };
#  };
#}
