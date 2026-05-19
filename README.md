# Kit de Auditoría de Red - Termux + PowerShell

Herramientas de auditoría de red para ejecutar desde PC (PowerShell) y móvil (Termux).

## Estructura

```
auditoria-red/
├── SCRIPTS/
│   ├── auditoria_rapida.ps1          # Escaneo completo de red
│   ├── auditoria_red.ps1             # Auditoría detallada
│   ├── auditoria_flash.ps1           # Diagnóstico ultra rápido
│   ├── monitoreo_continuo.ps1        # Monitoreo en tiempo real
│   ├── termux_setup.sh               # Instalación Termux (1 vez)
│   ├── termux_auditoria.sh           # Auditoría completa desde móvil
│   ├── termux_monitor.sh             # Monitoreo continuo móvil
│   └── termux_enviar_reporte.sh      # Exportar datos
├── DOCUMENTACION/
│   ├── GUIA_TERMOVIL_TERMUX.md       # Guía completa Termux
│   └── ...
├── REPORTES/                         # Reportes (gitignored)
├── CAPTURAS/                         # Capturas Wireshark (gitignored)
├── DATOS_CLIENTES/                   # Datos sensibles (gitignored)
└── HERRAMIENTAS/                     # Binarios (gitignored)
```

## Inicio Rápido en Termux

```bash
# 1. Clonar repo
git clone https://github.com/pachuki87/auditoria-red.git
cd auditoria-red

# 2. Instalar herramientas
bash SCRIPTS/termux_setup.sh

# 3. Ejecutar auditoría completa
bash SCRIPTS/termux_auditoria.sh

# 4. Auditoría rápida
bash SCRIPTS/termux_auditoria.sh --rapido

# 5. Monitoreo continuo (cada 30 min)
bash SCRIPTS/termux_monitor.sh 30
```

## En PC (PowerShell)

```powershell
# Auditoría rápida
powershell -ExecutionPolicy Bypass -File .\SCRIPTS\auditoria_rapida.ps1

# Monitoreo continuo
powershell -ExecutionPolicy Bypass -File .\SCRIPTS\monitoreo_continuo.ps1
```

## Qué Hace Cada Script

### Termux (móvil)
| Script | Tiempo | Función |
|--------|--------|---------|
| `termux_setup.sh` | 5 min | Instala nmap, python, curl, dnsutils... |
| `termux_auditoria.sh` | 2-5 min | WiFi info, IP, dispositivos, puertos, seguridad |
| `termux_monitor.sh` | Continuo | Log cada X min, alertas de IP/latencia |
| `termux_enviar_reporte.sh` | - | ZIP, Telegram, SSH |

### PowerShell (PC)
| Script | Función |
|--------|---------|
| `OBTENER_DATOS_CLIENTE.ps1` | IP pública + dispositivos rápidos |
| `auditoria_rapida.ps1` | Escaneo completo con identificación MAC |
| `monitoreo_continuo.ps1` | Monitoreo en tiempo real |
| `MONITOREO_REMOTO_CLIENTE.ps1` | Acceso remoto al router |

## Requisitos

**PC:** PowerShell 5+, Windows 10/11
**Móvil:** Termux + Termux:API (desde [F-Droid](https://f-droid.org))

## Vendors MAC Soportados

| Prefijo | Fabricante |
|---------|------------|
| `e4:ab:89` | Movistar/ZTE |
| `ee:6b:9a` | Xiaomi/MIWiFi |
| `f8:25:51` | Xiaomi Smart |
| `a4:83:e7` | Samsung TV |
| `c8:7b:2a` | LG TV |
| `00:1b:63` | Apple |
| `2c:7b:a0` | Intel/PC |

## Licencia

Uso privado. No compartir datos de clientes.
