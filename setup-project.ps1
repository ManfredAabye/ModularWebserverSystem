# Setup-Script für ModularWebserverSystem
# Initialisiert das Projekt falls noch nicht vorhanden

$ErrorActionPreference = "Stop"

$projectName = "ModularWebserverSystem"
$basePath = $PSScriptRoot

Write-Host "=== $projectName - Projekt-Setup ===" -ForegroundColor Cyan
Write-Host ""

# Prüfe ob .csproj existiert
$csprojPath = Join-Path $basePath "$projectName.csproj"

if (!(Test-Path $csprojPath)) {
    Write-Host "[INIT] Erstelle .csproj Datei..." -ForegroundColor Yellow
    
    # Erstelle Console-Projekt
    Push-Location $basePath
    dotnet new console -n $projectName -f net8.0 --force
    Pop-Location
    
    # Entferne generierte Program.cs (wir haben schon eine)
    $generatedProgram = Join-Path $basePath "Program.cs.bak"
    if (Test-Path (Join-Path $basePath "Program.cs")) {
        Move-Item -Path (Join-Path $basePath "Program.cs") -Destination $generatedProgram -Force
    }
    
    Write-Host "[OK] .csproj erstellt" -ForegroundColor Green
} else {
    Write-Host "[INFO] .csproj existiert bereits" -ForegroundColor Gray
}

# Aktualisiere .csproj mit unseren Einstellungen
Write-Host "[UPDATE] Aktualisiere .csproj Einstellungen..." -ForegroundColor Yellow

$csprojContent = @"
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

  <ItemGroup>
    <None Update="mow3s.config.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>

</Project>
"@

Set-Content -Path $csprojPath -Value $csprojContent
Write-Host "[OK] .csproj aktualisiert" -ForegroundColor Green

# Restore dependencies
Write-Host "[RESTORE] Lade NuGet Pakete..." -ForegroundColor Yellow
dotnet restore
Write-Host "[OK] Dependencies geladen" -ForegroundColor Green

Write-Host ""
Write-Host "=== Setup abgeschlossen ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Yellow
Write-Host "1. Build: dotnet build" -ForegroundColor Gray
Write-Host "2. Run: dotnet run" -ForegroundColor Gray
Write-Host "3. Publish: dotnet publish -c Release -r win-x64 --self-contained true" -ForegroundColor Gray
