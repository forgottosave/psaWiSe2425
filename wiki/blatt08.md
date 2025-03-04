# Aufgabenblatt 08

In diesem Blatt geht es darum einen LDAP Server (VM 7) einzurichten und diesen von allen VMs für die Nutzer Authentifizierung zu nutzen.

## Teilaufgaben

**Alles noch TODO...**

### 0) Notizen

Lösungsansätze:

- [x] **FAILED** Anleitung: Fehler bei Einlesen con base.ldif
    `sudo ldapadd -H ldapi:// -Y EXTERNAL -f base.ldif`

    ```shell
    adding new entry "dc=team03,dc=psa,dc=cit,dc=tum,dc=de"
    ldap_add: Invalid DN syntax (34)
           additional info: invalid DN
    ```

    Schon 2-mal von vorne versucht...
    Hab es nicht hinbekommen das Problem zu lösen, weiß nicht was schief läuft.
    Wenn man das hinbekommen würde wäre das hier ein möglicher Lösungsansatz...
    Optional auch erstmal ohne SSL. Schauen ob das klappt?

    Idee: vielleicht liegt das an irendwelchen DNS geschichten? needs investigation

- [ ] Dieser Arch-Linux LDAP Anleitung folgen: https://wiki.archlinux.org/title/OpenLDAP
    Optional auch erstmal ohne SSL. Schauen ob das klappt?

- [ ] Einrichten auf einem nicht-NixOS System & hoffen dass man es da hinbekommt (mehr Anleitungen, Quellen, etc.)
    Benötigt allerdings das Einrichten einer neuen nicht NixOS-VM, mit samt Nutzern, DNS, etc.
    Wäre vermutlich mehr Aufwand als es irgendiwe auf NixOS hinzukommen. Wäre nur ne Notfall-Lösung...
