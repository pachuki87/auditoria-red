# 🔧 ROUTER ZTE F6640 - GUÍA COMPLETA

**Fecha registro:** 10 de mayo de 2026
**ISP:** Pepephone
**Tipo:** Router ONT Fiber

---

## 📋 Especificaciones Técnicas

| Campo | Valor |
|-------|-------|
| **Modelo** | ZTE F6640 |
| **Fabricante** | ZTE Corporation |
| **Tipo** | Router ONT GPON + WiFi |
| **IP Local** | 192.168.1.1 |
| **Usuario** | admin |
| **Contraseña por defecto** | admin / 1234 |
| **Acceso remoto** | Puerto 8443 |
| **SSID por defecto** | MOVISTAR_XXXX |
| **Canales WiFi** | 2.4 GHz y 5 GHz |

---

## 🌐 Interfaz Web

### Acceso Local
```
http://192.168.1.1
```

### Acceso Remoto
```
https://62.93.179.163:8443
```

**Nota:** El acceso remoto debe estar habilitado en:
`Red → WAN → Administración Remota`

---

## 🔑 Credenciales

### Acceso por Defecto
| Usuario | Contraseña | Nivel |
|---------|------------|-------|
| admin | admin | Administrador |
| user | user | Usuario limitado |

### Si no funcionan las credenciales por defecto
1. Revisar la etiqueta debajo del router
2. Presionar el botón de reset (10 segundos) para restaurar

---

## ⚙️ Configuración Recomendada

### 1. Cambiar Contraseña de Administrador
```
Menú: Administración → Administrador → Contraseña
- Usar contraseña fuerte: 12+ caracteres, símbolos, números
```

### 2. Configurar WiFi Seguro
```
Menú: Red → WiFi
- SSID: MIWIFI_U4hX (o nombre personalizado)
- Contraseña: Mínimo 12 caracteres
- Cifrado: WPA2-PSK (AES)
- Canal: Auto o 1, 6, 11 (2.4 GHz)
```

### 3. Habilitar Administración Remota
```
Menú: Red → WAN → Administración Remota
- Habilitar: Sí
- Puerto: 8443
- Protocolo: HTTPS
```

### 4. Configurar QoS
```
Menú: Red → QoS
- Tipo: Basado en IP
- Prioridad ALTA: Dispositivos padres
- Prioridad MEDIA: Tablets, consolas
- Prioridad BAJA: Smart TVs
```

---

## 📡 Información WiFi

### Red Principal (Cliente)
| Campo | Valor |
|-------|-------|
| **SSID** | MIWIFI_U4hX |
| **BSSID** | ee:6b:9a:12:33:fc |
| **Tipo** | WPA2-PSK |
| **Canal** | 3 (2422 MHz, 2.4 GHz) |
| **Velocidad** | Hasta 144 Mbps |
| **Estándar** | WiFi 4 (802.11n) |

### Redes Adicionales Detectadas
- MOVISTAR_PLUS_EF90 (conectada actualmente)
- MOVISTAR_EF90
- MIWIFI_H7AR
- MIWIFI_vt3T
- MIWIFI_xh2C

---

## 🐛 Problemas Conocidos y Soluciones

### Problema 1: Smart TV consume mucho ancho de banda
**Síntoma:** 15-25% del ancho de banda consumido por streaming 4K
**Solución:**
1. Limitar calidad de streaming a 1080p
2. Configurar QoS con prioridad baja para la IP de la TV
3. Usar cable Ethernet si es posible

### Problema 2: Latencia en videoconferencias
**Síntoma:** Cortes o retrasos en Zoom/Teams
**Solución:**
1. Configurar QoS con prioridad ALTA para dispositivos de trabajo
2. Desconectar dispositivos no esenciales durante llamadas
3. Usar banda 5 GHz si disponible

### Problema 3: No se puede acceder a la interfaz
**Síntoma:** Error de conexión al 192.168.1.1
**Solución:**
1. Verificar conexión Ethernet
2. Usar cable de red, no WiFi
3. Restablecer router (botón reset 10 segundos)

---

## 📊 Rendimiento Esperado

| Métrica | Valor |
|---------|-------|
| **Ancho de banda downstream** | Hasta 300 Mbps (fibra) |
| **Ancho de banda upstream** | Hasta 30 Mbps |
| **Latencia** | 2-27ms (router) |
| **Jitter** | < 5ms |
| **Dispositivos simultáneos** | Hasta 32 |

---

## 🔐 Seguridad Recomendada

### 1. Firewall
```
Menú: Seguridad → Firewall
- Habilitar SPI (Stateful Packet Inspection)
- Bloquear ping desde WAN
- Filtrar puertos no usados
```

### 2. Control Parental
```
Menú: Seguridad → Control Parental
- Restringir horarios de uso
- Bloquear categorías de contenido
```

### 3. Actualización de Firmware
```
Menú: Administración → Actualización
- Buscar actualizaciones automáticamente
- Revisar versión actual: v1.0.X
```

---

## 📱 Dispositivos Conectados

### Dispositivos Identificados (Auditoría 9 mayo 2026)
| IP | MAC | Tipo | Estado |
|----|-----|-----|--------|
| 192.168.1.1 | e4:ab:89:2a:ef:99 | Router | ✅ Activo |
| 192.168.1.47 | f8:25:51:XX:XX:XX | Smart TV | ⚠️ Alto consumo |
| 192.168.1.86 | c8:7b:2a:XX:XX:XX | Smart TV/Dispositivo | ⚠️ Medio consumo |
| 192.168.1.81 | 2c:7b:a0:96:57:3f | PC Principal | ✅ Normal |
| 192.168.1.82 | 3e:7e:e0:70:db:a4 | Android | ✅ Normal |

---

## 🔄 Mantenimiento Programado

| Tarea | Frecuencia | Próxima ejecución |
|-------|-----------|-------------------|
| Revisión firmware | Mensual | 9 junio 2026 |
| Análisis dispositivos | Semanal | 17 mayo 2026 |
| Limpieza cache | Trimestral | 9 agosto 2026 |
| Cambio contraseñas | Semestral | 9 noviembre 2026 |

---

## 📞 Soporte Técnico

**ISP:** Pepephone
**Soporte:** 1234 (desde teléfono fijo)
**Horario:** 24/7

---

## 📝 Historial de Cambios

| Fecha | Cambio | Responsable |
|-------|--------|-------------|
| 09/05/2026 | Auditoría inicial completa | Sistema |
| 09/05/2026 | Habilitado acceso remoto puerto 8443 | Sistema |
| 09/05/2026 | Identificado consumo excesivo Smart TVs | Sistema |
| 10/05/2026 | Instalado adaptador WiFi Atheros AR9271 | Sistema |
| 10/05/2026 | Documentación completa creada | Sistema |

---

*Este documento contiene información sensible. Mantener confidencial.*
