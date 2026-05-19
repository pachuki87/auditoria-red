# AUDITORIA FLASH - OBTENER DATOS CRITICOS EN SEGUNDOS
param([string]$Gateway = "192.168.1.1")

Write-Host "⚡ AUDITORIA FLASH - DATOS CRITICOS" -ForegroundColor Cyan

# 1. IP PUBLICA
Write-Host "`n1. IP PUBLICA:" -ForegroundColor Yellow
try {
    $ipPublica = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
    Write-Host "IP PUBLICA: $ipPublica" -ForegroundColor Green
} catch {
    $ipPublica = "ERROR"
    Write-Host "ERROR obteniendo IP publica" -ForegroundColor Red
}

# 2. CONFIGURACION RED
Write-Host "`n2. CONFIGURACION:" -ForegroundColor Yellow
$config = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "192.168.*" }
Write-Host "Tu IP: $($config.IPAddress)" -ForegroundColor Green
Write-Host "Gateway: $Gateway" -ForegroundColor Green

# 3. DISPOSITIVOS RAPIDO
Write-Host "`n3. DISPOSITIVOS:" -ForegroundColor Yellow
$dispositivos = @()
$rangoBase = $Gateway.Substring(0, $Gateway.LastIndexOf('.'))

1..20 | ForEach-Object {
    $ip = "$rangoBase.$_"
    try {
        $ping = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
        if ($ping) {
            $mac = arp -a $ip | Select-String "$ip"
            if ($mac) {
                $macAddr = (($mac.ToString() -split '\s+')[1])
                Write-Host "$ip - $macAddr" -ForegroundColor Green
                $dispositivos += @{IP=$ip; MAC=$macAddr}
            }
        }
    } catch {}
}

# 4. PUERTOS ROUTER
Write-Host "`n4. PUERTOS ROUTER:" -ForegroundColor Yellow
$puertos = @(80, 443, 8080, 8443)
foreach ($puerto in $puertos) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($Gateway, $puerto, 100)
        if ($tcp.Connected) {
            Write-Host "Puerto ${puerto}: ABIERTO" -ForegroundColor Yellow
            $tcp.Close()
        }
    } catch {
        Write-Host "Puerto ${puerto}: CERRADO" -ForegroundColor Green
    }
}

# 5. DATOS CONEXION REMOTA
Write-Host "`n5. DATOS ACCESO REMOTO:" -ForegroundColor Yellow
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Write-Host "IP PUBLICA: $ipPublica" -ForegroundColor Cyan
Write-Host "GATEWAY: $Gateway" -ForegroundColor Cyan
Write-Host "DISPOSITIVOS: $($dispositivos.Count)" -ForegroundColor Cyan

# Guardar datos
$datos = @"
IP_PUBLICA=$ipPublica
GATEWAY=$Gateway
DISPOSITIVOS=$($dispositivos.Count)
FECHA=$(Get-Date)

COMANDOS ACCESO REMOTO:
1. https://$ipPublica:8443 (si puerto abierto)
2. Configurar VPN en router
3. Usar ZeroTier para acceso

DISPOSITIVOS:
"@

foreach ($disp in $dispositivos) {
    $datos += "$($disp.IP) - $($disp.MAC)`n"
}

$archivo = "C:\Users\pabli\acceso_remoto_$timestamp.txt"
$datos | Out-File -FilePath $archivo -Encoding UTF8
Write-Host "DATOS GUARDADOS: $archivo" -ForegroundColor Green

# 6. WIRESHARK
Write-Host "`n6. WIRESHARK:" -ForegroundColor Yellow
$wireshark = "C:\Program Files\Wireshark\dumpcap.exe"
if (Test-Path $wireshark) {
    Write-Host "Wireshark INSTALADO - Listo para captura" -ForegroundColor Green
    $captura = "C:\Users\pabli\captura_$timestamp.pcapng"
    Write-Host "Para capturar: dumpcap -i Wi-Fi -w $captura" -ForegroundColor Gray
} else {
    Write-Host "Wireshark NO INSTALADO" -ForegroundColor Red
    Write-Host "Instalar: winget install Wireshark.Wireshark" -ForegroundColor Gray
}

Write-Host "`n⚡ AUDITORIA COMPLETADA" -ForegroundColor Cyan
Write-Host "LISTO PARA ACCESO REMOTO DESDE TU CASA" -ForegroundColor Green