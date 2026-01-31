# 📡 WEBHOOKS - DOCUMENTACIÓN COMPLETA

**Fecha:** 30 de Enero de 2026  
**Estado:** ✅ **IMPLEMENTADO Y DOCUMENTADO**

---

## 🎯 TIPOS DE WEBHOOKS

La API Terra Canada utiliza **DOS tipos** de webhooks:

### **1. ⬇️ WEBHOOKS ENTRANTES** (Recibidos por nuestra API)
Endpoints que nuestra API expone para recibir notificaciones de servicios externos.

### **2. ⬆️ WEBHOOKS SALIENTES** (Enviados desde nuestra API)
Integraciones donde nuestra API envía datos a servicios externos.

---

## ⬇️ WEBHOOKS ENTRANTES

### **📥 Webhook N8N - Documento Procesado**

**Endpoint:**
```
POST /api/v1/webhooks/n8n/documento-procesado
```

**Descripción:**
N8N notifica a nuestra API cuando termina de procesar un documento usando OCR.

**Autenticación:**
```http
x-n8n-token: {token_configurado_en_env}
```

**Payload Recibido:**
```json
{
  "documento_id": 123,
  "tipo_procesamiento": "FACTURA",
  "exito": true,
  "mensaje": "OCR completado exitosamente",
  "codigos_encontrados": [
    {
      "codigo_reserva": "AC12345",
      "encontrado": true,
      "pago_id": 501,
      "observaciones": "Código encontrado en línea 5"
    }
  ],
  "codigos_no_encontrados": ["XYZ999"],
  "timestamp": "2026-01-30T04:30:15.234Z"
}
```

**Respuesta Exitosa (200):**
```json
{
  "success": true,
  "message": "Webhook procesado exitosamente",
  "data": {
    "pagos_actualizados": 1,
    "pagos_encontrados": [501],
    "codigos_no_encontrados": ["XYZ999"],
    "errores": []
  }
}
```

**Acciones Realizadas:**
1. ✅ Actualiza estado del documento a `COMPLETADO`
2. ✅ Busca pagos por códigos de reserva
3. ✅ Actualiza pagos encontrados: `estado=PAGADO`, `verificado=TRUE`, `pagado=TRUE`
4. ✅ Vincula documento con los pagos
5. ✅ Registra códigos no encontrados en auditoría

**Swagger:**
✅ Documentado en `/api-docs` bajo tag **Webhooks**

---

## ⬆️ WEBHOOKS SALIENTES

### **1. 📄 Procesamiento de Facturas (N8N)**

**URL:**
```
POST https://n8n.salazargroup.cloud/webhook/recibiendo_pdf
```

**Cuándo se envía:**
- Al llamar `POST /api/v1/facturas/procesar`

**Autenticación:**
```http
Authorization: Basic QWRtaW5pc3RyYWRvcjpuOG5jNzc3LTRkNTctYTYwOS02ZWFmMWY5ZTg3ZjZ0ZXJyYWNhbmFkYQ==
```

**Payload Enviado:**
```json
{
  "usuario": "Julie",
  "id_usuario": 12,
  "tipo_usuario": "ADMIN",
  "ip": "192.168.1.100",
  "archivos": [
    {
      "nombre": "NA - 39331961285.2025-01-31.pdf",
      "tipo": "application/pdf",
      "base64": "JVBERi0xLjQKJeLjz9MKM..."
    }
  ]
}
```

**Respuesta Esperada:**
```json
{
  "code": 200,
  "estado": true,
  "mensaje": "Facturas procesadas correctamente",
  "facturas": [
    {
      "codigo_pago": "ABC123",
      "encontrado": true
    }
  ]
}
```

**Timeout:** 60 segundos

---

### **2. ✏️ Editar Pago con PDF (N8N)**

**URL:**
```
POST https://n8n.salazargroup.cloud/webhook/edit_pago
```

**Cuándo se envía:**
- Al llamar `PUT /api/v1/pagos/:id/con-pdf`

**Autenticación:**
```http
Authorization: Basic QWRtaW5pc3RyYWRvcjpuOG5jNzc3LTRkNTctYTYwOS02ZWFmMWY5ZTg3ZjZ0ZXJyYWNhbmFkYQ==
```

**Payload Enviado:**
```json
{
  "pago_id": 123,
  "usuario_id": 5,
  "usuario_nombre": "Admin User",
  "ip": "192.168.1.100",
  "estado": "PAGADO",
  "verificado": true,
  "archivo": {
    "nombre": "comprobante_123.pdf",
    "tipo": "application/pdf",
    "base64": "JVBERi0xLjQKJeLjz9MKM..."
  },
  "codigo_reserva": "AC12345",
  "monto": 1500.50,
  "moneda": "CAD"
}
```

**Respuesta Esperada:**
```json
{
  "code": 200,
  "estado": true,
  "mensaje": "Pago editado correctamente"
}
```

**Timeout:** 30 segundos

---

### **3. 📧 Enviar Correo Gmail (N8N)**

**URL:**
```
POST https://n8n.salazargroup.cloud/webhook/enviar_gmail
```

**Cuándo se envía:**
- Al llamar `POST /api/v1/correos/:id/enviar`

**Autenticación:**
```http
Authorization: Basic YWRtaW46Y3JpcF9hZG1pbmQ1Ny1hNjA5LTZlYWYxZjllODdmNg==
```

**Payload Enviado:**
```json
{
  "info_correo": {
    "destinatario": "billing@aircanada.com",
    "asunto": "Payment Confirmation - Terra Canada",
    "cuerpo": "Dear Air Canada,\n\nWe are writing to confirm...",
    "proveedor": {
      "id": 5,
      "nombre": "Air Canada",
      "lenguaje": "English"
    }
  },
  "info_pagos": [
    {
      "id": 501,
      "codigo_reserva": "AC12345",
      "monto": 1500.50,
      "moneda": "CAD",
      "fecha_pago": "2026-01-30"
    }
  ]
}
```

**Respuesta Esperada:**
```json
{
  "code": 200,
  "estado": true,
  "mensaje": "Correo enviado exitosamente"
}
```

**Timeout:** 30 segundos

---

### **4. 🔔 Notificaciones de Cambios en Pagos (Intelexia Labs)**

**URL:**
```
POST https://intelexia-labs-ob-mediafile.af9gwe.easypanel.host/upload
```

**Cuándo se envía:**
- Al crear un pago: `POST /api/v1/pagos`
- Al actualizar un pago: `PUT /api/v1/pagos/:id`
- Al eliminar un pago: `DELETE /api/v1/pagos/:id`

**Autenticación:**
Sin autenticación

**Payload Enviado:**
```json
{
  "accion": "CREAR | ACTUALIZAR | ELIMINAR",
  "timestamp": "2026-01-30T00:30:00.000Z",
  "pago": {
    "id": 123,
    "codigo_reserva": "ABC123",
    "monto": 1500.50,
    "moneda": "CAD",
    "estado": "PAGADO",
    "verificado": true,
    "pagado": true,
    "gmail_enviado": false,
    "proveedor_id": 5,
    "proveedor_nombre": "Air Canada",
    "usuario_nombre": "admin",
    "cliente_nombre": "John Doe",
    "fecha_pago": "2026-01-30",
    "fecha_creacion": "2026-01-30T00:15:00.000Z",
    "fecha_actualizacion": "2026-01-30T00:30:00.000Z"
  }
}
```

**Respuestas Esperadas:**
```json
// Éxito
{ "status": 200, "message": "Recibido correctamente" }

// Error
{ "status": 400, "message": "Error al procesar", "error": "..." }
```

**Timeout:** 10 segundos

**Comportamiento:**
- ✅ **No bloquea** la operación principal si falla
- ✅ Solo registra errores en logs
- ✅ La operación del pago se completa normalmente

---

## 📊 RESUMEN DE WEBHOOKS

| Webhook | Tipo | URL | Auth | Swagger |
|---------|------|-----|------|---------|
| **Documento Procesado** | ⬇️ ENTRANTE | `/api/v1/webhooks/n8n/documento-procesado` | x-n8n-token | ✅ |
| **Procesar Facturas** | ⬆️ SALIENTE | N8N `/webhook/recibiendo_pdf` | Basic Auth | ℹ️ Docs only |
| **Editar Pago con PDF** | ⬆️ SALIENTE | N8N `/webhook/edit_pago` | Basic Auth | ℹ️ Docs only |
| **Enviar Gmail** | ⬆️ SALIENTE | N8N `/webhook/enviar_gmail` | Basic Auth | ℹ️ Docs only |
| **Notificar Cambios Pagos** | ⬆️ SALIENTE | Intelexia Labs `/upload` | None | ℹ️ Docs only |

---

## 🔐 SEGURIDAD

### **Webhooks Entrantes:**
- ✅ Requieren token en header `x-n8n-token`
- ✅ Token configurado en `.env` (`N8N_WEBHOOK_TOKEN`)
- ✅ Validación en cada request
- ✅ Logs de intentos no autorizados

### **Webhooks Salientes:**
- ✅ Basic Auth para N8N (credenciales hardcodeadas)
- ✅ Sin auth para Intelexia Labs
- ✅ Timeout configurado para cada servicio
- ✅ Manejo robusto de errores

---

## 🧪 TESTING

### **Probar Webhook Entrante (N8N):**
```bash
curl -X POST http://localhost:3000/api/v1/webhooks/n8n/documento-procesado \
  -H "Content-Type: application/json" \
  -H "x-n8n-token: tu_token_secreto" \
  -d '{
    "documento_id": 1,
    "tipo_procesamiento": "FACTURA",
    "exito": true,
    "codigos_encontrados": [
      {
        "codigo_reserva": "TEST123",
        "encontrado": true
      }
    ],
    "timestamp": "2026-01-30T00:00:00.000Z"
  }'
```

### **Probar Webhooks Salientes:**
Simplemente usar los endpoints de la API que los disparan:

```bash
# Factura
POST /api/v1/facturas/procesar

# Editar pago con PDF
PUT /api/v1/pagos/123/con-pdf

# Enviar correo
POST /api/v1/correos/5/enviar

# Notificar cambio de pago
POST /api/v1/pagos  # Se dispara automáticamente
```

---

## 📁 ARCHIVOS RELACIONADOS

### **Webhooks Entrantes:**
- `src/schemas/webhooks.schema.ts` - Validaciones Zod
- `src/services/webhooks.service.ts` - Lógica de negocio
- `src/controllers/webhooks.controller.ts` - Controlador HTTP
- `src/routes/webhooks.routes.ts` - Rutas y Swagger

### **Webhooks Salientes:**
- `src/utils/n8n.util.ts` - Cliente N8N y notificaciones
- `src/services/pagos.service.ts` - Notificaciones de pagos
- `src/controllers/facturas.controller.ts` - Procesamiento de facturas
- `src/services/correos.service.ts` - Envío de correos

---

## 📖 SWAGGER UI

### **Webhooks Entrantes:**
✅ Totalmente documentados en: `http://localhost:3000/api-docs`  
✅ Tag: **Webhooks**  
✅ Incluye ejemplos y schemas

### **Webhooks Salientes:**
ℹ️ Documentados en este archivo  
ℹ️ No aparecen en Swagger (son llamadas que hace la API, no endpoints)

---

## 🎯 ESTADO FINAL

| Componente | Estado |
|------------|--------|
| **Webhooks Entrantes - Implementación** | ✅ Completo |
| **Webhooks Entrantes - Swagger** | ✅ Documentado |
| **Webhooks Salientes - Implementación** | ✅ Completo |
| **Webhooks Salientes - Documentación** | ✅ Completo |
| **Tests** | ⏳ Pendiente |

---

**Actualizado:** 30 de Enero de 2026  
**Estado:** ✅ **PRODUCCIÓN READY**
