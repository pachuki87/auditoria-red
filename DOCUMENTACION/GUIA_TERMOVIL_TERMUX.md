# Kit Termux - Auditoría desde el Móvil

## Scripts Disponibles

| Script | Función |
|--------|---------|
| `termux_setup.sh` | Instala todas las herramientas (ejecutar 1 vez) |
| `termux_auditoria.sh` | Auditoría completa de la red |
| `termux_monitor.sh` | Monitoreo continuo cada X minutos |
| `termux_enviar_reporte.sh` | Exportar datos (ZIP, Telegram, SSH) |

## Instalación Rápida

### 1. Preparar Termux en el móvil

```bash
# Abrir Termux y ejecutar:
pkg update && pkg upgrade -y
pkg install -y termux-api
```

### 2. Instalar la app Termux:API

Descargar desde **F-Droid** (NO Google Play, está desactualizada):
- Buscar "Termux:API" en F-Droid
- Debe coincidir con la versión de Termux instalada

### 3. Transferir scripts al móvil

**Opción A - Por ADB (recomendado):**
```powershell
# En el PC, con el móvil conectado por USB:
adb push termux_setup.sh /data/data/com.termux/files/home/
adb push termux_auditoria.sh /data/data/com.termux/files/home/
adb push termux_monitor.sh /data/data/com.termux/files/home/
adb push termux_enviar_reporte.sh /data/data/com.termux/files/home/
```

**Opción B - Por WhatsApp/Telegram:**
- Enviarse los scripts como archivo
- Guardar en Downloads
- En Termux: `cp /storage/emulated/0/Download/termux_*.sh ~/`

### 4. Ejecutar setup

```bash
cd ~
chmod +x termux_setup.sh
bash termux_setup.sh
```

Esto instala: nmap, dnsutils, whois, curl, wget, net-tools, iproute2, traceroute, python, openssh, rsync, termux-api.

## Uso Diario

### Auditoría rápida
```bash
bash termux_auditoria.sh --rapido
# ~2 minutos, puertos comunes
```

### Auditoría completa
```bash
bash termux_auditoria.sh --completo
# ~5 minutos, todos los puertos
```

### Monitoreo continuo
```bash
bash termux_monitor.sh 30
# Escanea cada 30 minutos
# Ctrl+C para detener
```

### Exportar datos
```bash
# Crear ZIP para enviar
bash termux_enviar_reporte.sh zip

# Enviar por Telegram
bash termux_enviar_reporte.sh telegram

# Via SSH al PC
bash termux_enviar_reporte.sh ssh
```

## Qué Recopila Cada Script

### termux_auditoria.sh
1. Info WiFi (SSID, BSSID, IP, gateway, DNS, frecuencia)
2. IP pública + ISP + ubicación
3. Todos los dispositivos en la red (MAC + vendor)
4. Puertos abiertos del router
5. Puertos abiertos en el móvil
6. Análisis de seguridad (Telnet, FTP, SMB, admin remoto)
7. Test de rendimiento (latencia, velocidad)
8. Resumen con alertas

### termux_monitor.sh
- Log continuo de: IP pública, dispositivos, latencia
- Alertas automáticas: cambio de IP, latencia alta
- Historial de dispositivos conectados

### termux_enviar_reporte.sh
- ZIP con todos los reportes y datos
- Telegram Bot
- SSH/SCP al PC
- ADB pull

## Estructura en el Móvil

```
~/auditoria/
├── reportes/          # Reportes de cada auditoría
├── capturas/          # Capturas (si se añaden)
├── datos/             # Logs y datos históricos
│   ├── monitor_log.txt          # Log del monitoreo
│   ├── dispositivos_historial.txt  # Historial MACs
│   ├── historial_ips.txt        # Historial IPs públicas
│   └── alertas.txt              # Alertas detectadas
└── termux_auditoria.sh
```

## Flujo de Trabajo Recomendado

### Primera visita al cliente:
1. Conectarse al WiFi del cliente
2. Ejecutar `bash termux_setup.sh` (solo la primera vez)
3. Ejecutar `bash termux_auditoria.sh --completo`
4. Exportar: `bash termux_enviar_reporte.sh zip`
5. Enviar ZIP al PC por Telegram/ADB

### Visitas de seguimiento:
1. Conectarse al WiFi
2. Auditoría rápida: `bash termux_auditoria.sh --rapido`
3. Comparar con reporte anterior

### Monitoreo largo (si dejas el móvil):
1. Dejar el móvil conectado al cargador
2. `bash termux_monitor.sh 15` (cada 15 min)
3. Al recoger: `bash termux_enviar_reporte.sh zip`

## Notas Importantes

- **Sin root:** nmap usa `-sT` (connect scan) en vez de `-sS` (syn scan)
- **Termux:API** es necesaria para info detallada del WiFi
- **Batería:** El monitoreo continuo consume batería, usar con cargador
- **Background:** Termux puede cerrarse en segundo plano en Xiaomi/MIUI. Usar:
  ```bash
  # Prevenir que MIUI mate Termux
  # Ajustes > Apps > Termux > Batería > Sin restricciones
  ```
