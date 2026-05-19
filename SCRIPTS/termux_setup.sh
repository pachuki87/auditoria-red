#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# SETUP INICIAL - Termux Auditoría de Red
# Ejecutar UNA SOLA VEZ en Termux del móvil
# ============================================================

echo "=========================================="
echo " SETUP AUDITORÍA CIBERSEGURIDAD - Termux"
echo "=========================================="
echo ""

# Actualizar paquetes
echo "[1/5] Actualizando paquetes..."
pkg update -y && pkg upgrade -y

# Instalar herramientas principales
echo ""
echo "[2/5] Instalando herramientas de red..."
pkg install -y nmap
pkg install -y dnsutils
pkg install -y whois
pkg install -y curl
pkg install -y wget
pkg install -y net-tools
pkg install -y iproute2
pkg install -y traceroute
pkg install -y openssh
pkg install -y rsync
pkg install -y tar
pkg install -y zip

# Instalar Python para scripts avanzados
echo ""
echo "[3/5] Instalando Python..."
pkg install -y python
pip install requests

# Instalar Termux API (requiere app aparte)
echo ""
echo "[4/5] Instalando Termux API..."
pkg install -y termux-api
echo ""
echo "  IMPORTANTE: Instala tambien la app 'Termux:API' desde F-Droid"
echo "  Sin ella, termux-api no funcionara."
echo ""

# Crear estructura de carpetas
echo "[5/5] Creando carpetas de trabajo..."
mkdir -p ~/auditoria/reportes
mkdir -p ~/auditoria/capturas
mkdir -p ~/auditoria/datos

# Copiar script principal
echo ""
echo "=========================================="
echo " SETUP COMPLETADO"
echo "=========================================="
echo ""
echo "Paquetes instalados:"
echo "  nmap, dnsutils, whois, curl, wget"
echo "  net-tools, iproute2, traceroute, python"
echo "  openssh, rsync, termux-api"
echo ""
echo "Carpetas creadas en ~/auditoria/"
echo ""
echo "Siguiente paso:"
echo "  1. Instala 'Termux:API' desde F-Droid"
echo "  2. Copia el script 'termux_auditoria.sh' a ~/auditoria/"
echo "  3. Ejecuta: chmod +x ~/auditoria/termux_auditoria.sh"
echo "  4. Ejecuta: ~/auditoria/termux_auditoria.sh"
echo ""
