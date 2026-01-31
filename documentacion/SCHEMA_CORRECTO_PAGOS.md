# ✅ SCHEMA CORRECTO - POST /pagos

## ❌ SCHEMA ANTIGUO (NO USAR)

El que estabas usando:

```json
{
  "monto": 500,
  "moneda": "USD",
  "medio_pago": "TARJETA_CREDITO", // ❌ Debe ser "tipo_medio_pago": "TARJETA"
  "proveedor_id": 1,
  "usuario_id": 2,
  "tarjeta_id": 1,
  "cuenta_id": 0, // ❌ Debe ser "cuenta_bancaria_id" y null
  "observaciones": "esto es una prueba" // ❌ Debe ser "descripcion"
  // ❌ Falta "codigo_reserva" que es OBLIGATORIO
}
```

---

## ✅ SCHEMA CORRECTO (USAR ESTE)

### Pago con TARJETA

```json
{
  "proveedor_id": 2,
  "usuario_id": 2,
  "codigo_reserva": "RES-2026-004",
  "monto": 500.0,
  "moneda": "USD",
  "tipo_medio_pago": "TARJETA",
  "tarjeta_id": 1,
  "clientes_ids": [1],
  "descripcion": "Pago de servicio de guía turística",
  "fecha_esperada_debito": "2026-02-15"
}
```

### Pago con CUENTA_BANCARIA

```json
{
  "proveedor_id": 2,
  "usuario_id": 2,
  "codigo_reserva": "RES-2026-005",
  "monto": 1200.0,
  "moneda": "CAD",
  "tipo_medio_pago": "CUENTA_BANCARIA",
  "cuenta_bancaria_id": 1,
  "clientes_ids": [1],
  "descripcion": "Pago de servicio hotelero"
}
```

---

## 📋 CAMPOS OBLIGATORIOS

| Campo             | Tipo   | Validación                        | Ejemplo        |
| ----------------- | ------ | --------------------------------- | -------------- |
| `proveedor_id`    | number | ID de proveedor activo            | 2              |
| `usuario_id`      | number | ID de usuario activo              | 2              |
| `codigo_reserva`  | string | **Único**, 1-50 caracteres        | "RES-2026-004" |
| `monto`           | number | Mayor a 0                         | 500.00         |
| `moneda`          | string | **Solo "USD" o "CAD"**            | "USD"          |
| `tipo_medio_pago` | string | **"TARJETA" o "CUENTA_BANCARIA"** | "TARJETA"      |

## 📋 CAMPOS CONDICIONALES

| Campo                | Cuándo es obligatorio                  | Ejemplo |
| -------------------- | -------------------------------------- | ------- |
| `tarjeta_id`         | Si tipo_medio_pago = "TARJETA"         | 1       |
| `cuenta_bancaria_id` | Si tipo_medio_pago = "CUENTA_BANCARIA" | 1       |

## 📋 CAMPOS OPCIONALES

| Campo                   | Tipo                | Ejemplo            |
| ----------------------- | ------------------- | ------------------ |
| `clientes_ids`          | array de números    | [1, 2]             |
| `descripcion`           | string              | "Pago de servicio" |
| `fecha_esperada_debito` | string (YYYY-MM-DD) | "2026-02-15"       |

---

## 🔄 COMPARACIÓN

### Lo que enviaste (INCORRECTO)

```json
{
  "monto": 500,
  "moneda": "USD",
  "medio_pago": "TARJETA_CREDITO", // ❌ campo incorrecto
  "proveedor_id": 1,
  "usuario_id": 2,
  "tarjeta_id": 1,
  "cuenta_id": 0, // ❌ campo incorrecto
  "observaciones": "esto es una prueba" // ❌ campo incorrecto
}
```

### Schema correcto

```json
{
  "proveedor_id": 1, // ✅
  "usuario_id": 2, // ✅
  "codigo_reserva": "RES-2026-TEST", // ✅ NUEVO - Obligatorio
  "monto": 500.0, // ✅
  "moneda": "USD", // ✅
  "tipo_medio_pago": "TARJETA", // ✅ (era "medio_pago": "TARJETA_CREDITO")
  "tarjeta_id": 1, // ✅
  "cuenta_bancaria_id": null, // ✅ (era "cuenta_id": 0)
  "descripcion": "esto es una prueba" // ✅ (era "observaciones")
}
```

---

## ⚠️ ERRORES COMUNES

### Error 1: Falta codigo_reserva

```json
{
  "monto": 500
  // ❌ Falta codigo_reserva
}
```

**Error**: "El código de reserva es obligatorio"

✅ **Correcto**:

```json
{
  "codigo_reserva": "RES-2026-TEST-001", // ✅ Siempre obligatorio
  "monto": 500
}
```

### Error 2: tipo_medio_pago incorrecto

```json
{
  "medio_pago": "TARJETA_CREDITO" // ❌ Campo incorrecto
}
```

**Error**: "Invalid option: expected one of \"TARJETA\"|\"CUENTA_BANCARIA\""

✅ **Correcto**:

```json
{
  "tipo_medio_pago": "TARJETA" // ✅ Solo TARJETA o CUENTA_BANCARIA
}
```

### Error 3: Medio de pago mal configurado

```json
{
  "tipo_medio_pago": "TARJETA",
  // ❌ Falta tarjeta_id
  "cuenta_bancaria_id": 1 // ❌ No debe estar
}
```

**Error**: "Debe especificar una tarjeta de crédito"

✅ **Correcto**:

```json
{
  "tipo_medio_pago": "TARJETA",
  "tarjeta_id": 1, // ✅ Obligatorio si es TARJETA
  "cuenta_bancaria_id": null // ✅ null (no omitir el campo)
}
```

---

## 🚀 CURL COMMAND

```bash
curl -X POST http://localhost:3000/api/v1/pagos \
  -H "Authorization: Bearer TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "proveedor_id": 2,
    "usuario_id": 2,
    "codigo_reserva": "RES-2026-004",
    "monto": 500.00,
    "moneda": "USD",
    "tipo_medio_pago": "TARJETA",
    "tarjeta_id": 1,
    "clientes_ids": [1],
    "descripcion": "Pago de servicio de guía turística",
    "fecha_esperada_debito": "2026-02-15"
  }'
```

---

## 🎯 VALIDACIONES CRÍTICAS

### Al crear con TARJETA:

- ✅ Verifica saldo suficiente
- ✅ **Descuenta el monto** del saldo de la tarjeta
- ❌ Si no hay saldo: Error 409 con saldo disponible

### Al crear con CUENTA_BANCARIA:

- ✅ Solo registra el pago
- ✅ **NO descuenta** nada

### Código de reserva:

- ✅ Debe ser único
- ❌ Si existe: Error 409 "Ya existe un pago con ese código de reserva"

---

## 📝 CAMBIOS REALIZADOS

1. ✅ Actualizada documentación de Swagger en `src/routes/pagos.routes.ts`
2. ✅ Schema POST ahora muestra campos correctos
3. ✅ Schema PUT ahora muestra campos correctos
4. ✅ Eliminados campos obsoletos del Swagger
5. ✅ Comentada ruta `/con-pdf` (temporal)

---

**Última actualización:** 2026-01-30 18:50  
**Estado:** ✅ SWAGGER ACTUALIZADO  
**Swagger URL:** http://localhost:3000/api-docs
