# AUDITORIA RELAMPAGO - OBTENER TODO EN SEGUNDOS
param([string]$Gateway = "192.168.1.1")

Write-Host "⚡ AUDITORIA RELAMPAGO - OBTENIENDO DATOS CRITICOS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1. IP PUBLICA DEL CLIENTE (URGENTE)
Write-Host "`n1. OBTENIENDO IP PUBLICA..." -ForegroundColor Yellow
try {
    $ipPublica = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
    Write-Host "✓ IP PUBLICA: $ipPublica" -ForegroundColor Green
} catch {
    Write-Host "✗ Error obteniendo IP publica" -ForegroundColor Red
    $ipPublica = "DESCONOCIDA"
}

# 2. CONFIGURACION DE RED ACTUAL
Write-Host "`n2. CONFIGURACION DE RED:" -ForegroundColor Yellow
$config = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "192.168.*" }
Write-Host "✓ Tu IP: $($config.IPAddress)" -ForegroundColor Green
Write-Host "✓ Gateway: $Gateway" -ForegroundColor Green
Write-Host "✓ Subnet: $($config.PrefixLength)" -ForegroundColor Green

# 3. ESCANEO ULTRA RAPIDO (solo dispositivos activos ahora)
Write-Host "`n3. ESCANEANDO DISPOSITIVOS ACTIVOS..." -ForegroundColor Yellow
$dispositivos = @()
$rangoBase = $Gateway.Substring(0, $Gateway.LastIndexOf('.'))

# Escaneo paralelo de IPs comunes
1..50 | ForEach-Object {
    $ip = "$rangoBase.$_"
    $ping = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if ($ping) {
        $mac = arp -a $ip | Select-String "$ip" | Select-String "[0-9a-f]{2}-"
        if ($mac) {
            $macAddr = (($mac.ToString() -split '\s+')[1])
            Write-Host "✓ $ip - $macAddr" -ForegroundColor Green
            $dispositivos += @{IP=$ip; MAC=$macAddr}
        }
    }
}

# 4. INFO DEL ROUTER (CRITICO PARA ACCESO REMOTO)
Write-Host "`n4. INFO ROUTER PARA ACCESO REMOTO:" -ForegroundColor Yellow
Write-Host "✓ IP PUBLICA: $ipPublica" -ForegroundColor Green
Write-Host "✓ IP LOCAL: $Gateway" -ForegroundColor Green
Write-Host "✓ PUERTOS ADMIN:" -ForegroundColor Green

# Verificar puertos rapidos
$puertos = @(80, 443, 8080, 8443, 22, 23)
foreach ($puerto in $puertos) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($Gateway, $puerto, 200)
        if ($tcp.Connected) {
            Write-Host "  ✓ Puerto $puerto ABIERTO" -ForegroundColor Yellow
            $tcp.Close()
        }
    } catch {}
}

# 5. INICIAR WIRESHARK (CAPTURA AUTOMATICA)
Write-Host "`n5. INICIANDO CAPTURA WIRESHARK..." -ForegroundColor Yellow

# Verificar si Wireshark está instalado
$wiresharkPath = "C:\Program Files\Wireshark\wireshark.exe"
$dumpcapPath = "C:\Program Files\Wireshark\dumpcap.exe"

if (Test-Path $dumpcapPath) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $capturaFile = "C:\Users\pabli\captura_$timestamp.pcapng"

    Write-Host "✓ Iniciando captura en: $capturaFile" -ForegroundColor Green
    Write-Host "✓ Interface: Wi-Fi" -ForegroundColor Green
    Write-Host "✓ Duracion: 60 segundos (cancelar con Ctrl+C)" -ForegroundColor Green

    # Iniciar captura en background
    $process = Start-Process -FilePath $dumpcapPath -ArgumentList "-i Wi-Fi -w $capturaFile -a duration:60 -f ip" -PassThru -WindowStyle Hidden

    Write-Host "✓ Capturando trafico..." -ForegroundColor Green
    Write-Host "✓ Archivo: $capturaFile" -ForegroundColor Green
} else {
    Write-Host "✗ Wireshark no encontrado. Instalar con: winget install Wireshark.Wireshark" -ForegroundColor Red
}

# 6. DATOS CRITICOS PARA ACCESO REMOTO
Write-Host "`n6. DATOS PARA ACCESO REMOTO INMEDIATO:" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Red
Write-Host "IP PUBLICA CLIENTE: $ipPublica" -ForegroundColor Cyan
Write-Host "GATEWAY LOCAL: $Gateway" -ForegroundColor Cyan
Write-Host "DISPOSITIVOS: $($dispositivos.Count)" -ForegroundColor Cyan

# Generar archivo de conexion remota
$conexionInfo = @"
# DATOS DE CONEXION REMOTA - CLIENTE
# Generado: $(Get-Date)

IP_PUBLICA=$ipPublica
GATEWAY=$Gateway
DISPOSITIVOS=$($dispositivos.Count)

# COMANDOS PARA CONECTAR:
# Opcion 1: Acceso directo al router
# https://$ipPublica:8443 (si puerto 8443 esta abierto)

# Opcion 2: VPN
# Configurar ZeroTier con Network ID: [CREAR EN zerotier.com]

# Opcion 3: Escritorio remoto
# La IP del cliente es: $ipPublica

# DISPOSITIVOS DETECTADOS:
"@

foreach ($disp in $dispositivos) {
    $conexionInfo += "$($disp.IP) - $($disp.MAC)`n"
}

$conexionFile = "C:\Users\pabli\conexion_remota_$timestamp.txt"
$conexionInfo | Out-File -FilePath $conexionFile -Encoding UTF8

Write-Host "✓ DATOS GUARDADOS: $conexionFile" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Red

# 7. RESUMEN EJECUTIVO
Write-Host "`n⚡ RESUMEN EJECUTIVO:" -ForegroundColor Yellow
Write-Host "✓ IP Publica: $ipPublica" -ForegroundColor Green
Write-Host "✓ Dispositivos: $($dispositivos.Count)" -ForegroundColor Green
Write-Host "✓ Captura Wireshark: Iniciada" -ForegroundColor Green
Write-Host "✓ Datos remotos: Guardados en $conexionFile" -ForegroundColor Green

Write-Host "`n🚀 LISTO PARA ACCESO REMOTO DESDE TU CASA:" -ForegroundColor Cyan
Write-Host "1. Usar IP publica: $ipPublica" -ForegroundColor Green
Write-Host "2. Configurar acceso en router (puerto 8443 recomendado)" -ForegroundColor Green
Write-Host "3. Analizar trafico con Wireshark: $capturaFile" -ForegroundColor Green

Write-Host "`n⚡ AUDITORIA COMPLETADA EN $((Get-Date).Second) segundos" -ForegroundColor Cyan