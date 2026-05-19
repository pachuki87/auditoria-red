# Auditoria Rapida de Red - Version Optimizada
param([string]$Gateway = "192.168.1.1")

Write-Host "========================================"
Write-Host " AUDITORIA RAPIDA DE RED"
Write-Host "========================================"
Write-Host "Fecha: $(Get-Date)"
Write-Host "Gateway: $Gateway"
Write-Host ""

# Funcion para obtener vendor de MAC
function Get-MacVendor {
    param([string]$mac)
    try {
        if ($mac.Length -ge 8) {
            $macPrefix = $mac.Substring(0, 8).Replace("-", ":")
            $vendors = @{
                "e4:ab:89" = "Movistar/Router"
                "f8:25:51" = "Xiaomi/Smart Device"
                "2c:7b:a0" = "Intel/PC"
                "00:1b:63" = "Apple"
                "00:0c:29" = "VMware"
                "08:00:27" = "VirtualBox"
                "a4:83:e7" = "Samsung/Smart TV"
                "c8:7b:2a" = "LG/Smart TV"
                "b4:96:91" = "Sony/Smart TV"
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

# 1. ESCANEO RAPIDO (solo primeros 50)
Write-Host "1. ESCANEANDO DISPOSITIVOS (rangos comunes)..."
Write-Host "----------------------------------------"

$dispositivos = @()
$rangoBase = $Gateway.Substring(0, $Gateway.LastIndexOf('.'))

# Escanear rangos comunes domesticos
$rangosComunes = @(1..50) + @(100..120)

foreach ($ultimoOcteto in $rangosComunes) {
    $ip = "$rangoBase.$ultimoOcteto"
    try {
        $ping = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
        if ($ping) {
            $macOutput = arp -a $ip 2>&1
            if ($macOutput -match "$ip") {
                $lines = $macOutput -split "`n"
                foreach ($line in $lines) {
                    if ($line -match "$ip" -and $line -match "[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}") {
                        $parts = $line -split '\s+'
                        $macAddress = $parts | Where-Object { $_ -match '^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$' }
                        if ($macAddress) {
                            $vendor = Get-MacVendor -mac $macAddress[0]
                            $dispositivos += [PSCustomObject]@{
                                IP = $ip
                                MAC = $macAddress[0]
                                Vendor = $vendor
                                Estado = "Activo"
                            }
                            Write-Host "  $ip - $($macAddress[0]) ($vendor)" -ForegroundColor Green
                        }
                    }
                }
            }
        }
    } catch {
        # Continuar
    }
}

Write-Host "`nTotal dispositivos encontrados: $($dispositivos.Count)" -ForegroundColor Cyan
Write-Host ""

# 2. ANALISIS DE TRAFICO ACTUAL
Write-Host "2. ANALIZANDO TRAFICO ACTUAL..."
Write-Host "----------------------------------------"

try {
    $conexiones = netstat -an 2>&1 | Select-String "ESTABLISHED"
    Write-Host "Conexiones activas totales: $($conexiones.Count)" -ForegroundColor Green

    # Conexiones externas (no locales)
    $conexionesExternas = $conexiones | Where-Object { $_ -notmatch "127\.0\.0\.1" }
    Write-Host "Conexiones no locales: $($conexionesExternas.Count)" -ForegroundColor Green

    # Mostrar algunas conexiones externas para analisis
    $conexionesInteresantes = $conexionesExternas | Select-Object -First 5
    if ($conexionesInteresantes) {
        Write-Host "`nEjemplo de conexiones externas:" -ForegroundColor Yellow
        $conexionesInteresantes | ForEach-Object {
            $parts = $_ -split '\s+'
            $ipExterna = $parts[2] -replace ':.*', ''
            $puerto = $parts[1] -replace '.*:', ''
            Write-Host "  Local:$puerto -> Remota:$ipExterna" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "Error al analizar conexiones: $_" -ForegroundColor Red
}
Write-Host ""

# 3. MEDICION DE LATENCIA Y VELOCIDAD
Write-Host "3. MIDIENDO LATENCIA Y CALIDAD DE CONEXION..."
Write-Host "----------------------------------------"

$pingRouter = $null
$pingInternet = $null

try {
    # Medir latencia al router
    $pingRouter = Test-Connection -ComputerName $Gateway -Count 10 -ErrorAction Stop
    $latenciaRouter = [math]::Round($pingRouter.ResponseTime.Average(), 2)
    Write-Host "Latencia media al router: $latenciaRouter ms" -ForegroundColor Green

    # Medir latencia a internet
    $pingInternet = Test-Connection -ComputerName "8.8.8.8" -Count 10 -ErrorAction Stop
    $latenciaInternet = [math]::Round($pingInternet.ResponseTime.Average(), 2)
    Write-Host "Latencia media a internet: $latenciaInternet ms" -ForegroundColor Green

    # Calcular calidad de conexion
    $perdidaRouter = $pingRouter.PacketLoss
    $perdidaInternet = $pingInternet.PacketLoss
    Write-Host "Perdida de paquetes router: $perdidaRouter %" -ForegroundColor Green
    Write-Host "Perdida de paquetes internet: $perdidaInternet %" -ForegroundColor Green

    # Evaluar calidad
    if ($latenciaRouter -lt 5 -and $latenciaInternet -lt 30) {
        Write-Host "Calidad de conexion: EXCELENTE" -ForegroundColor Green
    } elseif ($latenciaRouter -lt 10 -and $latenciaInternet -lt 50) {
        Write-Host "Calidad de conexion: BUENA" -ForegroundColor Yellow
    } else {
        Write-Host "Calidad de conexion: PROBLEMATICA" -ForegroundColor Red
    }

} catch {
    Write-Host "Error al medir latencia: $_" -ForegroundColor Red
}
Write-Host ""

# 4. ANALISIS DE DISPOSITIVOS SOSPECHOSOS
Write-Host "4. ANALISIS DE DISPOSITIVOS..."
Write-Host "----------------------------------------"

$smartTVs = $dispositivos | Where-Object { $_.Vendor -like "*TV*" -or $_.Vendor -like "*Samsung*" -or $_.Vendor -like "*LG*" -or $_.Vendor -like "*Sony*" }
if ($smartTVs) {
    Write-Host "Smart TVs detectadas (posibles consumidores de ancho de banda):" -ForegroundColor Yellow
    $smartTVs | ForEach-Object {
        Write-Host "  $($_.IP) - $($_.MAC) - $($_.Vendor)" -ForegroundColor Red
    }
} else {
    Write-Host "No se detectaron Smart TVs" -ForegroundColor Green
}

$desconocidos = $dispositivos | Where-Object { $_.Vendor -eq "Desconocido" }
if ($desconocidos) {
    Write-Host "`nDispositivos desconocidos:" -ForegroundColor Yellow
    $desconocidos | ForEach-Object {
        Write-Host "  $($_.IP) - $($_.MAC)" -ForegroundColor Gray
    }
}
Write-Host ""

# 5. VERIFICACION DE SEGURIDAD BASICA
Write-Host "5. VERIFICACION DE SEGURIDAD..."
Write-Host "----------------------------------------"

# Verificar puertos comunes en router
$puertosComunes = @(80, 443, 8080, 8443, 22, 23)
Write-Host "Verificando puertos de administracion remota:"

foreach ($puerto in $puertosComunes) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.ReceiveTimeout = 500
        $tcp.Connect($Gateway, $puerto)
        if ($tcp.Connected) {
            $nombrePuerto = switch($puerto) {
                80 { "HTTP" }
                443 { "HTTPS" }
                8080 { "HTTP-Alt" }
                8443 { "HTTPS-Alt" }
                22 { "SSH" }
                23 { "Telnet" }
                default { "Puerto $puerto" }
            }
            Write-Host "  $nombrePuerto ($puerto): ABIERTO - Riesgo potencial" -ForegroundColor Yellow
            $tcp.Close()
        }
    } catch {
        $nombrePuerto = switch($puerto) {
            80 { "HTTP" }
            443 { "HTTPS" }
            8080 { "HTTP-Alt" }
            8443 { "HTTPS-Alt" }
            22 { "SSH" }
            23 { "Telnet" }
            default { "Puerto $puerto" }
        }
        Write-Host "  $nombrePuerto ($puerto): CERRADO - Seguro" -ForegroundColor Green
    }
}
Write-Host ""

# 6. RECOMENDACIONES ESPECIFICAS
Write-Host "6. RECOMENDACIONES DE OPTIMIZACION:"
Write-Host "----------------------------------------"

$recomendaciones = @()

if ($dispositivos.Count -gt 15) {
    $recomendaciones += "⚠️  Red sobrecargada: $($dispositivos.Count) dispositivos. Considerar red WiFi invitados."
}

if ($smartTVs.Count -gt 2) {
    $recomendaciones += "⚠️  Múltiples Smart TVs: Configurar QoS para limitar streaming."
}

if ($pingInternet -and $pingInternet.ResponseTime.Average() -gt 50) {
    $recomendaciones += "⚠️  Latencia alta a internet: Revisar conexión ISP."
}

if ($pingRouter -and $pingRouter.ResponseTime.Average() -gt 15) {
    $recomendaciones += "⚠️  Latencia alta al router: Posible interferencia WiFi."
}

if ($recomendaciones.Count -eq 0) {
    $recomendaciones += "OK - Red aparentemente saludable"
} else {
    $recomendaciones += "OK - Considerar configurar QoS para priorizar trafico critico"
    $recomendaciones += "OK - Verificar actualizaciones de firmware del router"
    $recomendaciones += "OK - Revisar dispositivos desconocidos conectados"
}

$recomendaciones | ForEach-Object { Write-Host $_ }

# 7. REPORTE FINAL
Write-Host ""
Write-Host "========================================"
Write-Host " REPORTE FINAL DE AUDITORIA"
Write-Host "========================================"
Write-Host "Dispositivos activos: $($dispositivos.Count)"
Write-Host "Smart TVs detectadas: $($smartTVs.Count)"
Write-Host "Dispositivos desconocidos: $($desconocidos.Count)"

if ($pingInternet) {
    Write-Host "Latencia media internet: $latenciaInternet ms"
}

Write-Host "Calidad general: $(if ($latenciaInternet -lt 30) { 'EXCELENTE' } elseif ($latenciaInternet -lt 50) { 'BUENA' } else { 'PROBLEMATICA' })"
Write-Host "Auditoria completada: $(Get-Date)"
Write-Host "========================================"

# Guardar reporte detallado
try {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $reporteFile = "C:\Users\pabli\auditoria_red_$timestamp.txt"

    $reporteContenido = @"
AUDITORIA DE RED RESIDENCIAL
=====================================
Fecha: $(Get-Date)
Gateway: $Gateway
Dispositivos encontrados: $($dispositivos.Count)

DISPOSITIVOS DETECTADOS:
=====================================
"@
    $dispositivos | Format-Table -AutoSize | Out-File -FilePath $reporteFile -Encoding UTF8 -Append

    $recomendaciones | Out-File -FilePath $reporteFile -Encoding UTF8 -Append

    Write-Host "`nReporte detallado guardado en: $reporteFile" -ForegroundColor Cyan
} catch {
    Write-Host "Error al guardar reporte: $_" -ForegroundColor Red
}