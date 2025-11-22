@echo off
REM Setup-Script für ModularWebserverSystem
REM Initialisiert das Projekt falls noch nicht vorhanden

setlocal enabledelayedexpansion

set "PROJECT_NAME=ModularWebserverSystem"
set "BASE_PATH=%~dp0"

echo === %PROJECT_NAME% - Projekt-Setup ===
echo.

REM Prüfe ob .csproj existiert
set "CSPROJ_PATH=%BASE_PATH%%PROJECT_NAME%.csproj"

if not exist "%CSPROJ_PATH%" (
    echo [INIT] Erstelle .csproj Datei...
    
    REM Erstelle Console-Projekt
    cd /d "%BASE_PATH%"
    dotnet new console -n "%PROJECT_NAME%" -f net8.0 --force
    
    REM Entferne generierte Program.cs falls vorhanden
    if exist "%BASE_PATH%Program.cs" (
        move /y "%BASE_PATH%Program.cs" "%BASE_PATH%Program.cs.bak.new" >nul 2>&1
    )
    
    echo [OK] .csproj erstellt
) else (
    echo [INFO] .csproj existiert bereits
)

REM Aktualisiere .csproj mit unseren Einstellungen
echo [UPDATE] Aktualisiere .csproj Einstellungen...

(
echo ^<Project Sdk="Microsoft.NET.Sdk"^>
echo.
echo   ^<PropertyGroup^>
echo     ^<OutputType^>Exe^</OutputType^>
echo     ^<TargetFramework^>net8.0^</TargetFramework^>
echo     ^<ImplicitUsings^>enable^</ImplicitUsings^>
echo     ^<Nullable^>enable^</Nullable^>
echo     ^<PublishSingleFile^>true^</PublishSingleFile^>
echo     ^<SelfContained^>true^</SelfContained^>
echo     ^<IncludeNativeLibrariesForSelfExtract^>true^</IncludeNativeLibrariesForSelfExtract^>
echo   ^</PropertyGroup^>
echo.
echo   ^<ItemGroup^>
echo     ^<None Update="mow3s.config.json"^>
echo       ^<CopyToOutputDirectory^>PreserveNewest^</CopyToOutputDirectory^>
echo     ^</None^>
echo   ^</ItemGroup^>
echo.
echo   ^<Target Name="PreBuildSetup" BeforeTargets="PreBuildEvent"^>
echo     ^<Message Text="[PRE-BUILD] Prüfe Projektstruktur..." Importance="high" /^>
echo     ^<Exec Command="pwsh -NoProfile -ExecutionPolicy Bypass -Command &quot;if (!(Test-Path '$(ProjectDir^)mow3s.config.json'^)^) { Write-Host '[WARN] mow3s.config.json fehlt!' -ForegroundColor Yellow }&quot;" 
echo           IgnoreExitCode="true" 
echo           Condition="'$(OS^)' == 'Windows_NT'" /^>
echo     ^<Exec Command="bash -c &quot;[ ! -f '$(ProjectDir^)mow3s.config.json' ] &amp;&amp; echo '[WARN] mow3s.config.json fehlt!' ^|^| true&quot;" 
echo           IgnoreExitCode="true" 
echo           Condition="'$(OS^)' != 'Windows_NT'" /^>
echo   ^</Target^>
echo.
echo ^</Project^>
) > "%CSPROJ_PATH%"

echo [OK] .csproj aktualisiert

REM Restore dependencies
echo [RESTORE] Lade NuGet Pakete...
dotnet restore
echo [OK] Dependencies geladen

echo.
echo === Setup abgeschlossen ===
echo.
echo Nächste Schritte:
echo 1. Build: dotnet build
echo 2. Run: dotnet run
echo 3. Publish: dotnet publish -c Release -r win-x64 --self-contained true
echo.

pause
