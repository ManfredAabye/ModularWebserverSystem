#!/bin/bash
# Download-Script für ModularWebserverSystem (Linux)
# Lädt MariaDB und Apache Binaries herunter und kopiert sie

set -e
# shellcheck disable=SC2034
MARIADB_VERSION="12.0.0"
# shellcheck disable=SC2034
APACHE_VERSION="2.4.65"

echo "=== ModularWebserverSystem - Linux Binary Setup ==="
echo ""

BASE_PATH="$(cd "$(dirname "$0")" && pwd)"
TARGET_PATH="$BASE_PATH/linux-x64"

echo "[INFO] Basisverzeichnis: $BASE_PATH"
echo "[INFO] Zielverzeichnis: $TARGET_PATH"
echo ""

# Prüfe ob Root-Rechte benötigt werden
if [ "$EUID" -ne 0 ]; then 
    echo "[WARN] Dieses Script benötigt möglicherweise Root-Rechte (sudo)"
    echo "[INFO] Führe aus mit: sudo ./download-binaries-linux.sh"
    echo ""
fi

# ========== MariaDB Installation ==========
echo "--- MariaDB Setup ---"
echo "[INFO] Installiere MariaDB über Paketmanager..."

if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    echo "[INSTALL] Verwende apt-get..."
    apt-get update -qq
    apt-get install -y mariadb-server mariadb-client
    
    MARIADB_BIN="/usr/sbin/mariadbd"
    if [ ! -f "$MARIADB_BIN" ]; then
        MARIADB_BIN="/usr/bin/mariadbd"
    fi
    
    MYSQL_INSTALL_DB="/usr/bin/mysql_install_db"
    
elif command -v yum &> /dev/null; then
    # RHEL/CentOS/Fedora
    echo "[INSTALL] Verwende yum..."
    yum install -y mariadb-server mariadb
    
    MARIADB_BIN="/usr/libexec/mariadbd"
    MYSQL_INSTALL_DB="/usr/bin/mysql_install_db"
    
elif command -v dnf &> /dev/null; then
    # Fedora (neuere Versionen)
    echo "[INSTALL] Verwende dnf..."
    dnf install -y mariadb-server mariadb
    
    MARIADB_BIN="/usr/libexec/mariadbd"
    MYSQL_INSTALL_DB="/usr/bin/mysql_install_db"
    
else
    echo "[ERROR] Kein unterstützter Paketmanager gefunden (apt-get/yum/dnf)"
    exit 1
fi

# Kopiere MariaDB Binaries
echo "[COPY] Kopiere MariaDB Binaries..."
mkdir -p "$TARGET_PATH/mariadb/bin"

if [ -f "$MARIADB_BIN" ]; then
    cp "$MARIADB_BIN" "$TARGET_PATH/mariadb/bin/mysqld"
    chmod +x "$TARGET_PATH/mariadb/bin/mysqld"
    echo "[OK] mysqld kopiert"
else
    echo "[ERROR] MariaDB Binary nicht gefunden: $MARIADB_BIN"
fi

if [ -f "$MYSQL_INSTALL_DB" ]; then
    cp "$MYSQL_INSTALL_DB" "$TARGET_PATH/mariadb/bin/mysql_install_db"
    chmod +x "$TARGET_PATH/mariadb/bin/mysql_install_db"
    echo "[OK] mysql_install_db kopiert"
else
    echo "[WARN] mysql_install_db nicht gefunden"
fi

# Kopiere Libraries falls benötigt
if [ -d "/usr/lib/mysql" ]; then
    mkdir -p "$TARGET_PATH/mariadb/lib"
    cp -r /usr/lib/mysql/* "$TARGET_PATH/mariadb/lib/" 2>/dev/null || true
fi

if [ -d "/usr/share/mysql" ]; then
    mkdir -p "$TARGET_PATH/mariadb/share"
    cp -r /usr/share/mysql/* "$TARGET_PATH/mariadb/share/" 2>/dev/null || true
fi

# ========== Apache Installation ==========
echo ""
echo "--- Apache Setup ---"
echo "[INSTALL] Installiere Apache über Paketmanager..."

if command -v apt-get &> /dev/null; then
    apt-get install -y apache2
    APACHE_BIN="/usr/sbin/apache2"
    APACHE_MODULES="/usr/lib/apache2/modules"
    
elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
    if command -v dnf &> /dev/null; then
        dnf install -y httpd
    else
        yum install -y httpd
    fi
    APACHE_BIN="/usr/sbin/httpd"
    APACHE_MODULES="/usr/lib64/httpd/modules"
fi

# Kopiere Apache Binaries
echo "[COPY] Kopiere Apache Binaries..."
mkdir -p "$TARGET_PATH/apache/bin"
mkdir -p "$TARGET_PATH/apache/modules"

if [ -f "$APACHE_BIN" ]; then
    cp "$APACHE_BIN" "$TARGET_PATH/apache/bin/httpd"
    chmod +x "$TARGET_PATH/apache/bin/httpd"
    echo "[OK] httpd kopiert"
else
    echo "[ERROR] Apache Binary nicht gefunden: $APACHE_BIN"
fi

# Kopiere Apache Module
if [ -d "$APACHE_MODULES" ]; then
    cp -r "$APACHE_MODULES"/* "$TARGET_PATH/apache/modules/" 2>/dev/null || true
    echo "[OK] Apache Module kopiert"
fi

# ========== Zusammenfassung ==========
echo ""
echo "=== Setup abgeschlossen ==="
echo ""
echo "Nächste Schritte:"
echo "1. Prüfe ob alle Dateien vorhanden sind:"
echo "   - linux-x64/mariadb/bin/mysqld"
echo "   - linux-x64/apache/bin/httpd"
echo ""
echo "2. Kompiliere das Projekt:"
echo "   dotnet publish -c Release -r linux-x64 --self-contained true"
echo ""
echo "3. Starte den Server:"
echo "   ./bin/Release/net8.0/linux-x64/publish/ModularWebserverSystem"
echo ""

# Prüfe kritische Dateien
echo "Status der kritischen Dateien:"
if [ -f "$TARGET_PATH/mariadb/bin/mysqld" ]; then
    echo "[OK] mysqld vorhanden"
else
    echo "[FEHLT] mysqld"
fi

if [ -f "$TARGET_PATH/apache/bin/httpd" ]; then
    echo "[OK] httpd vorhanden"
else
    echo "[FEHLT] httpd"
fi

echo ""
echo "[INFO] Beachte: Die Binaries sind für deine aktuelle Linux-Distribution kompiliert."
echo "[INFO] Für andere Distributionen müssen die Binaries eventuell neu kompiliert werden."
