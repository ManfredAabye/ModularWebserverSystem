#!/bin/bash
# Setup-Script für ModularWebserverSystem (Linux/macOS)
# Initialisiert das Projekt falls noch nicht vorhanden

set -e

PROJECT_NAME="ModularWebserverSystem"
BASE_PATH="$(cd "$(dirname "$0")" && pwd)"

echo "=== $PROJECT_NAME - Projekt-Setup ==="
echo ""

# Prüfe ob .csproj existiert
CSPROJ_PATH="$BASE_PATH/$PROJECT_NAME.csproj"

if [ ! -f "$CSPROJ_PATH" ]; then
    echo "[INIT] Erstelle .csproj Datei..."
    
    # Erstelle Console-Projekt
    cd "$BASE_PATH"
    dotnet new console -n "$PROJECT_NAME" -f net8.0 --force
    
    # Entferne generierte Program.cs (wir haben schon eine)
    if [ -f "$BASE_PATH/Program.cs" ]; then
        mv "$BASE_PATH/Program.cs" "$BASE_PATH/Program.cs.bak.new" 2>/dev/null || true
    fi
    
    echo "[OK] .csproj erstellt"
else
    echo "[INFO] .csproj existiert bereits"
fi

# Aktualisiere .csproj mit unseren Einstellungen
echo "[UPDATE] Aktualisiere .csproj Einstellungen..."

cat > "$CSPROJ_PATH" << 'EOF'
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

  <Target Name="PreBuildSetup" BeforeTargets="PreBuildEvent">
    <Message Text="[PRE-BUILD] Prüfe Projektstruktur..." Importance="high" />
    <Exec Command="pwsh -NoProfile -ExecutionPolicy Bypass -Command &quot;if (!(Test-Path '$(ProjectDir)mow3s.config.json')) { Write-Host '[WARN] mow3s.config.json fehlt!' -ForegroundColor Yellow }&quot;" 
          IgnoreExitCode="true" 
          Condition="'$(OS)' == 'Windows_NT'" />
    <Exec Command="bash -c &quot;[ ! -f '$(ProjectDir)mow3s.config.json' ] &amp;&amp; echo '[WARN] mow3s.config.json fehlt!' || true&quot;" 
          IgnoreExitCode="true" 
          Condition="'$(OS)' != 'Windows_NT'" />
  </Target>

</Project>
EOF

echo "[OK] .csproj aktualisiert"

# Restore dependencies
echo "[RESTORE] Lade NuGet Pakete..."
dotnet restore
echo "[OK] Dependencies geladen"

echo ""
echo "=== Setup abgeschlossen ==="
echo ""
echo "Nächste Schritte:"
echo "1. Build: dotnet build"
echo "2. Run: dotnet run"
echo "3. Publish: dotnet publish -c Release -r linux-x64 --self-contained true"
echo ""
