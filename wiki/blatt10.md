# Aufgabenblatt 10

In diesem Blatt geht es darum, alle bisher erstellten Systeme zentral zu überwachen und bei Bedarf über Fehler informiert zu werden.
Um dies umzusetzen, haben wir uns für Prometheus und Grafana entschieden, wobei Prometheus die Metriken sammelt und Grafana diese visualisiert.

Aufgaben:

1. Installation von Prometheus und Grafana
2. Überwachung der Dienste:
    1. Betriebssystem -> Ping, CPU Load, Prozesse
    2. Netzwerk -> Router up, Ping eigene Team-VMs, Ping andere Team-VMs
    3. DNS -> Verfügbarkeit, prüfe, ob Domain-Tests auflöst, Anzahl Anfragen
    4. DHCP -> Verfügbarkeit, Anzahl Anfragen
    5. Webserver -> Verfügbarkeit (HTTP & HTTPS), Ladezeit, Anzahl Anfragen
    6. Datenbank -> Verfügbarkeit (eigene & Team X), Anzahl Anfragen
    7. Webanwendung -> Verfügbarkeit, Ladezeit, Anzahl Anfragen
    8. Fileserver -> Freien Speicherplatz
    9. LDAP -> Verfügbarkeit, Anzahl Anfragen
    10. Mail -> Länge der Warteschlange
3. Alarmierung bei Fehlern aber auch mit alternative zum Mailserver
4. Testen

## Teilaufgaben

### 1. Installation

#### 1.1) Konfiguration von Nixos

Zum Deployen von Prometheus und Grafana haben wir uns entschieden, Docker zu verwenden. Dafür haben wir zunächst das `docker-compose`-Paket zur `configuration.nix` hinzugefügt und dann eine neue NixOS-Config `monitoring-config.nix` erstellt und in der `configuration.nix` importiert.

```nix
# monitoring-config.nix
{ config, lib, pkgs, ... }:
{
    virtualisation.docker.enable = true;
    users.extraGroups.docker.members = [ "root" ];
}
```

Hiermit sind nur noch Änderungen an der Firewall notwendig, um die Verbindung zu Dockerhub zu erlauben und die Ports für Prometheus und Grafana freizugeben:

```nix
#vm-network-config.nix
      iptables -A INPUT -p tcp --dport 9100 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9100 -j ACCEPT 
      iptables -A OUTPUT -p tcp --dport 9090 -j ACCEPT
```

#### 1.2) Konfiguration von Docker

Zunächst brauchen wir die folgenden Dateien und Verzeichnisse in denen nacher die Config-Datein der einzelnen Dienste liegen:

```shell
# Create the directory structure
mkdir -p /root/docker/alert-manager
mkdir -p /root/docker/grafana
mkdir -p /root/docker/prometheus
mkdir -p /root/docker/blackbox

# Create the config files
touch /root/docker/docker-compose.yaml
touch /root/docker/alert-manager/alertmanager.yml
touch /root/docker/grafana/grafana.ini
touch /root/docker/prometheus/alert-rules.yml
touch /root/docker/prometheus/prometheus.yml
touch /root/docker/blackbox/blackbox.yml
```

Nun können wir die Docker-Compose Datei erstellen:

```yml
# docker-compose.yml
services:
  # Prometheus zur Metriken-Sammlung
  prometheus:
    image: prom/prometheus
    ports:
      - '9090:9090'
    volumes:
      - /root/docker/prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--web.enable-lifecycle'
    restart: unless-stopped

  # Grafana zur Visualisierung
  grafana:
    image: grafana/grafana
    ports:
      - '3000:3000'
    depends_on:
      - prometheus
    restart: unless-stopped
    environment:
     - HTTP_PROXY=http://proxy.cit.tum.de:8080/
     - HTTPS_PROXY=http://proxy.cit.tum.de:8080/
     - NO_PROXY=localhost,127.0.0.1,prometheus
    volumes:
     - grafana-storage:/var/lib/grafana

  # Alertmanager zur Alarmierung bei Fehlern
  alertmanager:
    image: prom/alertmanager
    ports:
      - "9093:9093"
    volumes:
      - /root/docker/alert-manager:/config
    command: --config.file=/config/alertmanager.yml --log.level=debug

  # Blackbox Exporter zur Überwachung von Webseiten
  blackbox:
    image: prom/blackbox-exporter:latest
    ports:
     - 9115:9115
    volumes:
     - /root/docker/blackbox:/etc/blackbox
    command:
     - --config.file=/etc/blackbox/blackbox.yml
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  grafana-storage: {}
```

Durch die obige compose-Datei wird ein Prometheus-Server, ein Grafana-Server, ein Alertmanager und ein Blackbox-Exporter gestartet. Die Konfigurationsdateien für die einzelnen Dienste werden in den entsprechenden Verzeichnissen gemountet und für Dienste die Internetzugriff benötigen, wird der Proxy konfiguriert.
  
#### 1.3) Konfiguration von Prometheus

Prometheus sammelt Metriken von den verschiedenen Diensten und speichert diese in einer Datenbank. Die Konfiguration erfolgt über die `prometheus.yml` Datei. Hier werden abgesehen von ein paar globalen Einstellungen die verschiedenen Dienste definiert, die Prometheus überwachen soll:

```yml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
  # Prometheus selbst als Beispiel
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
      
#rule_files:
#  - 'alert-rules.yml'
#alerting:
#  alertmanagers:
#    - scheme: http
#    - static_configs:
#        - targets: ['host.docker.internal:9093']
```

Hiermit sind alle zum jetzigen Zeitpunkt relevanten Konfigurationen abgeschlossen und docker kann gestartet werden:

```shell
# current firewall rule (allow all)
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F

docker compose up -d
```

#### 1.4) Konfiguration von Grafana

Wenn Grafana zum erstenmal gestartet wird, muss ein neues Passwort gesetzt werden. Zunächst muss man sich mit dem Standard-Login `admin` und Passwort `admin` anmelden und wird dann nach einen neuen Passwort gefragt.

Jetzt muss nur noch Prometheus als Datenquelle hinzugefügt werden und dann ist auch Grafana einsatzbereit. Hierzu wählt man im linken Menü unter dem Reiter "Connections” "Data Sources" aus. Dort dann auf "Add data source" klicken und "Prometheus" als Datenquelle auswählen. Die URL sollte auf `http://prometheus:9090` gesetzt werden und dann auf "Save & Test" klicken. (Wichtig: der Hostname muss `prometheus` sein)

Nun sollten die folgenden Dienste erreichbar sein:

- Prometheus: [link](http://131.159.74.56:60312/)
- Grafana: [link](http://131.159.74.56:60313/)
- Alertmanager: [link](http://131.159.74.56:60314/)

### 2. Überwachung der Dienste

#### 2.1) Betriebssystem [Dashboard](http://131.159.74.56:60313/d/rYdddlPWk/01-os-metrik?orgId=1&from=now-24h&to=now&timezone=browser&var-datasource=default&var-job=os-status&var-node=192.168.3.1%3A9100&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B%7Cmmcblk%5B0-9%5D%2B&refresh=1m)

Zunächst sollen die beiden vm1 und vm2 überwacht werden. Dafür müssen wir auf den beiden VMs den node-exporter installieren. Dieser sammelt Metriken über das Betriebssystem und stellt sie Prometheus zur Verfügung.

```nix
# os-exporter.nix
{ config, lib, pkgs, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "logind"
      "systemd"
    ];
    disabledCollectors = [
      "textfile"
    ];
    openFirewall = true;
  };
}
```

Nach einen rebuild der VMs können wir den node-exporter in Prometheus eintragen damit die Exporter auch von Prometheus abgefragt werden:

```yml
# prometheus.yml
...
scrape_configs:
  ...
  - job_name: 'os-status'
    static_configs:
      - targets: 
          - '192.168.3.1:9100' #vm1
          - '192.168.3.2:9100' #vm2
          - '192.168.3.3:9100' #router
```

Darauf muss `prometheus` mittels `docker compose restart prometheus` neugestarted werden.
Worauf unter `http://131.159.74.56:60312/targets` die beiden VMs als `UP` angezeigt werden sollten. (hierfür ist natürlich zunächst eine Portweiterleitung in VirtualBox notwendig)

Nun können wir in Grafana die Metriken visualisieren. Dafür erstellen wir ein neues Dashboard und fügen ein Panel hinzu. Eine tolle Sache an Grafana ist hier das es bereits viele fertige Dashboards gibt, wie das `https://grafana.com/grafana/dashboards/1860-node-exporter-full/` Dashboard welches alle Metriken des node-exporters visualisiert.

Um dieses Dashboard zu verwenden, müssen wir es in Grafana importieren. Dafür gehen wir auf `Dashboard` -> `New` -> `Import` und geben die ID des Dashboards ein. In diesem Fall `1860`. Nun muss nur noch `Prometheus` als Datenquelle ausgewählt werden und das Dashboard ist einsatzbereit.

#### 2.2) Netzwerk [Dashboard](http://131.159.74.56:60313/d/NEzutrbMk/02-network?orgId=1&from=now-6h&to=now&timezone=browser&var-job=%24__all&var-instance=%24__all&refresh=1m)

Um die Erreichbarkeit der verschiedenen VMs zu überwachen, verwenden wir den `blackbox-exporter`. Dieser kann verschiedene Module verwenden, um die Erreichbarkeit von Diensten zu überprüfen. Configuriert wird dieser exporter über seine eigene `yml` Datei welche in compose file definiert wird. In unserem Fall verwenden wir das `ping`-Modul, wir wie folgt definiert haben:

```yml
# blackbox.yml
modules:
  ping:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip4"
```

Nun brauchen wir noch noch einen euen Job in der `prometheus.yml` Datei, um den blackbox-exporter abzufagen:

```yml
# prometheus.yml
...
  - job_name: 'network'
    metrics_path: /probe
    params:
      module: [ping]  # Look for a HTTP 200 response.
    static_configs:
      - targets:
        - vm1.psa-team03.cit.tum.de
        - vm2.psa-team03.cit.tum.de
        - router.psa-team03.cit.tum.de
        - database.psa-team03.cit.tum.de
        - homeassistant.psa-team03.cit.tum.de
        - vm6.psa-team03.cit.tum.de
        - ldap.psa-team03.cit.tum.de
        - fileserver.psa-team03.cit.tum.de
        - mail.psa-team03.cit.tum.de
        - monitoring.psa-team03.cit.tum.de
        # team routers
        - vm001.psa-team01.cit.tum.de
        - vm1.psa-team02.cit.tum.de
        - vm4.psa-team02.cit.tum.de
        - vm04-02.psa-team04.cit.tum.de
        - vm01.psa-team05.cit.tum.de
        - shika.psa-team06.cit.tum.de
        - vm1.psa-team07.cit.tum.de
        - router.psa-team08.cit.tum.de
        - ns01.psa-team09.cit.tum.de
        - vm02.psa-team10.cit.tum.de
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115  # muss blackbox:9115 sein
```

In grafana importieren wir nun das interface `https://grafana.com/grafana/dashboards/13659-blackbox-exporter-http-prober/` und nach etwas Anpassung haben nun eine schöne Übersicht über die Erreichbarkeit der verschiedenen Server.

#### 2.3) DNS [Dashboard](http://131.159.74.56:60313/d/wY4blRMGz/03-dns?orgId=1&from=now-1h&to=now&timezone=browser&var-instance=%24__all&refresh=5s)

CoreDNS bietet nativen prometheus support und es lässt such ein exporter einfach durch hinzufügen von `prometheus :9153` in `dns-config.nix` aktivieren:

```nix
{ ... }:
{ ... }:
{
  services.coredns = {
    enable = true;
    config = ''
        (default) {
            bind enp0s8
            root /etc/nixos/dns
            log
            prometheus :9153
        }
...
```

 -> testen ob erreichbar über `curl http://localhost:9153/metrics`

dann nur noch zu prometheus hinzufügen:

```yml
  - job_name: "coredns"
      static_configs:
        - targets:
            - "192.168.3.3:9153"
```

In grafana importieren wir nun das interface `https://grafana.com/grafana/dashboards/14981-coredns/` und nach etwas Anpassung haben nun eine schöne Übersicht über unseren CoreDNS Server.

#### 2.4) DHCP [Dashboard](http://131.159.74.56:60313/d/cdgjnsy1l6pkwc/04-dhcp?orgId=1&from=now-30m&to=now&timezone=browser&var-host=192.168.3.3%3A9101&var-ipv4_pool=%24__all&var-ipv6_pool=%24__all&var-ipv4_subnet=%24__all&var-ipv6_subnet=%24__all)

Hier ist die bereitstellung des exporters etwas aufwendiger aber immernoch einfach umzusetzen. Zunächst muss ein controll socket in der dhcp config hinzugefügt werden:

```bash
# dhcp.conf
...
        "control-socket": {
            "socket-type": "unix",
            "socket-name": "/run/kea/kea-dhcp4.socket"
        },
...
```

und dann ein neuer exporter zur `router-exporter.nix`:

```nix
# router-exporter.nix
{ config, lib, pkgs, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "logind"
      "systemd"
    ];
    disabledCollectors = [
      "textfile"
    ];
    openFirewall = true;
  };
  services.prometheus.exporters.kea = {
    enable = true;
    targets = ["/run/kea/kea-dhcp4.socket"];
    port = 9101;
  };
}
```

Bei grafana haben wir uns für das folgende Dashboard entschieden und auf unsere Bedürfnisse angepasst `https://grafana.com/grafana/dashboards/12688-kea-dhcp/`

#### 2.5) Webserver [Dashboard](http://131.159.74.56:60313/d/EmUBHUFGk/05-webserver?orgId=1&from=now-30m&to=now&timezone=browser&var-target=http%3A%2F%2Fweb1.psa-team03.cit.tum.de)

Zum testen des Webservers haben wir uns für `blackbox-exporter` entschieden welcher die einzelnen Webseiten auf Verfügbarkeit prüft. Für Blackbox haben iwr dann die folgende Konfig für http und icmp Anfragen erstellt:

```yml
# blackbox.yml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []
      method: GET
      follow_redirects: true
      fail_if_ssl: false
      fail_if_not_ssl: false
      tls_config:
        insecure_skip_verify: true
      preferred_ip_protocol: "ip4" # defaults to "ip6"
      ip_protocol_fallback: false  # no fallback to "ip6"
  ping:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip4"
```

Nun muss noch in Prometheus ein neuer Job hinzugefügt werden:

```yml
# prometheus.yml
...
  - job_name: 'webserver'
    metrics_path: /probe
    params:
      module: [http_2xx]  # Look for a HTTP 200 response.
    static_configs:
      - targets:
        - http://web1.psa-team03.cit.tum.de
        - https://web1.psa-team03.cit.tum.de
        - https://web2.psa-team03.cit.tum.de
        - https://web3.psa-team03.cit.tum.de
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 192.168.3.6:9102  # muss blackbox:9115 sein
```

Und bei Grafana haben wir das folgende Interface angepasst: `https://grafana.com/grafana/dashboards/13659-blackbox-exporter-http-prober/`

#### 2.6) Datenbank [Dashboard](http://131.159.74.56:60313/d/000000039/06-database?var-interval=%24__auto&orgId=1&from=now-6h&to=now&timezone=browser&var-DS_PROMETHEUS=aealih1zjcdtsa&var-namespace&var-release&var-instance=192.168.3.2%3A9101&var-datname=%24__all&var-mode=%24__all&refresh=10s)

Wir haben insgesamt 3 Datenbanken zu überwachen:

1. unsere **"Haupt"-Datenbank** (192.168.3.4), genutzt von Team 4,
2. die dazugehörige **Backup-Datenbank** (192.168.3.2) und
3. die Datenbank von **Team 2**, auf welche wir zugreifen.

Auf den ersten beiden Datenbank-VMs lässt sich einfach der Prometheus-Exporter aktivieren:

```nixos
# database.nix & database-backup.nix
services.prometheus.exporters.postgres = {
  enable = true;
  port = 9100;
  runAsLocalSuperUser = true;
};
```

Beide `exporter` können nun in Prometheus zusätzlich eingetragen werden:

```yml
# prometheus.yml
  ...
  - job_name: 'postgresql'
    static_configs:
      - targets: ['192.168.3.4:9100']
  - job_name: 'postgresql-backup'
    static_configs:
      - targets: ['192.168.3.2:9100']
```

Diese Daten können wir einfach in Grafana mit [dieser Konfiguration](https://grafana.com/grafana/dashboards/9628-postgresql-database/) visuell darstellen.

Bei Team 2 werden wir nur die Erreichbarkeit prüfen. Genaue Metriken zu sammeln ergibt hier wenig Sinn, da diese auf einer Systemüberwachung von Team 2 gesammelt werden.
Für die Erreichbarkeits-Überwachung richten wir einen `exporter` ein, der einfach ein simples script ausführen kann:

```nixos
services.prometheus.exporters.script = {
  enable = true;
  port = 9100;
  settings.scripts = [
    { name = "db-check"; script = "nc -zv 192.168.4.5 3306"; }
  ];
};
```

mit `curl http://localhost:9100/probe?name=db-check` können wir testen, ob das Skript funktioniert und erhalten wie erwartet:

```shell
script_duration_seconds{script="db-check"} 0.012866
script_success{script="db-check"} 0
```

Quellen:

- [NixOs Postgresql Prometheus Exporter](https://github.com/prometheus-community/postgres_exporter)
- [NixOs Postgresql Prometheus Exporter Optionen](https://search.nixos.org/options?channel=24.11&show=services.prometheus.exporters.postgres.dataSourceName&from=0&size=50&sort=relevance&type=packages&query=services.prometheus.exporters.postgres)
- [NixOs Script Prometheus Exporter](https://github.com/adhocteam/script_exporter#sample-configuration)
- [NixOs Script Prometheus Exporter Optionen](https://search.nixos.org/options?channel=24.11&show=services.prometheus.exporters.script.settings.scripts.*.script&from=0&size=50&sort=relevance&type=packages&query=services.prometheus.exporters.script)
- [Grafana Prometheus Postgresql Dashboard](https://grafana.com/grafana/dashboards/9628-postgresql-database/)

#### 2.7) Webanwendung

Um die webanwendung zu überwachen haben wir uns für Cadvisor entschieden welches Metricken über Container im selben Stack sammelt und da bei uns Homeassistant in einem Docker Container läuft, ist dies eine sehr einfache und effektive Lösung. Um Cadvisor zu deployen, haben wir das homeassistant compose file um Cadvisor erweitert:

```yml
  cadvisor:
    container_name: cadvisor
    image: gcr.io/cadvisor/cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8080:8080"
    restart: unless-stopped
    devices:
      - /dev/kmsg
    privileged: true
```

einen neuen Job in der `prometheus.yml` Datei hinzufügen:

```yml
- job_name: 'homeassistant'
    static_configs:
      - targets: ['192.168.3.5:8080']
```

und ein neues Dashboard in Grafana importieren: `https://grafana.com/grafana/dashboards/19792-cadvisor-dashboard/` und angepasst

#### 2.8) Fileserver [Dashboard](http://131.159.74.56:60313/d/rYdddlPWK/08-fileserver?orgId=1&from=now-24h&to=now&timezone=browser&var-datasource=default&var-job=fileserver&var-node=192.168.3.8%3A9100&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B%7Cmmcblk%5B0-9%5D%2B&refresh=1m)

Zur überwachung des fileservers lassen wir auch einfach den node-exporter laufen und fügen ihn zu prometheus hinzu:

```yml
# prometheus.yml
  - job_name: 'fileserver'
    static_configs:
      - targets: 
          - '192.168.3.8:9100' #vm1
```

fügen das bekannte grafana interface hinzu `https://grafana.com/grafana/dashboards/13976-node-exporter-full/` und anpassen es an sodass belegter und noch freier Speicherplatz angezeigt wird

#### 2.9) LDAP

Leider wird für LDAP kein standard exporter angeboten, weder in NixOS, noch als fertig konfigurierter Docker Container. Wir bauen uns deshalb ein Custom-Nix-Package aus diesem Github Projekt: [Github.com/tomcz/openldap_exporter](https://github.com/tomcz/openldap_exporter). Es ist ein recht altes Projekt, aber dennoch die beste Alternative, die wir finden konnten und funktioniert einwandfrei. Das einzie Manko ist, dass TLS nicht zu funktionieren scheint. Wir haben als Workaround deshalb hierfür `ldap:///` zusätzlich in der `ldap.nix` freigeben müssen.

1. Installation: Hier bauen wir das custom Nix-Package, die Schritte sind als Kommentare erklärt:

   ```shell
   { pkgs, ... }:
   let
       # Definieren des Exporter Packages
       openldap_exporter = pkgs.stdenv.mkDerivation {
           name = "openldap_exporter-2.3.2";
           pname = "openldap_exporter";
           version = "2.3.2";
           # Github Quelle
           src = pkgs.fetchurl {
             url = "https://github.com/tomcz/openldap_exporter/releases/download/v2.3.2/openldap_exporter-linux-amd64.gz";
             sha256 = "dddd48d707a704e7ee54d70924edacca7f0eea7a54457a3b5078ac502c06b622";
           };
           nativeBuildInputs = [ pkgs.gzip pkgs.autoPatchelfHook ];
           buildInputs = [ pkgs.glibc ];

           # Da kein .tar.gz, muss die unpack-Phase explizit definiert werden
           unpackPhase = ''
             mkdir source
             gzip -d < $src > source/openldap_exporter
             chmod +x source/openldap_exporter
           '';
           
           # Ebenso definieren wir die Installation
           installPhase = ''
             mkdir -p $out/bin
             cp source/openldap_exporter $out/bin/
           '';
   
           # Zum Schluss legen wir der Sauberkeit-halber ein paar Metadaten an
           meta = with pkgs.lib; {
             description = "Prometheus OpenLDAP Exporter";
             license = licenses.asl20;
             platforms = platforms.linux;
           };
       };
   }
   in
   {
       environment.systemPackages = [ openldap_exporter ]; 
       # Hier definieren wir noch genauere Konfigurationen, wie das startup Kommande:
       systemd.services.openldap_exporter = {
           description = "Prometheus OpenLDAP Exporter";
           after = [ "network.target" ];
           wantedBy = [ "multi-user.target" ];
           serviceConfig = {
               # Beim Aufrufen geben wir den Nutzer, sowie das Passwort an
               # Die Verbindungen lassen wir mit default Einstellungen (e.g. port des prometheus services = 9330)
               ExecStart = "${openldap_exporter}/bin/openldap_exporter --ldapUser admin --ldapPass <Passwort>";
               Restart = "always";
           };
       };
   }
   ```

2. Prometheus Yaml

   ```yml
   # prometheus.yml
     - job_name: 'openldap'
       static_configs:
         - targets: 
             - '192.168.3.9:9330'
   ```

Quellen:

- [OpenLDAP Prometheus Exporter](https://github.com/jcollie/openldap_exporter)

#### 2.10) Mail [Dashboard](http://131.159.74.56:60313/d/h36Havfik/10-mail?orgId=1&from=now-6h&to=now&timezone=browser&var-instance=%24__all)

Für den Mail-Service nutzen wir den Prometheus Exporter für Postfix, um Metriken zu sammeln und die Mail Warteschlange anzuzeigen.

```nix
# Konfiguration für den Prometheus Exporter für Postfix
services.prometheus.exporters.postfix = {
  enable = true;
  port = 9154;
  telemetryPath = "/metrics";
  openFirewall = true;
};
```

auch hier müssen wir den Exporter in Prometheus eintragen:

```yml
# prometheus.yml
  - job_name: 'postfix'
    static_configs:
      - targets: 
          - '192.168.3.9:9154'
```

darauf haben wir das folgende Dashboard in Grafana importiert `https://grafana.com/grafana/dashboards/10013-postfix/` und angepasst sodass die Warteschlange angezeigt wird.

### 3. Alarmierung

Um schnell wichtige Probleme / Ausfäle zu erkennen, werden zum Schluss noch Alerts eingerichtet. Hierfür benötigen wir 2 Konfigurationen:

1. `alert.rules.yml` beinhaltet alle Alert-Regeln und wird von Prometheus eingelesen. Sollte ein Alert ausgelöst werden, wird dieser an den `Alert Manager` gesendet.
2. `alertmanager.yml` beinhaltet die Konfiguration für den Alert Manager. Hier wird definiert, wer bei welcher Art von Alert benachrichtigt wird.

#### 3.1) Alert Manager

Der Prometheus Alert Manager unterstützt viele Arten von Alert-Möglichkeiten, beispielsweise Mail, Slack, oder PagerDuty. Wir haben uns entschieden einen Slack-Bot einzurichten.

Hierfür muss zuerst eine Slack-Webhook eingerichtet werden. Wir haben zum Testen einen neuen Slack Kanal erstellt, auf welchem die Webhook posten kann.

![alt text](slack.png)

Im Anschluss wird in der `alertmanager.yml` die Route gesetzt und ein neuer Slack-`receiver` eingerichtet. Hier können wir die eben erstellte Webhook angeben.

```yml
# alertmanager.yml
route:
  receiver: slack
  repeat_interval: 1m
receivers:
  - name: slack
    slack_configs:
      - channel: "#all-praktikum-system-administration-ws2425"
        send_resolved: true
        api_url: "https://hooks.slack.com/services/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"
        title: Alert
        text: >-
          {{ range .Alerts -}}
          *Alert:* {{ .Annotations.title }}{{ if .Labels.severity }} - `{{ .Labels.severity }}`{{ end }}
          *Description:* {{ .Annotations.description }}
          *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
```

#### 3.2) Prometheus (Alert Regeln)

Um den Alert Manager mit Prometheus zu verbinden muss dieser in der `prometheus.yml` unter `alerting` eingetragen werden. Auch wird hier der Pfad zu der Datei mit den Alert-Regeln `rule_files` angegeben:

```yml
# prometheus.yml
rule_files:
  - "alert.rules.yml"
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]
```

In der `alert.rules.yml` können nun Alert-Regeln gesetzt werden. Diese Regeln können in Gruppen unterteilt werden. Eine Alert-Konfiguration sieht folgendermaßen aus:

```yml
# alert.rules.yml
groups:
  - name: <Gruppen-Name>
    rules:
      - alert: <Alert-Titel>
        expr: <Bedingung>
        for: <Dauer>
        labels:
          severity: <Level>
        annotations:
          summary: <Kurz-Beschreibung>
          description: <Beschreibung>
```

Wir können beispielsweise überprüfen, ob Prometheus selbst funktioniert...

```yml
# alert.rules.yml
      - alert: PrometheusJobMissing
        expr: absent(up{job="prometheus"})
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: Prometheus job missing (instance {{ $labels.instance }})
          description: "A Prometheus job has disappeared\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```

...oder ob die Datenbank gerade läuft.

```yml
# alert.rules.yml
      - alert: PostgresqlDown
        expr: pg_up == 0
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: Postgresql down (instance {{ $labels.instance }})
          description: "Postgresql instance is down\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```

Nachdem wir sehr viele dieser Alerts nutzen (auch viele vorkonfigurierte von [Github](https://samber.github.io/awesome-prometheus-alerts/rules.html)), werden wir nicht auf alle im Detail eingehen. Sie können in [`alert.rules.yml`](alert.rules.yml) eingesehen werden. Wir haben folgende Alert-Gruppen eingerichtet:

- `CoreDNS`: CoreDNS Panic Count
- `DHCP`: DHCP läuft
- `Homeassistant`: Homeassistant läuft
- `NodeOsStatus`: VM-Überwachung (ungewöhnliche CPU Last, voller Speicher, läuft Filesystem-RAID noch)
- `OpenLDAP`: OpenLDAP Server läuft
- `Postfix`: Postfix Server läuft
- `Postgresql`: Datenbanken (sind am laufen, Deadlock-Rate, ...)
- `Prometheus`: Prometheus Funktionalitäten (besonders wichtig: Verfügbarkeit von Exportern)

Jeder Alert ist bei funktionierendem System `INACTIVE`, bei Fehlerhaften Checks wird dieser auf `FIRING` gesetzt.

![alt text](alert-state.png)

Quellen:

- [Adding Prometheus alerts](https://signoz.io/guides/how-do-i-add-alerts-to-prometheus/)
- [Adding AlertManager Slack notifications](https://blog.devops.dev/how-to-build-an-alerting-system-with-prometheus-and-alertmanager-cd75a28c2b74)
- [Collection of useful alerts](https://samber.github.io/awesome-prometheus-alerts/rules.html)
