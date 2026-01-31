# 💳 ENDPOINTS - PAGOS

## Fecha: 2026-01-30

## Estado: ✅ Refactorizado para usar funciones PostgreSQL

---

## 📋 ENDPOINTS DISPONIBLES

| Método    | Endpoint                  | Descripción                       |
| --------- | ------------------------- | --------------------------------- |
| GET       | /pagos                    | Obtener todos los pagos           |
| GET       | /pagos/:id                | Obtener un pago específico        |
| POST      | /pagos                    | Crear nuevo pago                  |
| PUT       | /pagos/:id                | Actualizar pago                   |
| DELETE    | /pagos/:id                | Eliminar pago                     |
| **PATCH** | **/pagos/:id/desactivar** | **Desactivar pago (soft delete)** |
| **PATCH** | **/pagos/:id/activar**    | **Activar pago**                  |

---

## 🎯 IMPORTANTE - Lógica de Negocio

### Medio de Pago

- **TARJETA**: Descuenta saldo automáticamente al crear
- **CUENTA_BANCARIA**: Solo registra, NO descuenta saldo

### Validaciones Críticas

- ✅ Código de reserva debe ser único
- ✅ Si es TARJETA: debe tener saldo suficiente
- ✅ Si medio_pago = TARJETA → solo tarjeta_id (no cuenta_bancaria_id)
- ✅ Si medio_pago = CUENTA_BANCARIA → solo cuenta_bancaria_id (no tarjeta_id)
- ❌ No se puede editar un pago verificado
- ❌ No se puede cambiar monto si es con tarjeta (ya se descontó)
- ❌ No se puede eliminar si gmail_enviado = true

---

## 📌 SCHEMA CORRECTO

### POST /pag

os - Crear Pago

#### Campos Obligatorios

| Campo             | Tipo   | Validación                    | Ejemplo        |
| ----------------- | ------ | ----------------------------- | -------------- |
| `proveedor_id`    | number | ID de proveedor activo        | 2              |
| `usuario_id`      | number | ID de usuario activo          | 2              |
| `codigo_reserva`  | string | Único, 1-50 caracteres        | "RES-2026-004" |
| `monto`           | number | Mayor a 0                     | 500.00         |
| `moneda`          | string | "USD" o "CAD"                 | "USD"          |
| `tipo_medio_pago` | string | "TARJETA" o "CUENTA_BANCARIA" | "TARJETA"      |

#### Campos Condicionales

| Campo                | Cuándo es obligatorio                  | Ejemplo |
| -------------------- | -------------------------------------- | ------- |
| `tarjeta_id`         | Si tipo_medio_pago = "TARJETA"         | 1       |
| `cuenta_bancaria_id` | Si tipo_medio_pago = "CUENTA_BANCARIA" | 1       |

#### Campos Opcionales

| Campo                   | Tipo          | Ejemplo                      |
| ----------------------- | ------------- | ---------------------------- |
| `clientes_ids`          | array<number> | [1, 2]                       |
| `descripcion`           | string        | "Pago de servicio turístico" |
| `fecha_esperada_debito` | string        | "2026-02-15"                 |

---

## 🔍 GET /pagos - Obtener todos los pagos

**Endpoint:** `GET /api/v1/pagos`  
**Autenticación:** Bearer Token  
**Roles:** Todos

### Response 200 - Éxito

```json
{
  "success": true,
  "message": "Pagos obtenidos",
  "data": [
    {
      "id": 2,
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
      "fecha_creacion": "2026-01-30T19:00:00Z",
      "fecha_actualizacion": "2026-01-30T19:00:00Z"
    }
  ]
}
```

---

## 🔍 GET /pagos/:id - Obtener pago específico

**Endpoint:** `GET /api/v1/pagos/:id`  
**Autenticación:** Bearer Token  
**Roles:** Todos

### Response 200 - Incluye documentos

```json
{
  "success": true,
  "message": "Pago obtenido",
  "data": {
    "id": 2,
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
    "documentos": [
      {
        "id": 1,
        "tipo_documento": "FACTURA",
        "url_documento": "https://...",
        "fecha_subida": "2026-01-30T19:05:00Z"
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
    "fecha_creacion": "2026-01-30T19:00:00Z",
    "fecha_actualizacion": "2026-01-30T19:00:00Z"
  }
}
```

---

## ➕ POST /pagos - Crear nuevo pago

**Endpoint:** `POST /api/v1/pagos`  
**Autenticación:** Bearer Token  
**Roles:** ADMIN, SUPERVISOR

### Ejemplo 1: Pago con TARJETA

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

**Nota:** Si la tarjeta tiene saldo insuficiente:

```json
{
  "success": false,
  "message": "Saldo insuficiente en la tarjeta. Disponible: 400.00",
  "data": {
    "saldo_disponible": 400.0
  }
}
```

### Ejemplo 2: Pago con CUENTA_BANCARIA

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

### Response 201 - Creado exitosamente

```json
{
  "success": true,
  "message": "Pago creado exitosamente",
  "data": {
    "id": 2,
    "codigo_reserva": "RES-2026-004",
    "monto": 500.0,
    "moneda": "USD"
    // ... (respuesta completa con todas las relaciones)
  }
}
```

### Errores Comunes

#### 400 - Código de reserva vacío

```json
{
  "success": false,
  "message": "El código de reserva es obligatorio"
}
```

#### 409 - Código de reserva duplicado

```json
{
  "success": false,
  "message": "Ya existe un pago con ese código de reserva"
}
```

#### 404 - Proveedor no existe

```json
{
  "success": false,
  "message": "El proveedor no existe o está inactivo"
}
```

#### 400 - Medio de pago mal configurado

```json
{
  "success": false,
  "message": "Debe especificar una tarjeta de crédito"
}
```

#### 409 - Saldo insuficiente

```json
{
  "success": false,
  "message": "Saldo insuficiente en la tarjeta. Disponible: 300.00",
  "data": {
    "saldo_disponible": 300.0
  }
}
```

---

## 🔄 PUT /pagos/:id - Actualizar pago

**Endpoint:** `PUT /api/v1/pagos/:id`  
**Autenticación:** Bearer Token  
**Roles:** ADMIN, SUPERVISOR

### Request Body (todos opcionales)

```json
{
  "monto": 600.0,
  "descripcion": "Descripción actualizada",
  "fecha_esperada_debito": "2026-03-01",
  "pagado": true,
  "verificado": false,
  "gmail_enviado": false,
  "activo": true
}
```

### Validaciones Importantes

- ❌ NO se puede editar si `verificado = true`
- ❌ NO se puede cambiar `monto` si es pago con tarjeta (ya se descontó)
- ✅ Si se marca `verificado = true`, automáticamente marca `pagado = true`

### Response 200 - Actualizado

```json
{
  "success": true,
  "message": "Pago actualizado",
  "data": {
    // pago completo actualizado
  }
}
```

### Errores

#### 404 - No encontrado

```json
{
  "success": false,
  "message": "Pago no encontrado"
}
```

#### 409 - Pago ya verificado

```json
{
  "success": false,
  "message": "No se puede editar un pago que ya está verificado"
}
```

#### 409 - No se puede cambiar monto

```json
{
  "success": false,
  "message": "No se puede cambiar el monto de un pago con tarjeta (ya se descontó el saldo)"
}
```

---

## ❌ DELETE /pagos/:id - Eliminar pago

**Endpoint:** `DELETE /api/v1/pagos/:id`  
**Autenticación:** Bearer Token  
**Roles:** ADMIN

### Request

```bash
DELETE /api/v1/pagos/2
Authorization: Bearer YOUR_TOKEN
```

### Response 200 - Eliminado exitosamente

```json
{
  "success": true,
  "message": "Pago eliminado",
  "data": {
    "codigo_reserva": "RES-2026-004",
    "monto_devuelto": 500.0
  }
}
```

**Nota:** Si el pago fue con tarjeta, el `monto_devuelto` será el monto que se regresó al saldo de la tarjeta.

### Errores

#### 404 - No encontrado

```json
{
  "success": false,
  "message": "Pago no encontrado"
}
```

#### 409 - Gmail ya enviado

```json
{
  "success": false,
  "message": "No se puede eliminar un pago que ya fue notificado por correo"
}
```

---

## 🧪 EJEMPLOS COMPLETOS

### Caso 1: Pago con tarjeta y múltiples clientes

```bash
POST /api/v1/pagos
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "proveedor_id": 2,
  "usuario_id": 2,
  "codigo_reserva": "RES-2026-010",
  "monto": 1500.00,
  "moneda": "USD",
  "tipo_medio_pago": "TARJETA",
  "tarjeta_id": 1,
  "clientes_ids": [1, 2, 3],
  "descripcion": "Paquete turístico para 3 clientes",
  "fecha_esperada_debito": "2026-03-01"
}
```

### Caso 2: Pago con cuenta bancaria sin clientes

```bash
POST /api/v1/pagos
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "proveedor_id": 3,
  "usuario_id": 2,
  "codigo_reserva": "RES-2026-011",
  "monto": 800.00,
  "moneda": "CAD",
  "tipo_medio_pago": "CUENTA_BANCARIA",
  "cuenta_bancaria_id": 1,
  "descripcion": "Pago general de servicio"
}
```

### Caso 3: Marcar pago como pagado

```bash
PUT /api/v1/pagos/2
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "pagado": true
}
```

### Caso 4: Marcar pago como verificado (marca pagado automáticamente)

```bash
PUT /api/v1/pagos/2
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "verificado": true
}
```

---

## 🚀 CURL COMMANDS

### Crear pago con tarjeta

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

### Obtener todos los pagos

```bash
curl -X GET http://localhost:3000/api/v1/pagos \
  -H "Authorization: Bearer TU_TOKEN"
```

### Marcar como pagado

```bash
curl -X PUT http://localhost:3000/api/v1/pagos/2 \
  -H "Authorization: Bearer TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pagado": true}'
```

---

## 📊 FUNCIONES POSTGRESQL UTILIZADAS

```sql
-- GET: todos o uno específico
SELECT pagos_get();        -- Todos
SELECT pagos_get(2);       -- Uno específico

-- POST: crear con tarjeta
SELECT pagos_post(
  2,                          -- proveedor_id
  2,                          -- usuario_id
  'RES-2026-004',             -- codigo_reserva
  500.00,                     -- monto
  'USD',                      -- moneda
  'TARJETA',                  -- tipo_medio_pago
  1,                          -- tarjeta_id
  NULL,                       -- cuenta_bancaria_id
  ARRAY[1]::BIGINT[],         -- clientes_ids
  'Pago de servicio',         -- descripcion
  '2026-02-15'                -- fecha_esperada_debito
);

-- POST: crear con cuenta bancaria
SELECT pagos_post(
  2, 2, 'RES-2026-005', 1200.00, 'CAD',
  'CUENTA_BANCARIA', NULL, 1,
  ARRAY[1]::BIGINT[], 'Pago hotelero', NULL
);

-- PUT: actualizar
SELECT pagos_put(
  2,                          -- id
  NULL,                       -- monto (NULL = no cambia)
  'Descripción actualizada',  -- descripcion
  '2026-03-01',               -- fecha_esperada_debito
  TRUE,                       -- pagado
  NULL,                       -- verificado
  NULL,                       -- gmail_enviado
  NULL                        -- activo
);

-- DELETE: eliminar (devuelve saldo si es tarjeta)
SELECT pagos_delete(2);
```

---

## 📝 CHECKLIST DE TESTING

### Crear Pagos

- [ ] POST con tarjeta - saldo suficiente
- [ ] POST con tarjeta - saldo insuficiente (debe dar error)
- [ ] POST con cuenta bancaria
- [ ] POST con múltiples clientes
- [ ] POST con código de reserva duplicado (debe dar error)
- [ ] POST sin tarjeta_id cuando tipo_medio_pago = TARJETA (debe dar error)

### Actualizar Pagos

- [ ] PUT marcar como pagado
- [ ] PUT marcar como verificado (debe marcar pagado automáticamente)
- [ ] PUT cambiar monto de pago con tarjeta (debe dar error)
- [ ] PUT editar pago ya verificado (debe dar error)

### Eliminar Pagos

- [ ] DELETE pago con tarjeta (debe devolver saldo)
- [ ] DELETE pago con gmail_enviado = true (debe dar error)
- [ ] DELETE pago con cuenta bancaria

---

**Última actualización:** 2026-01-30 18:45  
**Versión:** 1.0.0  
**Estado:** ✅ LISTO PARA TESTING
