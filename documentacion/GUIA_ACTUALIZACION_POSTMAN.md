# 🔧 GUÍA DE ACTUALIZACIÓN MANUAL - Colección de Postman

**Fecha:** 30 de Enero de 2026  
**Archivo:** `API_Terra_Canada.postman_collection.json`

---

## 📝 INSTRUCCIONES PASO A PASO

### Opción 1: Importar Endpoints Nuevos (Recomendado)

1. **Abrir Postman**
2. **Importar colección actual:**
   - File > Import
   - Seleccionar: `API_Terra_Canada.postman_collection.json`

3. **Agregar endpoints faltantes manualmente:**

---

## 🔴 MÓDULO: PAGOS (Agregar 5 endpoints)

### 1. Desactivar Pago

```
Método: PATCH
URL: {{base_url}}/pagos/1/desactivar
Headers: (ninguno)
Body: (ninguno)
Description: Desactiva un pago (soft delete). El pago no se elimina, solo se marca como inactivo.
```

### 2. Activar Pago

```
Método: PATCH
URL: {{base_url}}/pagos/1/activar
Headers: (ninguno)
Body: (ninguno)
Description: Reactiva un pago previamente desactivado.
```

### 3. Enviar Documento de Estado (N8N)

```
Método: POST
URL: {{base_url}}/pagos/documento-estado
Headers:
  Content-Type: application/json
Body (raw JSON):
{
  "pdf": "JVBERi0xLjQKJeLjz9MKMSAwIG9iag...",
  "id_pago": 10,
  "usuario_id": 2
}
Description: Envía documento de estado de pago a N8N. Webhook: https://n8n.salazargroup.cloud/webhook/documento_pago. Incluye usuario_id para trazabilidad.
```

### 4. Subir Facturas (N8N)

```
Método: POST
URL: {{base_url}}/pagos/subir-facturas
Headers:
  Content-Type: application/json
Body (raw JSON):
{
  "usuario_id": 2,
  "facturas": [
    {
      "pdf": "JVBERi0xLjQKJeLjz9MK...",
      "proveedor_id": 1
    },
    {
      "pdf": "JVBERi0xLjQKJeLjz9MK...",
      "proveedor_id": 2
    }
  ]
}
Description: Sube hasta 3 facturas a N8N para procesamiento. Webhook: https://n8n.salazargroup.cloud/webhook/docu. Incluye usuario_id.
```

### 5. Subir Extracto de Banco (N8N)

```
Método: POST
URL: {{base_url}}/pagos/subir-extracto-banco
Headers:
  Content-Type: application/json
Body (raw JSON):
{
  "pdf": "JVBERi0xLjQKJeLjz9MK...",
  "usuario_id": 2
}
Description: Sube extracto bancario a N8N para procesamiento. Webhook: https://n8n.salazargroup.cloud/webhook/docu. Incluye usuario_id.
```

---

## 🔴 MÓDULO: DOCUMENTOS (Actualizar 1 endpoint)

### Actualizar: Crear Documento

**ANTES:**

```
Método: POST
URL: {{base_url}}/documentos/upload
Body: formdata
```

**DESPUÉS:**

```
Método: POST
URL: {{base_url}}/documentos
Headers:
  Content-Type: application/json
Body (raw JSON):
{
  "tipo_documento": "FACTURA",
  "nombre_archivo": "factura_RES-2026-001.pdf",
  "url_documento": "https://storage.terracanada.com/facturas/factura.pdf",
  "usuario_id": 2,
  "pago_id": 10
}
Description: Crear nuevo documento. Tipos: FACTURA, DOCUMENTO_BANCO
```

---

## 🔴 MÓDULO: DOCUMENTOS (Agregar 1 endpoint)

### 6. Actualizar Documento

```
Método: PUT
URL: {{base_url}}/documentos/1
Headers:
  Content-Type: application/json
Body (raw JSON):
{
  "nombre_archivo": "factura_corregida.pdf",
  "url_documento": "https://storage.terracanada.com/nueva_url/factura.pdf"
}
Description: Actualizar nombre o URL del documento
```

---

## 🟡 MÓDULO: ROLES (Agregar 3 endpoints)

### 7. Crear Rol

```
Método: POST
URL: {{base_url}}/roles
Headers:
  Content-Type: application/json
Body (raw JSON):
{
  "nombre": "CONTADOR",
  "descripcion": "Rol para contadores"
}
Description: Crear nuevo rol
```

### 8. Actualizar Rol

```
Método: PUT
URL: {{base_url}}/roles/1
Headers:
  Content-Type: application/json
Body (raw JSON):
{
  "nombre": "CONTADOR_SENIOR",
  "descripcion": "Rol para contadores senior"
}
Description: Actualizar rol existente
```

### 9. Eliminar Rol

```
Método: DELETE
URL: {{base_url}}/roles/1
Headers: (ninguno)
Body: (ninguno)
Description: Eliminar rol
```

---

## 🟡 MÓDULO: CORREOS (Agregar 1 endpoint)

### 10. Obtener Correos Pendientes

```
Método: GET
URL: {{base_url}}/correos/pendientes
Headers: (ninguno)
Body: (ninguno)
Description: Obtener solo correos en estado BORRADOR
```

---

## 🟢 MÓDULO: AUTH (Corregir 1 endpoint)

### Corregir: Get Current User Profile

**ANTES:**

```
URL: {{base_url}}/auth/profile
```

**DESPUÉS:**

```
URL: {{base_url}}/auth/me
```

---

## 🟢 MÓDULO: FACTURAS (Eliminar y mover)

### Eliminar:

- POST `/facturas/procesar`

**Razón:** Este endpoint ya está en el módulo de Pagos como "Subir Facturas (N8N)"

---

## ✅ CHECKLIST DE ACTUALIZACIÓN

- [ ] **Pagos:** Agregar 5 endpoints (desactivar, activar, 3 webhooks N8N)
- [ ] **Documentos:** Actualizar POST `/documentos` (formdata → JSON)
- [ ] **Documentos:** Agregar PUT `/documentos/:id`
- [ ] **Roles:** Agregar POST, PUT, DELETE
- [ ] **Correos:** Agregar GET `/correos/pendientes`
- [ ] **Auth:** Corregir GET `/auth/profile` → `/auth/me`
- [ ] **Facturas:** Eliminar POST `/facturas/procesar` (duplicado)

**Total:** 13 cambios

---

## 📊 RESULTADO ESPERADO

Después de aplicar todos los cambios:

| Módulo     | Endpoints Antes | Endpoints Después | Cambios             |
| ---------- | --------------- | ----------------- | ------------------- |
| Auth       | 2               | 2                 | 1 corrección        |
| Roles      | 2               | 5                 | +3                  |
| Pagos      | 6               | 11                | +5                  |
| Documentos | 5               | 6                 | +1, 1 actualización |
| Correos    | 7               | 8                 | +1                  |
| Facturas   | 1               | 0                 | -1 (eliminado)      |
| **TOTAL**  | **~60**         | **~70**           | **+13**             |

---

## 🎯 ALTERNATIVA: Usar Archivo JSON

Si prefieres importar los endpoints automáticamente:

1. Importar archivo: `nuevos_endpoints_pagos.json`
2. Copiar los 5 endpoints al módulo "Pagos" en tu colección
3. Repetir para los demás módulos

---

## ✅ VERIFICACIÓN FINAL

Después de actualizar, verifica:

1. ✅ Módulo "Pagos" tiene 11 endpoints
2. ✅ Módulo "Documentos" tiene 6 endpoints
3. ✅ Módulo "Roles" tiene 5 endpoints
4. ✅ Módulo "Correos" tiene 8 endpoints
5. ✅ Endpoint `/auth/me` existe
6. ✅ Todos los webhooks N8N incluyen `usuario_id`

---

**Generado por:** Antigravity AI  
**Fecha:** 30 de Enero de 2026
