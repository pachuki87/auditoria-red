#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# ENVIAR REPORTE - Transfiere datos del móvil al PC
# Opciones:
#   bash termux_enviar_reporte.sh local     -> Copia via ADB
#   bash termux_enviar_reporte.sh zip       -> Crea ZIP para enviar
#   bash termux_enviar_reporte.sh telegram  -> Envía por Telegram
#   bash termux_enviar_reporte.sh ssh       -> Envía por SSH/SCP
# ============================================================

METODO="${1:-zip}"
DIR_HOME="$HOME/auditoria"
FECHA=$(date +"%Y-%m-%d_%H%M%S")
ARCHIVO_ZIP="$DIR_HOME/reportes_auditoria_${FECHA}.zip"

echo "=========================================="
echo " EXPORTAR DATOS DE AUDITORÍA"
echo " Método: $METODO"
echo "=========================================="
echo ""

case "$METODO" in

    zip)
        echo "Creando archivo ZIP..."
        cd "$DIR_HOME"
        zip -r "$ARCHIVO_ZIP" reportes/ datos/ 2>/dev/null
        if [ -f "$ARCHIVO_ZIP" ]; then
            SIZE=$(du -h "$ARCHIVO_ZIP" | awk '{print $1}')
            echo ""
            echo "Archivo creado: $ARCHIVO_ZIP"
            echo "Tamaño: $SIZE"
            echo ""
            echo "Puedes compartirlo con:"
            echo "  termux-share $ARCHIVO_ZIP"
            echo "  o moverlo a Downloads:"
            echo "  cp $ARCHIVO_ZIP /storage/emulated/0/Download/"
        else
            echo "Error creando ZIP"
        fi
        ;;

    local)
        # Via ADB - requiere PC conectado por USB o red ADB
        echo "Intentando transferencia ADB..."
        echo ""
        echo "1. Conecta el móvil al PC por USB"
        echo "2. En el PC ejecuta:"
        echo "   adb pull /data/data/com.termux/files/home/auditoria/ C:\\Users\\pabli\\AUDITORIA_CIBERSEGURIDAD\\DATOS_TERMOVIL\\"
        echo ""
        echo "O si ADB por red:"
        echo "   adb connect <IP_DEL_MOVIL>:5555"
        echo "   adb pull /data/data/com.termux/files/home/auditoria/ ./DATOS_TERMOVIL/"
        ;;

    telegram)
        # Enviar por Telegram Bot
        read -p "Token del Bot de Telegram: " BOT_TOKEN
        read -p "Chat ID de Telegram: " CHAT_ID

        # Crear ZIP primero
        cd "$DIR_HOME"
        zip -r "$ARCHIVO_ZIP" reportes/ datos/ 2>/dev/null

        if [ -f "$ARCHIVO_ZIP" ]; then
            echo "Enviando a Telegram..."
            curl -s -F "document=@$ARCHIVO_ZIP" \
                "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
                -F "chat_id=${CHAT_ID}" \
                -F "caption=\"Reporte auditoría $(date +"%d/%m/%Y %H:%M")\""
            echo ""
            echo "Enviado."
        fi
        ;;

    ssh)
        read -p "IP del PC destino: " PC_IP
        read -p "Usuario SSH: " SSH_USER
        read -p "Ruta destino (Enter para default): " DESTINO
        DESTINO="${DESTINO:-/tmp/auditoria_termux}"

        echo "Enviando via SCP..."
        scp -r "$DIR_HOME/reportes/" "$DIR_HOME/datos/" \
            "${SSH_USER}@${PC_IP}:${DESTINO}/"
        ;;

    *)
        echo "Método no reconocido: $METODO"
        echo "Usa: zip, local, telegram o ssh"
        ;;
esac

echo ""
