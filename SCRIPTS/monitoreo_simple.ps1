# MONITOREO REMOTO CLIENTE - VERSION SIMPLE
param([switch]$ModoDemo = $false)

Write-Host "MONITOREO REMOTO CLIENTE PEPEPHONE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Datos simulados del router
$dispositivos = @(
    @{IP="192.168.1.47"; Tipo="Smart TV Samsung"; Consumo=18.5},
    @{IP="192.168.1.86"; Tipo="Smart TV Xiaomi"; Consumo=14.2},
    @{IP="192.168.1.92"; Tipo="PlayStation"; Consumo=9.8}
)

$traficoTotal = @{
    Entrada = 156.8
    Salida = 142.3
    Conexiones = 247
}

# 1. DISPOSITIVOS CONECTADOS
Write-Host "`nDISPOSITIVOS CONECTADOS:" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow

foreach ($disp in $dispositivos) {
    $barra = "█" * [math]::Min(20, [math]::Floor($disp.Consumo))
    $color = if ($disp.Consumo -gt 15) { "Red" } elseif ($disp.Consumo -gt 10) { "Yellow" } else { "Green" }

    Write-Host "  $($disp.IP) - $($disp.Tipo)" -ForegroundColor White
    Write-Host "    Consumo: $barra $($disp.Consumo) MB" -ForegroundColor $color
}

# 2. TRAFICO TOTAL
Write-Host "`nTRAFICO TOTAL:" -ForegroundColor Yellow
Write-Host "-------------" -ForegroundColor Yellow
Write-Host "  Entrada: $($traficoTotal.Entrada) MB" -ForegroundColor Green
Write-Host "  Salida: $($traficoTotal.Salida) MB" -ForegroundColor Green
Write-Host "  Conexiones: $($traficoTotal.Conexiones)" -ForegroundColor Green

# 3. PROBLEMAS DETECTADOS
Write-Host "`nPROBLEMAS DETECTADOS:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

$problematicos = $dispositivos | Where-Object { $_.Consumo -gt 15 }
if ($problematicos) {
    foreach ($prob in $problematicos) {
        Write-Host "  - $($prob.IP): $($prob.Consumo) MB (ALTO)" -ForegroundColor Red
    }
    Write-Host "`nRECOMENDACION:" -ForegroundColor Yellow
    Write-Host "  Limitar dispositivos problematicos" -ForegroundColor Green
} else {
    Write-Host "  No se detectan problemas" -ForegroundColor Green
}

Write-Host "`nLISTO PARA DIAGNOSTICO REMOTO" -ForegroundColor Cyan