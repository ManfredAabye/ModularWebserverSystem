# ⚠️This is a feasibility study and has no practical use yet

# ModularWebserverSystem (MoWe3S) - .NET 8.0

Cross-Platform portables Server-System mit Apache und MariaDB.

## Projektstruktur

```bash
ModularWebserverSystem/
├── ModularWebserverSystem.csproj   # .NET 8.0 Projektdatei
├── Program.cs                      # Hauptprogramm
├── Mow3sConfig.cs                  # Konfigurationsklassen
├── mow3s.config.json               # Konfigurationsdatei (Ports, Adressen, etc.)
├── setup-project.ps1               # Setup-Script für Windows
├── setup-project.sh                # Setup-Script für Linux/macOS
├── clean.bat                       # Clean-Script für Windows
├── clean.sh                        # Clean-Script für Linux/macOS
├── download-binaries-windows.ps1   # Automatischer Download für Windows
├── download-binaries-linux.sh      # Automatischer Download für Linux
├── .gitattributes                  # Git Line-Ending Configuration
├── win-x64/                        # Windows Binaries
│   ├── mariadb/
│   │   ├── bin/                    # HIER: mysqld.exe, mysql_install_db.exe einfügen
│   │   └── my.ini
│   └── apache/
│       ├── bin/                    # HIER: httpd.exe einfügen
│       ├── modules/
│       └── conf/
│           └── httpd.conf
├── linux-x64/                      # Linux Binaries
│   ├── mariadb/
│   │   ├── bin/                    # HIER: mysqld, mysql_install_db einfügen
│   │   └── my.cnf
│   └── apache/
│       ├── bin/                    # HIER: httpd einfügen
│       ├── modules/
│       └── conf/
│           └── httpd.conf
├── osx-x64/                        # macOS Binaries
│   ├── mariadb/
│   │   ├── bin/                    # HIER: mysqld, mysql_install_db einfügen
│   │   └── my.cnf
│   └── apache/
│       ├── bin/                    # HIER: httpd einfügen
│       ├── modules/
│       └── conf/
│           └── httpd.conf
├── www/                            # Webroot (OS-unabhängig)
│   └── index.html
└── data/                           # Wird automatisch erstellt
```

## Voraussetzungen

1. **.NET 8.0 SDK** installiert
2. **Server-Binaries** für jede Plattform (automatisch oder manuell)

## Schnellstart

### 1. Projekt Setup

**Windows:**

```powershell
.\setup-project.ps1
```

**Linux/macOS:**

```bash
chmod +x setup-project.sh
./setup-project.sh
```

### 2. Server-Binaries installieren

#### Automatischer Download (empfohlen)

**Windows:**

```powershell
.\download-binaries-windows.ps1
```

**Linux:**

```bash
chmod +x download-binaries-linux.sh
sudo ./download-binaries-linux.sh
```

#### Manuelle Installation

**Windows:**

- MariaDB 12.0: <https://mariadb.org/download/>
- Apache 2.4.65: <https://www.apachelounge.com/download/>

**Linux:**

```bash
sudo apt-get install mariadb-server apache2
# Binaries nach linux-x64/ kopieren
```

**macOS:**

```bash
brew install mariadb httpd
# Binaries nach osx-x64/ kopieren
```

### 3. Kompilieren

```bash
# Windows
dotnet publish -c Release -r win-x64 --self-contained true -o publish/win-x64

# Linux
dotnet publish -c Release -r linux-x64 --self-contained true -o publish/linux-x64

# macOS
dotnet publish -c Release -r osx-x64 --self-contained true -o publish/osx-x64
```

### 4. Ausführen

**Windows:**

```powershell
.\publish\win-x64\ModularWebserverSystem.exe
```

**Linux/macOS:**

```bash
chmod +x ./publish/linux-x64/ModularWebserverSystem
./publish/linux-x64/ModularWebserverSystem
```

## Konfiguration

Die `mow3s.config.json` Datei ermöglicht die Anpassung aller wichtigen Einstellungen:

```json
{
  "Server": {
    "MySQL": {
      "Port": 3306,
      "BindAddress": "127.0.0.1",
      "DataDirectory": "data"
    },
    "Apache": {
      "Port": 80,
      "BindAddress": "0.0.0.0",
      "DocumentRoot": "www"
    }
  },
  "Database": {
    "DefaultDatabases": ["testdb"],
    "CharacterSet": "utf8mb4",
    "Collation": "utf8mb4_unicode_ci"
  },
  "Performance": {
    "MySQL": {
      "MaxConnections": 100,
      "InnoDBBufferPoolSize": "128M"
    }
  }
}
```

Du kannst Ports, Bind-Adressen, Verzeichnisse und Datenbanknamen nach Bedarf anpassen.

## Nach dem Start

- **Apache:** Konfigurierbar via `mow3s.config.json` (Standard: Port 80)
- **MySQL:** Konfigurierbar via `mow3s.config.json` (Standard: Port 3306)
- **Stop:** CTRL+C drücken

## Wichtige Hinweise

1. **Ports 80 und 3306** müssen frei sein
2. **Administrator/Root-Rechte** können erforderlich sein (Port 80)
3. **Firewall-Regeln** eventuell anpassen
4. Die **data/** Ordner wird automatisch erstellt
5. **Konfigurationsdateien** müssen an die jeweilige Apache/MariaDB-Version angepasst werden

## Logs

- MariaDB: `data/mysql_error.log`
- Apache: `{platform}/apache/logs/error.log`

## Projekt aufräumen

**Windows:**

```cmd
clean.bat
```

**Linux/macOS:**

```bash
chmod +x clean.sh
./clean.sh
```

Löscht alle Build-Artefakte (bin/, obj/, *.sln,*.bak, *.csproj.user, publish/)

## Features

- [OK] Cross-Platform (Windows, Linux, macOS)
- [OK] Automatische OS-Detection
- [OK] Async/Await Pattern
- [OK] Sauberes Shutdown-Management
- [OK] Keine Emojis (ASCII-only für Kompatibilität)
- [OK] Single-File Deployment möglich
- [OK] Plattform-spezifische Binaries - Automatische Auswahl basierend auf OS
- [OK] Konfigurierbar via JSON-Datei
- [OK] Automatische Download-Scripts für Server-Binaries
- [OK] Setup- und Clean-Scripts für alle Plattformen

## Technische Details

- **.NET 8.0** mit C# 12
- **MariaDB 12.0** (neueste stabile Version)
- **Apache 2.4.65** (neueste stabile Version)
- **System.Text.Json** für Konfiguration
- **Cross-Platform Process Management**

## Lizenz

Frei verwendbar für eigene Projekte.

## Troubleshooting

### Port bereits belegt

Ändere die Ports in `mow3s.config.json`

### Binaries fehlen

Führe die Download-Scripts aus oder installiere manuell

### Permission Denied (Linux/macOS)

```bash
chmod +x ModularWebserverSystem
sudo ./ModularWebserverSystem  # Falls Port < 1024
```

### Datenbank startet nicht

Prüfe Logs in `data/mysql_error.log`

### Apache startet nicht

Prüfe Logs in `{platform}/apache/logs/error.log`

