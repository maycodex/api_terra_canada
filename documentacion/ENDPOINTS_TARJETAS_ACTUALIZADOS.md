# 💳 ENDPOINTS ACTUALIZADOS - TARJETAS DE CRÉDITO

## Fecha: 2026-01-30

## Estado: ✅ Refactorizado para usar funciones PostgreSQL

---

## 📌 Cambios Importantes

### ❌ Campos ANTIGUOS (ya NO se usan):

- `numero_tarjeta_encriptado`
- `titular`
- `tipo` (enum)
- `saldo_asignado`
- `cliente_id`
- `fecha_vencimiento`

### ✅ Campos NUEVOS (funciones PostgreSQL):

- `nombre_titular`
- `ultimos_4_digitos` (exactamente 4 dígitos)
- `moneda` (USD | CAD)
- `limite_mensual`
- `tipo_tarjeta` (string, ej: "Visa", "Mastercard")
- `saldo_disponible` (calculado automáticamente)

---

## 🔍 GET /tarjetas - Listar todas las tarjetas

**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

### Request

```
GET /api/v1/tarjetas
```

### Response 200 - Éxito

```json
{
  "success": true,
  "message": "Tarjetas obtenidas",
  "data": [
    {
      "id": 1,
      "nombre_titular": "Juan Carlos Pérez",
      "ultimos_4_digitos": "1234",
      "moneda": "USD",
      "limite_mensual": 6000.0,
      "saldo_disponible": 4900.0,
      "tipo_tarjeta": "Visa Platinum",
      "activo": true,
      "porcentaje_uso": 18.33,
      "fecha_creacion": "2026-01-28T23:50:24.124396-04:00",
      "fecha_actualizacion": "2026-01-29T01:13:37.528359-04:00"
    }
  ]
}
```

---

## 🔍 GET /tarjetas/:id - Obtener tarjeta específica

**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

### Request

```
GET /api/v1/tarjetas/1
```

### Response 200 - Éxito

```json
{
  "success": true,
  "message": "Tarjeta obtenida",
  "data": {
    "id": 1,
    "nombre_titular": "Juan Carlos Pérez",
    "ultimos_4_digitos": "1234",
    "moneda": "USD",
    "limite_mensual": 6000.0,
    "saldo_disponible": 4900.0,
    "tipo_tarjeta": "Visa Platinum",
    "activo": true,
    "porcentaje_uso": 18.33,
    "fecha_creacion": "2026-01-28T23:50:24.124396-04:00",
    "fecha_actualizacion": "2026-01-29T01:13:37.528359-04:00"
  }
}
```

### Response 404 - No encontrada

```json
{
  "success": false,
  "message": "Tarjeta no encontrada"
}
```

---

## ➕ POST /tarjetas - Crear nueva tarjeta

**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

### Request Body

```json
{
  "nombre_titular": "Juan Pérez",
  "ultimos_4_digitos": "1234",
  "moneda": "USD",
  "limite_mensual": 5000.0,
  "tipo_tarjeta": "Visa",
  "activo": true
}
```

### Validaciones

- `nombre_titular`: string, mínimo 1 carácter, máximo 100
- `ultimos_4_digitos`: string, exactamente 4 dígitos numéricos
- `moneda`: enum ["USD", "CAD"]
- `limite_mensual`: number, mayor a 0
- `tipo_tarjeta`: string, opcional (default: "Visa")
- `activo`: boolean, opcional (default: true)

### Response 201 - Creada exitosamente

```json
{
  "success": true,
  "message": "Tarjeta creada",
  "data": {
    "id": 2,
    "nombre_titular": "Juan Pérez",
    "ultimos_4_digitos": "1234",
    "moneda": "USD",
    "limite_mensual": 5000.0,
    "saldo_disponible": 5000.0,
    "tipo_tarjeta": "Visa",
    "activo": true,
    "fecha_creacion": "2026-01-30T17:52:00Z"
  }
}
```

### Response 400 - Validación fallida

```json
{
  "success": false,
  "message": "Error de validación",
  "errors": [
    {
      "field": "ultimos_4_digitos",
      "message": "Deben ser exactamente 4 dígitos numéricos"
    }
  ]
}
```

---

## 🔄 PUT /tarjetas/:id - Actualizar tarjeta

**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

### Request Body (todos los campos opcionales)

```json
{
  "nombre_titular": "Juan Carlos Pérez",
  "limite_mensual": 6000.0,
  "tipo_tarjeta": "Visa Platinum",
  "activo": true
}
```

### Notas Importantes

- Si se cambia `limite_mensual`, el saldo disponible se ajusta proporcionalmente
- NO se puede cambiar `ultimos_4_digitos` ni `moneda` después de crear la tarjeta

### Response 200 - Actualizada exitosamente

```json
{
  "success": true,
  "message": "Tarjeta actualizada",
  "data": {
    "id": 1,
    "nombre_titular": "Juan Carlos Pérez",
    "ultimos_4_digitos": "1234",
    "moneda": "USD",
    "limite_mensual": 6000.0,
    "saldo_disponible": 4900.0,
    "tipo_tarjeta": "Visa Platinum",
    "activo": true,
    "porcentaje_uso": 18.33,
    "fecha_actualizacion": "2026-01-30T17:52:00Z"
  }
}
```

### Response 404 - No encontrada

```json
{
  "success": false,
  "message": "Tarjeta no encontrada"
}
```

---

## ❌ DELETE /tarjetas/:id - Eliminar tarjeta (soft delete)

**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN

### Request

```
DELETE /api/v1/tarjetas/1
```

### Response 200 - Eliminada exitosamente

```json
{
  "success": true,
  "message": "Tarjeta eliminada",
  "data": {
    "nombre_titular": "Juan Pérez",
    "ultimos_4_digitos": "1234"
  }
}
```

### Response 409 - Conflicto (tiene pagos asociados)

```json
{
  "success": false,
  "message": "No se puede eliminar la tarjeta porque tiene pagos asociados"
}
```

### Response 404 - No encontrada

```json
{
  "success": false,
  "message": "Tarjeta no encontrada"
}
```

---

## 📊 Campos Calculados Automáticamente

### `saldo_disponible`

- Se inicializa igual a `limite_mensual` al crear la tarjeta
- Se ajusta automáticamente cuando se cambia `limite_mensual`
- Se reduce cuando se realizan pagos

### `porcentaje_uso`

- Fórmula: `((limite_mensual - saldo_disponible) / limite_mensual) * 100`
- Redondeado a 2 decimales
- Muestra qué porcentaje del límite se ha usado

---

## 🔧 Funciones PostgreSQL Utilizadas

```sql
-- GET: todas o una específica
SELECT tarjetas_credito_get();           -- Todas
SELECT tarjetas_credito_get(1);          -- Una específica

-- POST: crear nueva
SELECT tarjetas_credito_post(
  'Juan Pérez',     -- nombre_titular
  '1234',           -- ultimos_4_digitos
  'USD',            -- moneda
  5000.00,          -- limite_mensual
  'Visa',           -- tipo_tarjeta
  true              -- activo
);

-- PUT: actualizar
SELECT tarjetas_credito_put(
  1,                      -- id
  'Juan Carlos Pérez',    -- nombre_titular
  6000.00,                -- limite_mensual
  'Visa Platinum',        -- tipo_tarjeta
  NULL                    -- activo (NULL = no cambiar)
);

-- DELETE: eliminar
SELECT tarjetas_credito_delete(1);
```

---

## ⚠️ Endpoints ELIMINADOS

### ❌ POST /tarjetas/:id/recargar

Este endpoint fue eliminado porque las funciones PostgreSQL no lo soportan.  
Para "recargar" una tarjeta, usar PUT para aumentar el `limite_mensual`.

---

## 🧪 Ejemplos de Prueba con cURL

### Crear tarjeta

```bash
curl -X POST http://localhost:3000/api/v1/tarjetas \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_titular": "Juan Pérez",
    "ultimos_4_digitos": "1234",
    "moneda": "USD",
    "limite_mensual": 5000.00,
    "tipo_tarjeta": "Visa"
  }'
```

### Obtener todas las tarjetas

```bash
curl -X GET http://localhost:3000/api/v1/tarjetas \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Actualizar tarjeta

```bash
curl -X PUT http://localhost:3000/api/v1/tarjetas/1 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "limite_mensual": 6000.00,
    "tipo_tarjeta": "Visa Platinum"
  }'
```

### Eliminar tarjeta

```bash
curl -X DELETE http://localhost:3000/api/v1/tarjetas/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```
