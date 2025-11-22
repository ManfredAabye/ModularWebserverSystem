@echo off
REM Download-Script für ModularWebserverSystem Binaries (Windows)
REM Lädt MariaDB und Apache herunter und entpackt sie

setlocal enabledelayedexpansion

REM Konfiguration
set "MARIADB_VERSION=12.0.0"
set "APACHE_VERSION=2.4.65"
set "APACHE_VS_VERSION=VS17"

set "BASE_PATH=%~dp0"
set "DOWNLOAD_PATH=%BASE_PATH%downloads"
set "TARGET_PATH=%BASE_PATH%win-x64"

REM URLs
set "MARIADB_URL=https://archive.mariadb.org/mariadb-12.0.0/winx64-packages/mariadb-12.0.0-winx64.zip"
set "APACHE_URL=https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.65-240902-win64-VS17.zip"

echo === ModularWebserverSystem - Binary Download (Windows) ===
echo.
echo MariaDB Version: %MARIADB_VERSION%
echo Apache Version: %APACHE_VERSION%
echo Download-Verzeichnis: %DOWNLOAD_PATH%
echo Ziel-Verzeichnis: %TARGET_PATH%
echo.

REM Erstelle Verzeichnisse
if not exist "%DOWNLOAD_PATH%" (
    echo [INIT] Erstelle Download-Verzeichnis...
    mkdir "%DOWNLOAD_PATH%"
)

if not exist "%TARGET_PATH%" (
    echo [INIT] Erstelle Ziel-Verzeichnis...
    mkdir "%TARGET_PATH%"
)

REM MariaDB Download
set "MARIADB_ZIP=%DOWNLOAD_PATH%\mariadb-%MARIADB_VERSION%-winx64.zip"

echo.
echo === MariaDB Download ===

if exist "%MARIADB_ZIP%" (
    echo [INFO] MariaDB ZIP existiert bereits
) else (
    echo [DOWNLOAD] Lade MariaDB %MARIADB_VERSION% herunter...
    echo URL: %MARIADB_URL%
    
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%MARIADB_URL%' -OutFile '%MARIADB_ZIP%' -UseBasicParsing }"
    
    if !errorlevel! neq 0 (
        echo [ERROR] MariaDB Download fehlgeschlagen
        exit /b 1
    )
    
    echo [OK] MariaDB heruntergeladen
)

REM MariaDB Entpacken
echo [EXTRACT] Entpacke MariaDB...

powershell -Command "& { Expand-Archive -Path '%MARIADB_ZIP%' -DestinationPath '%DOWNLOAD_PATH%\mariadb-temp' -Force }"

if !errorlevel! neq 0 (
    echo [ERROR] MariaDB Entpacken fehlgeschlagen
    exit /b 1
)

REM MariaDB Dateien kopieren
echo [COPY] Kopiere MariaDB nach %TARGET_PATH%\mysql...

if not exist "%TARGET_PATH%\mysql" mkdir "%TARGET_PATH%\mysql"

xcopy /E /I /Y "%DOWNLOAD_PATH%\mariadb-temp\mariadb-%MARIADB_VERSION%-winx64\*" "%TARGET_PATH%\mysql\"

if !errorlevel! neq 0 (
    echo [ERROR] MariaDB Kopieren fehlgeschlagen
    exit /b 1
)

echo [OK] MariaDB installiert

REM Apache Download
set "APACHE_ZIP=%DOWNLOAD_PATH%\httpd-%APACHE_VERSION%-win64-%APACHE_VS_VERSION%.zip"

echo.
echo === Apache Download ===

if exist "%APACHE_ZIP%" (
    echo [INFO] Apache ZIP existiert bereits
) else (
    echo [DOWNLOAD] Lade Apache %APACHE_VERSION% herunter...
    echo URL: %APACHE_URL%
    
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%APACHE_URL%' -OutFile '%APACHE_ZIP%' -UseBasicParsing }"
    
    if !errorlevel! neq 0 (
        echo [ERROR] Apache Download fehlgeschlagen
        exit /b 1
    )
    
    echo [OK] Apache heruntergeladen
)

REM Apache Entpacken
echo [EXTRACT] Entpacke Apache...

powershell -Command "& { Expand-Archive -Path '%APACHE_ZIP%' -DestinationPath '%DOWNLOAD_PATH%\apache-temp' -Force }"

if !errorlevel! neq 0 (
    echo [ERROR] Apache Entpacken fehlgeschlagen
    exit /b 1
)

REM Apache Dateien kopieren
echo [COPY] Kopiere Apache nach %TARGET_PATH%\apache...

if not exist "%TARGET_PATH%\apache" mkdir "%TARGET_PATH%\apache"

xcopy /E /I /Y "%DOWNLOAD_PATH%\apache-temp\Apache24\*" "%TARGET_PATH%\apache\"

if !errorlevel! neq 0 (
    echo [ERROR] Apache Kopieren fehlgeschlagen
    exit /b 1
)

echo [OK] Apache installiert

REM Cleanup temporäre Dateien
echo.
echo [CLEANUP] Räume temporäre Dateien auf...

if exist "%DOWNLOAD_PATH%\mariadb-temp" (
    rmdir /S /Q "%DOWNLOAD_PATH%\mariadb-temp"
)

if exist "%DOWNLOAD_PATH%\apache-temp" (
    rmdir /S /Q "%DOWNLOAD_PATH%\apache-temp"
)

echo [OK] Cleanup abgeschlossen

REM Validierung
echo.
echo === Validierung ===

set "ALL_OK=1"

if exist "%TARGET_PATH%\mysql\bin\mysqld.exe" (
    echo [OK] MariaDB mysqld.exe gefunden
) else (
    echo [ERROR] MariaDB mysqld.exe nicht gefunden
    set "ALL_OK=0"
)

if exist "%TARGET_PATH%\apache\bin\httpd.exe" (
    echo [OK] Apache httpd.exe gefunden
) else (
    echo [ERROR] Apache httpd.exe nicht gefunden
    set "ALL_OK=0"
)

echo.

if "%ALL_OK%"=="1" (
    echo === Download abgeschlossen - Alle Binaries erfolgreich installiert ===
    echo.
    echo Die Server-Binaries befinden sich in:
    echo - MariaDB: %TARGET_PATH%\mysql
    echo - Apache: %TARGET_PATH%\apache
    echo.
    echo Nächste Schritte:
    echo 1. Konfiguriere mow3s.config.json
    echo 2. Build: dotnet build
    echo 3. Run: dotnet run
) else (
    echo [ERROR] Installation unvollständig - Bitte Fehler prüfen
    exit /b 1
)

echo.
pause
