# 📄 ENDPOINTS DE DOCUMENTOS - Webhooks N8N

## Fecha: 2026-01-30

## Estado: ✅ IMPLEMENTADO

---

## 📋 RESUMEN DE ENDPOINTS (Todos en módulo Pagos)

| #   | Método | Endpoint                      | Descripción             | Webhook        |
| --- | ------ | ----------------------------- | ----------------------- | -------------- |
| 1   | POST   | `/pagos/documento-estado`     | Enviar doc de pago      | documento_pago |
| 2   | POST   | `/pagos/subir-facturas`       | Subir hasta 3 facturas  | docu           |
| 3   | POST   | `/pagos/subir-extracto-banco` | Subir extracto bancario | docu           |

---

## 🔗 WEBHOOKS DE N8N

| Webhook            | URL                                                     |
| ------------------ | ------------------------------------------------------- |
| **documento_pago** | `https://n8n.salazargroup.cloud/webhook/documento_pago` |
| **docu**           | `https://n8n.salazargroup.cloud/webhook/docu`           |

---

## 🔑 CAMPO COMÚN: `usuario_id`

**Todos los endpoints requieren el campo `usuario_id`** que identifica al usuario que está logueado y realiza la acción. Este campo es enviado por el front y se reenvía al webhook para trazabilidad.

---

## 📌 ENDPOINT 1: Enviar Documento de Pago

### `POST /api/v1/pagos/documento-estado`

### 📋 FLUJO

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  FRONTEND   │────►│   BACKEND   │────►│    N8N      │────►│  RESPUESTA  │
│ pdf+id_pago │     │ + codigo    │     │  Procesa    │     │  Al Front   │
│ + user_id   │     │   _reserva  │     │  Documento  │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Request del Front

```json
{
  "pdf": "JVBERi0xLjQK...",
  "id_pago": 2,
  "usuario_id": 5
}
```

### Lo que el Backend envía al Webhook

```json
{
  "pdf": "JVBERi0xLjQK...",
  "id_pago": 2,
  "codigo_reserva": "23445634",
  "usuario_id": 5
}
```

### Respuesta del Webhook (se retorna al Front)

```json
{
  "codigo": "200",
  "mensaje": "el codigo de reserva fue encontrado"
}
```

### cURL Ejemplo

```bash
curl -X POST http://localhost:3000/api/v1/pagos/documento-estado \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pdf": "JVBERi0xLjQK...",
    "id_pago": 2,
    "usuario_id": 5
  }'
```

---

## 📌 ENDPOINT 2: Subir Múltiples Facturas

### `POST /api/v1/pagos/subir-facturas`

### 📋 FLUJO

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  FRONTEND   │────►│   BACKEND   │────►│    N8N      │────►│  RESPUESTA  │
│  modulo +   │     │  Reenvía    │     │  Procesa    │     │  Códigos    │
│  user_id +  │     │  al webhook │     │  PDFs       │     │  Encontrados│
│  facturas   │     │             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Request del Front

```json
{
  "modulo": "factura",
  "usuario_id": 5,
  "facturas": [
    { "pdf": "base64...", "proveedor_id": 2 },
    { "pdf": "base64...", "proveedor_id": 3 },
    { "pdf": "base64...", "proveedor_id": 4 }
  ]
}
```

### Lo que el Backend envía al Webhook

```json
{
  "modulo": "factura",
  "usuario_id": 5,
  "facturas": [
    { "pdf": "base64...", "proveedor_id": 2 },
    { "pdf": "base64...", "proveedor_id": 3 }
  ]
}
```

### Respuesta del Webhook (se retorna al Front)

```json
{
  "codigo": 200,
  "codigos_reserva": [324, 234234]
}
```

### ⚠️ VALIDACIONES

- ✅ Mínimo 1 factura
- ❌ Máximo 3 facturas
- ✅ `usuario_id` obligatorio

### cURL Ejemplo

```bash
curl -X POST http://localhost:3000/api/v1/pagos/subir-facturas \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "modulo": "factura",
    "usuario_id": 5,
    "facturas": [
      {"pdf": "JVBERi0xLjQK...", "proveedor_id": 2},
      {"pdf": "JVBERi0xLjQK...", "proveedor_id": 3}
    ]
  }'
```

---

## 📌 ENDPOINT 3: Subir Extracto de Banco

### `POST /api/v1/pagos/subir-extracto-banco`

### 📋 FLUJO

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  FRONTEND   │────►│   BACKEND   │────►│    N8N      │────►│  RESPUESTA  │
│  pdf        │     │ + modulo    │     │  Procesa    │     │  Códigos    │
│  + user_id  │     │   Banco     │     │  Extracto   │     │  Encontrados│
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Request del Front

```json
{
  "pdf": "JVBERi0xLjQK...",
  "usuario_id": 5
}
```

### Lo que el Backend envía al Webhook

```json
{
  "modulo": "Banco",
  "pdf": "JVBERi0xLjQK...",
  "usuario_id": 5
}
```

### Respuesta del Webhook (se retorna al Front)

```json
{
  "codigo": 200,
  "codigos_reserva": [213423, 23423, 234234]
}
```

### cURL Ejemplo

```bash
curl -X POST http://localhost:3000/api/v1/pagos/subir-extracto-banco \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pdf": "JVBERi0xLjQK...",
    "usuario_id": 5
  }'
```

---

## 📚 ARCHIVOS MODIFICADOS

| Archivo                                         | Descripción                           |
| ----------------------------------------------- | ------------------------------------- |
| `src/schemas/documentos-pago.schema.ts`         | Schemas con `usuario_id` obligatorio  |
| `src/controllers/documentos-pago.controller.ts` | Controlador con 3 métodos             |
| `src/routes/pagos.routes.ts`                    | Todos los endpoints en módulo Pagos   |
| `src/utils/n8n.util.ts`                         | 3 métodos de webhook con `usuario_id` |

---

## ✅ CHECKLIST DE TESTING

### Endpoint 1: documento-estado

- [ ] POST /pagos/documento-estado con pdf + id_pago + usuario_id
- [ ] Verificar que el webhook recibe pdf, id_pago, codigo_reserva, usuario_id
- [ ] Verificar que la respuesta del webhook se retorna al front

### Endpoint 2: subir-facturas

- [ ] POST /pagos/subir-facturas con usuario_id + 1 factura
- [ ] POST /pagos/subir-facturas con usuario_id + 3 facturas
- [ ] Verificar error si envía más de 3
- [ ] Verificar respuesta con codigos_reserva

### Endpoint 3: subir-extracto-banco

- [ ] POST /pagos/subir-extracto-banco con PDF + usuario_id
- [ ] Verificar que el webhook recibe modulo: "Banco" + usuario_id
- [ ] Verificar respuesta con codigos_reserva

---

## 🧪 SWAGGER

Todos los endpoints están documentados en Swagger bajo el tag **[Pagos]**:
**URL:** http://localhost:3000/api-docs

---

**Última actualización:** 2026-01-30 22:05  
**Estado:** ✅ IMPLEMENTADO - LISTO PARA TESTING
