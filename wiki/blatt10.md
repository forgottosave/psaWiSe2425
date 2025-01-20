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

#### Docker

```shell
# Create the directory structure
mkdir -p /root/docker/alert-manager
mkdir -p /root/docker/grafana
mkdir -p /root/docker/prometheus
mkdir -p /root/docker/blackbox

# Create the files
touch /root/docker/docker-compose.yaml
touch /root/docker/alert-manager/alertmanager.yml
touch /root/docker/grafana/grafana.ini
touch /root/docker/prometheus/alert-rules.yml
touch /root/docker/prometheus/prometheus.yml
touch /root/docker/blackbox/blackbox.yml
```

```yml
# docker-compose.yml
services:
  prometheus:
    image: prom/prometheus
    ports:
      - '9090:9090'
    volumes:
      - /root/docker/prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--web.enable-lifecycle'
    restart: always

  grafana:
    image: grafana/grafana
    ports:
      - '3000:3000'
    depends_on:
      - prometheus
    restart: unless-stopped
    environment:
#     - GF_SERVER_ROOT_URL=http://my.grafana.server/
     - HTTP_PROXY=http://proxy.cit.tum.de:8080/
     - HTTPS_PROXY=http://proxy.cit.tum.de:8080/
     - NO_PROXY=localhost,127.0.0.1,prometheus
#     - GF_INSTALL_PLUGINS=grafana-clock-panel
    volumes:
     - grafana-storage:/var/lib/grafana

  alertmanager:
    image: prom/alertmanager
    ports:
      - "9093:9093"
    volumes:
      - /root/docker/alert-manager:/config
    command: --config.file=/config/alertmanager.yml --log.level=debug

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


```yml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
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

```shell
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F

docker compose up -d
```

grafana setup:
login and set new passwd

Once you have logged in, click on the “Connections” icon in the left-hand menu, then click on “Data Sources”. Click on the “Add data source” button and select “Prometheus” as the data source type. Configure the URL to http://prometheus:9090 (muss prometheus:... sein) and click on the "Save & Test" button

### 2. Überwachung der Dienste

erlauben in firewall sowohl in router als auch in vm... (ggf noch zu viel erlaubt)

```shell
      # Allow: prometheus exporter
      iptables -A INPUT -p tcp --dport 9100 -j ACCEPT
      iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 9100 -j ACCEPT 
      iptables -A OUTPUT -p tcp --dport 9090 -j ACCEPT
```

#### 2.1) Betriebssystem

anpassen von der prometheus.yml:

```yml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'os-vm1'
    static_configs:
      - targets: ['192.168.3.1:9100']
  - job_name: 'os-vm2'
    static_configs:
      - targets: ['192.168.3.2:9100']
```

und dann noch den node exporter zu den vms hinzufügen:

#### 2.2) Netzwerk

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


#### 2.4) DHCP

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

blackbox config:

```yml
# blackbox.yml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      preferred_ip_protocol: ip4
  http_post_2xx:
    prober: http
    timeout: 5s
    http:
      method: POST
      basic_auth:
        username: "username"
        password: "mysecret"
      body_size_limit: 1MB
  tcp_connect:
    prober: tcp
    timeout: 5s
  icmp_test:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: ip4
  dns_test:
    prober: dns
    timeout: 5s
    dns:
      query_name: example.com
      preferred_ip_protocol: ip4
      ip_protocol_fallback: false
      validate_answer_rrs:
        fail_if_matches_regexp: [test]
```

neuer prometheus job:

```yml
# prometheus.yml
- job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]  # Look for a HTTP 200 response.
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
        replacement: blackbox:9115  # muss blackbox: ... sein
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

cadvisor zu homeassistant compose file:

```yml
  cadvisor:
    container_name: cadvisor
    image: google/cadvisor:latest
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
```

grafana: https://grafana.com/grafana/dashboards/10619-docker-host-container-overview/

#### 2.8) Fileserver


#### 2.9) LDAP


#### 2.10) Mail
