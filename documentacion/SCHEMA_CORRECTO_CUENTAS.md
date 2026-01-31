# ✅ SCHEMA CORRECTO - POST /cuentas

## ❌ SCHEMA ANTIGUO (NO USAR)

El que estabas usando:

```json
{
  "nombre_banco": "TD Canada Trust",
  "numero_cuenta": "1234567890", // ❌ Ya no existe
  "tipo_cuenta": "CORRIENTE", // ❌ Ya no existe
  "titular": "Terra Canada Inc.", // ❌ Ya no existe
  "moneda": "CAD",
  "sucursal": "Downtown Toronto", // ❌ Ya no existe
  "swift": "TDOMCATTTOR" // ❌ Ya no existe
}
```

**Este schema es del modelo antiguo y ya NO funciona.**

---

## ✅ SCHEMA CORRECTO (USAR ESTE)

```json
{
  "nombre_banco": "TD Canada Trust",
  "nombre_cuenta": "Business Checking Account",
  "ultimos_4_digitos": "5678",
  "moneda": "CAD"
}
```

---

## 📋 CAMPOS OBLIGATORIOS

| Campo               | Tipo   | Validación                | Ejemplo                     |
| ------------------- | ------ | ------------------------- | --------------------------- |
| `nombre_banco`      | string | 1-100 caracteres          | "TD Canada Trust"           |
| `nombre_cuenta`     | string | 1-100 caracteres          | "Business Checking Account" |
| `ultimos_4_digitos` | string | **Exactamente 4 dígitos** | "5678"                      |
| `moneda`            | string | **Solo "USD" o "CAD"**    | "CAD"                       |

## 📋 CAMPOS OPCIONALES

| Campo    | Tipo    | Default | Ejemplo |
| -------- | ------- | ------- | ------- |
| `activo` | boolean | true    | true    |

---

## 🧪 EJEMPLOS CORRECTOS

### Ejemplo 1: Cuenta CAD

```json
{
  "nombre_banco": "TD Canada Trust",
  "nombre_cuenta": "Business Checking Account",
  "ultimos_4_digitos": "5678",
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

### Ejemplo 3: Con todos los campos

```json
{
  "nombre_banco": "Scotiabank",
  "nombre_cuenta": "Savings Account Premium",
  "ultimos_4_digitos": "1234",
  "moneda": "CAD",
  "activo": true
}
```

---

## 🔄 COMPARACIÓN

### ANTES (Lo que enviaste - Incorrecto)

```json
{
  "nombre_banco": "TD Canada Trust",
  "numero_cuenta": "1234567890", // ❌
  "tipo_cuenta": "CORRIENTE", // ❌
  "titular": "Terra Canada Inc.", // ❌
  "moneda": "CAD", // ✅
  "sucursal": "Downtown Toronto", // ❌
  "swift": "TDOMCATTTOR" // ❌
}
```

### DESPUÉS (Schema correcto)

```json
{
  "nombre_banco": "TD Canada Trust", // ✅
  "nombre_cuenta": "Business Account", // ✅ (era "titular")
  "ultimos_4_digitos": "7890", // ✅ (últimos 4 de "1234567890")
  "moneda": "CAD" // ✅
}
```

---

## 🚀 CURL COMMAND

```bash
curl -X POST http://localhost:3000/api/v1/cuentas \
  -H "Authorization: Bearer TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_banco": "TD Canada Trust",
    "nombre_cuenta": "Business Checking Account",
    "ultimos_4_digitos": "5678",
    "moneda": "CAD"
  }'
```

---

## 📊 RESPUESTA ESPERADA (201 Created)

```json
{
  "success": true,
  "message": "Cuenta creada",
  "data": {
    "id": 1,
    "nombre_banco": "TD Canada Trust",
    "nombre_cuenta": "Business Checking Account",
    "ultimos_4_digitos": "5678",
    "moneda": "CAD",
    "activo": true,
    "fecha_creacion": "2026-01-30T18:28:00Z"
  }
}
```

---

## ⚠️ CAMBIOS IMPORTANTES

| Campo Antiguo   | Campo Nuevo         | Notas                          |
| --------------- | ------------------- | ------------------------------ |
| `numero_cuenta` | `ultimos_4_digitos` | Solo guardar últimos 4 dígitos |
| `titular`       | `nombre_cuenta`     | Cambio de propósito del campo  |
| `tipo_cuenta`   | ❌ ELIMINADO        | Ya no existe                   |
| `sucursal`      | ❌ ELIMINADO        | Ya no existe                   |
| `swift`         | ❌ ELIMINADO        | Ya no existe                   |
| `moneda` (EUR)  | `moneda` (USD/CAD)  | Solo USD o CAD                 |

---

## 📝 CAMBIOS REALIZADOS

1. ✅ Actualizada documentación de Swagger en `src/routes/cuentas.routes.ts`
2. ✅ Schema POST ahora muestra campos correctos
3. ✅ Schema PUT ahora muestra campos correctos
4. ✅ Eliminados campos obsoletos (numero_cuenta, tipo_cuenta, titular, sucursal, swift)

---

## 🎯 SIGUIENTE PASO

Usa el **schema correcto** para crear tu cuenta:

```json
{
  "nombre_banco": "TD Canada Trust",
  "nombre_cuenta": "Business Checking Account",
  "ultimos_4_digitos": "5678",
  "moneda": "CAD"
}
```

**Última actualización:** 2026-01-30 18:28  
**Estado:** ✅ SWAGGER ACTUALIZADO  
**Swagger URL:** http://localhost:3000/api-docs
