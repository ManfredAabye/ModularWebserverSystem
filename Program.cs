using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json;

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
    private static Mow3sConfig _config = new();

    static async Task Main(string[] args)
    {
        Console.Title = "Portable Server";
        
        // Lade Konfiguration
        _config = LoadConfiguration();
        
        // CTRL+C Handler
        Console.CancelKeyPress += (sender, e) =>
        {
            e.Cancel = true;
            _isRunning = false;
        };

        Console.WriteLine("=== Portable Server Starting ===");
        Console.WriteLine($"Platform: {RuntimeInformation.OSDescription}");
        Console.WriteLine($"Path: {_basePath}");
        Console.WriteLine($"MySQL Port: {_config.Server.MySQL.Port}");
        Console.WriteLine($"Apache Port: {_config.Server.Apache.Port}");

        try
        {
            await StartServersAsync();
            
            Console.WriteLine("\n[OK] Server erfolgreich gestartet!");
            Console.WriteLine($"[DB] MySQL: {_config.Server.MySQL.BindAddress}:{_config.Server.MySQL.Port}");
            Console.WriteLine($"[WEB] Apache: http://{_config.Server.Apache.BindAddress}:{_config.Server.Apache.Port}");
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
        string dataDir = Path.Combine(_basePath, _config.Server.MySQL.DataDirectory);
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
            Arguments = $"--defaults-file=\"{configFile}\" --datadir=\"{dataDir}\" --port={_config.Server.MySQL.Port} --bind-address={_config.Server.MySQL.BindAddress}",
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
        string dataDir = Path.Combine(_basePath, _config.Server.MySQL.DataDirectory);

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

    static Mow3sConfig LoadConfiguration()
    {
        string configPath = Path.Combine(_basePath, "mow3s.config.json");
        
        try
        {
            if (File.Exists(configPath))
            {
                string jsonContent = File.ReadAllText(configPath);
                var config = JsonSerializer.Deserialize<Mow3sConfig>(jsonContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true,
                    ReadCommentHandling = JsonCommentHandling.Skip
                });
                
                if (config != null)
                {
                    Console.WriteLine("[CONFIG] mow3s.config.json geladen");
                    return config;
                }
            }
            else
            {
                Console.WriteLine("[WARN] mow3s.config.json nicht gefunden, verwende Standardwerte");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ERROR] Fehler beim Laden der Konfiguration: {ex.Message}");
            Console.WriteLine("[INFO] Verwende Standardwerte");
        }
        
        return new Mow3sConfig();
    }
}
