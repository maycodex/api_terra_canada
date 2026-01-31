# 🏦 ENDPOINTS - CUENTAS BANCARIAS

## Fecha: 2026-01-30

## Estado: ✅ Refactorizado para usar funciones PostgreSQL

---

## 📌 SCHEMA CORRECTO

### Campos Obligatorios (POST)

| Campo               | Tipo   | Validación                | Ejemplo                        |
| ------------------- | ------ | ------------------------- | ------------------------------ |
| `nombre_banco`      | string | Mínimo 1, máximo 100      | "Banco Nacional de Canadá"     |
| `nombre_cuenta`     | string | Mínimo 1, máximo 100      | "Cuenta Corriente Empresarial" |
| `ultimos_4_digitos` | string | **Exactamente 4 dígitos** | "5678"                         |
| `moneda`            | string | **Solo "USD" o "CAD"**    | "CAD"                          |

### Campos Opcionales

| Campo    | Tipo    | Default | Ejemplo |
| -------- | ------- | ------- | ------- |
| `activo` | boolean | true    | true    |

---

## 🔍 GET /cuentas - Obtener todas las cuentas

**Endpoint:** `GET /api/v1/cuentas`  
**Autenticación:** Bearer Token  
**Roles:** Todos

### Request

```bash
GET /api/v1/cuentas
Authorization: Bearer YOUR_TOKEN
```

### Response 200 - Éxito

```json
{
  "success": true,
  "message": "Cuentas obtenidas",
  "data": [
    {
      "id": 1,
      "nombre_banco": "Banco Nacional de Canadá",
      "nombre_cuenta": "Cuenta Empresarial Premium",
      "ultimos_4_digitos": "5678",
      "moneda": "CAD",
      "activo": true,
      "fecha_creacion": "2026-01-30T18:00:00Z",
      "fecha_actualizacion": "2026-01-30T18:00:00Z"
    }
  ]
}
```

---

## 🔍 GET /cuentas/:id - Obtener cuenta específica

**Endpoint:** `GET /api/v1/cuentas/:id`  
**Autenticación:** Bearer Token  
**Roles:** Todos

### Request

```bash
GET /api/v1/cuentas/1
Authorization: Bearer YOUR_TOKEN
```

### Response 200 - Éxito

```json
{
  "success": true,
  "message": "Cuenta obtenida",
  "data": {
    "id": 1,
    "nombre_banco": "Banco Nacional de Canadá",
    "nombre_cuenta": "Cuenta Empresarial Premium",
    "ultimos_4_digitos": "5678",
    "moneda": "CAD",
    "activo": true,
    "fecha_creacion": "2026-01-30T18:00:00Z",
    "fecha_actualizacion": "2026-01-30T18:00:00Z"
  }
}
```

### Response 404 - No encontrada

```json
{
  "success": false,
  "message": "Cuenta bancaria no encontrada"
}
```

---

## ➕ POST /cuentas - Crear nueva cuenta

**Endpoint:** `POST /api/v1/cuentas`  
**Autenticación:** Bearer Token  
**Roles:** ADMIN, SUPERVISOR

### Request Body

```json
{
  "nombre_banco": "Banco Nacional",
  "nombre_cuenta": "Cuenta Corriente Empresarial",
  "ultimos_4_digitos": "5678",
  "moneda": "CAD",
  "activo": true
}
```

### Response 201 - Creada exitosamente

```json
{
  "success": true,
  "message": "Cuenta creada",
  "data": {
    "id": 2,
    "nombre_banco": "Banco Nacional",
    "nombre_cuenta": "Cuenta Corriente Empresarial",
    "ultimos_4_digitos": "5678",
    "moneda": "CAD",
    "activo": true,
    "fecha_creacion": "2026-01-30T18:20:00Z"
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

## 🔄 PUT /cuentas/:id - Actualizar cuenta

**Endpoint:** `PUT /api/v1/cuentas/:id`  
**Autenticación:** Bearer Token  
**Roles:** ADMIN, SUPERVISOR

### Request Body (todos opcionales)

```json
{
  "nombre_banco": "Banco Nacional de Canadá",
  "nombre_cuenta": "Cuenta Empresarial Premium",
  "activo": true
}
```

### Notas Importantes

- NO se puede cambiar `ultimos_4_digitos` ni `moneda` después de crear
- Todos los campos son opcionales

### Response 200 - Actualizada exitosamente

```json
{
  "success": true,
  "message": "Cuenta actualizada",
  "data": {
    "id": 1,
    "nombre_banco": "Banco Nacional de Canadá",
    "nombre_cuenta": "Cuenta Empresarial Premium",
    "ultimos_4_digitos": "5678",
    "moneda": "CAD",
    "activo": true,
    "fecha_creacion": "2026-01-30T18:00:00Z",
    "fecha_actualizacion": "2026-01-30T18:22:00Z"
  }
}
```

### Response 404 - No encontrada

```json
{
  "success": false,
  "message": "Cuenta bancaria no encontrada"
}
```

---

## ❌ DELETE /cuentas/:id - Eliminar cuenta

**Endpoint:** `DELETE /api/v1/cuentas/:id`  
**Autenticación:** Bearer Token  
**Roles:** ADMIN

### Request

```bash
DELETE /api/v1/cuentas/1
Authorization: Bearer YOUR_TOKEN
```

### Response 200 - Eliminada exitosamente

```json
{
  "success": true,
  "message": "Cuenta eliminada",
  "data": {
    "nombre_cuenta": "Cuenta Corriente Empresarial",
    "nombre_banco": "Banco Nacional"
  }
}
```

### Response 409 - Conflicto (tiene pagos asociados)

```json
{
  "success": false,
  "message": "No se puede eliminar la cuenta porque tiene pagos asociados"
}
```

### Response 404 - No encontrada

```json
{
  "success": false,
  "message": "Cuenta bancaria no encontrada"
}
```

---

## 🧪 EJEMPLOS DE PRUEBA

### Ejemplo 1: Cuenta CAD

```json
{
  "nombre_banco": "TD Canada Trust",
  "nombre_cuenta": "Business Checking Account",
  "ultimos_4_digitos": "1234",
  "moneda": "CAD"
}
```

### Ejemplo 2: Cuenta USD

```json
{
  "nombre_banco": "Royal Bank of Canada",
  "nombre_cuenta": "USD Corporate Account",
  "ultimos_4_digitos": "9876",
  "moneda": "USD"
}
```

### Ejemplo 3: Cuenta inactiva (crear desactivada)

```json
{
  "nombre_banco": "Scotiabank",
  "nombre_cuenta": "Cuenta Temporal",
  "ultimos_4_digitos": "5555",
  "moneda": "CAD",
  "activo": false
}
```

---

## ⚠️ ERRORES COMUNES

### Error 1: ultimos_4_digitos inválido

```json
{
  "ultimos_4_digitos": "12" // ❌ Solo 2 dígitos
}
```

**Error**: "Los últimos 4 dígitos deben ser exactamente 4 números"

```json
{
  "ultimos_4_digitos": "abcd" // ❌ No son números
}
```

**Error**: "Deben ser exactamente 4 dígitos numéricos"

✅ **Correcto**:

```json
{
  "ultimos_4_digitos": "5678"
}
```

### Error 2: Moneda inválida

```json
{
  "moneda": "EUR" // ❌ Solo USD o CAD
}
```

**Error**: "Invalid option: expected one of \"USD\"|\"CAD\""

✅ **Correcto**:

```json
{
  "moneda": "CAD" // ✅ o "USD"
}
```

### Error 3: Campo obligatorio faltante

```json
{
  "nombre_banco": "TD Bank"
  // ❌ Falta nombre_cuenta
}
```

**Error**: "El nombre de la cuenta es obligatorio"

---

## 🚀 CURL COMMANDS

### Crear cuenta

```bash
curl -X POST http://localhost:3000/api/v1/cuentas \
  -H "Authorization: Bearer TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_banco": "Banco Nacional",
    "nombre_cuenta": "Cuenta Corriente Empresarial",
    "ultimos_4_digitos": "5678",
    "moneda": "CAD"
  }'
```

### Obtener todas las cuentas

```bash
curl -X GET http://localhost:3000/api/v1/cuentas \
  -H "Authorization: Bearer TU_TOKEN"
```

### Obtener cuenta específica

```bash
curl -X GET http://localhost:3000/api/v1/cuentas/1 \
  -H "Authorization: Bearer TU_TOKEN"
```

### Actualizar cuenta

```bash
curl -X PUT http://localhost:3000/api/v1/cuentas/1 \
  -H "Authorization: Bearer TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_banco": "Banco Nacional de Canadá",
    "nombre_cuenta": "Cuenta Empresarial Premium"
  }'
```

### Eliminar cuenta

```bash
curl -X DELETE http://localhost:3000/api/v1/cuentas/1 \
  -H "Authorization: Bearer TU_TOKEN"
```

---

## 📊 FUNCIONES POSTGRESQL UTILIZADAS

```sql
-- GET: todas o una específica
SELECT cuentas_bancarias_get();        -- Todas
SELECT cuentas_bancarias_get(1);       -- Una específica

-- POST: crear nueva
SELECT cuentas_bancarias_post(
  'Banco Nacional',                   -- nombre_banco
  'Cuenta Corriente Empresarial',     -- nombre_cuenta
  '5678',                              -- ultimos_4_digitos
  'CAD',                               -- moneda
  true                                 -- activo
);

-- PUT: actualizar
SELECT cuentas_bancarias_put(
  1,                                   -- id
  'Banco Nacional de Canadá',         -- nombre_banco
  'Cuenta Empresarial Premium',       -- nombre_cuenta
  NULL                                 -- activo (NULL = no cambiar)
);

-- DELETE: eliminar
SELECT cuentas_bancarias_delete(1);
```

---

## 🔄 DIFERENCIAS CON SCHEMA ANTIGUO

| Campo Antiguo              | Campo Nuevo         | Cambio                    |
| -------------------------- | ------------------- | ------------------------- |
| `numero_cuenta_encriptado` | `ultimos_4_digitos` | ✅ Solo últimos 4 dígitos |
| `tipo_cuenta` (ENUM)       | ❌ ELIMINADO        | Ya no existe              |
| `titular`                  | `nombre_cuenta`     | ✅ Cambio de nombre       |
| `cliente_id`               | ❌ ELIMINADO        | Ya no se usa              |
| ❌ NO EXISTÍA              | `moneda`            | ✅ NUEVO campo            |

---

## ⚠️ BREAKING CHANGES

### Campos Eliminados

- ❌ `numero_cuenta_encriptado` → Ahora es `ultimos_4_digitos`
- ❌ `tipo_cuenta` → Ya no existe
- ❌ `titular` → Ahora es `nombre_cuenta`
- ❌ `cliente_id` → Ya no se requiere

### Campos Nuevos

- ✅ `moneda` - OBLIGATORIO (USD o CAD)
- ✅ `ultimos_4_digitos` - OBLIGATORIO (exactamente 4 dígitos)
- ✅ `nombre_cuenta` - OBLIGATORIO (descripción de la cuenta)

---

## 📝 CHECKLIST DE TESTING

- [ ] GET /cuentas - Obtener todas
- [ ] GET /cuentas/:id - Obtener específica
- [ ] POST /cuentas - Crear con moneda USD
- [ ] POST /cuentas - Crear con moneda CAD
- [ ] PUT /cuentas/:id - Actualizar
- [ ] DELETE /cuentas/:id - Eliminar
- [ ] Validar error con ultimos_4_digitos inválido
- [ ] Validar error con moneda inválida
- [ ] Validar error al eliminar con pagos asociados

---

**Última actualización:** 2026-01-30 18:22  
**Versión:** 1.0.0  
**Estado:** ✅ LISTO PARA TESTING
