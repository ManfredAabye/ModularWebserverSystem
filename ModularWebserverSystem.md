# ModularWebserverSystem (MoWe3S)

## Technische Dokumentation

### Architektur

Das ModularWebserverSystem ist eine .NET 8.0 Konsolenanwendung, die Apache und MariaDB als portable Server-Lösung verwaltet.

#### Hauptkomponenten

1. **Program.cs** - Hauptanwendung mit Prozessmanagement
2. **Mow3sConfig.cs** - Konfigurationsmodell
3. **mow3s.config.json** - Laufzeitkonfiguration

### Prozessmanagement

```bash
Start
  ├─> OS Detection (Windows/Linux/macOS)
  ├─> Config laden (mow3s.config.json)
  ├─> MariaDB starten
  │   ├─> Datenverzeichnis prüfen/erstellen
  │   ├─> DB initialisieren (falls neu)
  │   └─> mysqld Prozess starten
  ├─> Apache starten
  │   └─> httpd Prozess starten
  ├─> Monitoring Loop
  │   └─> Prozesse überwachen
  └─> Shutdown (CTRL+C)
      ├─> MariaDB stoppen
      ├─> Apache stoppen
      └─> Cleanup
```

### Cross-Platform Support

#### OS Detection

```csharp
private static readonly bool _isWindows = RuntimeInformation.IsOSPlatform(OSPlatform.Windows);
private static readonly bool _isLinux = RuntimeInformation.IsOSPlatform(OSPlatform.Linux);
private static readonly bool _isMacOS = RuntimeInformation.IsOSPlatform(OSPlatform.OSX);
```

#### Plattform-spezifische Pfade

```bash
GetPlatformDirectory()
  ├─> Windows -> "win-x64"
  ├─> Linux   -> "linux-x64"
  └─> macOS   -> "osx-x64"
```

### Konfigurationssystem

#### Hierarchie

```bash
Mow3sConfig
  ├─> ServerSettings
  │   ├─> MySQLServerSettings (Port, BindAddress, DataDirectory)
  │   └─> ApacheServerSettings (Port, BindAddress, DocumentRoot)
  ├─> DatabaseSettings (DefaultDatabases, CharacterSet, Collation)
  ├─> PerformanceSettings
  │   └─> MySQLPerformanceSettings (MaxConnections, BufferPoolSize)
  └─> LoggingSettings
      ├─> MySQLLoggingSettings (ErrorLog)
      └─> ApacheLoggingSettings (ErrorLog, AccessLog)
```

#### Laden der Konfiguration

```csharp
LoadConfiguration()
  ├─> Datei existiert?
  │   ├─> Ja: JSON deserialisieren
  │   └─> Nein: Standardwerte verwenden
  └─> Fehlerbehandlung mit Fallback
```

### Prozess-Lifecycle

#### Start

```csharp
StartMariaDB()
  1. Platform-Verzeichnis ermitteln
  2. Executable-Pfad konstruieren
  3. Config-Datei lokalisieren (my.ini/my.cnf)
  4. Datenverzeichnis prüfen
  5. DB initialisieren falls nötig
  6. Prozess mit Argumenten starten
  7. Prozess-Handle zurückgeben
```

#### Stop

```csharp
StopServersAsync()
  1. Beide Prozesse parallel stoppen
  2. Graceful Shutdown mit Timeout (5s)
  3. Force Kill bei Timeout
  4. Verwaiste Prozesse aufräumen
  5. Ressourcen freigeben
```

### Async/Await Pattern

Alle I/O-Operationen sind asynchron:

- `Task Main()`
- `Task StartServersAsync()`
- `Task StopServersAsync()`
- `Task KillProcessAsync()`
- `WaitForExitAsync()` mit CancellationToken

### Fehlerbehandlung

#### Strategien

1. **Try-Catch** um kritische Bereiche
2. **Fallback-Werte** bei Config-Fehlern
3. **Prozess-Monitoring** mit Restart-Erkennung
4. **Graceful Degradation** statt harter Abbrüche

#### Logging

```bash
[OK]      - Erfolgreiche Operation
[ERROR]   - Kritischer Fehler
[WARN]    - Warnung
[INFO]    - Information
[CONFIG]  - Konfiguration geladen
[DELETE]  - Datei/Verzeichnis gelöscht
[STOP]    - Server wird gestoppt
```

### Build-System

#### Project File Features

```xml
<PublishSingleFile>true</PublishSingleFile>        <!-- Eine einzige EXE -->
<SelfContained>true</SelfContained>                <!-- Kein .NET Runtime nötig -->
<IncludeNativeLibrariesForSelfExtract>true</>      <!-- Native Libs einbetten -->
```

#### PreBuild Target

Prüft vor jedem Build ob `mow3s.config.json` existiert.

### Helper-Scripts

#### setup-project.ps1 / .sh

- Erstellt .csproj falls nicht vorhanden
- Konfiguriert Projekt-Einstellungen
- Restored NuGet-Pakete

#### download-binaries-windows.ps1

- Lädt MariaDB 12.0 herunter
- Lädt Apache 2.4.65 herunter
- Entpackt und kopiert Binaries
- Validiert kritische Dateien

#### download-binaries-linux.sh

- Installiert via Paketmanager (apt/yum/dnf)
- Kopiert Binaries aus System-Verzeichnissen
- Unterstützt Debian, RHEL, Fedora

#### clean.bat / .sh

- Löscht bin/, obj/, publish/
- Entfernt .sln, .bak, .csproj.user
- Bereitet für Clean-Build vor

### Git-Integration

#### .gitattributes

```bash
*.sh         -> LF (Linux/macOS)
*.bat *.ps1  -> CRLF (Windows)
*.json *.md  -> LF (plattformunabhängig)
Binaries     -> binary (keine Konvertierung)
```

#### .gitkeep

Leere Dateien in Binary-Verzeichnissen damit Git die Struktur erhält.

### Sicherheitsaspekte

1. **Bind-Address**: Standard auf 127.0.0.1 (nur localhost)
2. **Port-Konfiguration**: Anpassbar für non-privileged Ports
3. **Prozess-Isolation**: Separate Prozesse für DB und Webserver
4. **Kein Root**: Sollte nicht als root/admin laufen (außer bei Port 80)

### Performance-Überlegungen

1. **Async I/O**: Keine blockierenden Operationen
2. **Paralleles Shutdown**: Beide Server gleichzeitig stoppen
3. **Buffer Pool**: Konfigurierbar via mow3s.config.json
4. **Max Connections**: Begrenzt um Ressourcen zu schonen

### Deployment-Optionen

#### Single-File

```bash
dotnet publish -p:PublishSingleFile=true
```

Resultat: Eine einzelne EXE + Config

#### Framework-Dependent

```bash
dotnet publish --self-contained false
```

Kleinere Dateigröße, benötigt .NET Runtime

#### Self-Contained (empfohlen)

```bash
dotnet publish --self-contained true
```

Keine Runtime-Abhängigkeit, größere Dateigröße

### Erweiterungsmöglichkeiten

1. **Weitere Server**: PHP-FPM, nginx, PostgreSQL
2. **Service-Integration**: systemd, Windows Service
3. **Web-UI**: Management-Interface
4. **Auto-Update**: Für Binaries
5. **Backup-System**: Automatische DB-Backups
6. **SSL/TLS**: Zertifikat-Management

### Best Practices

1. **Versionskontrolle**: Git-Workflow verwenden
2. **Config-Management**: mow3s.config.json nicht committen wenn sensitive Daten
3. **Binary-Verwaltung**: Download-Scripts verwenden
4. **Clean Builds**: Regelmäßig clean.sh/bat ausführen
5. **Testing**: Auf allen Zielplattformen testen

### Bekannte Limitierungen

1. **Windows-only Binaries**: Apache/MariaDB müssen für jedes OS separat besorgt werden
2. **Port 80**: Benötigt Admin-Rechte auf Windows, root auf Linux/macOS
3. **Single-Instance**: Kein Multi-Instancing Support
4. **No Hot-Reload**: Config-Änderungen erfordern Neustart

### Versionsinformationen

- **.NET**: 8.0
- **MariaDB**: 12.0.0 (konfigurierbar)
- **Apache**: 2.4.65 (konfigurierbar)
- **Plattformen**: Windows 10/11, Linux (Debian/RHEL), macOS 12+

### Lizenz & Copyright

Frei verwendbar. Keine Garantie. Auf eigene Gefahr nutzen.
