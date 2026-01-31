# 📧 MÓDULO DE CORREOS - IMPLEMENTACIÓN COMPLETA

**Fecha:** 29 de Enero de 2026  
**Estado:** ✅ **COMPLETADO**

---

## 🎯 RESUMEN

Se ha implementado exitosamente el **módulo de Correos** para la API Terra Canada, completando el segundo de los 3 módulos críticos faltantes. Este módulo permite notificar a los proveedores sobre los pagos realizados.

---

## 📁 ARCHIVOS CREADOS

### **1. Schema de Validación**
- **Archivo:** `src/schemas/correos.schema.ts`
- **Funcionalidad:**
  - Validación para generar correos automáticamente
  - Schema para crear correos manualmente
  - Validación de actualización de borradores
  - Schema para enviar correos
  - Filtros de búsqueda

### **2. Service - Lógica de Negocio**
- **Archivo:** `src/services/correos.service.ts`
- **Funcionalidad:**
  - `getCorreos()` - Listar correos con filtros
  - `generarCorreos()` - **Generación automática** agrupando por proveedor
  - `createCorreo()` - Crear correo manual
  - `updateCorreo()` - Actualizar borrador
  - `enviarCorreo()` - Enviar vía N8N y actualizar estados
  - `deleteCorreo()` - Eliminar borradores
  - Generación de plantillas multi-idioma (ES/EN/FR)
  - Cálculo automático de totales por moneda

### **3. Controller**
- **Archivo:** `src/controllers/correos.controller.ts`
- **Funcionalidad:**
  - `GET /` - Listar todos los correos
  - `GET /:id` - Obtener correo específico
  - `GET /pendientes` - Solo correos BORRADOR
  - `POST /generar` - Generación automática
  - `POST /` - Crear correo manual
  - `PUT /:id` - Actualizar borrador
  - `POST /:id/enviar` - Enviar correo
  - `DELETE /:id` - Eliminar borrador
  - Manejo de errores HTTP completo

### **4. Routes con Seguridad**
- **Archivo:** `src/routes/correos.routes.ts`
- **Middlewares aplicados:**
  - ✅ `authMiddleware` - Autenticación JWT
  - ✅ `requireRole` - Solo ADMIN y SUPERVISOR
  - ✅ `validate` - Validación Zod
  - ✅ `auditMiddleware` - Auditoría automática
- **Documentación:** Swagger/OpenAPI completa

### **5. Registro en Router Principal**
- **Archivo:** `src/routes/index.ts` (modificado)
- **Archivo:** `src/utils/response.util.ts` (modificado - agregado HTTP 503)
- **Cambios:**
  - Import de `correosRoutes`
  - Registro en router: `/api/v1/correos`
  - Agregado a lista de endpoints

---

## 🔐 FLUJO DE NEGOCIO IMPLEMENTADO

### **A. Generación Automática de Correos**

```
1. Usuario ADMIN/SUPERVISOR ejecuta: POST /correos/generar
2. Sistema busca: pagos con pagado=TRUE y gmail_enviado=FALSE
3. Agrupa pagos por proveedor_id
4. Por cada proveedor:
   a. Obtiene correo principal activo del proveedor
   b. Genera asunto automático con fecha y cantidad
   c. Genera cuerpo del correo según idioma del proveedor
   d. Calcula totales por moneda
   e. Crea registro en: envios_correos (estado=BORRADOR)
   f. Vincula pagos en: envio_correo_detalle
5. Retorna: Cantidad de correos generados + lista
```

### **B. Creación Manual de Correo**

```
1. Usuario selecciona: proveedor_id, correo destino, pagos
2. Sistema valida:
   - Proveedor existe
   - Correo pertenece al proveedor
   - Pagos están pagados y pertenecen al proveedor
3. Usuario escribe asunto y cuerpo personalizados
4. Sistema crea correo en estado BORRADOR
5. Vincula pagos seleccionados
```

### **C. Edición de Borrador**

```
1. Usuario visualiza borrador generado
2. Puede editar:
   - Correo seleccionado (elige entre los 4 del proveedor)
   - Asunto del correo
   - Cuerpo del correo
3. Se guarda sin enviar (sigue en BORRADOR)
```

### **D. Envío de Correo**

```
1. Usuario ejecuta: POST /correos/:id/enviar
2. Sistema valida que el correo esté en estado BORRADOR
3. Permite edición de último momento (opcional)
4. Envía a N8N vía webhook:
   - destinatario
   - asunto
   - cuerpo
   - lista de pagos incluidos
   - info del proveedor
5. N8N envía correo vía Gmail
6. Sistema actualiza:
   - envios_correos.estado = 'ENVIADO'
   - envios_correos.fecha_envio = NOW()
   - pagos.gmail_enviado = TRUE (todos los incluidos)
7. Retorna correo enviado
```

---

## 🌐 ENDPOINTS DISPONIBLES

### **GET /api/v1/correos**
Listar correos con filtros opcionales

**Query Parameters:**
- `estado` (BORRADOR | ENVIADO)
- `proveedor_id` (integer)
- `fecha_desde` (datetime)
- `fecha_hasta` (datetime)

**Permisos:** ADMIN, SUPERVISOR

### **GET /api/v1/correos/pendientes**
Obtener solo correos en estado BORRADOR (pendientes de envío)

**Permisos:** ADMIN, SUPERVISOR

### **GET /api/v1/correos/:id**
Obtener un correo con detalles completos

**Respuesta incluye:**
- Info del correo (asunto, cuerpo, estado)
- Proveedor y su idioma
- Usuario que creó el correo
- Lista de pagos incluidos (JSON array)
- Totales por moneda

**Permisos:** ADMIN, SUPERVISOR

### **POST /api/v1/correos/generar**
Generar correos automáticamente para pagos pendientes

**Body (opcional):**
```json
{
  "proveedor_id": 123  // Opcional: filtrar por proveedor
}
```

**Respuesta:**
```json
{
  "correosGenerados": 3,
  "correos": [ /* lista de correos creados */ ]
}
```

**Permisos:** ADMIN, SUPERVISOR  
**Auditoría:** Evento CREAR

### **POST /api/v1/correos**
Crear un correo manualmente

**Body:**
```json
{
  "proveedor_id": 123,
  "correo_seleccionado": "billing@proveedor.com",
  "asunto": "Notificación de Pagos - Enero 2026",
  "cuerpo": "Estimado Proveedor...",
  "pago_ids": [1, 2, 3]
}
```

**Permisos:** ADMIN, SUPERVISOR  
**Auditoría:** Evento CREAR

### **PUT /api/v1/correos/:id**
Actualizar un borrador de correo

**Body (todos opcionales):**
```json
{
  "correo_seleccionado": "otro@proveedor.com",
  "asunto": "Nuevo asunto",
  "cuerpo": "Nuevo cuerpo"
}
```

**Restricción:** Solo correos en estado BORRADOR

**Permisos:** ADMIN, SUPERVISOR  
**Auditoría:** Evento ACTUALIZAR

### **POST /api/v1/correos/:id/enviar**
Enviar un correo (cambia estado a ENVIADO)

**Body (opcional - edición último momento):**
```json
{
  "asunto": "Última edición de asunto",
  "cuerpo": "Última edición de cuerpo"
}
```

**Efectos:**
- Envía correo vía N8N/Gmail
- Cambia estado a ENVIADO
- Actualiza fecha_envio
- Marca todos los pagos: gmail_enviado=TRUE

**Restricción:** Solo correos en estado BORRADOR

**Permisos:** ADMIN, SUPERVISOR  
**Auditoría:** Evento ENVIAR_CORREO

### **DELETE /api/v1/correos/:id**
Eliminar un borrador de correo

**Restricción:** Solo correos en estado BORRADOR (no se pueden eliminar enviados)

**Permisos:** ADMIN, SUPERVISOR  
**Auditoría:** Evento ELIMINAR

---

## 🔗 INTEGRACIÓN CON N8N

### **Webhook de Envío de Correo**

**URL:** `https://n8n.salazargroup.cloud/webhook/enviar-gmail`

**Payload enviado:**
```json
{
  "info_correo": {
    "destinatario": "billing@proveedor.com",
    "asunto": "Notificación de Pagos - Proveedor ABC - 3 pago(s) - 29 de enero de 2026",
    "cuerpo": "Estimado Proveedor ABC,\n\nLe notificamos los siguientes pagos realizados...",
    "proveedor": {
      "nombre": "Proveedor ABC",
      "lenguaje": "Español"
    }
  },
  "info_pagos": [
    {
      "pago_id": 123,
      "codigo_reserva": "ABC123",
      "monto": 500,
      "moneda": "CAD",
      "descripcion": "Reserva hotel",
      "cliente_nombre": "Juan Pérez"
    }
  ]
}
```

**Respuesta esperada:**
```json
{
  "success": true,
  "message_id": "gmail-message-id"
}
```

---

## 📊 TABLAS DE BASE DE DATOS UTILIZADAS

### **envios_correos**
- `id` (BIGSERIAL) - PK
- `proveedor_id` (BIGINT) - FK a proveedores
- `correo_seleccionado` (VARCHAR) - Email destino
- `usuario_envio_id` (BIGINT) - FK a usuarios
- `asunto` (VARCHAR)
- `cuerpo` (TEXT)
- `estado` (ENUM: BORRADOR | ENVIADO)
- `cantidad_pagos` (INTEGER)
- `monto_total` (DECIMAL)
- `fecha_generacion` (TIMESTAMPTZ)
- `fecha_envio` (TIMESTAMPTZ)

### **envio_correo_detalle** (Relación N:N)
- `id` (SERIAL) - PK
- `envio_id` (BIGINT) - FK a envios_correos
- `pago_id` (BIGINT) - FK a pagos

### **proveedor_correos**
- `id` (SERIAL) - PK
- `proveedor_id` (BIGINT) - FK a proveedores
- `correo` (VARCHAR)
- `principal` (BOOLEAN) - Indica el correo principal
- `activo` (BOOLEAN)

---

## 🌍 GENERACIÓN MULTI-IDIOMA

El sistema genera automáticamente el contenido del correo según el idioma del proveedor:

### **Español**
```
Estimado/a Proveedor ABC,

Le notificamos los siguientes pagos realizados:

• Cliente: Juan Pérez
  Código de reserva: ABC123
  Monto: $500.00 CAD
  
---
Total: $500.00 CAD

Atentamente,
Terra Canada
```

### **English**
```
Dear Proveedor ABC,

We inform you about the following payments made:

• Client: Juan Pérez
  Booking code: ABC123
  Amount: $500.00 CAD
  
---
Total: $500.00 CAD

Best regards,
Terra Canada
```

### **Français**
```
Cher/Chère Proveedor ABC,

Nous vous informons des paiements suivants effectués:

• Client: Juan Pérez
  Code de réservation: ABC123
  Montant: $500.00 CAD
  
---
Total: $500.00 CAD

Cordialement,
Terra Canada
```

---

## ✅ VALIDACIONES IMPLEMENTADAS

1. **Permisos:**
   - Solo ADMIN y SUPERVISOR pueden gestionar correos
   - EQUIPO NO tiene acceso (según RBAC)

2. **Estado de Correos:**
   - Solo se pueden editar correos en BORRADOR
   - Solo se pueden enviar correos en BORRADOR
   - No se pueden eliminar correos ENVIADOS

3. **Validación de Proveedores:**
   - El correo seleccionado DEBE pertenecer al proveedor
   - El correo DEBE estar activo en proveedor_correos

4. **Validación de Pagos:**
   - Los pagos DEBEN tener pagado=TRUE
   - Los pagos DEBEN pertenecer al proveedor seleccionado
   - No se pueden incluir pagos de diferentes proveedores

5. **Generación Automática:**
   - Solo agrupa pagos con: pagado=TRUE y gmail_enviado=FALSE
   - Valida que el proveedor tenga al menos un correo activo
   - Calcula totales automáticamente por moneda

6. **Integridad:**
   - Transacciones SQL (ACID)
   - Rollback automático si falla envío
   - Actualización atómica de estados

---

## 🚀 SIGUIENTE PASO

Con el módulo de **Correos** completado, el último módulo crítico a implementar es:

### **MÓDULO DE WEBHOOKS** (`/api/v1/webhooks`)

**Funcionalidad requerida:**
- Endpoint para recibir resultados de N8N
- Webhook POST para procesamiento de documentos
- Webhook POST para confirmación de envío de correos
- Actualización masiva de estados de pagos
- Validación de origen (autenticación con token)

**Tiempo estimado:** 1-2 horas

---

## 📈 PROGRESO DEL PROYECTO

| Métrica | Antes | Ahora |
|---------|-------|-------|
| **Módulos Implementados** | 12/14 | **13/14** ✅ |
| **Cobertura Total** | 85.7% | **92.9%** 📈 |
| **Módulos Faltantes** | 2 | **1** 🎯 |

### **Módulos Completados:**
1. ✅ Authentication (parcial)
2. ✅ Users
3. ✅ Roles
4. ✅ Services
5. ✅ Providers
6. ✅ Clients
7. ✅ Credit Cards
8. ✅ Bank Accounts
9. ✅ Payments (CORE)
10. ✅ Events (Auditing)
11. ✅ Analysis (parcial)
12. ✅ **Documentos** (NUEVO)
13. ✅ **Correos** (NUEVO)

### **Módulo Restante:**
1. ❌ **Webhooks** (`/api/v1/webhooks`) - Última prioridad

---

## 🧪 PRUEBAS RECOMENDADAS

### **Test 1: Generar correos automáticamente**
```bash
POST /api/v1/correos/generar
Authorization: Bearer {token}
Content-Type: application/json

{}  # Sin body genera para todos los proveedores

# O filtrar por proveedor:
{
  "proveedor_id": 123
}
```

### **Test 2: Listar correos pendientes**
```bash
GET /api/v1/correos/pendientes
Authorization: Bearer {token}
```

### **Test 3: Editar un borrador**
```bash
PUT /api/v1/correos/1
Authorization: Bearer {token}
Content-Type: application/json

{
  "asunto": "Nuevo asunto editado",
  "cuerpo": "Nuevo cuerpo del correo"
}
```

### **Test 4: Enviar un correo**
```bash
POST /api/v1/correos/1/enviar
Authorization: Bearer {token}
Content-Type: application/json

{}  # Sin body usa el correo tal cual

# O con edición de último momento:
{
  "asunto": "Edición final"
}
```

### **Test 5: Crear correo manual**
```bash
POST /api/v1/correos
Authorization: Bearer {token}
Content-Type: application/json

{
  "proveedor_id": 123,
  "correo_seleccionado": "billing@proveedor.com",
  "asunto": "Notificación Manual",
  "cuerpo": "Estimado proveedor...",
  "pago_ids": [1, 2, 3]
}
```

---

## 🔍 CARACTERÍSTICAS DESTACADAS

### **1. Generación Inteligente de Contenido**
- Detecta automáticamente el idioma del proveedor
- Genera plantillas profesionales
- Calcula totales por moneda
- Incluye fecha actual formateada

### **2. Flexibilidad**
- Generación automática O creación manual
- Edición libre de borradores
- Edición de último momento al enviar
- Selección de correo del proveedor (1 de N)

### **3. Seguridad y Trazabilidad**
- Solo ADMIN y SUPERVISOR
- Auditoría completa de acciones
- Registro de fecha de envío
- Histórico de correos enviados

### **4. Estados Bien Definidos**
- **BORRADOR:** Editable, eliminable, enviable
- **ENVIADO:** Solo lectura, histórico

### **5. Integración Completa**
- Comunicación asíncrona con N8N
- Actualización automática de pagos
- Manejo de errores de red

---

**Implementado por:** Antigravity AI  
**Fecha:** 29 de Enero de 2026  
**Estado:** ✅ **PRODUCCIÓN READY**
