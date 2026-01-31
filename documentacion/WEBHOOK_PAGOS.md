# 🔔 WEBHOOK N8N - Notificación de Pagos

## Fecha: 2026-01-30

## Estado: ✅ IMPLEMENTADO (CREAR, ACTUALIZAR, ELIMINAR)

---

## 📌 INFORMACIÓN DEL WEBHOOK

**URL:** `https://n8n.salazargroup.cloud/webhook/pago`  
**Método:** POST  
**Content-Type:** application/json

### Respuestas del Webhook

| Código  | Significado                                     |
| ------- | ----------------------------------------------- |
| **200** | ✅ Todo bien - El webhook procesó correctamente |
| **400** | ❌ Algo salió mal - Error en el procesamiento   |

---

## 🔄 CUÁNDO SE ENVÍA

El webhook se ejecuta automáticamente en las siguientes acciones:

| Acción         | Endpoint          | Estado          |
| -------------- | ----------------- | --------------- |
| **CREAR**      | POST /pagos       | ✅ Implementado |
| **ACTUALIZAR** | PUT /pagos/:id    | ✅ Implementado |
| **ELIMINAR**   | DELETE /pagos/:id | ✅ Implementado |

---

## 📤 PAYLOAD ENVIADO AL WEBHOOK

### Acción: CREAR

```json
{
  "accion": "CREAR",
  "timestamp": "2026-01-30T19:05:00.000Z",
  "pago": {
    "id": 5,
    "codigo_reserva": "RES-2026-004",
    "monto": 500.0,
    "moneda": "USD",
    "descripcion": "Pago de servicio de guía turística",
    "fecha_esperada_debito": "2026-02-15",
    "proveedor": {
      "id": 2,
      "nombre": "Air Canada",
      "servicio": {
        "id": 1,
        "nombre": "Vuelos"
      }
    },
    "usuario": {
      "id": 2,
      "nombre_completo": "Juan Pérez",
      "rol": "SUPERVISOR"
    },
    "medio_pago": {
      "tipo": "TARJETA",
      "id": 1,
      "titular": "Juan Pérez",
      "ultimos_digitos": "1234",
      "tipo_tarjeta": "Visa",
      "moneda": "USD"
    },
    "clientes": [
      {
        "id": 1,
        "nombre": "Cliente Corp",
        "ubicacion": "Toronto"
      }
    ],
    "estados": {
      "pagado": false,
      "verificado": false,
      "gmail_enviado": false,
      "activo": true
    },
    "fecha_pago": null,
    "fecha_verificacion": null,
    "fecha_creacion": "2026-01-30T19:05:00Z",
    "fecha_actualizacion": "2026-01-30T19:05:00Z"
  }
}
```

### Acción: ACTUALIZAR

```json
{
  "accion": "ACTUALIZAR",
  "timestamp": "2026-01-30T19:10:00.000Z",
  "pago": {
    "id": 5,
    "codigo_reserva": "RES-2026-004",
    "monto": 500.0,
    "moneda": "USD",
    "descripcion": "Descripción actualizada",
    "estados": {
      "pagado": true,
      "verificado": false,
      "gmail_enviado": false,
      "activo": true
    }
    // ... resto de los datos del pago actualizado
  }
}
```

### Acción: ELIMINAR

```json
{
  "accion": "ELIMINAR",
  "timestamp": "2026-01-30T19:15:00.000Z",
  "pago": {
    "id": 5,
    "codigo_reserva": "RES-2026-004",
    "monto_devuelto": 500.0
  }
}
```

---

## 📥 RESPUESTA DEL WEBHOOK

### Respuesta Exitosa (200)

```json
{
  "code": 200,
  "estado": true,
  "mensaje": "Pago recibido correctamente",
  "data": {
    // Datos procesados por N8N (opcional)
  }
}
```

### Respuesta con Error (400)

```json
{
  "code": 400,
  "estado": false,
  "mensaje": "Error al procesar el pago",
  "error": "Descripción del error"
}
```

---

## 🧪 PRUEBAS

### 1. Probar webhook directamente (cURL)

```bash
curl --location 'https://n8n.salazargroup.cloud/webhook/pago' \
--header 'Content-Type: application/json' \
--data '{
    "accion": "CREAR",
    "timestamp": "2026-01-30T19:05:00.000Z",
    "pago": {
        "id": 999,
        "codigo_reserva": "TEST-001",
        "monto": 100.00,
        "moneda": "USD",
        "descripcion": "Pago de prueba"
    }
}'
```

### 2. Probar creando un pago desde la API

```bash
POST /api/v1/pagos
{
  "proveedor_id": 2,
  "usuario_id": 2,
  "codigo_reserva": "RES-2026-WEBHOOK-TEST",
  "monto": 500.00,
  "moneda": "USD",
  "tipo_medio_pago": "TARJETA",
  "tarjeta_id": 1,
  "descripcion": "Prueba de webhook"
}
```

**Revisar en logs:**

```
INFO: Pago creado: RES-2026-WEBHOOK-TEST - Monto: 500 USD
INFO: Enviando pago 5 al webhook N8N { url: '...', accion: 'CREAR' }
INFO: Pago enviado exitosamente al webhook N8N { pagoId: 5, status: 200 }
```

### 3. Probar actualizando un pago

```bash
PUT /api/v1/pagos/5
{
  "pagado": true
}
```

**Revisar en logs:**

```
INFO: Pago actualizado: ID 5
INFO: Pago 5 actualizado enviado al webhook N8N
```

### 4. Probar eliminando un pago

```bash
DELETE /api/v1/pagos/5
```

**Revisar en logs:**

```
INFO: Pago eliminado: RES-2026-WEBHOOK-TEST - Monto devuelto: 500
INFO: Eliminación de pago 5 enviada al webhook N8N
```

---

## ⚠️ COMPORTAMIENTO

### No Bloquea la Operación

El webhook **nunca bloquea** la operación principal:

| Resultado del Webhook | Acción en API              |
| --------------------- | -------------------------- |
| ✅ Responde 200       | Pago procesado + log INFO  |
| ❌ Responde 400       | Pago procesado + log WARN  |
| ❌ Sin respuesta      | Pago procesado + log ERROR |

**En todos los casos el pago se crea/actualiza/elimina correctamente.**

---

## 📊 LOGS DE EJEMPLO

### Creación exitosa

```
2026-01-30 19:05:00 INFO: Pago creado: RES-2026-004 - Monto: 500 USD
2026-01-30 19:05:00 INFO: Enviando pago 5 al webhook N8N { url: 'https://n8n.salazargroup.cloud/webhook/pago', accion: 'CREAR' }
2026-01-30 19:05:01 INFO: Pago enviado exitosamente al webhook N8N { accion: 'CREAR', pagoId: 5, status: 200 }
```

### Webhook falla (pago igual se crea)

```
2026-01-30 19:05:00 INFO: Pago creado: RES-2026-004 - Monto: 500 USD
2026-01-30 19:05:00 INFO: Enviando pago 5 al webhook N8N {...}
2026-01-30 19:05:15 WARN: Pago 5 creado pero falló envío a webhook N8N: No se pudo conectar con el webhook N8N
```

---

## 🔧 CONFIGURACIÓN

### Archivo: `src/utils/n8n.util.ts`

| Parámetro    | Valor                                         |
| ------------ | --------------------------------------------- |
| `webhookUrl` | `https://n8n.salazargroup.cloud/webhook/pago` |
| `timeout`    | 15000 ms (15 segundos)                        |
| `headers`    | `Content-Type: application/json`              |

### Archivo: `src/services/pagos.service.ts`

El webhook se llama en:

- `createPago()` → acción: `'CREAR'`
- `updatePago()` → acción: `'ACTUALIZAR'`
- `deletePago()` → acción: `'ELIMINAR'`

---

## ✅ CHECKLIST DE TESTING

### Crear Pago

- [ ] POST /pagos - Verificar que llega al webhook
- [ ] Verificar logs con status 200
- [ ] Probar con webhook caído (debe crear pago igual)

### Actualizar Pago

- [ ] PUT /pagos/:id - Verificar que llega al webhook
- [ ] Verificar logs con status 200
- [ ] Verificar que incluye datos actualizados

### Eliminar Pago

- [ ] DELETE /pagos/:id - Verificar que llega al webhook
- [ ] Verificar logs con status 200
- [ ] Verificar que incluye monto_devuelto

---

## 📚 ARCHIVOS MODIFICADOS

| Archivo                          | Cambio                                    |
| -------------------------------- | ----------------------------------------- |
| `src/utils/n8n.util.ts`          | ✅ Agregado método `notificarPagoWebhook` |
| `src/services/pagos.service.ts`  | ✅ Webhook en CREAR, ACTUALIZAR, ELIMINAR |
| `documentacion/WEBHOOK_PAGOS.md` | ✅ Esta documentación                     |

---

**Última actualización:** 2026-01-30 19:08  
**Estado:** ✅ COMPLETAMENTE IMPLEMENTADO
