using System.Text.Json.Serialization;

namespace ModularWebserverSystem;

public class ServerConfig
{
    public ServerSettings Server { get; set; } = new();
    public DatabaseSettings Database { get; set; } = new();
    public PerformanceSettings Performance { get; set; } = new();
    public LoggingSettings Logging { get; set; } = new();
}

public class ServerSettings
{
    public MySQLServerSettings MySQL { get; set; } = new();
    public ApacheServerSettings Apache { get; set; } = new();
}

public class MySQLServerSettings
{
    public int Port { get; set; } = 3306;
    public string BindAddress { get; set; } = "127.0.0.1";
    public string DataDirectory { get; set; } = "data";
}

public class ApacheServerSettings
{
    public int Port { get; set; } = 80;
    public string BindAddress { get; set; } = "0.0.0.0";
    public string DocumentRoot { get; set; } = "www";
}

public class DatabaseSettings
{
    public List<string> DefaultDatabases { get; set; } = new() { "testdb" };
    public string CharacterSet { get; set; } = "utf8mb4";
    public string Collation { get; set; } = "utf8mb4_unicode_ci";
}

public class PerformanceSettings
{
    public MySQLPerformanceSettings MySQL { get; set; } = new();
}

public class MySQLPerformanceSettings
{
    public int MaxConnections { get; set; } = 100;
    public string InnoDBBufferPoolSize { get; set; } = "128M";
}

public class LoggingSettings
{
    public MySQLLoggingSettings MySQL { get; set; } = new();
    public ApacheLoggingSettings Apache { get; set; } = new();
}

public class MySQLLoggingSettings
{
    public string ErrorLog { get; set; } = "mysql_error.log";
}

public class ApacheLoggingSettings
{
    public string ErrorLog { get; set; } = "logs/error.log";
    public string AccessLog { get; set; } = "logs/access.log";
}
