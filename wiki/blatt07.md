# Aufgabenblatt 07

In diesem Blatt geht es darum einen Fileserver für alle Daten einzurichten. Dieser wird bei uns auf VM 8 gehostet.

## Teilaufgaben

### 1) Hardware Konfiguration

#### 1.1) Einrichten der neuen Festplatten

Für die benötigte Ausfallsicherheit reicht RAID 5 aus und hat zudem eine vergleichsweise gute Disk-Space-Efficiency. Die Anforderung, 10GB an Speicher bei 2GB Festplatten zu haben wird laut [Online RAID Rechner](https://www.gigacalculator.com/calculators/raid-calculator.php) mit 6 Festplatten erreicht. Nur um sicher zu gehen werden wir im folgenden 7 Festplatten verwenden.

1. Erstellen der VM
   Wie bei vorherigen VMs durch Ausführung von `./create_vm 03 08`, jedoch wird der letzte Schritt, das Starten der VM ausgesetzt.

2. Hinzufügen der Festplatten
   In VirtualBox können diese unter `Settings > Storage > Devices` graphisch angelegt werden. Hierfür einen neuen SATA Controller anlegen und diesem 7 Festplatten (`.vdi`) mit je 2GB anhängen.

   ![image](https://github.com/user-attachments/assets/91df6a54-8cbd-4fb0-8d3a-041a3e59ca51)

3. Mit der Installation von NixOS fortfahren (siehe [Blatt 01](blatt01.md)).

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
