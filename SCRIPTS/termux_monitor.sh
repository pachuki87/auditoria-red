#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# MONITOREO CONTINUO - Termux
# Ejecuta escaneos cada X minutos y guarda resultados
# Uso: bash termux_monitor.sh [intervalo_minutos]
# Por defecto: 30 minutos
# ============================================================

INTERVALO="${1:-30}"  # minutos
DIR_HOME="$HOME/auditoria"
DIR_DATOS="$DIR_HOME/datos"
DIR_REPORTE="$DIR_HOME/reportes"

mkdir -p "$DIR_DATOS" "$DIR_REPORTE"

echo "=========================================="
echo " MONITOREO CONTINUO - Termux"
echo " Intervalo: cada ${INTERVALO} minutos"
echo " Ctrl+C para detener"
echo "=========================================="
echo ""

CICLO=0

while true; do
    CICLO=$((CICLO + 1))
    FECHA=$(date +"%Y-%m-%d_%H%M%S")
    TIMESTAMP=$(date +"%d/%m/%Y %H:%M:%S")

    echo "--- Ciclo #$CICLO | $TIMESTAMP ---"

    # Datos que recopilar cada ciclo
    GATEWAY=$(ip route 2>/dev/null | grep default | awk '{print $3}')
    [ -z "$GATEWAY" ] && GATEWAY="192.168.1.1"
    SUBNET=$(echo "$GATEWAY" | cut -d'.' -f1-3)
    IP_PUBLICA=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)

    # Log de línea
    LOG_LINE="$TIMESTAMP | Ciclo:$CICLO | IP_Publica:${IP_PUBLICA:-N/A} | GW:$GATEWAY"

    # Ping sweep rápido
    for i in $(seq 1 254); do
        ping -c 1 -W 1 "${SUBNET}.${i}" >/dev/null 2>&1 &
    done
    wait

    # Contar dispositivos
    DISP=$(ip neigh show 2>/dev/null | grep -v FAILED | grep -v "00:00:00:00:00:00" | wc -l)
    LOG_LINE="$LOG_LINE | Dispositivos:$DISP"

    # Latencia gateway
    LATENCIA=$(ping -c 3 "$GATEWAY" 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
    LOG_LINE="$LOG_LINE | Latencia_GW:${LATENCIA:-N/A}ms"

    # Latencia DNS
    LATENCIA_DNS=$(ping -c 3 8.8.8.8 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
    LOG_LINE="$LOG_LINE | Latencia_DNS:${LATENCIA_DNS:-N/A}ms"

    # Guardar log
    echo "$LOG_LINE" >> "$DIR_DATOS/monitor_log.txt"

    # Guardar lista de dispositivos actual
    echo "=== $TIMESTAMP (Ciclo #$CICLO) ===" >> "$DIR_DATOS/dispositivos_historial.txt"
    ip neigh show 2>/dev/null | grep -v FAILED >> "$DIR_DATOS/dispositivos_historial.txt"
    echo "" >> "$DIR_DATOS/dispositivos_historial.txt"

    echo "  IP: ${IP_PUBLICA:-N/A} | Disp: $DISP | GW: ${LATENCIA:-N/A}ms | DNS: ${LATENCIA_DNS:-N/A}ms"

    # Alerta si cambió la IP pública
    IP_ANTERIOR=$(tail -2 "$DIR_DATOS/monitor_log.txt" | head -1 | grep -oP 'IP_Publica:\K[^ ]+')
    if [ -n "$IP_PUBLICA" ] && [ -n "$IP_ANTERIOR" ] && [ "$IP_PUBLICA" != "$IP_ANTERIOR" ]; then
        echo "  *** ALERTA: IP pública cambió de $IP_ANTERIOR a $IP_PUBLICA ***"
        echo "$TIMESTAMP | ALERTA | IP cambio: $IP_ANTERIOR -> $IP_PUBLICA" >> "$DIR_DATOS/alertas.txt"
    fi

    # Alerta si sube mucho la latencia
    if [ -n "$LATENCIA" ]; then
        LAT_MS=$(echo "$LATENCIA" | awk '{printf "%.0f", $1}')
        if [ "$LAT_MS" -gt 100 ] 2>/dev/null; then
            echo "  *** ALERTA: Latencia alta al gateway: ${LAT_MS}ms ***"
            echo "$TIMESTAMP | ALERTA | Latencia alta GW: ${LAT_MS}ms" >> "$DIR_DATOS/alertas.txt"
        fi
    fi

    echo "  Esperando ${INTERVALO} minutos..."
    echo ""
    sleep "${INTERVALO}m"
done
