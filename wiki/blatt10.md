# Aufgabenblatt 10

In diesem Blatt geht es darum alle bisher erstellten Systeme zentral zu überwachen und bei Bedarf über Fehler informiert zu werden.
Um dies umzusetzen haben wir uns für Prometheus und Grafana entschieden, wobei Prometheus die Metriken sammelt und Grafana diese visualisiert.

Aufgaben:

1. installieren von Prometheus und Grafana
2. Überwachung der Dienste:
    1. Betriebssystem -> ping, cpu load, Prozesse
    2. Netzwerk -> router up, ping eigene Team VMs, ping andere Team VMs
    3. DNS -> verfügbarkeit, prüfe ob Domain test domains auflöst, anzahl Anfragen
    4. DHCP -> verfügbarkeit, anzahl anfragen
    5. Webserver -> verfügbarkeit (http & https), ladezeit, anzahl anfragen
    6. Datenbank -> verfügbarkeit (eigene & Team x), anzahl anfragen
    7. Webanwendung -> verfügbarkeit, ladezeit, anzahl anfragen
    8. Fileserver -> freien Speicherplatz
    9. LDAP -> verfügbarkeit, anzahl anfragen
    10. Mail -> Länge der Warteschlange
3. Für alle Dienste soll eine Art Status-Übersicht erstellt werden
4. Alarmierung bei Fehlern aber auch mit alternative zum Mailserver
5. Testen

## Teilaufgaben

### 1. Installation

#### 1.1) Konfiguaration von Nixos

Zum deployen von Prometheus und Grafana haben wir uns entschieden Docker zu verwenden. Dafür haben wir zunächst das `docker-compose` pkg zur `configuration.nix` hinzugefügt und dann eine neue nixos-config `monitoring-config.nix` erstellt und in der `configuration.nix` importiert.

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
#TODO
      iptables -A INPUT -p tcp --dport 9100 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9100 -j ACCEPT 
      iptables -A OUTPUT -p tcp --dport 9090 -j ACCEPT
```

#### 1.2) Konfiguaration von Docker

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
    environment:
     - HTTP_PROXY=http://proxy.cit.tum.de:8080/
     - HTTPS_PROXY=http://proxy.cit.tum.de:8080/
     - NO_PROXY=localhost,127.0.0.1,blackbox

volumes:
  grafana-storage: {}
```

Durch die obige compose Datei wird ein Prometheus-Server, ein Grafana-Server, ein Alertmanager und ein Blackbox-Exporter gestartet. Die Konfigurationsdateien für die einzelnen Dienste werden in den entsprechenden Verzeichnissen gemountet und für Dienste die Internetzugriff benötigen, wird der Proxy konfiguriert.

#### 1.3) Konfiguaration von Prometheus

Prometheus sammelt Metriken von den verschiedenen Diensten und speichert diese in einer Datenbank. Die Konfiguration erfolgt über die `prometheus.yml` Datei. Hier werden abgesehen von ein par globalen einstellungen, die verschiedenen Dienste definiert, die Prometheus überwachen soll:

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

#### 1.4) Konfiguaration von Grafana

Wenn Grafana zum erstenmal gestartet wird, muss ein neues Passwort gesetzt werden. Zunächst muss man sich mit dem Standard-Login `admin` und Passwort `admin` anmelden und wird dann nach einen neuen Passwort gefragt.

Jetzt muss nur noch Prometheus als Datenquelle hinzugefügt werden und dann ist auch Grafane einsatzbereit. Hierzu wählt man im linken Menü uter dem Reiter "Connections” "Data Sources" aus. Dort dann auf "Add data source" klicken und "Prometheus" als Datenquelle auswählen. Die URL sollte auf http://prometheus:9090 gesetzt werden und dann auf "Save & Test" klicken. (Wichtig: der Hostname muss `prometheus` sein)







### 2. Überwachung der Dienste

#### 2.1) Betriebssystem

Zunächst sollen die beidem vm1 und vm2 überwacht werden. Dafür müssen wir auf den beiden VMs den node-exporter installieren. Dieser sammelt Metriken über das Betriebssystem und stellt sie Prometheus zur Verfügung.

```nix
# os-expoerter.nix
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
          # database, homeassistant up over own exporter
          - '192.168.3.6:9100' #webserver
          - '192.168.3.7:9100' #fileserver
```

Darauf muss `prometheus` neu gestartet mittels `docker compose restart prometheus` neugestarted werden.
Worauf unter `http://131.159.74.56:60312/targets` die beiden VMs als `UP` angezeigt werden sollten.

Nun können wir in Grafana die Metriken visualisieren. Dafür erstellen wir ein neues Dashboard und fügen ein Panel hinzu. Eine tolle Sache an Grafana ist hier das es bereits viele fertige Dashboards gibt, wie das `https://grafana.com/grafana/dashboards/1860-node-exporter-full/` Dashboard welches alle Metriken des node-exporters visualisiert.

Um dieses Dashboard zu verwenden, müssen wir es in Grafana importieren. Dafür gehen wir auf `Dashboard` -> `New` -> `Import` und geben die ID des Dashboards ein. In diesem Fall `1860`. Nun muss nur noch `Prometheus` als Datenquelle ausgewählt werden und das Dashboard ist einsatzbereit.

#### 2.2) Netzwerk

# TODO

alle vms mit nodeexporter -> up/down

##### pinging

neuer prometheus job:

```yml
# prometheus.yml
...
  - job_name: 'network'
    metrics_path: /probe
    params:
      module: [ping]  # Look for a HTTP 200 response.
    static_configs:
      - targets:
        - 192.168.3.1
        - 192.168.3.2
        - 192.168.3.3
        - 192.168.3.4
        - 192.168.3.5
        - 192.168.3.6
        - 192.168.3.7
        - 192.168.3.8
        - 192.168.3.9
        - 192.168.3.10
        # team routers
        - 192.168.1.1
        - 192.168.2.1
        - 192.168.4.1
        - 192.168.5.1
        - 192.168.6.1
        - 192.168.7.1
        - 192.168.8.5
        - 192.168.9.1
        - 192.168.10.2
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115  # muss blackbox:9115 sein
```


in grafana :
The Prometheus Stat you are looking for it just 'up'.

If up is 0, that means the target is unreachable, if it is 1 that means it is responding.

To create a panel in Grafana that shows this, you can use a "Stat" panel.
Set the Query to something like: up
The legend to: {{instance}}
And make a value mapping so that:
1 -> UP and the color is Green
0 -> DOWN and the color is RED
(Value Mapping can be set in the panel settings, all the way at the bottom.)

This will show all your Prometheus targets, their name, and whether they are up or down.

#### 2.3) DNS

CoreDNS nativen prometheus exporter diesen nur aktivieren durch hinzufügen von `prometheus :9153` in `dns-config.nix`:

```nix
{ ... }:
{
  services.coredns = {
    enable = true;
    config = ''
        (default) {
            bind enp0s8
            root /etc/nixos/dns
            log
        }
        
        . {
            forward . 131.159.254.1 131.159.254.2
            prometheus :9153 # Include metrics for this zone if desired
            import default
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

grafana: https://grafana.com/grafana/dashboards/14981-coredns/

#### 2.4) DHCP

# Fertig? 

added controll oscket to dhcpd.conf:

```shell

        "control-socket": {
            "socket-type": "unix",
            "socket-name": "/run/kea/kea-dhcp4.socket"
        },

```

created extra router-exporter.nix:

```nix
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

firewall

grafana https://grafana.com/grafana/dashboards/12688-kea-dhcp/

#### 2.5) Webserver

# FIXME 
blackbox config:

```yml
# blackbox.yml
modules:
  http_2xx_example:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []  # Defaults to 2xx
      method: GET
      headers:
        Host: vhost.example.com
        Accept-Language: en-US
        Origin: example.com
      follow_redirects: true
      fail_if_ssl: false
      fail_if_not_ssl: false
      fail_if_body_matches_regexp:
        - "Could not connect to database"
      fail_if_body_not_matches_regexp:
        - "Download the latest version here"
      fail_if_header_matches: # Verifies that no cookies are set
        - header: Set-Cookie
          allow_missing: true
          regexp: '.*'
      fail_if_header_not_matches:
        - header: Access-Control-Allow-Origin
          regexp: '(\*|example\.com)'
      tls_config:
        insecure_skip_verify: false
      preferred_ip_protocol: "ip4" # defaults to "ip6"
      ip_protocol_fallback: false  # no fallback to "ip6"
  http_with_proxy:
    prober: http
    http:
      proxy_url: "http://proxy.cit.tum.de:8080/"
      skip_resolve_phase_with_proxy: true
  dns_udp_example:
    prober: dns
    timeout: 5s
    dns:
      query_name: "www.prometheus.io"
      query_type: "A"
      valid_rcodes:
        - NOERROR
      validate_answer_rrs:
        fail_if_matches_regexp:
          - ".*127.0.0.1"
        fail_if_all_match_regexp:
          - ".*127.0.0.1"
        fail_if_not_matches_regexp:
          - "www.prometheus.io.\t300\tIN\tA\t127.0.0.1"
        fail_if_none_matches_regexp:
          - "127.0.0.1"
      validate_authority_rrs:
        fail_if_matches_regexp:
          - ".*127.0.0.1"
      validate_additional_rrs:
        fail_if_matches_regexp:
          - ".*127.0.0.1"
  dns_soa:
    prober: dns
    dns:
      query_name: "prometheus.io"
      query_type: "SOA"
  dns_tcp_example:
    prober: dns
    dns:
      transport_protocol: "tcp" # defaults to "udp"
      preferred_ip_protocol: "ip4" # defaults to "ip6"
      query_name: "www.prometheus.io"
  ping:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip4"
      source_ip_address: "127.0.0.1"
```

neuer prometheus job:

```yml
# prometheus.yml
...
  - job_name: 'webserver'
    metrics_path: /probe
    params:
      module: [http_with_proxy]  # Look for a HTTP 200 response.
    static_configs:
      - targets:
        - http://prometheus.io    # Target to probe with http.
        - https://prometheus.io   # Target to probe with https.
        #- http://example.com:8080 # Target to probe with http on port 8080.
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115  # muss blackbox:9115 sein
```

grafana: https://grafana.com/grafana/dashboards/13659-blackbox-exporter-http-prober/


```yml
  - job_name: 'webserver'
    static_configs:
      - targets: ['192.168.3.6:9101']
```


#### 2.6) Datenbank

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

# funktioniert, fertig?
cadvisor zu homeassistant compose file:

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

grafana: https://grafana.com/grafana/dashboards/19792-cadvisor-dashboard/

#### 2.8) Fileserver


#### 2.9) LDAP


#### 2.10) Mail


### 3. Status-Übersicht


### 4. Alarmierung


```yml
# alert-rules.yml
groups:
  - name: tutorial-rules
    rules:
      # Triggers a critical alert if a server is down for more than 1 minute.
      - alert: ServerDown
        expr: up < 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Server {{ $labels.instance }} down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute."
```

```yml
# alertmanager.yml
route:
  receiver: tutorial-alert-manager
  repeat_interval: 1m
receivers:
  - name: 'tutorial-alert-manager'
    telegram_configs:
      - bot_token: tutorial_token
        api_url: https://api.telegram.org
        chat_id: -12345678
        parse_mode: ''
    email_configs:
      - to: 'tutorial.inbox@gmail.com'
        from: 'tutorial.outbox@gmail.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'username'
        auth_password: 'password'
```

Quellen:

- [Adding Prometheus alerts](https://signoz.io/guides/how-do-i-add-alerts-to-prometheus/)
- [Collection of useful alerts](https://samber.github.io/awesome-prometheus-alerts/rules.html)
