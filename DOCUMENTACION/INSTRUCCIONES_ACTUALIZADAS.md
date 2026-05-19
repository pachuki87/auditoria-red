# ⚡ INSTRUCCIONES ACTUALIZADAS - SISTEMA AUDITORÍA 2.0

**Fecha:** 10 de mayo de 2026
**Versión:** 2.0

---

## 🎯 NOVEDADES EN VERSIÓN 2.0

### ✅ Nuevos Recursos
| Recurso | Descripción | Estado |
|---------|-------------|--------|
| **Router ZTE F6640** | Documentación completa del router | ✅ Disponible |
| **MIWIFI_U4hX** | Análisis detallado de la red | ✅ Disponible |
| **Atheros AR9271** | Adaptador WiFi USB instalado | ✅ Funcionando |
| **Script específico** | auditoria_zte_f6640.ps1 | ✅ Listo |

### ✅ Archivos Organizados
Todos los archivos ahora están en carpetas organizadas:
- `SCRIPTS/` - 11 scripts PowerShell
- `DOCUMENTACION/` - 7 guías y manuales
- `REPORTES/` - 3 reportes de clientes
- `CAPTURAS/` - Capturas Wireshark
- `DATOS_CLIENTES/` - Datos de conexión

---

## 🚀 CÓMO USAR EL SISTEMA ACTUALIZADO

### 1. Auditoría Completa del Router ZTE F6640

```powershell
# Entrar en el directorio
cd C:\Users\pabli\AUDITORIA_CIBERSEGURIDAD

# Ejecutar auditoría específica
powershell -ExecutionPolicy Bypass -File "SCRIPTS\auditoria_zte_f6640.ps1"
```

**Resultado:**
- Escaneo de dispositivos en red 192.168.1.0
- Análisis de Router ZTE F6640
- Análisis de red MIWIFI_U4hX
- IP pública del cliente
- Redes MIWIFI cercanas
- Recomendaciones de seguridad

### 2. Análisis de Red MIWIFI_U4hX

```powershell
# Ver documentación
notepad "DOCUMENTACION\RED_MIWIFI_U4HX_ANALISIS.md"

# O usar el script que incluye este análisis
powershell -ExecutionPolicy Bypass -File "SCRIPTS\auditoria_zte_f6640.ps1"
```

**Información obtenida:**
- SSID: MIWIFI_U4hX
- BSSID: ee:6b:9a:12:33:fc
- Canal: 3 (2422 MHz, 2.4 GHz)
- Seguridad: WPA2-PSK
- Fabricante: Xiaomi MIWiFi

### 3. Documentación Router ZTE F6640

```powershell
# Ver guía completa
notepad "DOCUMENTACION\ROUTER_ZTE_F6640_GUIA.md"
```

**Contenido:**
- Especificaciones técnicas
- Credenciales de acceso
- Configuración recomendada
- Problemas conocidos y soluciones
- Mantenimiento programado

### 4. Auditoría Rápida General

```powershell
powershell -ExecutionPolicy Bypass -File "SCRIPTS\auditoria_rapida.ps1"
```

**Para cuando necesites:**
- Auditoría de cualquier red
- Escaneo de dispositivos
- Identificación por MAC
- Análisis rápido

### 5. Monitoreo Remoto del Cliente

```powershell
powershell -ExecutionPolicy Bypass -File "SCRIPTS\MONITOREO_REMOTO_CLIENTE.ps1"
```

**Para acceso remoto:**
- https://62.93.179.163:8443
- Usuario: admin
- Router: ZTE F6640

---

## 📱 USAR ADAPTADOR WIFI ATHEROS AR9271

### Verificar Estado
```powershell
Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Atheros" }
```

**Resultado esperado:**
```
Name    : Wi-Fi 2
Status  : Disconnected
MAC     : C0-1C-30-49-CD-E2
```

### Escanear Redes WiFi
```powershell
netsh wlan show networks mode=bssid
```

### Capturar Tráfico con Wireshark
```powershell
# Iniciar captura de 30 segundos
"C:\Program Files\Wireshark\dumpcap.exe" -i "Wi-Fi 2" -w "CAPTURAS\captura_$(Get-Date -Format 'yyyyMMdd_HHmmss').pccapng" -a duration:30
```

---

## 📱 USAR TELÉFONO ANDROID (ADB)

### Ver Dispositivos Conectados
```bash
~/adb/platform-tools/adb.exe devices
```

### Ver Redes WiFi Guardadas
```bash
~/adb/platform-tools/adb.exe shell "dumpsys wifi" | grep -E "SSID|BSSID"
```

### Recuperar Contraseña WiFi (Método QR)
1. En el teléfono: Ajustes → WiFi → Redes guardadas
2. Seleccionar MIWIFI_U4hX
3. Tocar "Compartir"
4. Autenticar con huella/PIN
5. El teléfono muestra un código QR con la contraseña

### Capturar Pantalla del Teléfono
```bash
~/adb/platform-tools/adb.exe exec-out screencap -p > screen_miwifi.png
```

---

## 📊 PROCEDIMIENTO ESTÁNDAR ACTUALIZADO

### Auditoría Completa del Cliente Pepephone

#### Fase 1: Preparación (Antes de ir)
```powershell
# 1. Verificar adaptador WiFi
Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Atheros" }

# 2. Verificar ADB
~/adb/platform-tools/adb.exe devices

# 3. Cargar scripts
cd C:\Users\pabli\AUDITORIA_CIBERSEGURIDAD
```

#### Fase 2: En el Domicilio (15-20 min)
```powershell
# 1. Obtener datos del cliente
powershell -ExecutionPolicy Bypass -File "SCRIPTS\OBTENER_DATOS_CLIENTE.ps1"

# 2. Auditoría completa Router ZTE F6640
powershell -ExecutionPolicy Bypass -File "SCRIPTS\auditoria_zte_f6640.ps1"

# 3. Capturar tráfico si es necesario
"C:\Program Files\Wireshark\dumpcap.exe" -i "Wi-Fi 2" -w "CAPTURAS\captura_cliente.pcapng" -a duration:30
```

#### Fase 3: Desde Casa (Diagnóstico Remoto)
```
1. Acceder al router: https://62.93.179.163:8443
2. Usuario: admin
3. Analizar dispositivos conectados
4. Revisar consumo de ancho de banda
5. Aplicar QoS si es necesario
```

---

## 🎓 GUÍAS RÁPIDAS

### Problema: No detecto MIWIFI_U4hX
**Solución:**
1. Verificar que el router esté encendido
2. Acercarse al router (menos de 10 metros)
3. Usar adaptador Atheros AR9271
4. Escanear con: `netsh wlan show networks mode=bssid`

### Problema: No puedo acceder al router ZTE F6640
**Solución:**
1. Verificar conexión: `ping 192.168.1.1`
2. Usar navegador: http://192.168.1.1
3. Usuario: admin, Contraseña: admin
4. Si no funciona, resetear router

### Problema: ADB no detecta el teléfono
**Solución:**
1. Verificar cable USB
2. Verificar Depuración USB activada
3. Aceptar diálogo en el teléfono
4. Ejecutar: `~/adb/platform-tools/adb.exe devices`

---

## 📁 ARCHIVOS PRINCIPALES

| Archivo | Propósito |
|---------|-----------|
| `README.md` | Guía principal del sistema |
| `INDICE_GENERAL.md` | Índice completo de recursos |
| `ROUTER_ZTE_F6640_GUIA.md` | Documentación Router ZTE F6640 |
| `RED_MIWIFI_U4HX_ANALISIS.md` | Análisis red MIWIFI_U4hX |
| `auditoria_zte_f6640.ps1` | Script auditoría específico |

---

## ⚡ COMANDOS RÁPIDOS

```powershell
# Auditoría completa del cliente
cd C:\Users\pabli\AUDITORIA_CIBERSEGURIDAD
powershell -ExecutionPolicy Bypass -File "SCRIPTS\auditoria_zte_f6640.ps1"

# Ver documentación Router ZTE
notepad "DOCUMENTACION\ROUTER_ZTE_F6640_GUIA.md"

# Ver análisis MIWIFI_U4hX
notepad "DOCUMENTACION\RED_MIWIFI_U4HX_ANALISIS.md"

# Ver índice general
notepad "INDICE_GENERAL.md"

# Escanear redes WiFi
netsh wlan show networks mode=bssid

# Ver adaptador Atheros
Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Atheros" }
```

---

## 🔄 PRÓXIMA ACTUALIZACIÓN

**Fecha prevista:** Cuando haya nueva información del cliente
**Cosas a añadir:**
- [ ] Contraseña MIWIFI_U4hX (recuperada)
- [ ] Firmware actual Router ZTE F6640
- [ ] Configuración QoS aplicada
- [ ] Nuevos dispositivos detectados

---

## 📞 SOPORTE

**Sistema mantenido por:** [Tu nombre]
**Fecha:** 10 de mayo de 2026
**Versión:** 2.0

---

*Estas instrucciones se actualizan con cada nueva versión del sistema.*
