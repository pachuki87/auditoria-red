# ⚡ AUDITORÍA ROUTER ZTE F6640
# Script genérico para routers ZTE F6640
# Uso: .\auditoria_zte_f6640.ps1 -Gateway "192.168.1.1" -TargetSSID "NOMBRE_RED"

param(
    [string]$Gateway = "192.168.1.1",
    [string]$RouterModel = "ZTE F6640",
    [string]$TargetSSID = ""
)

# Configuración
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " AUDITORÍA ROUTER $RouterModel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)" -ForegroundColor White
Write-Host "Router: $RouterModel" -ForegroundColor White
Write-Host "Gateway: $Gateway" -ForegroundColor White
Write-Host "Red Objetivo: $TargetSSID" -ForegroundColor Yellow
Write-Host ""

# Base de datos de vendors MAC
function Get-MacVendor {
    param([string]$mac)
    try {
        if ($mac.Length -ge 8) {
            $macPrefix = $mac.Substring(0, 8).Replace("-", ":")
            $vendors = @{
                "e4:ab:89" = "Movistar/Router ZTE"
                "ee:6b:9a" = "Xiaomi/MIWiFi Router"
                "f8:25:51" = "Xiaomi/Smart Device"
                "2c:7b:a0" = "Intel/PC"
                "00:1b:63" = "Apple/iPhone"
                "00:0c:29" = "VMware"
                "08:00:27" = "VirtualBox"
                "a4:83:e7" = "Samsung/Smart TV"
                "c8:7b:2a" = "LG/Smart TV"
                "b4:96:91" = "Sony/Smart TV"
                "3e:7e:e0" = "Android/Phone"
                "c0:1c:30" = "Atheros/WiFi-USB"
            }
            if ($vendors.ContainsKey($macPrefix)) {
                return $vendors[$macPrefix]
            }
        }
    } catch {
        return "Desconocido"
    }
    return "Desconocido"
}

# 1. ESCANEAR DISPOSITIVOS
Write-Host "1. ESCANEANDO DISPOSITIVOS EN RED $Gateway..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$dispositivos = @()
$rangoBase = $Gateway.Substring(0, $Gateway.LastIndexOf('.'))
$rangosComunes = @(1..50) + @(100..120)

foreach ($ultimoOcteto in $rangosComunes) {
    $ip = "$rangoBase.$ultimoOcteto"
    try {
        $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($ping) {
            $arp = arp -a | Select-String "$ip " | Select-Object -First 1
            if ($arp) {
                $parts = $arp -split '\s+'
                $mac = $parts[1]
                $vendor = Get-MacVendor -mac $mac
                $dispositivos += [PSCustomObject]@{
                    IP = $ip
                    MAC = $mac
                    Vendor = $vendor
                    Estado = "Activo"
                }
                Write-Host "  $($ip) - $($mac) - $($vendor)" -ForegroundColor Green
            }
        }
    } catch {}
}

Write-Host "`nTotal dispositivos encontrados: $($dispositivos.Count)" -ForegroundColor Cyan

# 2. ANALIZAR RED WiFi OBJETIVO
if ($TargetSSID) {
    Write-Host "`n2. ANALIZANDO RED $TargetSSID..." -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow

    try {
        $redes = netsh wlan show networks mode=bssid
        $redObjetivo = $redes | Select-String "SSID.*:\s+$TargetSSID" -Context 0,10
        if ($redObjetivo) {
            Write-Host "Red encontrada:" -ForegroundColor Green
            Write-Host $redObjetivo
        } else {
            Write-Host "Red '$TargetSSID' no encontrada en el escaneo" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error al escanear redes WiFi" -ForegroundColor Red
    }
}

# 3. INFORMACIÓN ROUTER
Write-Host "`n3. INFORMACIÓN ROUTER $RouterModel..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

Write-Host "Modelo: $RouterModel" -ForegroundColor White
Write-Host "Gateway: $Gateway" -ForegroundColor White
Write-Host "Tipo: ONT Fiber + WiFi" -ForegroundColor White

# Intentar acceso al panel
$httpCode = try { (Invoke-WebRequest -Uri "http://$Gateway" -UseBasicParsing -TimeoutSec 5).StatusCode } catch { "Sin respuesta" }
Write-Host "Panel HTTP: $httpCode" -ForegroundColor $(if ($httpCode -eq 200) { "Green" } else { "Yellow" })

# 4. OBTENER IP PÚBLICA
Write-Host "`n4. OBTENIENDO IP PÚBLICA..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

try {
    $ipPublica = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10).Content
    Write-Host "IP PUBLICA: $ipPublica" -ForegroundColor Green

    $ispInfo = (Invoke-WebRequest -Uri "http://ip-api.com/json/$ipPublica?fields=isp,org,city" -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
    Write-Host "ISP: $($ispInfo.isp)" -ForegroundColor White
    Write-Host "Ciudad: $($ispInfo.city)" -ForegroundColor White
} catch {
    Write-Host "No se pudo obtener la IP publica" -ForegroundColor Red
    $ipPublica = "DESCONOCIDA"
}

# 5. ESCANEAR REDES WIFI CERCANAS
Write-Host "`n5. ESCANEANDO REDES WIFI CERCANAS..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

try {
    $redes = netsh wlan show networks | Select-String "SSID\s+\d+\s+:\s+(.+)"
    $redesLista = @()
    foreach ($line in $redes) {
        $ssid = $matches[1].Trim()
        if ($ssid -and $ssid -ne "") {
            $redesLista += $ssid
            Write-Host "  $ssid" -ForegroundColor White
        }
    }
    Write-Host "`nTotal redes WiFi detectadas: $($redesLista.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "Error al escanear redes WiFi" -ForegroundColor Red
}

# 6. ANALIZAR CONSUMO POTENCIAL
Write-Host "`n6. ANALIZANDO DISPOSITIVOS DE ALTO CONSUMO..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$dispositivosAltoConsumo = $dispositivos | Where-Object { $_.Vendor -match "Smart TV|Xiaomi" }

if ($dispositivosAltoConsumo) {
    Write-Host "DISPOSITIVOS CON ALTO CONSUMO POTENCIAL:" -ForegroundColor Red
    foreach ($disp in $dispositivosAltoConsumo) {
        Write-Host "  $($disp.IP) - $($disp.Vendor)" -ForegroundColor Yellow
    }
    Write-Host "`nRecomendacion: Configurar QoS para limitar streaming" -ForegroundColor Cyan
} else {
    Write-Host "No se detectaron dispositivos de alto consumo obvios" -ForegroundColor Green
}

# 7. GUARDAR DATOS
Write-Host "`n7. GUARDANDO DATOS DE AUDITORIA..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$directorioReportes = "$PSScriptRoot\..\REPORTES"
if (-not (Test-Path $directorioReportes)) { mkdir $directorioReportes -Force | Out-Null }

$reporte = @"
========================================
AUDITORIA ROUTER $RouterModel
========================================
Fecha: $(Get-Date)
Router: $RouterModel
Gateway: $Gateway
IP Publica: $ipPublica
ISP: $($ispInfo.isp)

DISPOSITIVOS ENCONTRADOS: $($dispositivos.Count)
========================================
"@

foreach ($disp in $dispositivos) {
    $reporte += "`n$($disp.IP) - $($disp.MAC) - $($disp.Vendor)"
}

$reporte += @"


========================================
REDES WIFI DETECTADAS: $($redesLista.Count)
========================================
$($redesLista -join "`n")

========================================
RECOMENDACIONES
========================================
1. Cambiar contrasena por defecto del router
2. Desactivar WPS si esta habilitado
3. Actualizar firmware del router
4. Configurar QoS para Smart TVs
5. Usar canal 1, 6 o 11 para evitar interferencias
6. Considerar banda 5 GHz si esta disponible
"@

$archivo = "$directorioReportes\AUDITORIA_${RouterModel.Replace(' ','_')}_$timestamp.txt"
$reporte | Out-File -FilePath $archivo -Encoding UTF8

Write-Host "Datos guardados: $archivo" -ForegroundColor Green

# 8. RECOMENDACIONES
Write-Host "`n8. RECOMENDACIONES..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

Write-Host "SEGURIDAD:" -ForegroundColor Cyan
Write-Host "  1. Cambiar contrasena por defecto del router" -ForegroundColor White
Write-Host "  2. Desactivar WPS si esta habilitado" -ForegroundColor White
Write-Host "  3. Actualizar firmware del router" -ForegroundColor White

Write-Host "`nRENDIMIENTO:" -ForegroundColor Cyan
Write-Host "  1. Configurar QoS para Smart TVs" -ForegroundColor White
Write-Host "  2. Usar canal 1, 6 o 11 para evitar interferencias" -ForegroundColor White
Write-Host "  3. Considerar banda 5 GHz si esta disponible" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " AUDITORIA COMPLETADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
