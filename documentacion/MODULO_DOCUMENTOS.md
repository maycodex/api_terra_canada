# 📄 MÓDULO DOCUMENTOS - CRUD con PostgreSQL

## Fecha: 2026-01-30

## Estado: ✅ IMPLEMENTADO

---

## 📋 RESUMEN DE ENDPOINTS

| Método | Endpoint          | Descripción                     | Función PostgreSQL      |
| ------ | ----------------- | ------------------------------- | ----------------------- |
| GET    | `/documentos`     | Obtener todos los documentos    | `documentos_get()`      |
| GET    | `/documentos/:id` | Obtener un documento específico | `documentos_get(id)`    |
| POST   | `/documentos`     | Crear nuevo documento           | `documentos_post(...)`  |
| PUT    | `/documentos/:id` | Actualizar documento            | `documentos_put(...)`   |
| DELETE | `/documentos/:id` | Eliminar documento              | `documentos_delete(id)` |

---

## 📌 TIPOS DE DOCUMENTO

| Tipo              | Descripción                                    |
| ----------------- | ---------------------------------------------- |
| `FACTURA`         | Documento de factura, puede vincularse a pagos |
| `DOCUMENTO_BANCO` | Extracto bancario                              |

---

## 📌 GET /documentos

### Obtener todos los documentos

**Función PostgreSQL:**

```sql
SELECT documentos_get();
```

**Respuesta:**

```json
{
  "success": true,
  "code": 200,
  "message": "Documentos obtenidos exitosamente",
  "data": [
    {
      "id": 1,
      "tipo_documento": "FACTURA",
      "nombre_archivo": "factura_RES-2026-001.pdf",
      "url_documento": "https://storage.terracanada.com/facturas/...",
      "usuario_subida": {
        "id": 2,
        "nombre_completo": "Juan Pérez"
      },
      "pagos_vinculados": 3,
      "fecha_subida": "2026-01-30T10:00:00Z"
    }
  ]
}
```

**cURL:**

```bash
curl -X GET http://localhost:3000/api/v1/documentos \
  -H "Authorization: Bearer TOKEN"
```

---

## 📌 GET /documentos/:id

### Obtener un documento específico

**Función PostgreSQL:**

```sql
SELECT documentos_get(1);
```

**Respuesta:**

```json
{
  "success": true,
  "code": 200,
  "message": "Documento obtenido exitosamente",
  "data": {
    "id": 1,
    "tipo_documento": "FACTURA",
    "nombre_archivo": "factura_RES-2026-001.pdf",
    "url_documento": "https://storage.terracanada.com/facturas/...",
    "usuario_subida": {
      "id": 2,
      "nombre_completo": "Juan Pérez"
    },
    "pagos_vinculados": [
      {
        "id": 10,
        "codigo_reserva": "RES-2026-001",
        "monto": 1500.0,
        "pagado": true,
        "verificado": false
      }
    ],
    "fecha_subida": "2026-01-30T10:00:00Z"
  }
}
```

**cURL:**

```bash
curl -X GET http://localhost:3000/api/v1/documentos/1 \
  -H "Authorization: Bearer TOKEN"
```

---

## 📌 POST /documentos

### Crear un nuevo documento

**Función PostgreSQL:**

```sql
SELECT documentos_post(
  'FACTURA',                        -- tipo_documento
  'factura_RES-2026-001.pdf',       -- nombre_archivo
  'https://storage.terra.../...',   -- url_documento
  2,                                -- usuario_id
  10                                -- pago_id (opcional)
);
```

**Request:**

```json
{
  "tipo_documento": "FACTURA",
  "nombre_archivo": "factura_RES-2026-001.pdf",
  "url_documento": "https://storage.terracanada.com/facturas/factura.pdf",
  "usuario_id": 2,
  "pago_id": 10
}
```

**Respuesta:**

```json
{
  "success": true,
  "code": 201,
  "message": "Documento creado exitosamente",
  "data": {
    "id": 1,
    "tipo_documento": "FACTURA",
    "nombre_archivo": "factura_RES-2026-001.pdf",
    "url_documento": "https://storage.terracanada.com/facturas/factura.pdf",
    "usuario_subida": {
      "id": 2,
      "nombre_completo": "Juan Pérez"
    },
    "pagos_vinculados": [
      {
        "id": 10,
        "codigo_reserva": "RES-2026-001",
        "monto": 1500.0,
        "pagado": false,
        "verificado": false
      }
    ],
    "fecha_subida": "2026-01-30T22:30:00Z"
  }
}
```

### ⚠️ VALIDACIONES

- ✅ `tipo_documento` debe ser `FACTURA` o `DOCUMENTO_BANCO`
- ✅ `nombre_archivo` es obligatorio
- ✅ `url_documento` es obligatorio
- ✅ `usuario_id` debe existir en la base de datos
- ✅ `pago_id` (si se proporciona) debe existir en la base de datos

**cURL:**

```bash
curl -X POST http://localhost:3000/api/v1/documentos \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tipo_documento": "FACTURA",
    "nombre_archivo": "factura_RES-2026-001.pdf",
    "url_documento": "https://storage.terracanada.com/facturas/factura.pdf",
    "usuario_id": 2,
    "pago_id": 10
  }'
```

---

## 📌 PUT /documentos/:id

### Actualizar un documento

**Función PostgreSQL:**

```sql
SELECT documentos_put(
  1,                          -- id
  'nuevo_nombre.pdf',         -- nombre_archivo (opcional)
  'https://nueva.url/...'     -- url_documento (opcional)
);
```

**Request:**

```json
{
  "nombre_archivo": "factura_corregida.pdf",
  "url_documento": "https://storage.terracanada.com/nueva_url/factura.pdf"
}
```

**Respuesta:**

```json
{
  "success": true,
  "code": 200,
  "message": "Documento actualizado exitosamente",
  "data": {
    "id": 1,
    "tipo_documento": "FACTURA",
    "nombre_archivo": "factura_corregida.pdf",
    "url_documento": "https://storage.terracanada.com/nueva_url/factura.pdf",
    ...
  }
}
```

### ⚠️ VALIDACIONES

- ✅ Debe proporcionar al menos un campo para actualizar
- ✅ Los campos vacíos se mantienen sin cambios

**cURL:**

```bash
curl -X PUT http://localhost:3000/api/v1/documentos/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_archivo": "factura_corregida.pdf"
  }'
```

---

## 📌 DELETE /documentos/:id

### Eliminar un documento

**Función PostgreSQL:**

```sql
SELECT documentos_delete(1);
```

**Respuesta Exitosa:**

```json
{
  "success": true,
  "code": 200,
  "message": "Documento eliminado exitosamente",
  "data": {
    "nombre_archivo": "factura_eliminada.pdf"
  }
}
```

**Respuesta Error (pagos verificados):**

```json
{
  "success": false,
  "code": 409,
  "message": "No se puede eliminar el documento porque tiene pagos verificados vinculados"
}
```

### ⚠️ RESTRICCIONES

- ❌ No se puede eliminar si tiene pagos **VERIFICADOS** vinculados
- ✅ Se eliminan automáticamente las vinculaciones con pagos no verificados

**cURL:**

```bash
curl -X DELETE http://localhost:3000/api/v1/documentos/1 \
  -H "Authorization: Bearer TOKEN"
```

---

## 📚 ARCHIVOS DEL MÓDULO

| Archivo                                    | Descripción                       |
| ------------------------------------------ | --------------------------------- |
| `src/schemas/documentos.schema.ts`         | Schemas de validación Zod         |
| `src/services/documentos.service.ts`       | Servicio con funciones PostgreSQL |
| `src/controllers/documentos.controller.ts` | Controlador CRUD                  |
| `src/routes/documentos.routes.ts`          | Rutas con Swagger                 |

---

## 🔐 PERMISOS POR ROL

| Endpoint               | ADMIN | SUPERVISOR | EQUIPO |
| ---------------------- | ----- | ---------- | ------ |
| GET /documentos        | ✅    | ✅         | ✅     |
| GET /documentos/:id    | ✅    | ✅         | ✅     |
| POST /documentos       | ✅    | ✅         | ❌     |
| PUT /documentos/:id    | ✅    | ✅         | ❌     |
| DELETE /documentos/:id | ✅    | ❌         | ❌     |

---

## 🧪 SWAGGER

Todos los endpoints están documentados en Swagger bajo el tag **[Documentos]**:
**URL:** http://localhost:3000/api-docs

---

**Última actualización:** 2026-01-30 22:25  
**Estado:** ✅ IMPLEMENTADO - LISTO PARA TESTING
