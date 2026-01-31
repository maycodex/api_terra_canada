# 📚 DOCUMENTACIÓN API TERRA CANADA - RESUMEN

**Fecha de actualización:** 30 de Enero de 2026  
**Versión:** 2.0.0

---

## 📁 ARCHIVOS GENERADOS

### 1. **API_ENDPOINTS_REFERENCE.md**

**Ubicación:** `documentacion/API_ENDPOINTS_REFERENCE.md`

**Contenido:**

- ✅ Referencia completa de todos los endpoints
- ✅ Códigos de respuesta HTTP detallados
- ✅ Ejemplos de request/response
- ✅ Descripción de cada endpoint
- ✅ Parámetros requeridos y opcionales
- ✅ Información de autenticación

**Módulos documentados:**

1. Autenticación
2. Usuarios
3. Roles
4. Servicios
5. Proveedores
6. Clientes
7. Tarjetas
8. Cuentas
9. Pagos (incluye webhooks N8N con `usuario_id`)
10. Documentos (CRUD con PostgreSQL)
11. Correos (con `usuario_id` en webhook)
12. Eventos
13. Análisis
14. Webhooks

---

### 2. **API_Terra_Canada_Updates_2026.postman_collection.json**

**Ubicación:** `documentacion/API_Terra_Canada_Updates_2026.postman_collection.json`

**Contenido:**

- ✅ Colección de Postman con endpoints nuevos y actualizados
- ✅ Endpoints de Documentos (CRUD completo)
- ✅ Endpoints de Correos (con `usuario_id`)
- ✅ Webhooks de Pagos actualizados (con `usuario_id`)
- ✅ Variables de entorno preconfiguradas
- ✅ Autenticación Bearer Token automática

**Cómo usar:**

1. Importar en Postman: `File > Import > API_Terra_Canada_Updates_2026.postman_collection.json`
2. Configurar variable `base_url` (default: `http://localhost:3000/api/v1`)
3. Ejecutar `Login` para obtener token JWT automáticamente
4. Los demás endpoints usarán el token automáticamente

---

## 🔄 CAMBIOS PRINCIPALES (Enero 2026)

### ✅ Módulo Documentos

**Estado:** IMPLEMENTADO

- **GET** `/documentos` - Listar todos
- **GET** `/documentos/:id` - Obtener por ID con pagos vinculados
- **POST** `/documentos` - Crear (con `usuario_id` y `pago_id` opcional)
- **PUT** `/documentos/:id` - Actualizar nombre/URL
- **DELETE** `/documentos/:id` - Eliminar

**Funciones PostgreSQL:**

- `documentos_get(id)`
- `documentos_post(...)`
- `documentos_put(...)`
- `documentos_delete(id)`

---

### ✅ Módulo Correos (con `usuario_id`)

**Estado:** IMPLEMENTADO

- **GET** `/correos` - Listar con filtros
- **GET** `/correos/pendientes` - Solo borradores
- **GET** `/correos/:id` - Obtener por ID
- **POST** `/correos/generar` - Generar automáticamente
- **POST** `/correos` - Crear manualmente
- **PUT** `/correos/:id` - Actualizar borrador
- **POST** `/correos/:id/enviar` - **Enviar vía N8N (incluye `usuario_id`)**
- **DELETE** `/correos/:id` - Eliminar borrador

**Webhook actualizado:**

```
URL: https://n8n.salazargroup.cloud/webhook/gmail_g
```

**Payload con `usuario_id`:**

```json
{
  "info_correo": {
    "destinatario": "billing@proveedor.com",
    "asunto": "...",
    "cuerpo": "...",
    "proveedor": {...},
    "usuario_id": 2  // ← NUEVO
  },
  "info_pagos": [...]
}
```

---

### ✅ Webhooks de Pagos (con `usuario_id`)

**Estado:** ACTUALIZADO

#### 1. POST `/pagos/documento-estado`

```json
{
  "pdf": "base64...",
  "id_pago": 10,
  "usuario_id": 2 // ← NUEVO
}
```

**Webhook:** `https://n8n.salazargroup.cloud/webhook/documento_pago`

#### 2. POST `/pagos/subir-facturas`

```json
{
  "usuario_id": 2, // ← NUEVO
  "facturas": [{ "pdf": "base64...", "proveedor_id": 1 }]
}
```

**Webhook:** `https://n8n.salazargroup.cloud/webhook/docu`

#### 3. POST `/pagos/subir-extracto-banco`

```json
{
  "pdf": "base64...",
  "usuario_id": 2 // ← NUEVO
}
```

**Webhook:** `https://n8n.salazargroup.cloud/webhook/docu`

---

## 📊 CÓDIGOS DE RESPUESTA

| Código  | Significado           | Cuándo se usa                                           |
| ------- | --------------------- | ------------------------------------------------------- |
| **200** | OK                    | Operación exitosa (GET, PUT, DELETE)                    |
| **201** | Created               | Recurso creado (POST)                                   |
| **400** | Bad Request           | Datos inválidos, validación fallida                     |
| **401** | Unauthorized          | No autenticado, token inválido                          |
| **403** | Forbidden             | Sin permisos para la operación                          |
| **404** | Not Found             | Recurso no encontrado                                   |
| **409** | Conflict              | Conflicto (ej: recurso ya existe, no se puede eliminar) |
| **500** | Internal Server Error | Error del servidor                                      |
| **503** | Service Unavailable   | Servicio externo (N8N) no disponible                    |

---

## 🔐 AUTENTICACIÓN

Todos los endpoints (excepto `/auth/login`) requieren JWT:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Obtener token:**

```bash
POST /api/v1/auth/login
{
  "nombre_usuario": "admin",
  "contrasena": "password123"
}
```

**Respuesta:**

```json
{
  "code": 200,
  "estado": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "usuario": {...}
  }
}
```

---

## 📦 FORMATO DE RESPUESTA ESTÁNDAR

### Éxito

```json
{
  "code": 200,
  "estado": true,
  "message": "Operación exitosa",
  "data": {...}
}
```

### Error

```json
{
  "code": 400,
  "estado": false,
  "message": "Descripción del error",
  "data": null
}
```

---

## 🧪 TESTING CON POSTMAN

### Paso 1: Importar Colección

```
File > Import > Seleccionar archivo:
- API_Terra_Canada_Updates_2026.postman_collection.json
```

### Paso 2: Configurar Variables

En la colección, configurar:

- `base_url`: `http://localhost:3000/api/v1`
- `jwt_token`: (se configura automáticamente al hacer login)

### Paso 3: Autenticarse

1. Ir a carpeta `1. Authentication`
2. Ejecutar request `Login`
3. El token se guarda automáticamente en `jwt_token`

### Paso 4: Probar Endpoints

Todos los demás requests usarán el token automáticamente.

---

## 🔗 WEBHOOKS N8N

### Correos (Gmail)

```
URL: https://n8n.salazargroup.cloud/webhook/gmail_g
Método: POST
Auth: Basic (hardcodeado en código)
```

### Documento de Pago

```
URL: https://n8n.salazargroup.cloud/webhook/documento_pago
Método: POST
```

### Facturas y Extractos

```
URL: https://n8n.salazargroup.cloud/webhook/docu
Método: POST
```

---

## 📝 NOTAS IMPORTANTES

### Trazabilidad con `usuario_id`

Todos los webhooks ahora incluyen `usuario_id` para identificar:

- ✅ Quién envió el correo
- ✅ Quién subió el documento
- ✅ Quién procesó el pago

### Funciones PostgreSQL

El módulo de Documentos usa funciones PostgreSQL:

- ✅ Mejor rendimiento
- ✅ Lógica centralizada en BD
- ✅ Validaciones automáticas
- ✅ Transacciones ACID

### Validación con Zod

Todos los endpoints validan datos con Zod:

- ✅ Validación de tipos
- ✅ Transformaciones automáticas
- ✅ Mensajes de error claros

---

## 📚 DOCUMENTACIÓN ADICIONAL

| Documento                        | Ubicación                                                             | Descripción                     |
| -------------------------------- | --------------------------------------------------------------------- | ------------------------------- |
| **Swagger UI**                   | `http://localhost:3000/api-docs`                                      | Documentación interactiva       |
| **Endpoints Reference**          | `documentacion/API_ENDPOINTS_REFERENCE.md`                            | Referencia completa             |
| **Postman Collection**           | `documentacion/API_Terra_Canada_Updates_2026.postman_collection.json` | Colección actualizada           |
| **Integración N8N Correos**      | `documentacion/INTEGRACION_N8N_CORREOS.md`                            | Detalles del webhook de correos |
| **Módulo Documentos**            | `documentacion/MODULO_DOCUMENTOS.md`                                  | CRUD de documentos              |
| **Endpoints Documentos Webhook** | `documentacion/ENDPOINTS_DOCUMENTOS_WEBHOOK.md`                       | Webhooks de pagos               |

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [x] Módulo Documentos con PostgreSQL
- [x] Módulo Correos con `usuario_id`
- [x] Webhooks de Pagos con `usuario_id`
- [x] Webhook de correos actualizado a `gmail_g`
- [x] Documentación de endpoints completa
- [x] Colección de Postman actualizada
- [x] Swagger documentado
- [x] Validación con Zod
- [x] Logging completo
- [x] Manejo de errores robusto
- [x] Autenticación JWT
- [x] RBAC (Control de acceso basado en roles)
- [x] Auditoría de eventos

---

## 🚀 PRÓXIMOS PASOS

1. **Testing:** Probar todos los endpoints con Postman
2. **Validación:** Verificar que N8N recibe correctamente los `usuario_id`
3. **Documentación:** Actualizar README principal del proyecto
4. **Deploy:** Preparar para producción

---

**Generado por:** Antigravity AI  
**Fecha:** 30 de Enero de 2026  
**Estado:** ✅ COMPLETO Y LISTO PARA USO
