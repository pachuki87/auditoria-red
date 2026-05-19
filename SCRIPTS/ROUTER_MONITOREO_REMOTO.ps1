# MONITOREO REMOTO VÍA ROUTER - VERSION SIMPLE
param([string]$IPRouter = "192.168.1.1")

Write-Host "MONITOREO REMOTO VÍA ROUTER" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# 1. CAPACIDADES DEL ROUTER
Write-Host "`nCAPACIDADES DEL ROUTER:" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow

$capacidades = @(
    "SNMP - Monitoreo de trafico",
    "NetFlow/sFlow - Exportacion de flujos",
    "Logs de conexion",
    "QoS en tiempo real",
    "Acceso remoto",
    "Estadisticas de interfaz",
    "Alertas automaticas"
)

foreach ($cap in $capacidades) {
    Write-Host "  - $cap" -ForegroundColor Green
}

# 2. METODOS DE ACCESO
Write-Host "`nMETODOS DE ACCESO REMOTO:" -ForegroundColor Yellow
Write-Host "--------------------------" -ForegroundColor Yellow

Write-Host "OPCION A: ACCESO DIRECTO" -ForegroundColor Cyan
Write-Host "  - Entrar: https://IP_PUBLICA:8443" -ForegroundColor Green
Write-Host "  - Panel de administracion" -ForegroundColor Green
Write-Host "  - Monitoreo en tiempo real" -ForegroundColor Green

Write-Host "`nOPCION B: SNMP" -ForegroundColor Cyan
Write-Host "  - Habilitar SNMP en router" -ForegroundColor Green
Write-Host "  - Herramientas SNMP desde tu casa" -ForegroundColor Green

Write-Host "`nOPCION C: NETFLOW" -ForegroundColor Cyan
Write-Host "  - Configurar exportacion de flujos" -ForegroundColor Green
Write-Host "  - Analisis detallado de patrones" -ForegroundColor Green

# 3. EJEMPLO DE ESTADISTICAS DEL ROUTER
Write-Host "`nESTADISTICAS DEL ROUTER:" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow

# Datos simulados de lo que obtendrias del router
$dispositivos = @(
    @{IP="192.168.1.47"; Consumo="15.5 MB"; Tipo="Smart TV"},
    @{IP="192.168.1.86"; Consumo="12.3 MB"; Tipo="Xiaomi"},
    @{IP="192.168.1.92"; Consumo="8.7 MB"; Tipo="Consola"}
)

Write-Host "TRAFFICO TOTAL:" -ForegroundColor Cyan
Write-Host "  Entrada: 45.2 MB" -ForegroundColor Green
Write-Host "  Salida: 38.7 MB" -ForegroundColor Green
Write-Host "  Conexiones: 127" -ForegroundColor Green

Write-Host "`nCONSUMO POR DISPOSITIVO:" -ForegroundColor Cyan
foreach ($disp in $dispositivos) {
    Write-Host "  $($disp.IP) ($($disp.Tipo))" -ForegroundColor White
    Write-Host "    Consumo: $($disp.Consumo)" -ForegroundColor Yellow
}

# 4. CONFIGURACION SNMP
Write-Host "`nCONFIGURACION SNMP:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

$snmpConfig = @"
PARA HABILITAR SNMP EN ROUTER:

1. Entrar: http://192.168.1.1
2. Buscar: SNMP -> Configuration
3. Habilitar:
   - SNMP v2c
   - Community: public
   - Puerto: 161
4. Permitir acceso desde tu IP
5. Guardar y aplicar

COMANDOS SNMP DESDE TU CASA:
snmpwalk -v2c -c public IP_ROUTER .1.3.6.1.2.1.2.2.1
"@

Write-Host $snmpConfig -ForegroundColor Gray

# 5. CHECKLIST VISITA CLIENTE
Write-Host "`nCHECKLIST VISITA CLIENTE:" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow

$checklist = @(
    "Entrar al router: http://192.168.1.1",
    "Habilitar administracion remota",
    "Configurar puerto seguro: 8443",
    "Anotar IP publica",
    "Probar acceso desde movil",
    "Habilitar SNMP si disponible",
    "Configurar QoS basico",
    "Documentar credenciales"
)

foreach ($item in $checklist) {
    Write-Host "  - $item" -ForegroundColor White
}

# 6. ACCESO DESDE TU CASA
Write-Host "`nACCESO DESDE TU CASA:" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Yellow

Write-Host "1. Conectarte: https://IP_PUBLICA:8443" -ForegroundColor Green
Write-Host "2. Ver dispositivos conectados" -ForegroundColor Green
Write-Host "3. Identificar consumos de ancho de banda" -ForegroundColor Green
Write-Host "4. Aplicar QoS o limitaciones" -ForegroundColor Green
Write-Host "5. Generar reporte de diagnostico" -ForegroundColor Green

# 7. VENTAJAS
Write-Host "`nVENTAJAS DEL ENFOQUE:" -ForegroundColor Yellow
Write-Host "---------------------" -ForegroundColor Yellow

$ventajas = @(
    "Sin PC adicional necesario",
    "Router siempre encendido",
    "Informacion centralizada",
    "Control QoS directo",
    "Monitoreo 24/7",
    "Configuracion unica",
    "SNMP automatizado",
    "Logs del router"
)

foreach ($ventaja in $ventajas) {
    Write-Host "  - $ventaja" -ForegroundColor Green
}

Write-Host "`nLISTO PARA MONITOREO REMOTO VÍA ROUTER" -ForegroundColor Cyan