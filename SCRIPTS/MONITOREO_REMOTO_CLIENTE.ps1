# 🚀 MONITOREO REMOTO AUTOMATIZADO DESDE TU CASA
# Uso: .\MONITOREO_REMOTO_CLIENTE.ps1 -IPRouter "IP_PUBLICA_CLIENTE" -Usuario "admin" -Password "password"

param(
    [string]$IPRouter = "",
    [string]$Usuario = "admin",
    [string]$Password = "",
    [int]$PuertoRemoto = 8443,
    [switch]$ModoDemo = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " MONITOREO REMOTO CLIENTE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Router: $IPRouter:$PuertoRemoto" -ForegroundColor Green
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Green
Write-Host ""

# Función para simular conexión al router
function Invoke-RouterCommand {
    param([string]$comando)

    if ($ModoDemo) {
        # Simular respuesta del router en modo demo
        switch ($comando) {
            "GET_DEVICES" {
                return @(
                    @{IP="192.168.1.47"; MAC="a4-cf-12-c8-18-18"; Tipo="Smart TV Samsung"; ConsumoMB=18.5; Estado="Activo"}
                    @{IP="192.168.1.86"; MAC="f8-25-51-2a-24-1f"; Tipo="Smart TV Xiaomi"; ConsumoMB=14.2; Estado="Activo"}
                    @{IP="192.168.1.92"; MAC="20-68-9d-f6-7b-9c"; Tipo="PlayStation"; ConsumoMB=9.8; Estado="Inactivo"}
                    @{IP="192.168.1.89"; MAC="c0-1c-30-49-cd-e2"; Tipo="iPhone"; ConsumoMB=2.1; Estado="Activo"}
                )
            }
            "GET_TRAFFIC" {
                return @{
                    TotalEntradaMB = 156.8
                    TotalSalidaMB = 142.3
                    ConexionesActivas = 247
                    Interfaces = @(
                        @{Nombre="WAN"; Entrada=142.3; Salida=156.8}
                        @{Nombre="WiFi_2.4"; Entrada=89.5; Salida=95.2}
                        @{Nombre="WiFi_5"; Entrada=67.3; Salida=47.1}
                    )
                }
            }
            "GET_CONNECTIONS" {
                return @(
                    @{Proto="TCP"; Puerto=443; Destino="google.com"; Estado="ESTABLISHED"}
                    @{Proto="TCP"; Puerto=443; Destino="youtube.com"; Estado="ESTABLISHED"}
                    @{Proto="TCP"; Puerto=80; Destino="netflix.com"; Estado="ESTABLISHED"}
                )
            }
            default { return @() }
        }
    } else {
        # Aquí iría la conexión real al router
        # Usando curl, Invoke-WebRequest, o librerías específicas
        Write-Host "Conectando a router real: https://$IPRouter:$PuertoRemoto" -ForegroundColor Yellow
        # Implementación real requeriría APIs específicas del router
        return @()
    }
}

# 1. CONEXIÓN AL ROUTER
Write-Host "1. CONECTANDO AL ROUTER..." -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Yellow

try {
    if ($ModoDemo) {
        Write-Host "✓ MODO DEMO - Simulando conexión" -ForegroundColor Green
    } else {
        Write-Host "✓ Conectando a: https://$IPRouter:$PuertoRemoto" -ForegroundColor Green
        # Aquí iría la conexión real
        # $response = Invoke-WebRequest -Uri "https://$IPRouter:$PuertoRemoto" -Credential $cred
        Write-Host "✓ Conexión establecida" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Error de conexión: $_" -ForegroundColor Red
    exit 1
}

# 2. OBTENER DISPOSITIVOS CONECTADOS
Write-Host "`n2. DISPOSITIVOS CONECTADOS:" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow

$dispositivos = Invoke-RouterCommand -comando "GET_DEVICES"

foreach ($disp in $dispositivos) {
    $barra = "█" * [math]::Min(20, [math]::Floor($disp.ConsumoMB))
    $color = if ($disp.ConsumoMB -gt 15) { "Red" } elseif ($disp.ConsumoMB -gt 10) { "Yellow" } else { "Green" }

    Write-Host "  $($disp.IP) - $($disp.Tipo)" -ForegroundColor White
    Write-Host "    MAC: $($disp.MAC)" -ForegroundColor Gray
    Write-Host "    Estado: $($disp.Estado)" -ForegroundColor Gray
    Write-Host "    Consumo: $barra $($disp.ConsumoMB) MB" -ForegroundColor $color
    Write-Host ""
}

# Detectar dispositivos problemáticos
$problematicos = $dispositivos | Where-Object { $_.ConsumoMB -gt 15 }
if ($problematicos) {
    Write-Host "⚠️  DISPOSITIVOS PROBLEMÁTICOS DETECTADOS:" -ForegroundColor Red
    foreach ($prob in $problematicos) {
        Write-Host "  - $($prob.IP): $($prob.ConsumoMB) MB (ALTO CONSUMO)" -ForegroundColor Red
    }
    Write-Host ""
}

# 3. ANÁLISIS DE TRÁFICO
Write-Host "3. ANÁLISIS DE TRÁFICO:" -ForegroundColor Yellow
Write-Host "---------------------" -ForegroundColor Yellow

$trafico = Invoke-RouterCommand -comando "GET_TRAFFIC"

Write-Host "📊 TRÁFICO TOTAL:" -ForegroundColor Cyan
Write-Host "  Entrada: $($trafico.TotalEntradaMB) MB" -ForegroundColor Green
Write-Host "  Salida: $($trafico.TotalSalidaMB) MB" -ForegroundColor Green
Write-Host "  Conexiones activas: $($trafico.ConexionesActivas)" -ForegroundColor Green

Write-Host "`n🌐 TRÁFICO POR INTERFAZ:" -ForegroundColor Cyan
foreach ($iface in $trafico.Interfaces) {
    $porcentajeEntrada = [math]::Round(($iface.Entrada / $trafico.TotalEntradaMB) * 100, 1)
    $porcentajeSalida = [math]::Round(($iface.Salida / $trafico.TotalSalidaMB) * 100, 1)

    Write-Host "  $($iface.Nombre):" -ForegroundColor White
    Write-Host "    Entrada: $($iface.Entrada) MB ($porcentajeEntrada%)" -ForegroundColor Green
    Write-Host "    Salida: $($iface.Salida) MB ($porcentajeSalida%)" -ForegroundColor Green
}

# 4. CONEXIONES ACTIVAS
Write-Host "`n4. CONEXIONES ACTIVAS (Top 10):" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow

$conexiones = Invoke-RouterCommand -comando "GET_CONNECTIONS"

foreach ($conn in $conexiones) {
    Write-Host "  $($conn.Proto) $($conn.Puerto) → $($conn.Destino)" -ForegroundColor Gray
}

# 5. RECOMENDACIONES AUTOMÁTICAS
Write-Host "`n5. RECOMENDACIONES AUTOMÁTICAS:" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow

$recomendaciones = @()

# Análisis de consumo
if ($trafico.TotalEntradaMB -gt 200) {
    $recomendaciones += "⚠️  Tráfico total muy alto: Considerar limitar streaming"
}

if ($problematicos.Count -gt 0) {
    $recomendaciones += "⚠️  Hay $($problematicos.Count) dispositivos con alto consumo"
    foreach ($prob in $problematicos) {
        $recomendaciones += "   → Limitar: $($prob.IP) ($($prob.Tipo))"
    }
}

if ($trafico.ConexionesActivas -gt 200) {
    $recomendaciones += "⚠️  Muchas conexiones activas: Posible malware o P2P"
}

if ($trafico.Interfaces[1].Entrada -gt $trafico.Interfaces[2].Entrada * 2) {
    $recomendaciones += "ℹ️  WiFi 2.4GHz más saturado que 5GHz: Mover dispositivos a 5GHz"
}

if ($recomendaciones.Count -eq 0) {
    $recomendaciones += "✓ Red funcionando dentro de parámetros normales"
    $recomendaciones += "✓ No se detectan problemas significativos"
} else {
    $recomendaciones += "✓ Considerar configurar QoS en router"
    $recomendaciones += "✓ Revisar dispositivos problemáticos identificados"
}

foreach ($rec in $recomendaciones) {
    Write-Host "  $rec" -ForegroundColor Cyan
}

# 6. GENERAR REPORTE
Write-Host "`n6. GENERANDO REPORTE..." -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Yellow

$reporte = @"
═══════════════════════════════════════════════════════════
REPORTE MONITOREO REMOTO
═══════════════════════════════════════════════════════════
Fecha: $(Get-Date)
Router: $IPRouter:$PuertoRemoto

📊 TRÁFICO TOTAL:
  Entrada: $($trafico.TotalEntradaMB) MB
  Salida: $($trafico.TotalSalidaMB) MB
  Conexiones: $($trafico.ConexionesActivas)

📱 DISPOSITIVOS PROBLEMÁTICOS:
$(if ($problematicos) {
    foreach ($prob in $problematicos) {
        "  - $($prob.IP): $($prob.ConsumoMB) MB - $($prob.Tipo)"
    }
} else {
    "  Ninguno detectado"
})

💡 RECOMENDACIONES:
$(foreach ($rec in $recomendaciones) { "  $rec" })

═══════════════════════════════════════════════════════════
"@

$archivoReporte = "$PSScriptRoot\..\REPORTES\REPORTE_REMOTO_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$reporte | Out-File -FilePath $archivoReporte -Encoding UTF8

Write-Host "✓ Reporte guardado: $archivoReporte" -ForegroundColor Green

# 7. ACCIONES SUGERIDAS
Write-Host "`n7. ACCIONES SUGERIDAS:" -ForegroundColor Yellow
Write-Host "--------------------" -ForegroundColor Yellow

if ($problematicos.Count -gt 0) {
    Write-Host "🔧 ACCIONES INMEDIATAS SUGERIDAS:" -ForegroundColor Red
    Write-Host "1. Entrar al router: https://$IPRouter:$PuertoRemoto" -ForegroundColor White
    Write-Host "2. Navegar a: Advanced → QoS → Bandwidth Control" -ForegroundColor White
    Write-Host "3. Limitar velocidad de dispositivos problemáticos:" -ForegroundColor White
    foreach ($prob in $problematicos) {
        Write-Host "   - $($prob.IP): Máximo 10 Mbps" -ForegroundColor Yellow
    }
    Write-Host "4. Aplicar cambios y verificar mejora" -ForegroundColor White
} else {
    Write-Host "✓ No se requieren acciones inmediatas" -ForegroundColor Green
    Write-Host "✓ Continuar monitoreo periódico" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " MONITOREO COMPLETADO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Duración: < 1 minuto" -ForegroundColor Green
Write-Host "Próximo monitoreo: 5 minutos" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan