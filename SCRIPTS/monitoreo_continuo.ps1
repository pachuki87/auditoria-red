# Script de Monitoreo Continuo de Red
# Para dejar instalado en PC del cliente y diagnosticar problemas futuros

param(
    [string]$Gateway = "192.168.1.1",
    [int]$IntervaloSegundos = 300,  # 5 minutos entre checks
    [string]$LogDir = "C:\LogsMonitoreo"
)

# Crear directorio de logs
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param([string]$mensaje, [string]$nivel = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$nivel] $mensaje"
    $logFile = Join-Path $LogDir "monitoreo_$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

function Test-InternetSpeed {
    try {
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 5 -ErrorAction Stop
        $latencia = [math]::Round($ping.ResponseTime | Measure-Object -Average | Select-Object -ExpandProperty Average, 2)
        $perdida = $ping.PacketLoss
        return @{
            Latencia = $latencia
            Perdida = $perdida
            Estado = if ($latencia -lt 50) { "BUENO" } elseif ($latencia -lt 100) { "REGULAR" } else { "MALO" }
        }
    } catch {
        return @{
            Latencia = 9999
            Perdida = 100
            Estado = "FALLO"
        }
    }
}

function Get-DispositivosConectados {
    try {
        $arpTable = arp -a
        $dispositivos = @()
        $lines = $arpTable -split "`n"

        foreach ($line in $lines) {
            if ($line -match "(\d+\.\d+\.\d+\.\d+).*?([0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2})") {
                $ip = $matches[1]
                $mac = $matches[2]
                $dispositivos += @{
                    IP = $ip
                    MAC = $mac
                    Timestamp = Get-Date
                }
            }
        }
        return $dispositivos
    } catch {
        return @()
    }
}

function Get-ConexionesActivas {
    try {
        $conexiones = netstat -an | Select-String "ESTABLISHED"
        $externas = $conexiones | Where-Object { $_ -notmatch "127\.0\.0\.1" -and $_ -notmatch "192\.168\." }
        return @{
            Total = $conexiones.Count
            Externas = $externas.Count
        }
    } catch {
        return @{ Total = 0; Externas = 0 }
    }
}

function Detect-StreamingDevices {
    $smartTVs = @()
    $vendorsStreaming = @(
        "a4:83:e7",  # Samsung
        "c8:7b:2a",  # LG
        "b4:96:91",  # Sony
        "f8:25:51"   # Xiaomi
    )

    try {
        $arpTable = arp -a
        $lines = $arpTable -split "`n"

        foreach ($line in $lines) {
            if ($line -match "(\d+\.\d+\.\d+\.\d+).*?([0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2})") {
                $mac = $matches[2]
                $macPrefix = $mac.Substring(0, 8)

                foreach ($vendor in $vendorsStreaming) {
                    if ($macPrefix -eq $vendor) {
                        $smartTVs += @{
                            IP = $matches[1]
                            MAC = $mac
                            Vendor = $vendor
                        }
                    }
                }
            }
        }
    } catch {
        # Error silencioso
    }

    return $smartTVs
}

function Send-Alerta {
    param([string]$mensaje, [string]$nivel = "WARNING")

    # Crear archivo de alerta
    $alertaFile = Join-Path $LogDir "ALERTA_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $alertaContenido = @"
ALERTA DE RED - $(Get-Date)
=====================================
NIVEL: $nivel
MENSAJE: $mensaje

DISPOSITIVOS CONECTADOS: $( (Get-DispositivosConectados).Count )
STREAMING DEVICES: $( (Detect-StreamingDevices).Count )
LATENCIA: $((Test-InternetSpeed).Latencia) ms
"@
    Set-Content -Path $alertaFile -Value $alertaContenido
    Write-Log "ALERTA GENERADA: $alertaFile" -nivel "ALERT"
}

# ======================
# CICLO PRINCIPAL
# ======================

Write-Log "Iniciando monitoreo continuo de red" -nivel "INFO"
Write-Log "Gateway: $Gateway, Intervalo: $IntervaloSegundos segundos" -nivel "INFO"

while ($true) {
    try {
        Write-Log "========================================" -nivel "INFO"
        Write-Log "Iniciando ciclo de monitoreo" -nivel "INFO"

        # 1. Verificar conexión a internet
        $estadoInternet = Test-InternetSpeed
        Write-Log "Internet - Latencia: $($estadoInternet.Latencia)ms, Pérdida: $($estadoInternet.Perdida)%, Estado: $($estadoInternet.Estado)" -nivel "INFO"

        # Alerta si la conexión es mala
        if ($estadoInternet.Estado -eq "FALLO") {
            Send-Alerta "SIN CONEXIÓN A INTERNET" -nivel "CRITICAL"
        } elseif ($estadoInternet.Estado -eq "MALO") {
            Send-Alerta "Conexión muy lenta: $($estadoInternet.Latencia)ms" -nivel "WARNING"
        }

        # 2. Dispositivos conectados
        $dispositivos = Get-DispositivosConectados
        Write-Log "Dispositivos conectados: $($dispositivos.Count)" -nivel "INFO"

        # Alerta si hay demasiados dispositivos
        if ($dispositivos.Count -gt 20) {
            Send-Alerta "Exceso de dispositivos conectados: $($dispositivos.Count)" -nivel "WARNING"
        }

        # 3. Dispositivos de streaming
        $streamingDevices = Detect-StreamingDevices
        Write-Log "Dispositivos streaming detectados: $($streamingDevices.Count)" -nivel "INFO"

        if ($streamingDevices.Count -gt 0) {
            foreach ($device in $streamingDevices) {
                Write-Log "  - $($device.IP) - $($device.MAC)" -nivel "INFO"
            }
        }

        # 4. Conexiones activas
        $conexiones = Get-ConexionesActivas
        Write-Log "Conexiones activas: $($conexiones.Total), Externas: $($conexiones.Externas)" -nivel "INFO"

        # Alerta si hay muchas conexiones externas
        if ($conexiones.Externas -gt 50) {
            Send-Alerta "Alta actividad de red: $($conexiones.Externas) conexiones externas" -nivel "WARNING"
        }

        # 5. Guardar estado actual
        $estadoFile = Join-Path $LogDir "estado_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $estado = @{
            Timestamp = Get-Date
            Internet = $estadoInternet
            DispositivosCount = $dispositivos.Count
            StreamingCount = $streamingDevices.Count
            Conexiones = $conexiones
        } | ConvertTo-Json

        Set-Content -Path $estadoFile -Value $estado

        Write-Log "Ciclo completado. Próximo check en $IntervaloSegundos segundos" -nivel "INFO"
        Write-Log "========================================" -nivel "INFO"

        # Esperar para el próximo ciclo
        Start-Sleep -Seconds $IntervaloSegundos

    } catch {
        Write-Log "Error en ciclo de monitoreo: $_" -nivel "ERROR"
        Start-Sleep -Seconds 60  # Esperar 1 minuto antes de reintentar
    }
}