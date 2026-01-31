# ✅ SCHEMA CORRECTO - POST /tarjetas

## ❌ SCHEMA ANTIGUO (NO USAR)

```json
{
  "numero_tarjeta": "4111111111111111",
  "titular": "John Doe",
  "fecha_vencimiento": "2025-12-31",
  "cvv": "123",
  "tipo": "VISA",
  "banco_emisor": "TD Bank",
  "limite_credito": 10000
}
```

**Este schema ya NO funciona**. Fue el schema antiguo que estaba en Swagger.

---

## ✅ SCHEMA CORRECTO (USAR ESTE)

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

---

## 📋 CAMPOS OBLIGATORIOS

| Campo               | Tipo   | Validación                          | Ejemplo      |
| ------------------- | ------ | ----------------------------------- | ------------ |
| `nombre_titular`    | string | Mínimo 1 carácter, máximo 100       | "Juan Pérez" |
| `ultimos_4_digitos` | string | **Exactamente 4 dígitos numéricos** | "1234"       |
| `moneda`            | string | **Solo "USD" o "CAD"**              | "USD"        |
| `limite_mensual`    | number | **Mayor a 0**                       | 5000.00      |

## 📋 CAMPOS OPCIONALES

| Campo          | Tipo    | Default | Ejemplo         |
| -------------- | ------- | ------- | --------------- |
| `tipo_tarjeta` | string  | "Visa"  | "Visa Platinum" |
| `activo`       | boolean | true    | true            |

---

## 🧪 EJEMPLOS DE PRUEBA

### Ejemplo 1: Tarjeta USD básica

```json
{
  "nombre_titular": "María García",
  "ultimos_4_digitos": "5678",
  "moneda": "USD",
  "limite_mensual": 3000.0
}
```

### Ejemplo 2: Tarjeta CAD con tipo específico

```json
{
  "nombre_titular": "Pierre Dubois",
  "ultimos_4_digitos": "9012",
  "moneda": "CAD",
  "limite_mensual": 8000.0,
  "tipo_tarjeta": "Mastercard Platinum",
  "activo": true
}
```

### Ejemplo 3: Tarjeta con límite alto

```json
{
  "nombre_titular": "Business Account",
  "ultimos_4_digitos": "3456",
  "moneda": "USD",
  "limite_mensual": 50000.0,
  "tipo_tarjeta": "Visa Business"
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

**Error**: "Deben ser exactamente 4 dígitos numéricos"

```json
{
  "ultimos_4_digitos": "abcd" // ❌ No son números
}
```

**Error**: "Deben ser exactamente 4 dígitos numéricos"

✅ **Correcto**:

```json
{
  "ultimos_4_digitos": "1234" // ✅ Exactamente 4 dígitos
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
  "moneda": "USD" // ✅ o "CAD"
}
```

### Error 3: Límite mensual inválido

```json
{
  "limite_mensual": 0 // ❌ Debe ser mayor a 0
}
```

**Error**: "El límite mensual debe ser mayor a 0"

✅ **Correcto**:

```json
{
  "limite_mensual": 1000.0 // ✅ Cualquier número > 0
}
```

---

## 🔄 SCHEMA PARA PUT /tarjetas/:id

Todos los campos son opcionales en PUT:

```json
{
  "nombre_titular": "Juan Carlos Pérez",
  "limite_mensual": 6000.0,
  "tipo_tarjeta": "Visa Platinum",
  "activo": true
}
```

**Nota**: NO puedes cambiar `ultimos_4_digitos` ni `moneda` después de crear la tarjeta.

---

## 📊 RESPUESTA ESPERADA (201 Created)

```json
{
  "success": true,
  "message": "Tarjeta creada",
  "data": {
    "id": 1,
    "nombre_titular": "Juan Pérez",
    "ultimos_4_digitos": "1234",
    "moneda": "USD",
    "limite_mensual": 5000.0,
    "saldo_disponible": 5000.0,
    "tipo_tarjeta": "Visa",
    "activo": true,
    "porcentaje_uso": 0.0,
    "fecha_creacion": "2026-01-30T18:15:00Z",
    "fecha_actualizacion": "2026-01-30T18:15:00Z"
  }
}
```

**Campos calculados automáticamente**:

- `saldo_disponible`: Inicia igual a `limite_mensual`
- `porcentaje_uso`: `((limite_mensual - saldo_disponible) / limite_mensual) * 100`

---

## 🚀 CURL COMMAND

```bash
curl -X POST http://localhost:3000/api/v1/tarjetas \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_titular": "Juan Pérez",
    "ultimos_4_digitos": "1234",
    "moneda": "USD",
    "limite_mensual": 5000.00,
    "tipo_tarjeta": "Visa"
  }'
```

---

## 📝 CAMBIOS REALIZADOS

1. ✅ Actualizada documentación de Swagger en `src/routes/tarjetas.routes.ts`
2. ✅ Schema POST ahora muestra campos correctos
3. ✅ Schema PUT ahora muestra campos correctos
4. ✅ Eliminados campos obsoletos (numero_tarjeta, cvv, fecha_vencimiento, etc.)

---

**Última actualización**: 2026-01-30 18:15  
**Estado**: ✅ SCHEMA CORRECTO EN SWAGGER  
**Swagger URL**: http://localhost:3000/api-docs
