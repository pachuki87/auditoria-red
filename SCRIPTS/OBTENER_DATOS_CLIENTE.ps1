# ⚡ SCRIPT FINAL - EJECUTAR EN CLIENTE PARA OBTENER DATOS
Write-Host "⚡ OBTENIENDO DATOS CRITICOS DEL CLIENTE..." -ForegroundColor Cyan

# IP PUBLICA
$ipPublica = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
Write-Host "IP PUBLICA: $ipPublica" -ForegroundColor Green

# DISPOSITIVOS
Write-Host "`nDISPOSITIVOS:" -ForegroundColor Yellow
arp -a | Select-String "192.168.1" | ForEach-Object {
    $parts = $_ -split '\s+'
    if ($parts[2] -match "192\.168\.1\.\d+") {
        Write-Host "$($parts[2]) - $($parts[1])" -ForegroundColor Green
    }
}

# GUARDAR DATOS
$datos = @"
IP PUBLICA: $ipPublica
GATEWAY: 192.168.1.1
FECHA: $(Get-Date)

PARA CONECTAR DESDE CASA:
https://$ipPublica:8443
"@

$timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
$archivo = "C:\Users\pabli\DATOS_CLIENTE_$timestamp.txt"
$datos | Out-File -FilePath $archivo -Encoding UTF8

Write-Host "`n⚡ DATOS GUARDADOS: $archivo" -ForegroundColor Cyan
Write-Host "⚡ LISTO PARA ACCESO REMOTO DESDE TU CASA" -ForegroundColor Green