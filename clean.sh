#!/bin/bash
# Clean-Script für ModularWebserverSystem (Linux/macOS)
# Löscht alle Build-Artefakte und temporäre Dateien

echo "=== ModularWebserverSystem - Clean ==="
echo ""

# Lösche bin-Verzeichnisse
if [ -d "bin" ]; then
    echo "[DELETE] Lösche bin/..."
    rm -rf bin
    echo "[OK] bin/ gelöscht"
else
    echo "[INFO] bin/ existiert nicht"
fi

# Lösche obj-Verzeichnisse
if [ -d "obj" ]; then
    echo "[DELETE] Lösche obj/..."
    rm -rf obj
    echo "[OK] obj/ gelöscht"
else
    echo "[INFO] obj/ existiert nicht"
fi

# Lösche .sln Dateien
echo "[DELETE] Lösche .sln Dateien..."
if ls ./*.sln 1> /dev/null 2>&1; then
    rm -f ./*.sln
    echo "[OK] .sln Dateien gelöscht"
else
    echo "[INFO] Keine .sln Dateien gefunden"
fi

# Lösche .bak Dateien
echo "[DELETE] Lösche .bak Dateien..."
if ls ./*.bak 1> /dev/null 2>&1; then
    rm -f ./*.bak
    echo "[OK] .bak Dateien gelöscht"
else
    echo "[INFO] Keine .bak Dateien gefunden"
fi

# Lösche .csproj.user Dateien
echo "[DELETE] Lösche .csproj.user Dateien..."
if ls ./*.csproj.user 1> /dev/null 2>&1; then
    rm -f ./*.csproj.user
    echo "[OK] .csproj.user Dateien gelöscht"
else
    echo "[INFO] Keine .csproj.user Dateien gefunden"
fi

# Lösche publish-Verzeichnisse
if [ -d "publish" ]; then
    echo "[DELETE] Lösche publish/..."
    rm -rf publish
    echo "[OK] publish/ gelöscht"
fi

echo ""
echo "=== Clean abgeschlossen ==="
echo ""
echo "Projekt kann jetzt neu gebaut werden mit:"
echo "  dotnet build"
echo "  oder"
echo "  ./setup-project.sh"
echo ""
