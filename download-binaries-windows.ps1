# Download-Script für ModularWebserverSystem (Windows)
# Lädt MariaDB und Apache automatisch herunter und entpackt sie

param(
    [string]$MariaDBVersion = "12.0.0",
    [string]$ApacheVersion = "2.4.65"
)

$ErrorActionPreference = "Stop"

Write-Host "=== ModularWebserverSystem - Windows Binary Download ===" -ForegroundColor Cyan
Write-Host ""

# Arbeitsverzeichnis
$basePath = $PSScriptRoot
$downloadPath = Join-Path $basePath "temp_download"
$targetPath = Join-Path $basePath "win-x64"

# Download-URLs (Hinweis: Diese URLs können sich ändern!)
$mariadbUrl = "https://archive.mariadb.org/mariadb-$MariaDBVersion/winx64-packages/mariadb-$MariaDBVersion-winx64.zip"
$apacheUrl = "https://www.apachelounge.com/download/VS17/binaries/httpd-$ApacheVersion-240902-win64-VS17.zip"

Write-Host "[INFO] Download-Verzeichnis: $downloadPath" -ForegroundColor Yellow
Write-Host "[INFO] Zielverzeichnis: $targetPath" -ForegroundColor Yellow
Write-Host ""

# Temp-Verzeichnis erstellen
if (!(Test-Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath | Out-Null
    Write-Host "[OK] Download-Verzeichnis erstellt" -ForegroundColor Green
}

# ========== MariaDB Download ==========
Write-Host ""
Write-Host "--- MariaDB Download ---" -ForegroundColor Cyan
$mariadbZip = Join-Path $downloadPath "mariadb.zip"
$mariadbExtract = Join-Path $downloadPath "mariadb_extracted"

try {
    Write-Host "[DOWNLOAD] MariaDB $MariaDBVersion wird heruntergeladen..." -ForegroundColor Yellow
    Write-Host "           Von: $mariadbUrl" -ForegroundColor Gray
    
    Invoke-WebRequest -Uri $mariadbUrl -OutFile $mariadbZip -UseBasicParsing
    Write-Host "[OK] MariaDB heruntergeladen" -ForegroundColor Green
    
    Write-Host "[EXTRACT] Entpacke MariaDB..." -ForegroundColor Yellow
    Expand-Archive -Path $mariadbZip -DestinationPath $mariadbExtract -Force
    
    # Finde das extrahierte Verzeichnis
    $mariadbDir = Get-ChildItem -Path $mariadbExtract -Directory | Select-Object -First 1
    
    if ($mariadbDir) {
        # Kopiere relevante Dateien
        $targetMariaDB = Join-Path $targetPath "mariadb"
        
        # Bin-Verzeichnis kopieren
        Write-Host "[COPY] Kopiere MariaDB Binaries..." -ForegroundColor Yellow
        $sourceBin = Join-Path $mariadbDir.FullName "bin"
        $targetBin = Join-Path $targetMariaDB "bin"
        
        if (Test-Path $sourceBin) {
            Copy-Item -Path $sourceBin -Destination $targetBin -Recurse -Force
            Write-Host "[OK] MariaDB Binaries kopiert" -ForegroundColor Green
        }
        
        # Share/Lib Verzeichnisse (falls benötigt)
        $sourceShare = Join-Path $mariadbDir.FullName "share"
        $targetShare = Join-Path $targetMariaDB "share"
        if (Test-Path $sourceShare) {
            Copy-Item -Path $sourceShare -Destination $targetShare -Recurse -Force
        }
        
        $sourceLib = Join-Path $mariadbDir.FullName "lib"
        $targetLib = Join-Path $targetMariaDB "lib"
        if (Test-Path $sourceLib) {
            Copy-Item -Path $sourceLib -Destination $targetLib -Recurse -Force
        }
    }
    
} catch {
    Write-Host "[ERROR] MariaDB Download fehlgeschlagen: $_" -ForegroundColor Red
    Write-Host "[INFO] Versuche alternative Methode oder lade manuell herunter von:" -ForegroundColor Yellow
    Write-Host "       https://mariadb.org/download/" -ForegroundColor Gray
}

# ========== Apache Download ==========
Write-Host ""
Write-Host "--- Apache Download ---" -ForegroundColor Cyan
$apacheZip = Join-Path $downloadPath "apache.zip"
$apacheExtract = Join-Path $downloadPath "apache_extracted"

try {
    Write-Host "[DOWNLOAD] Apache $ApacheVersion wird heruntergeladen..." -ForegroundColor Yellow
    Write-Host "           Von: $apacheUrl" -ForegroundColor Gray
    
    Invoke-WebRequest -Uri $apacheUrl -OutFile $apacheZip -UseBasicParsing
    Write-Host "[OK] Apache heruntergeladen" -ForegroundColor Green
    
    Write-Host "[EXTRACT] Entpacke Apache..." -ForegroundColor Yellow
    Expand-Archive -Path $apacheZip -DestinationPath $apacheExtract -Force
    
    # Finde das extrahierte Verzeichnis
    $apacheDir = Get-ChildItem -Path $apacheExtract -Directory -Filter "Apache*" | Select-Object -First 1
    
    if ($apacheDir) {
        # Kopiere relevante Dateien
        $targetApache = Join-Path $targetPath "apache"
        
        Write-Host "[COPY] Kopiere Apache Dateien..." -ForegroundColor Yellow
        
        # Bin-Verzeichnis
        $sourceBin = Join-Path $apacheDir.FullName "bin"
        $targetBin = Join-Path $targetApache "bin"
        if (Test-Path $sourceBin) {
            Copy-Item -Path $sourceBin -Destination $targetBin -Recurse -Force
        }
        
        # Modules-Verzeichnis
        $sourceModules = Join-Path $apacheDir.FullName "modules"
        $targetModules = Join-Path $targetApache "modules"
        if (Test-Path $sourceModules) {
            Copy-Item -Path $sourceModules -Destination $targetModules -Recurse -Force
        }
        
        # Conf-Verzeichnis (Merge mit bestehendem)
        $sourceConf = Join-Path $apacheDir.FullName "conf"
        if (Test-Path $sourceConf) {
            $originalConf = Get-Content (Join-Path $targetApache "conf\httpd.conf") -Raw
            Copy-Item -Path "$sourceConf\*" -Destination (Join-Path $targetApache "conf") -Recurse -Force
            # Stelle original httpd.conf wieder her
            Set-Content -Path (Join-Path $targetApache "conf\httpd.conf") -Value $originalConf
        }
        
        Write-Host "[OK] Apache Dateien kopiert" -ForegroundColor Green
    }
    
} catch {
    Write-Host "[ERROR] Apache Download fehlgeschlagen: $_" -ForegroundColor Red
    Write-Host "[INFO] Versuche alternative Methode oder lade manuell herunter von:" -ForegroundColor Yellow
    Write-Host "       https://www.apachelounge.com/download/" -ForegroundColor Gray
}

# ========== Cleanup ==========
Write-Host ""
Write-Host "--- Cleanup ---" -ForegroundColor Cyan
try {
    Remove-Item -Path $downloadPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Temporäre Dateien gelöscht" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Temporäre Dateien konnten nicht gelöscht werden: $downloadPath" -ForegroundColor Yellow
}

# ========== Zusammenfassung ==========
Write-Host ""
Write-Host "=== Download abgeschlossen ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Yellow
Write-Host "1. Prüfe ob alle Dateien vorhanden sind:" -ForegroundColor White
Write-Host "   - win-x64\mariadb\bin\mysqld.exe" -ForegroundColor Gray
Write-Host "   - win-x64\mariadb\bin\mysql_install_db.exe" -ForegroundColor Gray
Write-Host "   - win-x64\apache\bin\httpd.exe" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Kompiliere das Projekt:" -ForegroundColor White
Write-Host "   dotnet publish -c Release -r win-x64 --self-contained true" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Starte den Server:" -ForegroundColor White
Write-Host "   .\bin\Release\net8.0\win-x64\publish\ModularWebserverSystem.exe" -ForegroundColor Gray
Write-Host ""

# Prüfe ob kritische Dateien vorhanden sind
$criticalFiles = @(
    "win-x64\mariadb\bin\mysqld.exe",
    "win-x64\apache\bin\httpd.exe"
)

$allPresent = $true
foreach ($file in $criticalFiles) {
    $fullPath = Join-Path $basePath $file
    if (!(Test-Path $fullPath)) {
        Write-Host "[FEHLT] $file" -ForegroundColor Red
        $allPresent = $false
    } else {
        Write-Host "[OK] $file vorhanden" -ForegroundColor Green
    }
}

if ($allPresent) {
    Write-Host ""
    Write-Host "[OK] Alle kritischen Dateien vorhanden!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[WARN] Einige Dateien fehlen. Bitte manuell herunterladen." -ForegroundColor Yellow
}
