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

