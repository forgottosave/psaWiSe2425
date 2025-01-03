# Aufgabenblatt 07

In diesem Blatt geht es darum einen Fileserver für alle Daten einzurichten.

## Teilaufgaben

### 1) Hardware Konfiguration

#### 1.1) Einrichten der neuen Festplatten

Für die benötigte Ausfallsicherheit reicht RAID 5 aus und hat zudem eine vergleichsweise gute Disk-Space-Efficiency. Die Anforderung, 10GB an Speicher bei 2GB Festplatten zu haben wird laut [Online RAId Rechner](https://www.gigacalculator.com/calculators/raid-calculator.php) mit 6 Festplatten erreicht. Nur um sicher zu gehen werden wir im folgenden 7 Festplatten verwenden.

#TODO

Quellen:

- [raid calculator](https://www.gigacalculator.com/calculators/raid-calculator.php)

### 2) Datenmigration

#TODO

### 3) Dienste (NFS, SMB/CIFS)

#TODO

### 4) Testen

Das grundlegende Test-Setup bleibt identisch zu den vorherigen Wochen (siehe Blatt03).
Das Skipt kann sowohl auf der Host-VM, als auch auf jeder andern VM mit Verbingung zur Host-VM ausgeführt werden und ändert die zu laufenden Tests automatisch für die jeweilige VM.

#TODO
