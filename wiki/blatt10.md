# Aufgabenblatt 10

In diesem Blatt geht es darum alle bisher erstellten Systeme zentral zu überwachen und bei Bedarf über Fehler informiert zu werden.
Um dies umzusetzen haben wir uns für Prometheus und Grafana entschieden, wobei Prometheus die Metriken sammelt und Grafana diese visualisiert.

Aufgaben:

1. installieren von Prometheus und Grafana
2. Überwachung der Dienste:
    - Betriebssystem -> ping, cpu load, Prozesse
    - Netzwerk -> ping eigene Team VMs, ping andere Team VMs
    - DNS -> verfügbarkeit, prüfe ob Domain test domains auflöst, anzahl Anfragen
    - DHCP -> verfügbarkeit, anzahl anfragen
    - Webserver -> verfügbarkeit (http & https), ladezeit, anzahl anfragen
    - Datenbank -> verfügbarkeit (eigene & Team x), anzahl anfragen
    - Webanwendung -> verfügbarkeit, ladezeit, anzahl anfragen
    - Fileserver -> freien Speicherplatz
    - LDAP -> verfügbarkeit, anzahl anfragen
    - Mail -> Länge der Warteschlange
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

# Create the files
touch /root/docker/docker-compose.yaml
touch /root/docker/alert-manager/alertmanager.yml
touch /root/docker/grafana/grafana.ini
touch /root/docker/prometheus/alert-rules.yml
touch /root/docker/prometheus/prometheus.yml
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
    restart: always

  alertmanager:
    image: prom/alertmanager
    ports:
      - "9093:9093"
    volumes:
      - /root/docker/alert-manager:/config
    command: --config.file=/config/alertmanager.yml --log.level=debug

  web_server:
    image: httpd:2.4
    ports:
      - '80:80'
    restart: always
```

```yml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
  - job_name: 'apache'
    static_configs:
      - targets: ['web_server:80']
rule_files:
  - 'alert-rules.yml'
alerting:
  alertmanagers:
    - scheme: http
    - static_configs:
        - targets: ['host.docker.internal:9093']
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
# grafana.ini
[paths]
data = /var/lib/grafana/data
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins
[server]
http_port = 3000
``` 

```shell
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F

docker compose up -d
```
