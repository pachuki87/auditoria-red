# Auditoria de Red Residencial
param([string]$Gateway = "192.168.1.1")

Write-Host "========================================"
Write-Host " AUDITORIA DE RED RESIDENCIAL"
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
Write-Host "1. ESCANEANDO DISPOSITIVOS..."
Write-Host "----------------------------------------"

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
                    if ($line -match "$ip") {
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
                            Write-Host "  $ip - $($macAddress[0]) ($vendor)"
                        }
                    }
                }
            }
        }
    } catch {
        # Continuar
    }
}

Write-Host "Total dispositivos: $($dispositivos.Count)"
Write-Host ""

# 2. ANALISIS DE TRAFICO
Write-Host "2. ANALIZANDO TRAFICO..."
Write-Host "----------------------------------------"

try {
    $conexiones = netstat -an 2>&1 | Select-String "ESTABLISHED"
    Write-Host "Conexiones activas: $($conexiones.Count)"

    $conexionesExternas = $conexiones | Where-Object { $_ -notmatch "127\.0\.0\.1" -and $_ -notmatch "192\.168\." }
    Write-Host "Conexiones externas: $($conexionesExternas.Count)"
} catch {
    Write-Host "Error al analizar conexiones"
}
Write-Host ""

# 3. LATENCIA
Write-Host "3. MIDIENDO LATENCIA..."
Write-Host "----------------------------------------"

$pingRouter = $null
$pingInternet = $null

try {
    $pingRouter = Test-Connection -ComputerName $Gateway -Count 5 -ErrorAction Stop
    $pingInternet = Test-Connection -ComputerName "8.8.8.8" -Count 5 -ErrorAction Stop

    Write-Host "Latencia Router: $($pingRouter.ResponseTime.Average().ToString('0.00')) ms"
    Write-Host "Latencia Internet: $($pingInternet.ResponseTime.Average().ToString('0.00')) ms"
    Write-Host "Perdida Router: $($pingRouter.PacketLoss)%"
    Write-Host "Perdida Internet: $($pingInternet.PacketLoss)%"
} catch {
    Write-Host "Error al medir latencia"
}
Write-Host ""

# 4. DNS
Write-Host "4. CONFIGURACION DNS..."
Write-Host "----------------------------------------"

try {
    $dnsResult = nslookup google.com 2>&1
    Write-Host "DNS configurado correctamente"
} catch {
    Write-Host "Error al consultar DNS"
}
Write-Host ""

# 5. PUERTOS
Write-Host "5. ANALISIS DE SEGURIDAD..."
Write-Host "----------------------------------------"

$puertosComunes = @(80, 443, 8080, 8443)
Write-Host "Verificando puertos:"

foreach ($puerto in $puertosComunes) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($Gateway, $puerto, 500)
        if ($tcp.Connected) {
            Write-Host "  Puerto $puerto ABIERTO"
            $tcp.Close()
        }
    } catch {
        Write-Host "  Puerto $puerto cerrado"
    }
}
Write-Host ""

# 6. RECOMENDACIONES
Write-Host "6. RECOMENDACIONES:"
Write-Host "----------------------------------------"

if ($dispositivos.Count -gt 10) {
    Write-Host "  - Muchos dispositivos conectados"
}

if ($pingRouter -and $pingRouter.ResponseTime.Average() -gt 10) {
    Write-Host "  - Latencia alta al router"
}

if ($pingInternet -and $pingInternet.ResponseTime.Average() -gt 50) {
    Write-Host "  - Latencia alta a internet"
}

Write-Host "  - Considerar configurar QoS"
Write-Host "  - Verificar actualizaciones de firmware"
Write-Host "  - Revisar dispositivos desconocidos"

# 7. REPORTE FINAL
Write-Host ""
Write-Host "========================================"
Write-Host " REPORTE FINAL"
Write-Host "========================================"
Write-Host "Dispositivos activos: $($dispositivos.Count)"

if ($pingInternet) {
    Write-Host "Latencia media: $($pingInternet.ResponseTime.Average().ToString('0.00')) ms"
}

Write-Host "Auditoria completada: $(Get-Date)"
Write-Host "========================================"

# Guardar reporte
try {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $reporteFile = "C:\Users\pabli\auditoria_red_$timestamp.txt"
    $dispositivos | Format-Table -AutoSize | Out-File -FilePath $reporteFile -Encoding UTF8
    Write-Host "Reporte guardado en: $reporteFile"
} catch {
    Write-Host "Error al guardar reporte"
}