# 🔗 INTEGRACIÓN N8N - ENVÍO DE CORREOS

**Fecha:** 30 de Enero de 2026  
**Módulo:** Correos  
**Webhook:** https://n8n.salazargroup.cloud/webhook/gmail_g

---

## 📋 RESUMEN

Se ha configurado la integración completa con el webhook de N8N para el envío automatizado de correos a proveedores vía Gmail. El sistema maneja correctamente las respuestas de éxito y error del webhook, propagando los mensajes específicos al usuario.

---

## 🔐 AUTENTICACIÓN

**Método:** Basic Authentication  
**Header:** `Authorization: Basic YWRtaW46Y3JpcF9hZG1pbmQ1Ny1hNjA5LTZlYWYxZjllODdmNg==`

Este header está **hardcodeado** en el archivo `src/utils/n8n.util.ts` y se envía automáticamente en cada request.

---

## 📤 REQUEST - Payload Enviado

### **Endpoint**

```
POST https://n8n.salazargroup.cloud/webhook/gmail_g
```

### **Headers**

```
Content-Type: application/json
Authorization: Basic YWRtaW46Y3JpcF9hZG1pbmQ1Ny1hNjA5LTZlYWYxZjllODdmNg==
```

### **Body**

```json
{
  "info_correo": {
    "destinatario": "billing@proveedor.com",
    "asunto": "Notificación de Pagos - Proveedor ABC - 3 pago(s) - 30 de enero de 2026",
    "cuerpo": "Estimado/a Proveedor ABC,\n\nLe notificamos los siguientes pagos realizados:\n\n• Cliente: Juan Pérez\n  Código de reserva: ABC123\n  Monto: $500.00 CAD\n  Descripción: Reserva hotel\n\n---\nTotal: $500.00 CAD\n\nAtentamente,\nTerra Canada",
    "proveedor": {
      "nombre": "Proveedor ABC",
      "lenguaje": "Español"
    },
    "usuario_id": 2
  },
  "info_pagos": [
    {
      "pago_id": 123,
      "codigo_reserva": "ABC123",
      "monto": 500,
      "moneda": "CAD",
      "descripcion": "Reserva hotel",
      "cliente_nombre": "Juan Pérez"
    },
    {
      "pago_id": 124,
      "codigo_reserva": "DEF456",
      "monto": 750.5,
      "moneda": "CAD",
      "descripcion": "Tours",
      "cliente_nombre": "María García"
    }
  ]
}
```

---

## 📥 RESPONSE - Respuestas del Webhook

### **✅ Respuesta de Éxito (200)**

```json
{
  "code": 200,
  "estado": true,
  "mensaje": "gmail enviado"
}
```

**Comportamiento del sistema:**

1. ✅ El correo se marca como **ENVIADO**
2. ✅ Se registra `fecha_envio = NOW()`
3. ✅ Todos los pagos incluidos: `gmail_enviado = TRUE`
4. ✅ Se retorna al usuario: `"Correo enviado exitosamente"`

---

### **❌ Respuesta de Error (400)**

```json
{
  "code": 400,
  "estado": false,
  "mensaje": "Error al validar credenciales de Gmail"
}
```

**Comportamiento del sistema:**

1. ❌ La transacción se revierte (ROLLBACK)
2. ❌ El correo permanece en estado **BORRADOR**
3. ❌ Los pagos NO se marcan como enviados
4. ❌ Se retorna al usuario el **mensaje exacto del webhook**:
   ```json
   {
     "code": 400,
     "estado": false,
     "message": "Error al validar credenciales de Gmail",
     "data": null
   }
   ```

---

## 🔄 FLUJO COMPLETO

### **1. Usuario solicita envío**

```bash
POST /api/v1/correos/123/enviar
Authorization: Bearer {token}
```

### **2. Controller valida y delega al Service**

```typescript
const correo = await correosService.enviarCorreo(id, validatedData);
```

### **3. Service inicia transacción**

```sql
BEGIN TRANSACTION;
```

### **4. Service prepara datos y llama a N8N Client**

```typescript
await n8nClient.enviarCorreo({
  destinatario: correo.correo_seleccionado,
  asunto: asuntoFinal,
  cuerpo: cuerpoFinal,
  pagos: correo.pagos_incluidos,
  proveedor: { ... },
  usuario_id: correo.usuario_envio_id
});
```

### **5. N8N Client envía request**

```typescript
const response = await axios.post(webhookUrl, payload, {
  headers: {
    Authorization: 'Basic YWR...',
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});
```

### **6A. Si N8N responde con éxito (code=200, estado=true)**

```typescript
// N8N Client retorna exitosamente
return data;

// Service actualiza estados en BD
UPDATE envios_correos SET estado = 'ENVIADO', fecha_envio = NOW();
UPDATE pagos SET gmail_enviado = TRUE WHERE id IN (...);

// Service hace COMMIT
COMMIT;

// Controller retorna éxito al usuario
return sendSuccess(res, 200, 'Correo enviado exitosamente', correo);
```

### **6B. Si N8N responde con error (code=400, estado=false)**

```typescript
// N8N Client lanza excepción con mensaje del webhook
throw new Error(data.mensaje); // Ej: "Error al validar credenciales de Gmail"

// Service detecta error y hace ROLLBACK
ROLLBACK;

// Controller captura el error y lo propaga
return sendError(res, 400, error.message); // Mensaje original del webhook
```

### **6C. Si hay error de red (timeout, no responde)**

```typescript
// N8N Client lanza excepción
throw new Error('No se pudo conectar con el servicio de correo...');

// Service hace ROLLBACK
ROLLBACK;

// Controller retorna error de servicio
return sendError(res, 503, 'No se pudo conectar...');
```

---

## 🛡️ MANEJO DE ERRORES

### **Tipos de errores manejados:**

| Tipo de Error            | Código HTTP | Mensaje al Usuario                                 | Estado del Correo |
| ------------------------ | ----------- | -------------------------------------------------- | ----------------- |
| **Webhook responde 200** | 200         | "Correo enviado exitosamente"                      | ENVIADO ✅        |
| **Webhook responde 400** | 400         | _Mensaje del webhook_                              | BORRADOR ❌       |
| **Timeout (30s)**        | 503         | "No se pudo conectar con el servicio de correo..." | BORRADOR ❌       |
| **Error de red**         | 503         | "No se pudo conectar con el servicio de correo..." | BORRADOR ❌       |
| **Correo no encontrado** | 404         | "Correo no encontrado"                             | N/A               |
| **No es borrador**       | 409         | "Solo se pueden enviar correos en estado BORRADOR" | Sin cambios       |

---

## 📝 DETALLES TÉCNICOS

### **Timeout**

- **30 segundos** - El envío de correo puede tardar más que otras operaciones

### **Transacciones SQL**

- Todas las operaciones se ejecutan en una **transacción ACID**
- Si el webhook falla, se hace **ROLLBACK automático**
- El estado del correo solo cambia si N8N confirma el envío exitoso

### **Logging**

Todo el proceso está completamente loggeado:

```typescript
// Inicio
logger.info('Enviando correo a billing@proveedor.com vía N8N', {
  url: 'https://n8n.salazargroup.cloud/webhook/gmail_g',
  cantidadPagos: 3,
  usuario_id: 2,
});

// Éxito
logger.info('Correo enviado exitosamente a billing@proveedor.com', {
  mensaje: 'gmail enviado',
});

// Error
logger.error('Webhook N8N respondió con error', {
  code: 400,
  mensaje: 'Error al validar credenciales de Gmail',
  destinatario: 'billing@proveedor.com',
});
```

---

## 🧪 PRUEBAS

### **Test 1: Envío exitoso**

```bash
POST /api/v1/correos/1/enviar
Authorization: Bearer {token}

# Respuesta esperada (200):
{
  "code": 200,
  "estado": true,
  "message": "Correo enviado exitosamente",
  "data": {
    "id": 1,
    "estado": "ENVIADO",
    "fecha_envio": "2026-01-29T23:45:00Z",
    ...
  }
}
```

### **Test 2: Error del webhook**

```bash
POST /api/v1/correos/1/enviar
Authorization: Bearer {token}

# Si N8N responde con error (400):
{
  "code": 400,
  "estado": false,
  "message": "Error al validar credenciales de Gmail",
  "data": null
}
```

### **Test 3: Verificar que el correo sigue en BORRADOR tras error**

```bash
GET /api/v1/correos/1
Authorization: Bearer {token}

# Respuesta:
{
  "code": 200,
  "estado": true,
  "data": {
    "id": 1,
    "estado": "BORRADOR",  // <-- Sigue en borrador
    "fecha_envio": null,
    ...
  }
}
```

---

## 🎯 VENTAJAS DE ESTA IMPLEMENTACIÓN

### **1. Atomicidad**

- ✅ Todo o nada: Si N8N falla, NADA se guarda en la BD
- ✅ Los pagos solo se marcan si el correo se envió realmente

### **2. Mensajes Informativos**

- ✅ El usuario recibe el **mensaje exacto** del webhook
- ✅ Puede actuar según el error específico (Ej: "Error de credenciales" → revisar configuración Gmail)

### **3. Reintentos Posibles**

- ✅ Si falla, el correo sigue en **BORRADOR**
- ✅ El usuario puede editar y **volver a intentar** el envío
- ✅ No se pierde información

### **4. Trazabilidad**

- ✅ Logs completos en `./logs`
- ✅ Auditoría automática del evento `ENVIAR_CORREO`
- ✅ Fecha de envío registrada solo si fue exitoso

### **5. Timeout Generoso**

- ✅ 30 segundos permiten que N8N procese el envío
- ✅ Evita falsos positivos por lentitud de red

---

## 📊 EJEMPLO DE PAYLOAD REAL

```json
{
  "info_correo": {
    "destinatario": "payments@aircanada.com",
    "asunto": "Notificación de Pagos - Air Canada - 5 pago(s) - 30 de enero de 2026",
    "cuerpo": "Dear Air Canada,\n\nWe inform you about the following payments made:\n\n• Client: John Smith\n  Booking code: AC1234\n  Amount: $1,250.00 CAD\n  Description: Flight YYZ-YVR\n\n• Client: María González\n  Booking code: AC1235\n  Amount: $890.50 CAD\n  Description: Flight YOW-YUL\n\n• Client: Pierre Dubois\n  Booking code: AC1236\n  Amount: $1,100.00 CAD\n  Description: Flight YUL-YYC\n\n• Client: Sarah Johnson\n  Booking code: AC1237\n  Amount: $750.00 CAD\n  Description: Flight YYC-YVR\n\n• Client: Ahmed Hassan\n  Booking code: AC1238\n  Amount: $2,300.00 CAD\n  Description: Flight YYZ-LHR\n\n---\nTotal: $6,290.50 CAD\n\nBest regards,\nTerra Canada",
    "proveedor": {
      "nombre": "Air Canada",
      "lenguaje": "English"
    },
    "usuario_id": 2
  },
  "info_pagos": [
    {
      "pago_id": 501,
      "codigo_reserva": "AC1234",
      "monto": 1250,
      "moneda": "CAD",
      "descripcion": "Flight YYZ-YVR",
      "cliente_nombre": "John Smith"
    },
    {
      "pago_id": 502,
      "codigo_reserva": "AC1235",
      "monto": 890.5,
      "moneda": "CAD",
      "descripcion": "Flight YOW-YUL",
      "cliente_nombre": "María González"
    },
    {
      "pago_id": 503,
      "codigo_reserva": "AC1236",
      "monto": 1100,
      "moneda": "CAD",
      "descripcion": "Flight YUL-YYC",
      "cliente_nombre": "Pierre Dubois"
    },
    {
      "pago_id": 504,
      "codigo_reserva": "AC1237",
      "monto": 750,
      "moneda": "CAD",
      "descripcion": "Flight YYC-YVR",
      "cliente_nombre": "Sarah Johnson"
    },
    {
      "pago_id": 505,
      "codigo_reserva": "AC1238",
      "monto": 2300,
      "moneda": "CAD",
      "descripcion": "Flight YYZ-LHR",
      "cliente_nombre": "Ahmed Hassan"
    }
  ]
}
```

---

## ✅ ESTADO DE IMPLEMENTACIÓN

| Componente                  | Estado                      |
| --------------------------- | --------------------------- |
| **Cliente N8N**             | ✅ Implementado             |
| **URL Webhook**             | ✅ Hardcodeado              |
| **Autenticación**           | ✅ Basic Auth hardcodeado   |
| **Payload Correcto**        | ✅ Según especificación     |
| **Manejo de Respuesta 200** | ✅ Implementado             |
| **Manejo de Respuesta 400** | ✅ Implementado             |
| **Manejo de Timeout**       | ✅ 30 segundos              |
| **Manejo de Error de Red**  | ✅ Implementado             |
| **Transacciones ACID**      | ✅ Implementado             |
| **Logging Completo**        | ✅ Implementado             |
| **Mensajes al Usuario**     | ✅ Propagados correctamente |

---

**Implementado por:** Antigravity AI  
**Fecha:** 30 de Enero de 2026  
**Última actualización:** Agregado `usuario_id` al payload  
**Estado:** ✅ **PRODUCCIÓN READY**
