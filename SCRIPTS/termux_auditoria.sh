#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# AUDITORÍA DE RED COMPLETA - Termux
# Se ejecuta en el móvil conectado a la red del cliente
# Uso: bash termux_auditoria.sh [--rapido|--completo|--silencio]
# ============================================================

MODO="${1:--completo}"
FECHA=$(date +"%Y-%m-%d_%H%M%S")
DIR_HOME="$HOME/auditoria"
DIR_REPORTE="$DIR_HOME/reportes"
DIR_DATOS="$DIR_HOME/datos"
REPORTE="$DIR_REPORTE/reporte_${FECHA}.txt"

# Colores
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m'

# Vendors MAC conocidos
get_vendor() {
    local mac=$(echo "$1" | tr '[:upper:]' '[:lower:]' | cut -d':' -f1-3)
    case "$mac" in
        e4:ab:89) echo "Movistar/ZTE Router" ;;
        ee:6b:9a) echo "Xiaomi/MIWiFi" ;;
        f8:25:51) echo "Xiaomi/Smart" ;;
        2c:7b:a0) echo "Intel/PC" ;;
        00:1b:63) echo "Apple/iPhone" ;;
        a4:83:e7) echo "Samsung/TV" ;;
        c8:7b:2a) echo "LG/TV" ;;
        b4:96:91) echo "Sony/TV" ;;
        3e:7e:e0) echo "Android/Phone" ;;
        c0:1c:30) echo "Atheros/WiFi-USB" ;;
        *) echo "Desconocido" ;;
    esac
}

# Encabezado del reporte
escribir_encabezado() {
    cat > "$REPORTE" << EOF
============================================================
 REPORTE DE AUDITORÍA DE RED - Termux Mobile
 Fecha: $(date +"%d/%m/%Y %H:%M:%S")
============================================================

EOF
}

# Sección: Info WiFi del dispositivo
info_wifi() {
    echo -e "${AZUL}[1/8] Información WiFi...${NC}"
    {
        echo "=== INFORMACIÓN WIFI ==="
        echo ""

        # Intentar con termux-api
        WIFI_INFO=$(termux-wifi-connectioninfo 2>/dev/null)
        if [ -n "$WIFI_INFO" ] && [ "$WIFI_INFO" != "null" ]; then
            echo "$WIFI_INFO" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f\"  SSID: {d.get('ssid','N/A')}\")
    print(f\"  BSSID: {d.get('bssid','N/A')}\")
    print(f\"  IP: {d.get('ip','N/A')}\")
    print(f\"  Gateway: {d.get('gateway','N/A')}\")
    print(f\"  Netmask: {d.get('netmask','N/A')}\")
    print(f\"  DNS: {d.get('dns','N/A')}\")
    print(f\"  Freq MHz: {d.get('frequency_mhz','N/A')}\")
    print(f\"  Link Speed: {d.get('link_speed_mbps','N/A')} Mbps\")
except:
    print('  Error leyendo datos WiFi')
" 2>/dev/null
        else
            # Fallback con ip command
            IP_LOCAL=$(ip -4 addr show wlan0 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)
            GATEWAY=$(ip route 2>/dev/null | grep default | awk '{print $3}')
            echo "  IP Local: ${IP_LOCAL:-No detectada}"
            echo "  Gateway: ${GATEWAY:-No detectado}"
            echo "  (Instala Termux:API para más datos)"
        fi
        echo ""
    } >> "$REPORTE"
}

# Sección: IP Pública y DNS
info_publica() {
    echo -e "${AZUL}[2/8] IP Pública y DNS...${NC}"
    {
        echo "=== IP PÚBLICA Y DNS ==="
        echo ""
        IP_PUBLICA=$(curl -s --max-time 10 https://api.ipify.org 2>/dev/null)
        if [ -z "$IP_PUBLICA" ]; then
            IP_PUBLICA=$(curl -s --max-time 10 https://ifconfig.me 2>/dev/null)
        fi
        echo "  IP Pública: ${IP_PUBLICA:-No detectada}"

        # Info del ISP
        if [ -n "$IP_PUBLICA" ]; then
            ISP_INFO=$(curl -s --max-time 10 "http://ip-api.com/json/${IP_PUBLICA}?fields=isp,org,country,regionName,city" 2>/dev/null)
            if [ -n "$ISP_INFO" ]; then
                echo "$ISP_INFO" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f\"  ISP: {d.get('isp','N/A')}\")
    print(f\"  Organización: {d.get('org','N/A')}\")
    print(f\"  Ubicación: {d.get('city','N/A')}, {d.get('regionName','N/A')}, {d.get('country','N/A')}\")
except:
    pass
" 2>/dev/null
            fi
        fi

        # DNS servers
        echo ""
        echo "  Servidores DNS:"
        DNS_SERVERS=$(termux-wifi-connectioninfo 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    dns = d.get('dns', 'N/A')
    print(f'  DNS del router: {dns}')
except:
    pass
" 2>/dev/null)

        # Test DNS externo
        echo "  Google (8.8.8.8): $(dig +short google.com @8.8.8.8 2>/dev/null | head -1 || echo 'Sin respuesta')"
        echo "  Cloudflare (1.1.1.1): $(dig +short cloudflare.com @1.1.1.1 2>/dev/null | head -1 || echo 'Sin respuesta')"

        echo ""
    } >> "$REPORTE"
}

# Sección: Escaneo de dispositivos
escanear_dispositivos() {
    echo -e "${AZUL}[3/8] Escaneando dispositivos en la red...${NC}"
    {
        echo "=== DISPOSITIVOS EN LA RED ==="
        echo ""

        # Obtener la red
        GATEWAY=$(ip route 2>/dev/null | grep default | awk '{print $3}')
        if [ -z "$GATEWAY" ]; then
            GATEWAY="192.168.1.1"
        fi

        # Determinar rango de red
        SUBNET=$(echo "$GATEWAY" | cut -d'.' -f1-3)

        echo "  Gateway: $GATEWAY"
        echo "  Rango escaneado: ${SUBNET}.0/24"
        echo ""
        echo "  IP               MAC                VENDOR"
        echo "  ---------------  -----------------  --------------------"

        # Ping sweep para poblar tabla ARP
        echo -e "${AMARILLO}  Escaneando ${SUBNET}.0/24 (espera)...${NC}"
        for i in $(seq 1 254); do
            ping -c 1 -W 1 "${SUBNET}.${i}" >/dev/null 2>&1 &
        done
        wait

        # Leer tabla ARP
        TOTAL=0
        while IFS= read -r line; do
            IP=$(echo "$line" | awk '{print $1}')
            MAC=$(echo "$line" | awk '{print $3}')
            if [ "$IP" != "?" ] && [ -n "$MAC" ] && [ "$MAC" != "00:00:00:00:00:00" ]; then
                VENDOR=$(get_vendor "$MAC")
                echo "  %-15s  %-17s  %s" "$IP" "$MAC" "$VENDOR" | python3 -c "import sys; print(sys.stdin.read().strip())" 2>/dev/null || \
                echo "  $IP  $MAC  $VENDOR"
                TOTAL=$((TOTAL + 1))
            fi
        done < <(ip neigh show 2>/dev/null | grep -v FAILED)

        echo ""
        echo "  Total dispositivos encontrados: $TOTAL"
        echo ""
    } >> "$REPORTE"
}

# Sección: Puertos del router
escanear_router() {
    echo -e "${AZUL}[4/8] Escaneando puertos del router...${NC}"
    {
        echo "=== PUERTOS DEL ROUTER ==="
        echo ""

        GATEWAY=$(ip route 2>/dev/null | grep default | awk '{print $3}')
        [ -z "$GATEWAY" ] && GATEWAY="192.168.1.1"

        if [ "$MODO" == "--rapido" ]; then
            # Solo puertos comunes
            echo "  Escaneo rápido de puertos comunes..."
            NMAP_OUTPUT=$(nmap -Pn -sT --top-ports 30 --max-retries 1 -T4 "$GATEWAY" 2>/dev/null)
        else
            # Todos los puertos
            echo "  Escaneo completo (puede tardar 1-2 min)..."
            NMAP_OUTPUT=$(nmap -Pn -sT -p- --max-retries 1 -T4 "$GATEWAY" 2>/dev/null)
        fi

        echo "$NMAP_OUTPUT" | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
    } >> "$REPORTE"
}

# Sección: Puertos abiertos en este dispositivo
escanear_local() {
    echo -e "${AZUL}[5/8] Puertos abiertos en este móvil...${NC}"
    {
        echo "=== PUERTOS ABIERTOS EN ESTE DISPOSITIVO ==="
        echo ""
        LOCAL_IP=$(ip -4 addr show wlan0 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)
        if [ -n "$LOCAL_IP" ]; then
            nmap -Pn -sT --top-ports 100 -T4 "$LOCAL_IP" 2>/dev/null | while IFS= read -r line; do
                echo "  $line"
            done
        else
            echo "  No se pudo determinar IP local"
        fi
        echo ""
    } >> "$REPORTE"
}

# Sección: Seguridad WiFi
seguridad_wifi() {
    echo -e "${AZUL}[6/8] Análisis de seguridad...${NC}"
    {
        echo "=== ANÁLISIS DE SEGURIDAD ==="
        echo ""

        GATEWAY=$(ip route 2>/dev/null | grep default | awk '{print $3}')
        [ -z "$GATEWAY" ] && GATEWAY="192.168.1.1"

        # Check admin router
        echo "  Panel admin router:"
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${GATEWAY}" 2>/dev/null)
        HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k "https://${GATEWAY}" 2>/dev/null)

        [ "$HTTP_CODE" != "000" ] && echo "    HTTP  (puerto 80): ACCESIBLE ($HTTP_CODE)" || echo "    HTTP  (puerto 80): Cerrado/Filtrado"
        [ "$HTTPS_CODE" != "000" ] && echo "    HTTPS (puerto 443): ACCESIBLE ($HTTPS_CODE)" || echo "    HTTPS (puerto 443): Cerrado/Filtrado"

        # Check common vulnerability ports
        echo ""
        echo "  Puertos de riesgo:"
        for PORT in 23 21 445 3389 8443; do
            RESULT=$(nmap -Pn -sT -p "$PORT" --max-retries 1 -T4 "$GATEWAY" 2>/dev/null | grep "open")
            if [ -n "$RESULT" ]; then
                case $PORT in
                    23) echo "    Puerto 23 (Telnet): ABIERTO - RIESGO ALTO" ;;
                    21) echo "    Puerto 21 (FTP): ABIERTO - RIESGO MEDIO" ;;
                    445) echo "    Puerto 445 (SMB): ABIERTO - RIESGO ALTO" ;;
                    3389) echo "    Puerto 3389 (RDP): ABIERTO - RIESGO MEDIO" ;;
                    8443) echo "    Puerto 8443 (Admin remoto): ABIERTO" ;;
                esac
            fi
        done

        # DNS hijacking check
        echo ""
        echo "  Test DNS hijacking:"
        TEST_IP=$(dig +short testwifi.here 2>/dev/null | head -1)
        if [ "$TEST_IP" = "$GATEWAY" ]; then
            echo "    Router responde a DNS personalizado (normal en routers domésticos)"
        fi

        echo ""
    } >> "$REPORTE"
}

# Sección: Rendimiento de red
rendimiento() {
    echo -e "${AZUL}[7/8] Test de rendimiento...${NC}"
    {
        echo "=== RENDIMIENTO DE RED ==="
        echo ""

        # Ping al gateway
        echo "  Latencia al gateway:"
        ping -c 5 "$GATEWAY" 2>/dev/null | tail -1
        echo ""

        # Ping a DNS externo
        echo "  Latencia a DNS Google (8.8.8.8):"
        ping -c 5 8.8.8.8 2>/dev/null | tail -1
        echo ""

        # Velocidad de descarga simple (1MB test)
        echo "  Test descarga (mide ~1MB):"
        START=$(date +%s%N)
        curl -s -o /dev/null --max-time 15 "http://speedtest.tele2.net/1MB.zip" 2>/dev/null
        END=$(date +%s%N)
        ELAPSED=$(( (END - START) / 1000000 ))
        if [ $ELAPSED -gt 0 ]; then
            SPEED=$(( 1000 * 1000 / ELAPSED ))
            echo "    Tiempo: ${ELAPSED}ms"
            echo "    Velocidad estimada: ~${SPEED} KB/s"
        fi

        echo ""
    } >> "$REPORTE"
}

# Sección: Resumen y alertas
resumen() {
    echo -e "${AZUL}[8/8] Generando resumen...${NC}"
    {
        echo "=== RESUMEN Y ALERTAS ==="
        echo ""

        GATEWAY=$(ip route 2>/dev/null | grep default | awk '{print $3}')
        [ -z "$GATEWAY" ] && GATEWAY="192.168.1.1"

        # Contar alertas
        ALERTAS=0

        # Check Telnet
        if nmap -Pn -sT -p 23 --max-retries 1 -T4 "$GATEWAY" 2>/dev/null | grep -q "open"; then
            echo "  [!] ALERTA: Telnet (puerto 23) ABIERTO en el router"
            ALERTAS=$((ALERTAS + 1))
        fi

        # Check FTP
        if nmap -Pn -sT -p 21 --max-retries 1 -T4 "$GATEWAY" 2>/dev/null | grep -q "open"; then
            echo "  [!] ALERTA: FTP (puerto 21) ABIERTO en el router"
            ALERTAS=$((ALERTAS + 1))
        fi

        # Check SMB
        if nmap -Pn -sT -p 445 --max-retries 1 -T4 "$GATEWAY" 2>/dev/null | grep -q "open"; then
            echo "  [!] ALERTA: SMB (puerto 445) ABIERTO - posible vector de ataque"
            ALERTAS=$((ALERTAS + 1))
        fi

        # Check admin from WAN side (si tenemos IP pública)
        IP_PUBLICA=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)
        if [ -n "$IP_PUBLICA" ] && [ "$IP_PUBLICA" != "$GATEWAY" ]; then
            REMOTE_ADMIN=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k "https://${IP_PUBLICA}:8443" 2>/dev/null)
            if [ "$REMOTE_ADMIN" != "000" ]; then
                echo "  [!] ALERTA: Admin remoto accesible desde WAN (puerto 8443)"
                ALERTAS=$((ALERTAS + 1))
            fi
        fi

        if [ $ALERTAS -eq 0 ]; then
            echo "  [OK] No se detectaron alertas críticas"
        else
            echo ""
            echo "  Total alertas: $ALERTAS"
        fi

        echo ""
        echo "============================================================"
        echo " Fin del reporte - $(date +"%d/%m/%Y %H:%M:%S")"
        echo "============================================================"
    } >> "$REPORTE"
}

# ============================================================
# FUNCIÓN PRINCIPAL
# ============================================================
main() {
    echo ""
    echo -e "${VERDE}=========================================="
    echo " AUDITORÍA DE RED - Termux Mobile"
    echo " Modo: $MODO"
    echo -e "==========================================${NC}"
    echo ""

    # Verificar herramientas
    if ! command -v nmap &>/dev/null; then
        echo -e "${ROJO}Error: nmap no instalado. Ejecuta termux_setup.sh primero${NC}"
        exit 1
    fi

    mkdir -p "$DIR_REPORTE" "$DIR_DATOS"

    escribir_encabezado
    info_wifi
    info_publica
    escanear_dispositivos
    escanear_router

    if [ "$MODO" != "--rapido" ]; then
        escanear_local
        seguridad_wifi
        rendimiento
    fi

    resumen

    # Mostrar resultado
    echo ""
    echo -e "${VERDE}Reporte guardado en:${NC}"
    echo "  $REPORTE"
    echo ""

    # Mostrar resumen en pantalla
    echo -e "${AMARILLO}--- RESUMEN RÁPIDO ---${NC}"
    tail -20 "$REPORTE"
    echo ""

    # Guardar IP + timestamp para tracking
    IP_PUBLICA=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)
    echo "$(date +"%Y-%m-%d %H:%M:%S") | IP: ${IP_PUBLICA:-N/A}" >> "$DIR_DATOS/historial_ips.txt"

    echo -e "${VERDE}Auditoría completada.${NC}"
}

main
