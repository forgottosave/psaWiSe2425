{ config, lib, pkgs, ... }:
let
    baseDN = "dc=team03,dc=psa,dc=cit,dc=tum,dc=de";
    domain = "ldap.team03.psa.cit.tum.de";

    rootName = "admin";
    rootPw = "{SSHA}2z9hw3YwUr94eBUdGhUmcnZht0TyF7VW";

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
    };
}
