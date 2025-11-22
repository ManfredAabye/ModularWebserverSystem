# ⚠️This is a feasibility study and has no practical use yet

# ModularWebserverSystem (MoW₃S) - .NET 8.0

Cross-Platform portables Server-System mit Apache und MariaDB.

## Projektstruktur

```bash
ModularWebserverSystem/
├── ModularWebserverSystem.csproj   # .NET 8.0 Projektdatei
├── Program.cs                      # Hauptprogramm
├── win-x64/                        # Windows Binaries
│   ├── mariadb/
│   │   ├── bin/                    # HIER: mysqld.exe, mysql_install_db.exe einfügen
│   │   └── my.ini
│   └── apache/
│       ├── bin/                    # HIER: httpd.exe einfügen
│       └── conf/
│           └── httpd.conf
├── linux-x64/                      # Linux Binaries
│   ├── mariadb/
│   │   ├── bin/                    # HIER: mysqld, mysql_install_db einfügen
│   │   └── my.cnf
│   └── apache/
│       ├── bin/                    # HIER: httpd einfügen
│       └── conf/
│           └── httpd.conf
├── osx-x64/                        # macOS Binaries
│   ├── mariadb/
│   │   ├── bin/                    # HIER: mysqld, mysql_install_db einfügen
│   │   └── my.cnf
│   └── apache/
│       ├── bin/                    # HIER: httpd einfügen
│       └── conf/
│           └── httpd.conf
├── www/                            # Webroot (OS-unabhängig)
│   └── index.html
└── data/                           # Wird automatisch erstellt
```

## Voraussetzungen

1. **.NET 8.0 SDK** installiert
2. **Server-Binaries** für jede Plattform:
   - **Windows**: MariaDB + Apache für Windows herunterladen
   - **Linux**: MariaDB + Apache Binaries
   - **macOS**: MariaDB + Apache Binaries

## Installation der Server-Binaries

### Automatischer Download (empfohlen)

#### Windows psowershell

```powershell
# Führe das Download-Script aus
.\download-binaries-windows.ps1

# Optional: Spezifische Versionen angeben
.\download-binaries-windows.ps1 -MariaDBVersion "11.4.0" -ApacheVersion "2.4.62"
```

Das Script lädt automatisch MariaDB und Apache herunter und kopiert die Binaries in die richtigen Verzeichnisse.

#### Linux bash

```bash
# Script ausführbar machen
chmod +x download-binaries-linux.sh

# Mit sudo ausführen (benötigt Root-Rechte)
sudo ./download-binaries-linux.sh
```

Das Script installiert MariaDB und Apache über den Paketmanager und kopiert die Binaries.

### Manuelle Installation

#### Windows

```powershell
# MariaDB für Windows herunterladen
# Von: https://mariadb.org/download/
# Dateien extrahieren nach: win-x64\mariadb\bin\

# Apache für Windows herunterladen
# Von: https://www.apachelounge.com/download/
# Dateien extrahieren nach: win-x64\apache\bin\
```

#### Linux

```bash
# MariaDB installieren und Binaries kopieren
sudo apt-get install mariadb-server
# Binaries von /usr/sbin nach linux-x64/mariadb/bin/ kopieren

# Apache installieren und Binaries kopieren
sudo apt-get install apache2
# Binaries von /usr/sbin nach linux-x64/apache/bin/ kopieren
```

#### macOS

```bash
# Mit Homebrew installieren
brew install mariadb
brew install httpd

# Binaries kopieren nach osx-x64/mariadb/bin/ und osx-x64/apache/bin/
```

## Kompilieren

### Für alle Plattformen einzeln

```bash
# Windows
dotnet publish -c Release -r win-x64 --self-contained true -o publish/win-x64

# Linux
dotnet publish -c Release -r linux-x64 --self-contained true -o publish/linux-x64

# macOS
dotnet publish -c Release -r osx-x64 --self-contained true -o publish/osx-x64
```

## Ausführen

### Windows Start

```powershell
.\ModularWebserverSystem.exe
```

### Linux/macOS Start

```bash
chmod +x ModularWebserverSystem
./ModularWebserverSystem
```

## Nach dem Start

- **Apache**: <http://localhost:80>
- **MySQL**: localhost:3306
- **Stop**: CTRL+C drücken

## Wichtige Hinweise

1. **Ports 80 und 3306** müssen frei sein
2. **Administrator/Root-Rechte** können erforderlich sein (Port 80)
3. **Firewall-Regeln** eventuell anpassen
4. Die **data/** Ordner wird automatisch erstellt
5. **Konfigurationsdateien** müssen an die jeweilige Apache/MariaDB-Version angepasst werden

## Logs

- MariaDB: `data/mysql_error.log`
- Apache: `{platform}/apache/logs/error.log`

## Features

- [OK] Cross-Platform (Windows, Linux, macOS)
- [OK] Automatische OS-Detection
- [OK] Async/Await Pattern
- [OK] Sauberes Shutdown-Management
- [OK] Keine Emojis (ASCII-only für Kompatibilität)
- [OK] Single-File Deployment möglich

## Lizenz

Frei verwendbar für eigene Projekte.



