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
#!/bin/bash

# define the IP range
ip_prefix="192.168.3."
start=1
end=10
temp_file=$(mktemp)

echo "Scanning IP range ${ip_prefix}${start}-${end}..."

# loop through IP range and perform nmap scan
for i in $(seq $start $end); do
    ip="${ip_prefix}${i}"
    echo "Scanning ${ip}..."
    nmap -oG - -p 1-65535 $ip | grep -v "^#" >> $temp_file
done

# print results
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
192.168.2.1     (ns.psa-team02.cit.tum.de)               22/open/tcp/ssh 53/open/tcp/domain 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.2     (vm2.psa-team02.cit.tum.de)              22/open/tcp/ssh 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.3     (vm3.psa-team02.cit.tum.de)              22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.4     (db.psa-team02.cit.tum.de)               22/open/tcp/ssh 3306/open/tcp/mysql 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.5     (dbm.psa-team02.cit.tum.de)              22/open/tcp/ssh 3306/open/tcp/mysql 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.6     (cloudserv.psa-team02.cit.tum.de)        22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.7     (fileserver.psa-team02.cit.tum.de)       22/open/tcp/ssh 111/open/tcp/rpcbind 139/open/tcp/netbios-ssn 445/open/tcp/microsoft-ds 2049/open/tcp/nfs 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.8     (ldap.psa-team02.cit.tum.de)             22/open/tcp/ssh 389/open/tcp/ldap 636/open/tcp/ldapssl 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.9     (mail.psa-team02.cit.tum.de)             22/open/tcp/ssh 25/open/tcp/smtp 110/open/tcp/pop3 143/open/tcp/imap 5666/open/tcp/nrpe 8123/open/tcp/polipo 
192.168.2.10    (due.psa-team02.cit.tum.de)              22/open/tcp/ssh 80/open/tcp/http 443/open/tcp/https 5666/open/tcp/nrpe 8123/open/tcp/polipo 
```


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
