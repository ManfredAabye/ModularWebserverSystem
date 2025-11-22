@echo off
REM Clean-Script für ModularWebserverSystem
REM Löscht alle Build-Artefakte und temporäre Dateien

echo === ModularWebserverSystem - Clean ===
echo.

REM Lösche bin-Verzeichnisse
if exist "bin\" (
    echo [DELETE] Lösche bin\...
    rmdir /s /q "bin"
    echo [OK] bin\ gelöscht
) else (
    echo [INFO] bin\ existiert nicht
)

REM Lösche obj-Verzeichnisse
if exist "obj\" (
    echo [DELETE] Lösche obj\...
    rmdir /s /q "obj"
    echo [OK] obj\ gelöscht
) else (
    echo [INFO] obj\ existiert nicht
)

REM Lösche .sln Dateien
echo [DELETE] Lösche .sln Dateien...
del /q *.sln 2>nul
if %errorlevel% equ 0 (
    echo [OK] .sln Dateien gelöscht
) else (
    echo [INFO] Keine .sln Dateien gefunden
)

REM Lösche .bak Dateien
echo [DELETE] Lösche .bak Dateien...
del /q *.bak 2>nul
if %errorlevel% equ 0 (
    echo [OK] .bak Dateien gelöscht
) else (
    echo [INFO] Keine .bak Dateien gefunden
)

REM Lösche .csproj.user Dateien
echo [DELETE] Lösche .csproj.user Dateien...
del /q *.csproj.user 2>nul
if %errorlevel% equ 0 (
    echo [OK] .csproj.user Dateien gelöscht
) else (
    echo [INFO] Keine .csproj.user Dateien gefunden
)

REM Lösche publish-Verzeichnisse falls vorhanden
if exist "publish\" (
    echo [DELETE] Lösche publish\...
    rmdir /s /q "publish"
    echo [OK] publish\ gelöscht
)

echo.
echo === Clean abgeschlossen ===
echo.
echo Projekt kann jetzt neu gebaut werden mit:
echo   dotnet build
echo   oder
echo   .\setup-project.ps1
echo.

pause
