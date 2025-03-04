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

nikto ist ein open soruce Webserver Scanner, der Webserver auf bekannte Sicherheitslücken und Schwachstellen scannt. Wir haben nikto auf allen webservern von vm6 mit `nikto -h http://web1.psa-team03.cit.tum.de -C all` ausgeführt. Dabei haben wir keine Sicherheitslücken gefunden haben aber ein paar warmings bekommen wobei bei http 2 warnungen und bei https noch zwei weitere warnungen aufgetreten sind. Die Warnungen waren:

- `X-Frame-Options header not set` welche dem browser sagt ob die webseite in einen frame oder iframe geladen werden darf. Zwar ist das für uns keine wirkliche relevante sicherheitslücke da wir keine sensitiven interaktionen auf der webseite haben. Die Lösung ist aber einfach ein `add_header X-Frame-Options "SAMEORIGIN";`in der nginx config hinzufügen weshalb wir dies auch gemacht haben.
- `X-Content-Type-Options header not set` welche gegen gewisse XSS Angriffe als auch vor Missinterpretationen des Content-Types schützt. Auch hier ist die Lösung einfach ein `add_header X-Content-Type-Options "nosniff";` in der nginx config hinzufügen weshalb wir dies auch gemacht haben.
- als nächstes wurde angekreidet das wir HSTS nicht aktiviert haben. HSTS ist ein header welcher dem browser sagt das er die seite nur über https laden soll. Da die Webserver aber laut Aufgabenstellung auch unter http erreichbar sein sollen haben wir dies nicht gemacht.
- als letztes wurde bemängelt das es sich beim SSL Zertifikat um ein Wildcard Zertifikat handelt. Dies ist zwar nicht unsicher aber es wird empfohlen für kritische subdomains individuelle Zertifikate zu verwenden. Da wir aber keine kritischen subdomains haben und dies auch so von der Aufgabenstellung vorgegeben ist haben wir dies nicht geändert.

Das tool ist durachaus nützlich um sicherheitslücken in webservern zu finden war aber in unseren Fall nicht all zu hilfreich da unsere Webserver sher simple sind und keine kritischen daten enthalten.

andere teams:

- team 1: 
- team 2:

### 2. Dokumentation gefundener Sicherheitslücken

#### 2.1. Eigene VMs, local exploit

#### 2.2. Eigene VMs, remote exploit

#### 2.3. Andere VMs, local exploit

#### 2.4. Andere VMs, remote exploit

### 3. Schließung gefundener Sicherheitslücken und Sicherheitsmaßnahmen

- `aideinit` als Intrusion Detection System
