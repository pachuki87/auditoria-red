# Auditoría de Red Residencial - Script Completo
# Para uso en auditorías autorizadas de redes residenciales

param(
    [string]$Gateway = "192.168.1.1",
    [int]$DuracionMonitoreo = 60
)

# Headers
Write-Host "="*60 -ForegroundColor Cyan
Write-Host " AUDITORÍA DE RED RESIDENCIAL" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Green
Write-Host "Gateway: $Gateway" -ForegroundColor Green
Write-Host ""

# Función para obtener vendor de MAC
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

# 1. ESCANEO DE RED
Write-Host "1. ESCANEANDO DISPOSITIVOS EN LA RED..." -ForegroundColor Yellow
Write-Host "-"*60

$dispositivos = @()
$rangoBase = $Gateway.Substring(0, $Gateway.LastIndexOf('.'))

1..254 | ForEach-Object {
    $ip = "$rangoBase.$_"
    try {
        $ping = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
        if ($ping) {
            $macOutput = arp -a $ip 2>&1
            if ($macOutput -match "$ip") {
                $lines = $macOutput -split "`n"
                foreach ($line in $lines) {
                    if ($line -match "$ip" -and $line -match "[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}") {
                        $macAddress = (($line -split '\s+') | Where-Object { $_ -match "^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$" })[0]
                        if ($macAddress) {
                            $vendor = Get-MacVendor -mac $macAddress
                            $dispositivos += [PSCustomObject]@{
                                IP = $ip
                                MAC = $macAddress
                                Vendor = $vendor
                                Estado = "Activo"
                            }
                            Write-Host "  $ip - $macAddress ($vendor)" -ForegroundColor Green
                        }
                    }
                }
            }
        }
    } catch {
        # Silencioso para continuar el escaneo
    }
}

Write-Host "`nTotal dispositivos encontrados: $($dispositivos.Count)" -ForegroundColor Cyan
Write-Host ""

# 2. ANÁLISIS DE TRÁFICO
Write-Host "2. ANALIZANDO TRÁFICO DE RED..." -ForegroundColor Yellow
Write-Host "-"*60

try {
    $conexiones = netstat -an 2>&1 | Select-String "ESTABLISHED"
    Write-Host "Conexiones activas: $($conexiones.Count)" -ForegroundColor Green

    # Conexiones externas
    $conexionesExternas = $conexiones | Where-Object { $_ -notmatch "127\.0\.0\.1" -and $_ -notmatch "192\.168\." }
    Write-Host "Conexiones externas: $($conexionesExternas.Count)" -ForegroundColor Green
} catch {
    Write-Host "Error al analizar conexiones: $_" -ForegroundColor Red
}
Write-Host ""

# 3. VELOCIDAD Y LATENCIA
Write-Host "3. MIDIENDO VELOCIDAD Y LATENCIA..." -ForegroundColor Yellow
Write-Host "-"*60

$pingRouter = $null
$pingInternet = $null

try {
    $pingRouter = Test-Connection -ComputerName $Gateway -Count 5 -ErrorAction Stop
    $pingInternet = Test-Connection -ComputerName "8.8.8.8" -Count 5 -ErrorAction Stop

    Write-Host "Latencia Router: $($pingRouter.ResponseTime.Average().ToString('0.00')) ms" -ForegroundColor Green
    Write-Host "Latencia Internet: $($pingInternet.ResponseTime.Average().ToString('0.00')) ms" -ForegroundColor Green
    Write-Host "Pérdida Router: $($pingRouter.PacketLoss)%" -ForegroundColor Green
    Write-Host "Pérdida Internet: $($pingInternet.PacketLoss)%" -ForegroundColor Green
} catch {
    Write-Host "Error al medir latencia: $_" -ForegroundColor Red
}
Write-Host ""

# 4. CONFIGURACIÓN DNS
Write-Host "4. VERIFICANDO CONFIGURACIÓN DNS..." -ForegroundColor Yellow
Write-Host "-"*60

try {
    $dnsResult = nslookup google.com 2>&1
    Write-Host "Configuración DNS:"
    $dnsLines = $dnsResult | Select-String "Server:"
    if ($dnsLines) {
        $dnsLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
    } else {
        Write-Host "  Usando DNS por defecto del sistema" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error al consultar DNS: $_" -ForegroundColor Red
}
Write-Host ""

# 5. ANÁLISIS DE SEGURIDAD
Write-Host "5. ANÁLISIS DE SEGURIDAD BÁSICO..." -ForegroundColor Yellow
Write-Host "-"*60

$puertosComunes = @(80, 443, 8080, 8443)
Write-Host "Verificando puertos de administración:"
foreach ($puerto in $puertosComunes) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $connect = $tcp.BeginConnect($Gateway, $puerto, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(1000, $false)
        if ($wait) {
            $tcp.EndConnect($connect)
            Write-Host "  Puerto $puerto ABIERTO en $Gateway" -ForegroundColor Yellow
            $tcp.Close()
        } else {
            Write-Host "  Puerto $puerto cerrado en $Gateway" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Puerto $puerto cerrado en $Gateway" -ForegroundColor Green
    }
}
Write-Host ""

# 6. RECOMENDACIONES
Write-Host "6. RECOMENDACIONES:" -ForegroundColor Yellow
Write-Host "-"*60

if ($dispositivos.Count -gt 10) {
    Write-Host "  Muchos dispositivos conectados. Considerar segmentación de red." -ForegroundColor Yellow
}

if ($pingRouter -and $pingRouter.ResponseTime.Average() -gt 10) {
    Write-Host "  Latencia alta al router. Posible congestión WiFi." -ForegroundColor Yellow
}

if ($pingInternet -and $pingInternet.ResponseTime.Average() -gt 50) {
    Write-Host "  Latencia alta a internet. Revisar conexión ISP." -ForegroundColor Yellow
}

Write-Host "  Considerar configurar QoS para priorizar tráfico crítico" -ForegroundColor Green
Write-Host "  Verificar actualizaciones de firmware del router" -ForegroundColor Green
Write-Host "  Revisar dispositivos desconocidos conectados" -ForegroundColor Green

# 7. REPORTE FINAL
Write-Host ""
Write-Host "="*60 -ForegroundColor Cyan
Write-Host " REPORTE FINAL" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Dispositivos activos: $($dispositivos.Count)" -ForegroundColor Green

if ($conexionesExternas) {
    Write-Host "Conexiones externas: $($conexionesExternas.Count)" -ForegroundColor Green
}

if ($pingInternet) {
    Write-Host "Latencia media a internet: $($pingInternet.ResponseTime.Average().ToString('0.00')) ms" -ForegroundColor Green
}

Write-Host "Auditoría completada: $(Get-Date)" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan

# Guardar reporte
try {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $reporteFile = "C:\Users\pabli\auditoria_red_$timestamp.txt"
    $dispositivos | Format-Table -AutoSize | Out-File -FilePath $reporteFile -Encoding UTF8
    Write-Host "Reporte guardado en: $reporteFile" -ForegroundColor Cyan
} catch {
    Write-Host "Error al guardar reporte" -ForegroundColor Red
}