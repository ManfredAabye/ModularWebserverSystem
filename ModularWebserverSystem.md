# ModularWebserverSystem **.NET 8.0** (MoWeS)

## 🚀 **C# Konsolen-App (.NET 8.0) - Cross-Platform**

## 1. **Project File (.csproj)**

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <PublishSingleFile>true</PublishSingleFile>
    <SelfContained>true</SelfContained>
    <IncludeNativeLibrariesForSelfExtract>true</IncludeNativeLibrariesForSelfExtract>
  </PropertyGroup>

</Project>
```

## 2. **Program.cs (.NET 8.0 Style)**

```csharp
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace ModularWebserverSystem;

class Program
{
    private static Process? _mysqlProcess;
    private static Process? _apacheProcess;
    private static readonly string _basePath = AppContext.BaseDirectory;
    private static bool _isRunning = true;
    private static readonly bool _isWindows = RuntimeInformation.IsOSPlatform(OSPlatform.Windows);
    private static readonly bool _isLinux = RuntimeInformation.IsOSPlatform(OSPlatform.Linux);
    private static readonly bool _isMacOS = RuntimeInformation.IsOSPlatform(OSPlatform.OSX);

    static async Task Main(string[] args)
    {
        Console.Title = "Portable Server";
        
        // CTRL+C Handler
        Console.CancelKeyPress += (sender, e) =>
        {
            e.Cancel = true;
            _isRunning = false;
        };

        Console.WriteLine("=== Portable Server Starting ===");
        Console.WriteLine($"Platform: {RuntimeInformation.OSDescription}");
        Console.WriteLine($"Path: {_basePath}");

        try
        {
            await StartServersAsync();
            
            Console.WriteLine("\n[OK] Server erfolgreich gestartet!");
            Console.WriteLine("[DB] MySQL: localhost:3306");
            Console.WriteLine("[WEB] Apache: http://localhost:80");
            Console.WriteLine("\nDruecke CTRL+C zum Beenden...");

            // Haupt-Loop
            while (_isRunning)
            {
                await Task.Delay(1000);

                // Pruefen ob Prozesse noch laufen
                if (_mysqlProcess?.HasExited == true)
                {
                    Console.WriteLine("[ERROR] MySQL wurde unerwartet beendet!");
                    break;
                }

                if (_apacheProcess?.HasExited == true)
                {
                    Console.WriteLine("[ERROR] Apache wurde unerwartet beendet!");
                    break;
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ERROR] Fehler: {ex.Message}");
        }
        finally
        {
            await StopServersAsync();
        }
    }

    static async Task StartServersAsync()
    {
        Console.WriteLine("\nStarting MariaDB...");
        _mysqlProcess = StartMariaDB();
        
        Console.WriteLine("Starting Apache...");
        _apacheProcess = StartApache();
        
        // Warten bis Server hochgefahren sind
        await Task.Delay(3000);
    }

    static Process StartMariaDB()
    {
        string platformDir = GetPlatformDirectory();
        string mysqlExe = GetExecutablePath(platformDir, "mariadb", "bin", _isWindows ? "mysqld.exe" : "mysqld");
        string dataDir = Path.Combine(_basePath, "data");
        string configFile = Path.Combine(_basePath, platformDir, "mariadb", _isWindows ? "my.ini" : "my.cnf");

        // Datenverzeichnis erstellen falls nicht vorhanden
        if (!Directory.Exists(dataDir))
        {
            Console.WriteLine("Creating data directory...");
            Directory.CreateDirectory(dataDir);
        }

        // Pruefen ob Datenbank initialisiert werden muss
        if (!Directory.Exists(Path.Combine(dataDir, "mysql")))
        {
            Console.WriteLine("Initializing database...");
            InitializeDatabase(platformDir);
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = mysqlExe,
            Arguments = $"--defaults-file=\"{configFile}\" --datadir=\"{dataDir}\" --port=3306",
            UseShellExecute = false,
            CreateNoWindow = _isWindows,
            RedirectStandardOutput = !_isWindows,
            RedirectStandardError = !_isWindows,
            WorkingDirectory = Path.GetDirectoryName(mysqlExe)
        };

        var process = Process.Start(startInfo);
        if (process == null)
            throw new InvalidOperationException("MySQL konnte nicht gestartet werden");
        
        return process;
    }

    static Process StartApache()
    {
        string platformDir = GetPlatformDirectory();
        string apacheExe = GetExecutablePath(platformDir, "apache", "bin", _isWindows ? "httpd.exe" : "httpd");
        string configFile = Path.Combine(_basePath, platformDir, "apache", "conf", "httpd.conf");

        var startInfo = new ProcessStartInfo
        {
            FileName = apacheExe,
            Arguments = $"-f \"{configFile}\"",
            UseShellExecute = false,
            CreateNoWindow = _isWindows,
            RedirectStandardOutput = !_isWindows,
            RedirectStandardError = !_isWindows,
            WorkingDirectory = Path.GetDirectoryName(apacheExe)
        };

        var process = Process.Start(startInfo);
        if (process == null)
            throw new InvalidOperationException("Apache konnte nicht gestartet werden");
        
        return process;
    }

    static void InitializeDatabase(string platformDir)
    {
        string initExe = GetExecutablePath(platformDir, "mariadb", "bin", 
            _isWindows ? "mysql_install_db.exe" : "mysql_install_db");
        string dataDir = Path.Combine(_basePath, "data");

        if (!File.Exists(initExe))
        {
            Console.WriteLine("[ERROR] mysql_install_db nicht gefunden!");
            return;
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = initExe,
            Arguments = $"--datadir=\"{dataDir}\"",
            UseShellExecute = false,
            CreateNoWindow = _isWindows,
            WorkingDirectory = Path.GetDirectoryName(initExe)
        };

        using var process = Process.Start(startInfo);
        if (process == null) return;
        
        process.WaitForExit(30000); // 30 Sekunden Timeout
        if (!process.HasExited)
        {
            process.Kill();
            Console.WriteLine("[ERROR] Datenbank-Initialisierung timeout!");
        }
    }

    static async Task StopServersAsync()
    {
        Console.WriteLine("\n[STOP] Stopping servers...");
        
        try
        {
            var tasks = new List<Task>();

            // MySQL stoppen
            if (_mysqlProcess is { HasExited: false })
            {
                Console.WriteLine("Stopping MySQL...");
                tasks.Add(KillProcessAsync(_mysqlProcess, "MySQL"));
            }

            // Apache stoppen
            if (_apacheProcess is { HasExited: false })
            {
                Console.WriteLine("Stopping Apache...");
                tasks.Add(KillProcessAsync(_apacheProcess, "Apache"));
            }

            // Auf Beenden warten
            if (tasks.Count > 0)
            {
                await Task.WhenAll(tasks);
            }

            // Verwaiste Prozesse beenden
            KillProcessesByName("mysqld");
            KillProcessesByName("httpd");

            Console.WriteLine("[OK] Server gestoppt.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ERROR] Fehler beim Stoppen: {ex.Message}");
        }
    }

    static async Task KillProcessAsync(Process process, string name)
    {
        try
        {
            process.Kill();
            
            // Korrekte Verwendung von WaitForExitAsync mit CancellationToken
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            await process.WaitForExitAsync(cts.Token);
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine($"[WARN] {name} Timeout - forciere Beendigung");
            try { process.Kill(true); } catch { /* Ignorieren */ }
        }
        catch
        {
            Console.WriteLine($"[ERROR] {name} konnte nicht gestoppt werden!");
        }
    }

    static void KillProcessesByName(string processName)
    {
        try
        {
            foreach (var process in Process.GetProcessesByName(processName))
            {
                try
                {
                    if (!process.HasExited)
                    {
                        process.Kill();
                        process.WaitForExit(3000);
                    }
                }
                catch
                {
                    // Ignorieren falls Prozess nicht beendet werden kann
                }
                finally
                {
                    process.Dispose();
                }
            }
        }
        catch
        {
            // Ignorieren
        }
    }

    static string GetPlatformDirectory()
    {
        if (_isWindows) return "win-x64";
        if (_isLinux) return "linux-x64";
        if (_isMacOS) return "osx-x64";
        throw new PlatformNotSupportedException("Nicht unterstuetztes Betriebssystem");
    }

    static string GetExecutablePath(string platformDir, params string[] pathParts)
    {
        var fullPath = Path.Combine(_basePath, platformDir);
        foreach (var part in pathParts)
        {
            fullPath = Path.Combine(fullPath, part);
        }
        return fullPath;
    }
}
```

## 3. **Kompilieren & Publishen**

```bash
# Für Windows
dotnet publish -c Release -r win-x64 --self-contained true

# Für Linux (falls benötigt)
dotnet publish -c Release -r linux-x64 --self-contained true

# Für macOS (falls benötigt)
dotnet publish -c Release -r osx-x64 --self-contained true
```

## 4. **Verzeichnisstruktur**

```bash
ModularWebserverSystem/
├── ModularWebserverSystem.exe          # .NET 8.0 EXE (Windows)
├── ModularWebserverSystem              # .NET 8.0 Binary (Linux/macOS)
│
├── win-x64/                    # Windows Binaries
│   ├── mariadb/
│   │   ├── bin/
│   │   │   ├── mysqld.exe
│   │   │   └── mysql_install_db.exe
│   │   └── my.ini
│   └── apache/
│       ├── bin/
│       │   └── httpd.exe
│       └── conf/
│           └── httpd.conf
│
├── linux-x64/                  # Linux Binaries
│   ├── mariadb/
│   │   ├── bin/
│   │   │   ├── mysqld
│   │   │   └── mysql_install_db
│   │   └── my.cnf
│   └── apache/
│       ├── bin/
│       │   └── httpd
│       └── conf/
│           └── httpd.conf
│
├── osx-x64/                    # macOS Binaries
│   ├── mariadb/
│   │   ├── bin/
│   │   │   ├── mysqld
│   │   │   └── mysql_install_db
│   │   └── my.cnf
│   └── apache/
│       ├── bin/
│       │   └── httpd
│       └── conf/
│           └── httpd.conf
│
├── data/                       # Wird automatisch erstellt (OS-unabhaengig)
└── www/                        # Webroot (OS-unabhaengig)
```

**Diese Version:**

- [OK] **.NET 8.0** - Modern & Cross-Platform
- [OK] **Win10/11 + Linux/macOS** kompatibel mit OS-Detection
- [OK] **Async/Await** - Moderne Pattern mit korrektem CancellationToken
- [OK] **Nullable Reference Types** - Type Safety
- [OK] **Single File Deployment** möglich
- [OK] **Plattform-spezifische Binaries** - Automatische Auswahl basierend auf OS
- [OK] **Keine Emojis** - Nur ASCII-Output für bessere Kompatibilität
