#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# AUDITORÍA DE RED PROFESIONAL - Termux
# Recopila TODA la información posible de la red
# Uso: bash termux_auditoria.sh [--rapido|--completo]
# ============================================================

MODO="${1:--completo}"
FECHA=$(date +"%Y-%m-%d_%H%M%S")
DIR_HOME="$HOME/auditoria"
DIR_REPORTE="$DIR_HOME/reportes"
DIR_DATOS="$DIR_HOME/datos"
REPORTE="$DIR_REPORTE/reporte_${FECHA}.txt"
JSON_DATA="$DIR_DATOS/datos_${FECHA}.json"

mkdir -p "$DIR_REPORTE" "$DIR_DATOS"

# Colores
R='\033[0;31m' V='\033[0;32m' A='\033[1;33m' Az='\033[0;34m' C='\033[0;36m' N='\033[0m'
SEPARADOR="============================================================"

# Vendors MAC
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
        dc:a6:32) echo "Raspberry Pi" ;;
        b8:27:eb) echo "Raspberry Pi" ;;
        00:0c:29) echo "VMware" ;;
        08:00:27) echo "VirtualBox" ;;
        52:54:00) echo "QEMU/KVM" ;;
        ac:1f:6b) echo "Samsung/Mobile" ;;
        48:db:50) echo "Samsung/Mobile" ;;
        28:39:5e) echo "Samsung/Mobile" ;;
        34:23:ba) echo "Amazon/Kindle" ;;
        40:b4:cd) echo "Amazon/Echo" ;;
        74:75:48) echo "Amazon/Device" ;;
        a0:02:dc) echo "HP/Printer" ;;
        00:1a:22) echo "Brother/Printer" ;;
        9c:93:4e) echo "Dell/PC" ;;
        00:50:56) echo "VMware" ;;
        f0:18:98) echo "AzureWave/IoT" ;;
        70:62:b8) echo "Shenzhen/IoT" ;;
        *) echo "Desconocido ($mac)" ;;
    esac
}

get_device_type() {
    local vendor="$1"
    case "$vendor" in
        *Router*|*ZTE*) echo "Router" ;;
        *TV*) echo "Smart TV" ;;
        *Phone*|*Mobile*|*iPhone*) echo "Telefono" ;;
        *PC*|*Intel*|*Dell*) echo "Ordenador" ;;
        *Printer*) echo "Impresora" ;;
        *IoT*|*Echo*|*Kindle*) echo "IoT" ;;
        *Pi*) echo "Servidor" ;;
        *VMware*|*VirtualBox*|*QEMU*) echo "Virtual" ;;
        *) echo "Desconocido" ;;
    esac
}

# ============================================================
# FUNCIONES DE RECOLECCIÓN
# ============================================================

seccion() {
    local num="$1"
    local total="$2"
    local titulo="$3"
    echo -e "\n${Az}[$num/$total] $titulo${N}"
    {
        echo ""
        echo "$SEPARADOR"
        echo " $titulo"
        echo "$SEPARADOR"
    } >> "$REPORTE"
}

escribir() {
    echo "$@" >> "$REPORTE"
}

# ============================================================
# 1. INFORMACIÓN DEL DISPOSITIVO
# ============================================================
info_dispositivo() {
    seccion 1 17 "INFORMACION DEL DISPOSITIVO MOVIL"
    {
        echo "  Fecha/Hora: $(date '+%d/%m/%Y %H:%M:%S')"
        echo "  Modelo: $(getprop ro.product.model 2>/dev/null || echo 'N/A')"
        echo "  Fabricante: $(getprop ro.product.manufacturer 2>/dev/null || echo 'N/A')"
        echo "  Android: $(getprop ro.build.version.release 2>/dev/null || echo 'N/A')"
        echo "  SDK: $(getprop ro.build.version.sdk 2>/dev/null || echo 'N/A')"
        echo "  Patch seguridad: $(getprop ro.build.version.security_patch 2>/dev/null || echo 'N/A')"
        echo "  Kernel: $(uname -r)"
        echo "  Arquitectura: $(uname -m)"
        echo "  Hostname: $(hostname)"
        echo "  Uptime: $(uptime)"
        echo "  Bateria: $(termux-battery-status 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f\"{d.get(\"percentage\",\"?\")}% - {d.get(\"status\",\"?\")}\")' 2>/dev/null || echo 'N/A')"
    } >> "$REPORTE"
}

# ============================================================
# 2. INTERFACES DE RED
# ============================================================
info_interfaces() {
    seccion 2 17 "INTERFACES DE RED"
    {
        # Interfaces detalladas
        ip -details -stats link show 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- IPv4 ---"
        ip -4 addr show 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- IPv6 ---"
        ip -6 addr show 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- Tabla ARP ---"
        echo "  IP               MAC                Estado     Dispositivo"
        echo "  ---------------  -----------------  ---------  --------------------"
        ip neigh show 2>/dev/null | while IFS= read -r line; do
            IP=$(echo "$line" | awk '{print $1}')
            MAC=$(echo "$line" | awk '{print $5}')
            STATE=$(echo "$line" | awk '{print $6}')
            if [ -n "$MAC" ] && [ "$MAC" != "00:00:00:00:00:00" ]; then
                VENDOR=$(get_vendor "$MAC")
                printf "  %-15s  %-17s  %-9s  %s\n" "$IP" "$MAC" "$STATE" "$VENDOR"
            fi
        done
    } >> "$REPORTE"
}

# ============================================================
# 3. TABLA DE RUTAS
# ============================================================
info_rutas() {
    seccion 3 17 "TABLA DE RUTAS"
    {
        echo "  --- Rutas IPv4 ---"
        ip -4 route show 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- Rutas IPv6 ---"
        ip -6 route show 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')
        SUBNET=$(echo "$GATEWAY" | cut -d'.' -f1-3)
        echo ""
        echo "  Gateway por defecto: ${GATEWAY:-No detectado}"
        echo "  Subred detectada: ${SUBNET}.0/24"
    } >> "$REPORTE"
}

# ============================================================
# 4. INFORMACIÓN WiFi DETALLADA
# ============================================================
info_wifi() {
    seccion 4 17 "INFORMACION WiFi DETALLADA"
    {
        # Termux API - info de conexión
        WIFI=$(termux-wifi-connectioninfo 2>/dev/null)
        if [ -n "$WIFI" ] && [ "$WIFI" != "null" ]; then
            echo "$WIFI" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f\"  SSID: {d.get('ssid','N/A')}\")
    print(f\"  BSSID: {d.get('bssid','N/A')}\")
    print(f\"  IP Local: {d.get('ip','N/A')}\")
    print(f\"  Gateway: {d.get('gateway','N/A')}\")
    print(f\"  Mascara red: {d.get('netmask','N/A')}\")
    print(f\"  DNS 1: {d.get('dns1','N/A')}\")
    print(f\"  DNS 2: {d.get('dns2','N/A')}\")
    print(f\"  Frecuencia: {d.get('frequency_mhz','N/A')} MHz\")
    print(f\"  Link Speed: {d.get('link_speed_mbps','N/A')} Mbps\")
    print(f\"  TX Link Speed: {d.get('tx_link_speed_mbps','N/A')} Mbps\")
    print(f\"  RX Link Speed: {d.get('rx_link_speed_mbps','N/A')} Mbps\")
    print(f\"  Server MAC: {d.get('server_mac','N/A')}\")
except Exception as e:
    print(f'  Error: {e}')
" 2>/dev/null
        else
            echo "  termux-api no disponible o sin conexion WiFi"
        fi

        # WiFi scan
        echo ""
        echo "  --- Redes WiFi Detectadas ---"
        SCAN=$(termux-wifi-scaninfo 2>/dev/null)
        if [ -n "$SCAN" ] && [ "$SCAN" != "[]" ]; then
            echo "$SCAN" | python3 -c "
import sys, json
try:
    redes = json.load(sys.stdin)
    redes_sorted = sorted(redes, key=lambda x: x.get('level', -100), reverse=True)
    print(f'  {\"SSID\":<25} {\"BSSID\":<18} {\"Freq\":<8} {\"Level\":<7} {\"Ch\":<4} {\"Auth\"}')
    print(f'  {\"---\":<25} {\"---\":<18} {\"---\":<8} {\"---\":<7} {\"---\":<4} {\"---\"}')
    for r in redes_sorted:
        ssid = r.get('ssid','?')[:24]
        bssid = r.get('bssid','?')
        freq = r.get('frequency', 0)
        level = r.get('level', 0)
        ch = r.get('channel', '?')
        caps = r.get('capabilities', '?')[:20]
        # Calcular calidad
        quality = max(0, min(100, level + 100))
        print(f'  {ssid:<25} {bssid:<18} {freq:<8} {level}dBm  {ch:<4} {caps}')
except Exception as e:
    print(f'  Error scan: {e}')
" 2>/dev/null
        else
            echo "  Escaneo no disponible"
        fi
    } >> "$REPORTE"
}

# ============================================================
# 5. IP PÚBLICA + ISP + GEOLOCALIZACIÓN
# ============================================================
info_publica() {
    seccion 5 17 "IP PUBLICA + ISP + GEOLOCALIZACION"
    {
        IP_PUBLICA=$(curl -s --max-time 10 https://api.ipify.org 2>/dev/null)
        if [ -z "$IP_PUBLICA" ]; then
            IP_PUBLICA=$(curl -s --max-time 10 https://ifconfig.me 2>/dev/null)
        fi
        echo "  IP Publica: ${IP_PUBLICA:-No detectada}"

        if [ -n "$IP_PUBLICA" ]; then
            # ip-api.com (info completa)
            curl -s --max-time 10 "http://ip-api.com/json/${IP_PUBLICA}?fields=status,message,continent,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,asname,mobile,proxy,hosting" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if d.get('status') == 'success':
        print(f\"  ISP: {d.get('isp','N/A')}\")
        print(f\"  Organizacion: {d.get('org','N/A')}\")
        print(f\"  AS: {d.get('as','N/A')}\")
        print(f\"  AS Name: {d.get('asname','N/A')}\")
        print(f\"  Continente: {d.get('continent','N/A')}\")
        print(f\"  Pais: {d.get('country','N/A')} ({d.get('countryCode','')})\")
        print(f\"  Region: {d.get('regionName','N/A')}\")
        print(f\"  Ciudad: {d.get('city','N/A')}\")
        print(f\"  Codigo Postal: {d.get('zip','N/A')}\")
        print(f\"  Coordenadas: {d.get('lat','')}, {d.get('lon','')}\")
        print(f\"  Timezone: {d.get('timezone','N/A')}\")
        print(f\"  Conexion movil: {d.get('mobile','N/A')}\")
        print(f\"  Proxy/VPN: {d.get('proxy','N/A')}\")
        print(f\"  Hosting: {d.get('hosting','N/A')}\")
    else:
        print(f\"  Error: {d.get('message','desconocido')}\")
except: pass
" 2>/dev/null

            # WHOIS de la IP
            echo ""
            echo "  --- WHOIS IP ---"
            whois "$IP_PUBLICA" 2>/dev/null | grep -iE "^(netname|descr|organization|country|inetnum|route|created|last-modified)" | head -15 | while IFS= read -r line; do
                echo "  $line"
            done

            # Reverse DNS
            echo ""
            echo "  --- Reverse DNS ---"
            RDNS=$(dig +short -x "$IP_PUBLICA" 2>/dev/null)
            echo "  ${RDNS:-Sin reverse DNS}"
        fi
    } >> "$REPORTE"
}

# ============================================================
# 6. ESCANEO COMPLETO DE DISPOSITIVOS
# ============================================================
escanear_dispositivos() {
    seccion 6 17 "DISPOSITIVOS EN LA RED (ESCANEo COMPLETO)"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')
        [ -z "$GATEWAY" ] && GATEWAY="192.168.1.1"
        SUBNET=$(echo "$GATEWAY" | cut -d'.' -f1-3)

        echo "  Gateway: $GATEWAY"
        echo "  Rango: ${SUBNET}.0/24"
        echo ""

        # Ping sweep completo (todos los 254 hosts)
        echo -e "${A}  Escaneando ${SUBNET}.1-254 (paciencia)...${N}"
        for i in $(seq 1 254); do
            ping -c 1 -W 1 "${SUBNET}.${i}" >/dev/null 2>&1 &
        done
        wait

        echo "  +-----------------+-------------------+---------------------+----------------+"
        echo "  | IP              | MAC               | VENDOR              | TIPO           |"
        echo "  +-----------------+-------------------+---------------------+----------------+"

        TOTAL=0
        DEVICES_JSON=""

        ip neigh show 2>/dev/null | grep -v FAILED | grep -v "00:00:00:00:00:00" | while IFS= read -r line; do
            IP=$(echo "$line" | awk '{print $1}')
            MAC=$(echo "$line" | awk '{print $5}')
            STATE=$(echo "$line" | awk '{print $6}')
            if [ -n "$IP" ] && [ -n "$MAC" ] && [ "$MAC" != "00:00:00:00:00:00" ]; then
                VENDOR=$(get_vendor "$MAC")
                TIPO=$(get_device_type "$VENDOR")
                printf "  | %-15s | %-17s | %-19s | %-14s |\n" "$IP" "$MAC" "$VENDOR" "$TIPO"
            fi
        done

        echo "  +-----------------+-------------------+---------------------+----------------+"
        TOTAL=$(ip neigh show 2>/dev/null | grep -v FAILED | grep -v "00:00:00:00:00:00" | wc -l)
        echo ""
        echo "  Total dispositivos detectados: $TOTAL"
    } >> "$REPORTE"
}

# ============================================================
# 7. ESCANEO DE PUERTOS DEL ROUTER (COMPLETO)
# ============================================================
escanear_puertos_router() {
    seccion 7 17 "PUERTOS DEL ROUTER (ESCANEo COMPLETO)"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')
        [ -z "$GATEWAY" ] && GATEWAY="192.168.1.1"

        if [ "$MODO" == "--rapido" ]; then
            echo "  Escaneo rapido (top 100 puertos)..."
            NMAP_FLAGS="-Pn -sT --top-ports 100 --max-retries 1 -T4"
        else
            echo "  Escaneo completo (65535 puertos, ~2-3 min)..."
            NMAP_FLAGS="-Pn -sT -p- --max-retries 1 -T4"
        fi

        echo ""
        NMAP_OUTPUT=$(nmap $NMAP_FLAGS "$GATEWAY" 2>/dev/null)

        echo "  Router: $GATEWAY"
        echo ""
        echo "  Puertos abiertos:"
        echo "  PORTA    ESTADO     SERVICIO     VERSION"
        echo "  ------   -------    ---------    --------"

        echo "$NMAP_OUTPUT" | while IFS= read -r line; do
            if echo "$line" | grep -q "open"; then
                PORT=$(echo "$line" | awk '{print $1}')
                STATE=$(echo "$line" | awk '{print $2}')
                SERVICE=$(echo "$line" | awk '{print $3}')
                VERSION=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf $i" "; print ""}')
                printf "  %-8s %-10s %-12s %s\n" "$PORT" "$STATE" "$SERVICE" "$VERSION"
            fi
        done

        echo ""

        # Service version detection on open ports
        echo "  --- Fingerprinting de servicios ---"
        OPEN_PORTS=$(echo "$NMAP_OUTPUT" | grep "open" | awk '{print $1}' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
        if [ -n "$OPEN_PORTS" ]; then
            nmap -Pn -sT -sV --version-intensity 5 -p "$OPEN_PORTS" "$GATEWAY" 2>/dev/null | grep -E "open|Service" | while IFS= read -r line; do
                echo "  $line"
            done
        fi
    } >> "$REPORTE"
}

# ============================================================
# 8. ESCANEO DE PUERTOS DE TODOS LOS DISPOSITIVOS
# ============================================================
escanear_puertos_dispositivos() {
    seccion 8 17 "PUERTOS ABIERTOS EN DISPOSITIVOS"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')
        SUBNET=$(echo "$GATEWAY" | cut -d'.' -f1-3)

        echo "  Escaneando puertos comunes en todos los dispositivos..."
        echo ""

        PORTS="21,22,23,25,53,80,111,135,139,443,445,993,995,1723,3306,3389,5432,5900,5901,8080,8443,8888,9090,27017"

        ip neigh show 2>/dev/null | grep -v FAILED | grep -v "00:00:00:00:00:00" | awk '{print $1}' | while IFS= read -r ip; do
            if [ "$ip" != "$GATEWAY" ] && [ -n "$ip" ]; then
                RESULT=$(nmap -Pn -sT -p "$PORTS" --max-retries 1 -T4 "$ip" 2>/dev/null)
                OPEN=$(echo "$RESULT" | grep "open")
                if [ -n "$OPEN" ]; then
                    MAC=$(ip neigh show 2>/dev/null | grep "$ip" | awk '{print $5}')
                    VENDOR=$(get_vendor "$MAC")
                    echo "  [$ip] ($VENDOR)"
                    echo "$OPEN" | while IFS= read -r line; do
                        echo "    $line"
                    done
                    echo ""
                fi
            fi
        done
    } >> "$REPORTE"
}

# ============================================================
# 9. ANÁLISIS DNS COMPLETO
# ============================================================
analisis_dns() {
    seccion 9 17 "ANALISIS DNS COMPLETO"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')

        # DNS del router
        echo "  --- DNS del Router ---"
        echo "  Router DNS: $GATEWAY"

        # DNS del WiFi
        WIFI_DNS=$(termux-wifi-connectioninfo 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f\"{d.get('dns1','')},{d.get('dns2','')}\")
except: pass
" 2>/dev/null)
        DNS1=$(echo "$WIFI_DNS" | cut -d',' -f1)
        DNS2=$(echo "$WIFI_DNS" | cut -d',' -f2)
        [ -n "$DNS1" ] && echo "  DNS 1 (DHCP): $DNS1"
        [ -n "$DNS2" ] && echo "  DNS 2 (DHCP): $DNS2"

        echo ""
        echo "  --- Test de Resolucion DNS ---"
        for domain in google.com youtube.com facebook.com amazon.com github.com wikipedia.org netflix.com; do
            TIME=$(dig +stats "$domain" @8.8.8.8 2>/dev/null | grep "Query time" | awk '{print $4}')
            IP_RES=$(dig +short "$domain" @8.8.8.8 2>/dev/null | head -1)
            printf "  %-20s -> %-16s (%s ms)\n" "$domain" "${IP_RES:-FAIL}" "${TIME:-?}"
        done

        echo ""
        echo "  --- Comparativa DNS Servers ---"
        for dns in "8.8.8.8:Google" "1.1.1.1:Cloudflare" "9.9.9.9:Quad9" "208.67.222.222:OpenDNS" "$GATEWAY:Router"; do
            DNS_IP=$(echo "$dns" | cut -d':' -f1)
            DNS_NAME=$(echo "$dns" | cut -d':' -f2)
            TIME=$(dig +stats google.com @"$DNS_IP" 2>/dev/null | grep "Query time" | awk '{print $4}')
            printf "  %-16s %-12s %s ms\n" "$DNS_IP" "$DNS_NAME" "${TIME:-sin respuesta}"
        done

        echo ""
        echo "  --- DNS Leak Test ---"
        for i in $(seq 1 5); do
            LEAK=$(dig +short "test${i}.leaktest.dns-oarc.net" @8.8.8.8 2>/dev/null)
            SERVER=$(dig +short "test${i}.leaktest.dns-oarc.net" @8.8.8.8 2>/dev/null)
            echo "  Test $i: ${LEAK:-sin respuesta}"
        done

        echo ""
        echo "  --- DNSSEC Check ---"
        DNSSEC=$(dig +dnssec google.com @8.8.8.8 2>/dev/null | grep "RRSIG\|flags:" | head -3)
        if [ -n "$DNSSEC" ]; then
            echo "  DNSSEC: Soportado"
            echo "$DNSSEC" | while IFS= read -r line; do echo "  $line"; done
        else
            echo "  DNSSEC: No detectado"
        fi
    } >> "$REPORTE"
}

# ============================================================
# 10. TRACEROUTE
# ============================================================
analisis_traceroute() {
    seccion 10 17 "TRACEROUTE Y TOPOLOGIA DE RED"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')

        echo "  --- Al Gateway ($GATEWAY) ---"
        traceroute -n -q 1 -w 2 "$GATEWAY" 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- A Google (8.8.8.8) ---"
        traceroute -n -q 1 -w 2 8.8.8.8 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- A Cloudflare (1.1.1.1) ---"
        traceroute -n -q 1 -w 2 1.1.1.1 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- MTU Path Discovery ---"
        MTU=$(ping -c 1 -M do -s 1472 "$GATEWAY" 2>/dev/null | grep "mtu" | awk '{print $NF}')
        if [ -n "$MTU" ]; then
            echo "  MTU detectado: $MTU"
        else
            echo "  MTU: 1500 (estandar)"
        fi
    } >> "$REPORTE"
}

# ============================================================
# 11. ANÁLISIS DE SEGURIDAD
# ============================================================
analisis_seguridad() {
    seccion 11 17 "ANALISIS DE SEGURIDAD"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')
        [ -z "$GATEWAY" ] && GATEWAY="192.168.1.1"
        ALERTAS=0

        echo "  --- Puertos de Riesgo en Router ---"
        for PORT_PROTO in "23:Telnet:ALTO" "21:FTP:ALTO" "445:SMB:ALTO" "3389:RDP:ALTO" "25:SMTP:MEDIO" "111:RPCinfo:ALTO" "135:MSRPC:MEDIO" "139:NetBIOS:MEDIO" "5432:PostgreSQL:MEDIO" "3306:MySQL:MEDIO" "27017:MongoDB:ALTO" "5900:VNC:ALTO"; do
            PORT=$(echo "$PORT_PROTO" | cut -d':' -f1)
            NAME=$(echo "$PORT_PROTO" | cut -d':' -f2)
            RISK=$(echo "$PORT_PROTO" | cut -d':' -f3)
            RESULT=$(nmap -Pn -sT -p "$PORT" --max-retries 1 -T4 "$GATEWAY" 2>/dev/null | grep "open")
            if [ -n "$RESULT" ]; then
                echo "  [!] Puerto $PORT ($NAME): ABIERTO - RIESGO $RISK"
                ALERTAS=$((ALERTAS + 1))
            else
                echo "  [OK] Puerto $PORT ($NAME): Cerrado"
            fi
        done

        echo ""
        echo "  --- Panel Admin Router ---"
        for PORT_URL in "80:HTTP" "443:HTTPS" "8080:HTTP-ALT" "8443:HTTPS-ALT" "443:HTTPS" "23:Telnet"; do
            PORT=$(echo "$PORT_URL" | cut -d':' -f1)
            PROTO=$(echo "$PORT_URL" | cut -d':' -f2)
            if [ "$PORT" = "443" ] || [ "$PORT" = "8443" ]; then
                CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 -k "https://${GATEWAY}:${PORT}" 2>/dev/null)
            else
                CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://${GATEWAY}:${PORT}" 2>/dev/null)
            fi
            if [ "$CODE" != "000" ]; then
                echo "  [!] $PROTO puerto $PORT: ACCESIBLE (HTTP $CODE)"
            fi
        done

        echo ""
        echo "  --- HTTP Headers del Router ---"
        curl -sI --max-time 5 -k "http://${GATEWAY}" 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- SSL/TLS del Router ---"
        CERT=$(echo | openssl s_client -connect "$GATEWAY:443" -servername "$GATEWAY" 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null)
        if [ -n "$CERT" ]; then
            echo "$CERT" | while IFS= read -r line; do echo "  $line"; done
        else
            CERT8443=$(echo | openssl s_client -connect "$GATEWAY:8443" -servername "$GATEWAY" 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null)
            if [ -n "$CERT8443" ]; then
                echo "$CERT8443" | while IFS= read -r line; do echo "  $line"; done
            else
                echo "  Sin SSL/TLS detectado en puertos comunes"
            fi
        fi

        echo ""
        echo "  --- UPnP/SSDP Discovery ---"
        UPNP=$(curl -s --max-time 3 -H "ST: ssdp:all" -H "MX: 2" "http://${GATEWAY}:1900" 2>/dev/null)
        if [ -n "$UPNP" ]; then
            echo "  [!] UPnP ACTIVO en el router"
            echo "$UPNP" | while IFS= read -r line; do echo "  $line"; done
        else
            echo "  [OK] UPnP no detectado o filtrado"
        fi

        echo ""
        echo "  Alertas totales: $ALERTAS"
    } >> "$REPORTE"
}

# ============================================================
# 12. RENDIMIENTO DE RED
# ============================================================
rendimiento() {
    seccion 12 17 "RENDIMIENTO DE RED"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')

        echo "  --- Latencia ---"
        echo ""
        echo "  Gateway ($GATEWAY):"
        ping -c 10 "$GATEWAY" 2>/dev/null | tail -2 | while IFS= read -r line; do echo "  $line"; done

        echo ""
        echo "  Google DNS (8.8.8.8):"
        ping -c 10 8.8.8.8 2>/dev/null | tail -2 | while IFS= read -r line; do echo "  $line"; done

        echo ""
        echo "  Cloudflare (1.1.1.1):"
        ping -c 10 1.1.1.1 2>/dev/null | tail -2 | while IFS= read -r line; do echo "  $line"; done

        echo ""
        echo "  --- Packet Loss ---"
        for target in "$GATEWAY" 8.8.8.8 1.1.1.1; do
            LOSS=$(ping -c 20 "$target" 2>/dev/null | grep "packet loss" | awk '{print $6}')
            printf "  %-15s packet loss: %s\n" "$target" "${LOSS:-N/A}"
        done

        echo ""
        echo "  --- Jitter (variacion latencia) ---"
        for target in "$GATEWAY" 8.8.8.8; do
            PINGS=$(ping -c 20 "$target" 2>/dev/null | grep "time=" | awk -F'=' '{print $4}' | cut -d' ' -f1 | tr '\n' ' ')
            if [ -n "$PINGS" ]; then
                echo "  $target: $PINGS (ms)"
            fi
        done

        echo ""
        echo "  --- Test Velocidad Descarga ---"
        echo "  Descargando test (1MB)..."
        START=$(date +%s%N)
        curl -s -o /dev/null --max-time 20 "http://speedtest.tele2.net/1MB.zip" 2>/dev/null
        END=$(date +%s%N)
        ELAPSED=$(( (END - START) / 1000000 ))
        if [ $ELAPSED -gt 0 ]; then
            SPEED_KB=$(( 1000 * 1000 / ELAPSED ))
            SPEED_MB=$(echo "scale=2; $SPEED_KB / 1024" | bc 2>/dev/null || echo "$((SPEED_KB / 1024))")
            echo "  Tiempo: ${ELAPSED}ms | Velocidad: ~${SPEED_KB} KB/s (~${SPEED_MB} MB/s)"
        fi

        echo ""
        echo "  --- Test Velocidad Subida ---"
        dd if=/dev/zero bs=1M count=1 2>/dev/null | curl -s -o /dev/null -w "  Upload: %{speed_upload} bytes/sec (%{size_upload} bytes en %{time_total}s)\n" --max-time 20 -X POST -d @- "http://speedtest.tele2.net/upload.php" 2>/dev/null || echo "  Upload test no disponible"
    } >> "$REPORTE"
}

# ============================================================
# 13. NMAP VULNERABILITY SCAN
# ============================================================
scan_vulnerabilidades() {
    seccion 13 17 "ESCANEo DE VULNERABILIDADES (NMAP SCRIPTS)"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')
        [ -z "$GATEWAY" ] && GATEWAY="192.168.1.1"

        echo "  Ejecutando scripts de vulnerabilidad Nmap..."
        echo ""

        # Common vuln scripts
        nmap -Pn -sT --script "vuln,exploit,auth,banner" --script-timeout 30s -p 21,22,23,25,53,80,111,135,139,443,445,993,995,1723,3306,3389,5432,5900,8080,8443 "$GATEWAY" 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
    } >> "$REPORTE"
}

# ============================================================
# 14. CONEXIONES ACTIVAS
# ============================================================
conexiones_activas() {
    seccion 14 17 "CONEXIONES DE RED ACTIVAS"
    {
        echo "  --- Sockets abiertos ---"
        ss -tuanp 2>/dev/null | head -50 | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- Conexiones establecidas ---"
        ss -tan state established 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- Procesos con actividad de red ---"
        ss -tuanp 2>/dev/null | grep -v "Local" | awk '{print $5}' | sort -u | while IFS= read -r addr; do
            [ -n "$addr" ] && echo "  $addr"
        done
    } >> "$REPORTE"
}

# ============================================================
# 15. ANALISIS IPv6
# ============================================================
analisis_ipv6() {
    seccion 15 17 "ANALISIS IPv6"
    {
        echo "  --- Direcciones IPv6 locales ---"
        ip -6 addr show 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- Rutas IPv6 ---"
        ip -6 route show 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done

        echo ""
        echo "  --- IPv6 Publico ---"
        IPV6=$(curl -s --max-time 10 -6 https://api6.ipify.org 2>/dev/null)
        if [ -n "$IPV6" ]; then
            echo "  IPv6 Publico: $IPV6"
            curl -s --max-time 10 "http://ip-api.com/json/$IPV6?fields=isp,org,city,country" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f\"  ISP: {d.get('isp','N/A')}\")
    print(f\"  Ciudad: {d.get('city','N/A')}\")
except: pass
" 2>/dev/null
        else
            echo "  IPv6: No disponible o no soportado"
        fi

        echo ""
        echo "  --- Test conectividad IPv6 ---"
        PING6=$(ping6 -c 3 google.com 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "  IPv6 funcional:"
            echo "$PING6" | tail -2 | while IFS= read -r line; do echo "  $line"; done
        else
            echo "  IPv6: Sin conectividad"
        fi
    } >> "$REPORTE"
}

# ============================================================
# 16. DETECCION DE SERVICIOS DE RED
# ============================================================
detectar_servicios() {
    seccion 16 17 "SERVICIOS DE RED DETECTADOS"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')
        SUBNET=$(echo "$GATEWAY" | cut -d'.' -f1-3)

        echo "  --- DHCP ---"
        echo "  Gateway (probable DHCP): $GATEWAY"
        WIFI_INFO=$(termux-wifi-connectioninfo 2>/dev/null)
        echo "$WIFI_INFO" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f\"  IP asignada: {d.get('ip','N/A')}\")
    print(f\"  Mascara: {d.get('netmask','N/A')}\")
    print(f\"  Lease duration: {d.get('lease_duration','N/A')}\")
    print(f\"  Server MAC: {d.get('server_mac','N/A')}\")
except: pass
" 2>/dev/null

        echo ""
        echo "  --- SMB/Comparticion (puerto 445) ---"
        ip neigh show 2>/dev/null | grep -v FAILED | grep -v "00:00:00:00:00:00" | awk '{print $1}' | while IFS= read -r ip; do
            SMB=$(nmap -Pn -sT -p 445,139 --max-retries 1 -T4 "$ip" 2>/dev/null | grep "open")
            if [ -n "$SMB" ]; then
                echo "  [!] SMB abierto en $ip"
            fi
        done

        echo ""
        echo "  --- mDNS/Bonjour ---"
        # Intentar descubrir servicios mDNS
        MDNS=$(python3 -c "
import socket, struct
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(3)
# mDNS query
query = b'\x00\x00\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00'
query += b'\x09_services\x07_dns-sd\x04_udp\x05local\x00\x00\x0c\x00\x01'
try:
    sock.sendto(query, ('224.0.0.251', 5353))
    while True:
        data, addr = sock.recvfrom(4096)
        print(f'  mDNS response from {addr[0]}')
except socket.timeout:
    pass
except Exception as e:
    pass
" 2>/dev/null)
        [ -n "$MDNS" ] && echo "$MDNS" || echo "  mDNS: Sin respuestas"

        echo ""
        echo "  --- Impresoras en red ---"
        ip neigh show 2>/dev/null | grep -v FAILED | grep -v "00:00:00:00:00:00" | awk '{print $1}' | while IFS= read -r ip; do
            IPP=$(curl -s --max-time 2 -o /dev/null -w "%{http_code}" "http://${ip}:631" 2>/dev/null)
            if [ "$IPP" = "200" ] || [ "$IPP" = "401" ]; then
                echo "  [!] Posible impresora en $ip (CUPS/IPP puerto 631)"
            fi
            HP=$(curl -s --max-time 2 -o /dev/null -w "%{http_code}" "http://${ip}" 2>/dev/null | head -1)
        done
    } >> "$REPORTE"
}

# ============================================================
# 17. RESUMEN Y ALERTAS
# ============================================================
resumen_final() {
    seccion 17 17 "RESUMEN EJECUTIVO Y ALERTAS"
    {
        GATEWAY=$(ip -4 route show 2>/dev/null | grep default | awk '{print $3}')
        IP_PUBLICA=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)
        TOTAL_DISP=$(ip neigh show 2>/dev/null | grep -v FAILED | grep -v "00:00:00:00:00:00" | wc -l)
        ALERTAS=0

        echo ""
        echo "  DATOS GENERALES:"
        echo "  - IP Publica: ${IP_PUBLICA:-N/A}"
        echo "  - Gateway: ${GATEWAY:-N/A}"
        echo "  - Dispositivos en red: $TOTAL_DISP"
        echo ""

        echo "  ALERTAS:"
        echo "  ---------"

        # Check puertos peligrosos
        for PORT_NAME in "23:Telnet" "21:FTP" "445:SMB" "3389:RDP" "8443:Admin remoto"; do
            PORT=$(echo "$PORT_NAME" | cut -d':' -f1)
            NAME=$(echo "$PORT_NAME" | cut -d':' -f2)
            if nmap -Pn -sT -p "$PORT" --max-retries 1 -T4 "$GATEWAY" 2>/dev/null | grep -q "open"; then
                echo "  [CRITICO] $NAME (puerto $PORT) ABIERTO en el router"
                ALERTAS=$((ALERTAS + 1))
            fi
        done

        # Check WPS
        echo "  [INFO] Verificar si WPS esta activo en el router"

        # Check contrasena por defecto
        echo "  [INFO] Verificar si la contrasena del router es la de fabrica"

        # Check firmware
        echo "  [INFO] Verificar si el firmware del router esta actualizado"

        # Check DNS
        echo "  [INFO] Verificar si los DNS son los del ISP o personalizados"

        if [ $ALERTAS -eq 0 ]; then
            echo "  [OK] No se detectaron alertas criticas automaticas"
        fi

        echo ""
        echo "  RECOMENDACIONES:"
        echo "  1. Cambiar contrasena por defecto del router"
        echo "  2. Desactivar WPS si esta habilitado"
        echo "  3. Desactivar Telnet/FTP si no se usan"
        echo "  4. Actualizar firmware del router"
        echo "  5. Configurar DNS seguros (1.1.1.1, 9.9.9.9)"
        echo "  6. Habilitar firewall si esta disponible"
        echo "  7. Configurar QoS para priorizar trafico"
        echo "  8. Revisar dispositivos desconocidos en la red"
        echo "  9. Cambiar canal WiFi si hay interferencias"
        echo "  10. Usar WPA3 si el router lo soporta"

        echo ""
        echo "$SEPARADOR"
        echo " Fin del reporte - $(date '+%d/%m/%Y %H:%M:%S')"
        echo " Generado por: Termux Auditor v2.0"
        echo "$SEPARADOR"
    } >> "$REPORTE"
}

# ============================================================
# EJECUCIÓN PRINCIPAL
# ============================================================
main() {
    echo ""
    echo -e "${V}$SEPARADOR"
    echo " AUDITORIA DE RED PROFESIONAL - Termux v2.0"
    echo " Modo: $MODO | Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
    echo -e "$SEPARADOR${N}"

    # Verificar herramientas
    MISSING=""
    for tool in nmap curl dig python3 ip; do
        command -v "$tool" &>/dev/null || MISSING="$MISSING $tool"
    done
    if [ -n "$MISSING" ]; then
        echo -e "${R}Faltan herramientas:$MISSING${N}"
        echo "Ejecuta: bash SCRIPTS/termux_setup.sh"
        exit 1
    fi

    # Crear header del reporte
    {
        echo "$SEPARADOR"
        echo " REPORTE DE AUDITORIA DE RED PROFESIONAL"
        echo " Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
        echo " Modo: $MODO"
        echo " Dispositivo: $(getprop ro.product.model 2>/dev/null)"
        echo " Android: $(getprop ro.build.version.release 2>/dev/null)"
        echo "$SEPARADOR"
    } > "$REPORTE"

    # Ejecutar todas las secciones
    info_dispositivo
    info_interfaces
    info_rutas
    info_wifi
    info_publica
    escanear_dispositivos
    escanear_puertos_router

    if [ "$MODO" != "--rapido" ]; then
        escanear_puertos_dispositivos
        analisis_dns
        analisis_traceroute
        analisis_seguridad
        rendimiento
        scan_vulnerabilidades
        conexiones_activas
        analisis_ipv6
        detectar_servicios
    fi

    resumen_final

    # Guardar datos para tracking
    echo "$(date '+%Y-%m-%d %H:%M:%S') | IP: ${IP_PUBLICA:-N/A} | GW: ${GATEWAY:-N/A}" >> "$DIR_DATOS/historial.txt"

    # Mostrar resumen
    echo ""
    echo -e "${V}$SEPARADOR"
    echo " AUDITORIA COMPLETADA"
    echo -e "$SEPARADOR${N}"
    echo -e " Reporte: ${V}$REPORTE${N}"
    echo ""

    # Contar lineas del reporte
    LINEAS=$(wc -l < "$REPORTE")
    echo "  El reporte tiene $LINEAS lineas"
    echo ""

    # Mostrar ultimas lineas (alertas)
    echo -e "${A}--- ALERTAS ---${N}"
    tail -25 "$REPORTE"
    echo ""
    echo -e "${V}Para ver el reporte completo:${N}"
    echo "  cat $REPORTE"
    echo ""
    echo -e "${V}Para exportar:${N}"
    echo "  bash SCRIPTS/termux_enviar_reporte.sh zip"
}

main
