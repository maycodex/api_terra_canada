# 📘 DOCUMENTACIÓN DEL NEGOCIO - SISTEMA DE GESTIÓN DE PAGOS TERRA CANADA

---

## 📋 TABLA DE CONTENIDOS

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Descripción del Negocio](#descripción-del-negocio)
3. [Actores del Sistema](#actores-del-sistema)
4. [Flujo Principal del Negocio](#flujo-principal-del-negocio)
5. [Módulos del Sistema](#módulos-del-sistema)
6. [Procesos Críticos](#procesos-críticos)
7. [Reglas de Negocio](#reglas-de-negocio)

---

## 🎯 RESUMEN EJECUTIVO

**Sistema de Gestión de Pagos** diseñado para Terra Canada, que permite:

- Registrar y controlar pagos a proveedores
- Gestionar múltiples medios de pago (tarjetas de crédito y cuentas bancarias)
- Verificar pagos mediante documentos (facturas, extractos)
- Enviar notificaciones automáticas a proveedores
- Mantener auditoría completa de todas las operaciones

**Tecnologías:**

- Base de datos: PostgreSQL
- Automatización: N8N (verificación de documentos)
- Backend: Node.js con Prisma ORM
- Frontend: React

---

## 🏢 DESCRIPCIÓN DEL NEGOCIO

Terra Canada gestiona pagos a múltiples proveedores de servicios turísticos en nombre de sus clientes (hoteles). El sistema debe:

1. **Registrar pagos** con diferentes medios de pago
2. **Verificar** que los pagos fueron procesados correctamente
3. **Notificar** a proveedores sobre pagos realizados
4. **Controlar** saldos de tarjetas de crédito
5. **Auditar** todas las operaciones del sistema

### Tipos de Servicios Gestionados:

- **Guianza** (servicios de guías turísticos)
- **Literie** (servicios de hotelería)
- **Paiement ponctuel** (pagos puntuales)
- **Car rental** (alquiler de vehículos)
- **Excursion** (excursiones y tours)

---

## 👥 ACTORES DEL SISTEMA

### 1. **ADMIN** (Administrador)

**Permisos:** Control total del sistema

- ✅ Gestionar usuarios
- ✅ Gestionar proveedores y clientes
- ✅ Registrar pagos con cualquier medio
- ✅ Ver todos los módulos
- ✅ Verificar pagos
- ✅ Enviar correos
- ✅ Acceder a auditoría completa

### 2. **SUPERVISOR** (Supervisor)

**Permisos:** Similar a Admin, con restricciones

- ❌ No puede crear/eliminar usuarios
- ❌ No puede ver algunos módulos de configuración
- ✅ Puede registrar pagos
- ✅ Puede verificar pagos
- ✅ Puede enviar correos
- ✅ Puede ver reportes y análisis

### 3. **EQUIPO** (Equipo de Operaciones)

**Permisos:** Operaciones básicas

- ✅ Registrar pagos **solo con tarjetas**
- ❌ No puede usar cuentas bancarias
- ✅ Subir documentos
- ✅ Ver sus propios pagos
- ❌ No puede verificar pagos
- ❌ No puede enviar correos

---

## 🔄 FLUJO PRINCIPAL DEL NEGOCIO

### **DIAGRAMA DE FLUJO COMPLETO**

```
┌─────────────────────────────────────────────────────────────────┐
│                    INICIO DEL PROCESO                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 1. REGISTRO DE PAGO                                             │
│                                                                  │
│ Usuario (Admin/Supervisor/Equipo):                              │
│ ├─ Selecciona: Proveedor                                        │
│ ├─ Selecciona: Servicio del proveedor                           │
│ ├─ Selecciona: Uno o más clientes (hoteles)                     │
│ ├─ Selecciona: Moneda (USD o CAD)                               │
│ ├─ Selecciona: Medio de pago (Tarjeta o Cuenta Bancaria)        │
│ ├─ Ingresa: Monto, código de reserva, descripción              │
│ └─ Ingresa: Fecha esperada de débito (opcional)                 │
│                                                                  │
│ VALIDACIONES:                                                    │
│ ✓ Si es TARJETA: verifica saldo disponible                     │
│ ✓ Si es TARJETA: descuenta del saldo                           │
│ ✓ Si es CUENTA BANCARIA: solo registra (no descuenta)          │
│                                                                  │
│ RESULTADO:                                                       │
│ • pagado = FALSE                                                 │
│ • verificado = FALSE                                             │
│ • gmail_enviado = FALSE                                          │
│ • activo = TRUE                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. SUBIDA DE DOCUMENTOS (2 TIPOS)                              │
│                                                                  │
│ Usuario sube PDF y selecciona tipo:                             │
│                                                                  │
│ OPCIÓN A - FACTURA (documento individual):                      │
│ ├─ Sistema almacena archivo en servidor/cloud                   │
│ ├─ Guarda URL/path en base de datos (NO base64)                │
│ ├─ Puede vincularse directamente a UN pago específico           │
│ └─ Trigger a N8N para procesamiento automático                  │
│                                                                  │
│ OPCIÓN B - DOCUMENTO_BANCO (lista de pagos):                    │
│ ├─ Sistema almacena archivo en servidor/cloud                   │
│ ├─ Guarda URL/path en base de datos (NO base64)                │
│ ├─ NO se vincula inicialmente a pagos específicos               │
│ └─ Trigger a N8N para procesamiento automático                  │
│                                                                  │
│ N8N PROCESA SEGÚN TIPO:                                          │
│ ├─ Lee el PDF con OCR/parser                                    │
│ ├─ Busca códigos de reserva en el documento                     │
│ └─ Vincula documento con pagos encontrados                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. PROCESAMIENTO AUTOMÁTICO POR N8N                            │
│                                                                  │
│ SI tipo_documento = FACTURA:                                     │
│ ├─ N8N busca código de reserva en la factura                    │
│ ├─ Busca pago con ese código                                    │
│ ├─ Cambia: pagado = TRUE                                         │
│ ├─ Vincula en tabla: documento_pago                             │
│ └─ Mantiene: verificado = FALSE (aún no verificado)             │
│                                                                  │
│ SI tipo_documento = DOCUMENTO_BANCO:                             │
│ ├─ N8N extrae lista de códigos de reserva del extracto         │
│ ├─ Por cada código encontrado:                                  │
│ │  ├─ Busca pago con ese código                                 │
│ │  ├─ Cambia: pagado = TRUE                                      │
│ │  ├─ Cambia: verificado = TRUE (verificación automática)       │
│ │  └─ Vincula en tabla: documento_pago                          │
│ └─ NOTA: Un documento banco puede verificar múltiples pagos    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. GENERACIÓN AUTOMÁTICA DE CORREOS                            │
│                                                                  │
│ Sistema detecta: pagado = TRUE + gmail_enviado = FALSE          │
│ ├─ Agrupa pagos por proveedor                                   │
│ ├─ Genera borrador de correo automáticamente                    │
│ ├─ Incluye: lista de pagos, montos, códigos                    │
│ └─ Almacena en: envios_correos (estado: BORRADOR)              │
│                                                                  │
│ Usuario ve: "Correos pendientes de envío"                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. ENVÍO MANUAL DE CORREO                                      │
│                                                                  │
│ Usuario (Admin/Supervisor/Equipo):                               │
│ ├─ Revisa correos pendientes                                    │
│ ├─ Ve idioma del proveedor (lenguaje) para redactar            │
│ ├─ Selecciona uno de los 4 correos del proveedor               │
│ ├─ Edita contenido si es necesario                             │
│ └─ Confirma envío                                               │
│                                                                  │
│ SISTEMA:                                                         │
│ ├─ Prepara datos del correo (info_correo + info_pagos)         │
│ ├─ Envía a webhook N8N:                                         │
│ │  POST https://n8n.salazargroup.cloud/webhook/enviar_gmail    │
│ │  Authorization: Basic [token]                                 │
│ │  Body: { info_correo: {...}, info_pagos: [...] }             │
│ ├─ Si respuesta 200: Actualiza gmail_enviado = TRUE            │
│ ├─ Cambia estado del correo: BORRADOR → ENVIADO                │
│ └─ Registra fecha y hora de envío                              │
│                                                                  │
│ REGLA: Un pago con gmail_enviado = TRUE no aparece en nuevos   │
│        correos pendientes                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. ESTADOS FINALES DEL PAGO                                    │
│                                                                  │
│ Un pago puede tener diferentes estados según documentos:        │
│                                                                  │
│ ESCENARIO 1 - Solo FACTURA subida:                              │
│ • pagado = TRUE (cambiado por N8N)                               │
│ • verificado = FALSE (aún no verificado en extracto banco)      │
│ • gmail_enviado = TRUE (después de enviar correo)               │
│ • activo = TRUE                                                  │
│                                                                  │
│ ESCENARIO 2 - FACTURA + DOCUMENTO_BANCO subidos:                │
│ • pagado = TRUE (cambiado por N8N con factura)                   │
│ • verificado = TRUE (cambiado por N8N con documento banco)      │
│ • gmail_enviado = TRUE (después de enviar correo)               │
│ • activo = TRUE                                                  │
│                                                                  │
│ ESCENARIO 3 - Solo DOCUMENTO_BANCO (sin factura previa):        │
│ • pagado = TRUE (cambiado por N8N con documento banco)           │
│ • verificado = TRUE (encontrado en extracto bancario)           │
│ • gmail_enviado = TRUE (se puede enviar si pagado=true)         │
│ • activo = TRUE                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      FIN DEL PROCESO                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 MÓDULOS DEL SISTEMA

### **1. MÓDULO DE USUARIOS Y ACCESOS**

**Descripción:** Gestión de usuarios del sistema y control de accesos

**Funcionalidades:**

- ✅ Crear/editar/eliminar usuarios
- ✅ Asignar roles (Admin, Supervisor, Equipo)
- ✅ Activar/desactivar usuarios
- ✅ Cambiar contraseñas
- ✅ Ver historial de accesos

**Tablas involucradas:**

- `usuarios`
- `roles`
- `eventos` (auditoría)

**Permisos:**

- **Admin:** Acceso completo
- **Supervisor:** Solo lectura
- **Equipo:** Sin acceso

---

### **2. MÓDULO DE PROVEEDORES Y SERVICIOS**

**Descripción:** Gestión de proveedores y sus servicios ofrecidos

**Funcionalidades:**

- ✅ Registrar proveedores
- ✅ Asignar hasta 4 correos electrónicos por proveedor
- ✅ Asociar servicios a proveedores
- ✅ Activar/desactivar proveedores
- ✅ Buscar proveedores por servicio

**Tipos de Servicios:**

- Guianza
- Literie
- Paiement ponctuel
- Car rental
- Excursion

**Tablas involucradas:**

- `proveedores`
- `servicios`
- `proveedor_correos`

**Permisos:**

- **Admin:** Acceso completo
- **Supervisor:** Acceso completo
- **Equipo:** Solo lectura

---

### **3. MÓDULO DE CLIENTES (HOTELES)**

**Descripción:** Gestión de clientes/hoteles que utilizan los servicios

**Funcionalidades:**

- ✅ Registrar clientes
- ✅ Editar información de contacto
- ✅ Activar/desactivar clientes
- ✅ Ver historial de pagos por cliente
- ✅ Vincular múltiples clientes a un pago

**Tablas involucradas:**

- `clientes`
- `pago_cliente` (relación N:N)

**Permisos:**

- **Admin:** Acceso completo
- **Supervisor:** Acceso completo
- **Equipo:** Solo lectura

---

### **4. MÓDULO DE MEDIOS DE PAGO**

**Descripción:** Gestión de tarjetas de crédito y cuentas bancarias

#### **4.1 TARJETAS DE CRÉDITO**

**Funcionalidades:**

- ✅ Registrar tarjetas (titular, últimos 4 dígitos, moneda)
- ✅ Establecer límite mensual
- ✅ Control automático de saldo
- ✅ Reset automático cada inicio de mes
- ✅ Ver saldo disponible en tiempo real
- ✅ Historial de transacciones

**Reglas de Negocio:**

- El saldo DISMINUYE cuando se registra un pago
- El saldo NO puede ser negativo
- El límite se resetea el día 1 de cada mes
- Las tarjetas pueden estar en moneda USD o CAD

**Ejemplo:**

```
Límite mensual: $10,000 USD
Saldo actual: $10,000 USD

[Usuario registra pago de $3,000]
→ Saldo nuevo: $7,000 USD

[Llega el día 1 del mes siguiente]
→ Saldo resetea a: $10,000 USD
```

#### **4.2 CUENTAS BANCARIAS**

**Funcionalidades:**

- ✅ Registrar cuentas (nombre, últimos dígitos, moneda)
- ✅ Etiquetar pagos con la cuenta utilizada
- ❌ NO controla saldo
- ❌ NO tiene límites

**Reglas de Negocio:**

- Solo sirve como etiqueta/referencia
- No se descuenta dinero al registrar pagos
- No se valida disponibilidad

**Tablas involucradas:**

- `tarjetas_credito`
- `cuentas_bancarias`

**Permisos:**

- **Admin:** Acceso completo a ambos
- **Supervisor:** Acceso completo a ambos
- **Equipo:** Solo puede usar tarjetas

---

### **5. MÓDULO DE PAGOS (CORE)**

**Descripción:** Registro y gestión del ciclo de vida de los pagos

**Funcionalidades:**

- ✅ Registrar nuevo pago
- ✅ Seleccionar múltiples clientes
- ✅ Seleccionar medio de pago
- ✅ Cambiar estado del pago
- ✅ Marcar como verificado
- ✅ Ver si fue enviado por correo
- ✅ Editar información (solo si no está verificado)
- ✅ Eliminar pago (desactivación lógica)
- ✅ Filtrar por: estado, verificación, fecha, proveedor

**Estados del Pago:**

```
PENDIENTE → PAGADO → VERIFICADO
   ↓          ↓          ↓
  [Registro] [N8N/manual solo admin]   [N8N/manual solo admin]
```

**Campos Importantes:**

- `pagado`: FALSE | TRUE (indica si el pago fue confirmado)
- `verificado`: FALSE | TRUE
- `gmail_enviado`: FALSE | TRUE
- `tipo_medio_pago`: TARJETA | CUENTA_BANCARIA

**Validaciones:**

- Si medio = TARJETA: validar saldo disponible
- Si medio = TARJETA: descontar del saldo
- Si medio = CUENTA_BANCARIA: solo registrar
- No permitir editar si verificado = TRUE
- No permitir eliminar si gmail_enviado = TRUE

**Tablas involucradas:**

- `pagos`
- `pago_cliente`

**Permisos:**

- **Admin:** Acceso completo
- **Supervisor:** Acceso completo
- **Equipo:** Solo crear con tarjetas, ver solo sus pagos

---

### **6. MÓDULO DE DOCUMENTOS**

**Descripción:** Almacenamiento y gestión de documentos de respaldo con dos tipos diferentes

**Funcionalidades:**

- ✅ Subir documentos (2 tipos: FACTURA o DOCUMENTO_BANCO)
- ✅ Almacenamiento por URL (no base64)
- ✅ Vinculación automática con pagos (N8N)
- ✅ Vinculación manual directa a un pago específico
- ✅ Ver documentos asociados a un pago
- ✅ Ver pagos asociados a un documento
- ✅ Eliminar documentos

**Tipos de Documentos:**

**TIPO 1 - FACTURA:**

- Documento individual de una transacción
- Se puede vincular directamente a UN pago específico
- N8N cambia: `pagado = TRUE`
- Procesa 1 pago a la vez

**TIPO 2 - DOCUMENTO_BANCO:**

- Extracto bancario con lista de múltiples pagos
- NO se vincula inicialmente a pagos específicos
- N8N cambia: `verificado = TRUE`
- Procesa múltiples pagos a la vez

**Integración con N8N:**

```
┌─────────────────────────────────┐
│ Usuario sube PDF + tipo         │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│ Sistema guarda URL en BD        │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│ Trigger webhook a N8N           │
└────────────┬────────────────────┘
             ↓
      ┌──────┴──────┐
      │             │
┌─────▼─────┐  ┌────▼────────┐
│ FACTURA   │  │ DOC_BANCO   │
└─────┬─────┘  └────┬────────┘
      │             │
      ↓             ↓
  N8N busca     N8N extrae
  1 código      lista códigos
      │             │
      ↓             ↓
  Cambia:       Cambia:
  pagado        verificado
  = TRUE        = TRUE
      │             │
      └──────┬──────┘
             ↓
┌─────────────────────────────────┐
│ Vincula en: documento_pago      │
└─────────────────────────────────┘
```

**Tablas involucradas:**

- `documentos` (con campo tipo_documento)
- `documento_pago` (relación N:N)

**Permisos:**

- **Admin:** Acceso completo
- **Supervisor:** Acceso completo
- **Equipo:** Puede subir, solo ve sus documentos

---

### **7. MÓDULO DE CORREOS**

**Descripción:** Generación y envío de notificaciones a proveedores

**Funcionalidades:**

- ✅ Generación automática de correos (cuando pagado = TRUE)
- ✅ Agrupación de pagos por proveedor
- ✅ Selección de correo destino (3 opciones por proveedor)
- ✅ Edición del contenido antes de enviar
- ✅ Envío manual por usuario
- ✅ Historial de correos enviados
- ✅ Ver pagos incluidos en cada correo

**Flujo de Generación:**

```
Sistema detecta: pagado = TRUE + gmail_enviado = FALSE
    ↓
Agrupa pagos por proveedor
    ↓
Crea borrador de correo en tabla envios_correos
    ↓
Usuario ve en "Correos Pendientes"
    ↓
Usuario selecciona 1 de los 4 correos del proveedor
    ↓
Usuario edita contenido (opcional)
    ↓
Usuario confirma envío
    ↓
Sistema envía correo
    ↓
Actualiza gmail_enviado = TRUE en todos los pagos
```

**Plantilla de Correo:**

```
Asunto: Notificación de Pagos - [Fecha]

Estimado [Nombre Proveedor],

Le notificamos los siguientes pagos realizados:

Cliente: [Nombre Hotel 1]
Código: [ABC123]
Monto: $X,XXX.XX USD

Cliente: [Nombre Hotel 2]
Código: [DEF456]
Monto: $X,XXX.XX USD

Total: $XX,XXX.XX USD

Atentamente,
Terra Canada
```

**Tablas involucradas:**

- `envios_correos`
- `envio_correo_detalle`
- `proveedor_correos`

**Permisos:**

- **Admin:** Acceso completo
- **Supervisor:** Acceso completo
- **Equipo:** Sin acceso

---

### **8. MÓDULO DE ANÁLISIS Y REPORTES**

**Descripción:** Dashboards y reportes del sistema

**Funcionalidades:**

- ✅ KPIs principales (pagados, pendientes, verificados)
- ✅ Comparativo: Tarjetas vs Cuentas Bancarias
- ✅ Gráfico temporal de pagos
- ✅ Top proveedores por monto
- ✅ Distribución de correos enviados
- ✅ Filtros por fecha (día, semana, mes, rango)

**KPIs del Dashboard:**

```
┌─────────────────────────────────────────────────┐
│  PAGOS PENDIENTES    │  PAGOS PAGADOS          │
│      [123]           │      [456]              │
├─────────────────────────────────────────────────┤
│  NO VERIFICADOS      │  VERIFICADOS            │
│      [78]            │      [378]              │
├─────────────────────────────────────────────────┤
│  CORREOS PENDIENTES  │  CORREOS ENVIADOS       │
│      [15]            │      [89]               │
└─────────────────────────────────────────────────┘
```

**Gráficos:**

1. **Comparativo Medios de Pago:**
   - Total pagado con tarjetas
   - Total pagado con cuentas bancarias

2. **Evolución Temporal:**
   - Gráfico de línea con pagos por día/semana/mes

3. **Top Proveedores:**
   - Tabla con: Proveedor | Cantidad de Pagos | Monto Total

4. **Distribución de Correos:**
   - Gráfico de dona: Enviados vs Pendientes

**Funciones de BD:**

- `dashboard_kpis_get()`
- `analisis_comparativo_medios_get()`
- `analisis_temporal_pagos_get()`
- `analisis_top_proveedores_get()`

**Permisos:**

- **Admin:** Ve todos los datos
- **Supervisor:** Ve todos los datos
- **Equipo:** Solo sus propios datos

---

### **9. MÓDULO DE AUDITORÍA**

**Descripción:** Registro de todas las acciones del sistema

**Funcionalidades:**

- ✅ Registro automático de cada acción
- ✅ Filtros por: usuario, tipo de evento, fecha, entidad
- ✅ Ver detalles completos de cada evento
- ✅ Exportar registros de auditoría

**Tipos de Eventos:**

- INICIO_SESION
- CREAR (cualquier entidad)
- ACTUALIZAR (cualquier entidad)
- ELIMINAR (cualquier entidad)
- VERIFICAR_PAGO
- CARGAR_TARJETA
- ENVIAR_CORREO

**Información Registrada:**

- Usuario que realizó la acción
- Fecha y hora exacta
- Tipo de acción
- Entidad afectada (ID y tipo)
- Descripción detallada
- IP del usuario (opcional)
- User agent (opcional)

**Tablas involucradas:**

- `eventos`

**Permisos:**

- **Admin:** Acceso completo
- **Supervisor:** Solo lectura
- **Equipo:** Sin acceso

---

## ⚙️ PROCESOS CRÍTICOS

### **1. RESET MENSUAL DE TARJETAS**

**Descripción:** Cada día 1 de mes, resetear saldos de tarjetas

**Proceso:**

```sql
-- Ejecutar vía CRON job el día 1 de cada mes a las 00:01
UPDATE tarjetas_credito
SET saldo = limite_mensual
WHERE activo = TRUE;
```

**Trigger:** Cron job del sistema operativo o scheduler de BD

**Notificación:** Enviar email a Admin confirmando reset

---

### **2. PROCESAMIENTO AUTOMÁTICO DE DOCUMENTOS (N8N)**

**Webhook de N8N:**

```
POST /api/n8n/webhook/documentos

Body: {
  "documento_id": "uuid",
  "url_documento": "https://..."
}

N8N Response: {
  "pagos_encontrados": [
    {
      "pago_id": "uuid",
      "codigo": "ABC123",
      "actualizado": true
    }
  ]
}
```

**Proceso en N8N:**

1. Recibir webhook con URL del documento
2. Descargar documento desde URL
3. Procesar con OCR (Tesseract o similar)
4. Buscar patrones de códigos de reserva
5. Por cada código encontrado:
   - Buscar pago en BD con ese código
   - Actualizar: pagado = TRUE
   - Actualizar: verificado = TRUE
   - Insertar en documento_pago
6. Retornar lista de pagos actualizados

---

### **3. GENERACIÓN AUTOMÁTICA DE CORREOS**

**Trigger:** Cambio de pagado a TRUE

**Proceso:**

```sql
-- Ejecutar cada 5 minutos vía scheduler
SELECT * FROM pagos
WHERE pagado = TRUE
  AND gmail_enviado = FALSE
GROUP BY proveedor_id;

-- Por cada proveedor, generar borrador de correo
INSERT INTO envios_correos (...);
INSERT INTO envio_correo_detalle (...);
```

**Lógica:**

- Agrupar pagos por proveedor
- Crear un correo por proveedor
- Incluir todos los pagos pendientes de ese proveedor
- Estado inicial: BORRADOR

---

## 📜 REGLAS DE NEGOCIO

### **PAGOS**

1. **Un pago puede tener múltiples clientes** (hoteles)
2. **Un pago solo puede usar UN medio de pago** (tarjeta O cuenta)
3. **Si se usa tarjeta, el saldo se descuenta inmediatamente**
4. **Si se usa cuenta bancaria, NO se descuenta nada**
5. **No se puede editar un pago si verificado = TRUE**
6. **No se puede eliminar un pago si gmail_enviado = TRUE**
7. **Un pago solo puede cambiar de pagado=TRUE a pagado=FALSE si no está verificado**

### **TARJETAS**

1. **El saldo nunca puede ser negativo**
2. **El saldo se resetea cada día 1 del mes al límite mensual**
3. **Las tarjetas inactivas no se pueden usar para pagos**
4. **El límite mensual solo se puede editar si no hay pagos pendientes**

### **CUENTAS BANCARIAS**

1. **No controlan saldo** (solo etiqueta)
2. **No se valida disponibilidad de fondos**
3. **Solo Admin y Supervisor pueden usarlas**

### **DOCUMENTOS**

1. **FACTURA: Se vincula a 1 pago, cambia pagado = TRUE**
2. **DOCUMENTO_BANCO: Se vincula a N pagos, cambia verificado = TRUE**
3. **Un pago puede tener múltiples documentos (factura + extractos)**
4. **No se puede eliminar un documento si tiene pagos verificados**
5. **Verificación es AUTOMÁTICA vía N8N (no manual)**

### **CORREOS**

1. **Un pago solo puede enviarse en UN correo**
2. **Una vez enviado (gmail_enviado = TRUE), no aparece en nuevos correos**
3. **El usuario debe seleccionar 1 de los 4 correos del proveedor**
4. **Se puede editar el contenido antes de enviar**
5. **No se puede revertir un envío**

### **PROVEEDORES**

1. **Un proveedor debe tener al menos 1 correo registrado**
2. **Máximo 4 correos por proveedor**
3. **Un proveedor puede ofrecer múltiples servicios**

### **USUARIOS**

1. **Rol Equipo solo puede usar tarjetas**
2. **Rol Equipo solo ve sus propios pagos**
3. **Solo Admin puede crear usuarios**
4. **No se pueden eliminar usuarios con pagos asociados** (desactivar)

---

## 🎯 CASOS DE USO PRINCIPALES

### **Caso 1: Registrar Pago con Tarjeta**

**Actor:** Usuario Equipo
**Precondición:** Tarjeta activa con saldo suficiente

**Flujo:**

1. Usuario selecciona "Nuevo Pago"
2. Selecciona proveedor y servicio
3. Selecciona uno o más clientes
4. Selecciona tarjeta de crédito
5. Ingresa monto y código de reserva
6. Sistema valida saldo disponible
7. Sistema descuenta del saldo de la tarjeta
8. Sistema crea pago con pagado = FALSE, verificado = FALSE
9. Sistema registra evento en auditoría

**Poscondición:** Pago creado y saldo de tarjeta actualizado

---

### **Caso 2A: Procesar FACTURA (documento individual)**

**Actor:** Sistema (N8N)
**Precondición:** Factura PDF subida con tipo = FACTURA

**Flujo:**

1. Usuario sube PDF y selecciona tipo "FACTURA"
2. Opcionalmente vincula directamente a un pago específico
3. Sistema guarda URL en tabla documentos
4. Sistema envía webhook a N8N con tipo_documento
5. N8N descarga y procesa PDF
6. N8N extrae código de reserva
7. N8N busca pago con ese código
8. N8N actualiza: pagado = TRUE
9. N8N vincula en documento_pago

**Poscondición:** Pago marcado con pagado=TRUE, listo para enviar correo

---

### **Caso 2B: Procesar DOCUMENTO_BANCO (extracto bancario)**

**Actor:** Sistema (N8N)
**Precondición:** Extracto bancario PDF subido con tipo = DOCUMENTO_BANCO

**Flujo:**

1. Usuario sube PDF y selecciona tipo "DOCUMENTO_BANCO"
2. Sistema guarda URL en tabla documentos (sin vinculación inicial)
3. Sistema envía webhook a N8N con tipo_documento
4. N8N descarga y procesa PDF
5. N8N extrae LISTA de códigos de reserva
6. Por cada código:
   - N8N busca pago con ese código
   - N8N actualiza: verificado = TRUE
   - N8N actualiza: fecha_verificacion = NOW()
   - N8N vincula en documento_pago
7. N8N ejecuta función: verificar_pagos_por_documento()

**Poscondición:** Múltiples pagos verificados automáticamente

---

### **Caso 3: Enviar Correo a Proveedor**

**Actor:** Usuario Admin
**Precondición:** Existen pagos con pagado = TRUE y gmail_enviado = FALSE

**Flujo:**

1. Usuario accede a "Correos Pendientes"
2. Sistema muestra lista de borradores agrupados por proveedor
3. Usuario selecciona un correo
4. Usuario selecciona 1 de los 4 correos del proveedor
5. Usuario revisa/edita contenido
6. Usuario confirma envío
7. Sistema envía correo electrónico
8. Sistema actualiza gmail_enviado = TRUE en pagos incluidos
9. Sistema registra evento en auditoría

**Poscondición:** Correo enviado y pagos marcados

---

## 📊 MÉTRICAS Y REPORTES CLAVE

### **Métricas Diarias:**

- Total de pagos registrados hoy
- Total de pagos verificados hoy
- Total de correos enviados hoy
- Saldo disponible en cada tarjeta

### **Métricas Mensuales:**

- Total pagado por proveedor
- Total pagado por servicio
- Total por medio de pago (tarjetas vs cuentas)
- Número de correos enviados

### **Reportes Requeridos:**

1. **Reporte de Pagos por Período**
2. **Reporte de Saldos de Tarjetas**
3. **Reporte de Pagos por Proveedor**
4. **Reporte de Auditoría (log completo)**
5. **Reporte de Correos Enviados**

---

## 🔒 CONSIDERACIONES DE SEGURIDAD

### **Autenticación:**

- Login con email y contraseña
- Hash de contraseñas con bcrypt
- Sesiones con JWT tokens

### **Autorización:**

- Validación de rol en cada endpoint
- Middleware de permisos por módulo

### **Auditoría:**

- Registro de TODAS las acciones
- Registro de IP y user agent
- No se pueden eliminar eventos de auditoría

### **Datos Sensibles:**

- Nunca mostrar número completo de tarjeta
- Siempre mostrar: \***\*-\*\***-\*\*\*\*-1234
- No almacenar CVV de tarjetas

---

## 📝 GLOSARIO

- **Pago:** Transacción registrada en el sistema
- **Proveedor:** Empresa que ofrece servicios turísticos
- **Cliente:** Hotel o empresa que utiliza los servicios
- **Servicio:** Tipo de servicio ofrecido (Guianza, Literie, etc.)
- **Medio de Pago:** Tarjeta de crédito o cuenta bancaria
- **Estado de Pago:** pagado (true/false), verificado (true/false), activo (true/false)
- **Verificado:** Confirmación manual de que el pago fue procesado
- **Gmail Enviado:** Indica si el pago fue notificado al proveedor
- **Documento:** PDF de respaldo (factura, extracto, etc.)
- **Código de Reserva:** Identificador único del pago (ej: ABC123)

---

**Fecha de Última Actualización:** 28 de Enero, 2026
**Versión del Documento:** 1.0
**Autor:** Claude AI
**Aprobado por:** Equipo Terra Canada
