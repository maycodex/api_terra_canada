# ✅ COLECCIÓN POSTMAN ACTUALIZADA

**Archivo:** `API_Terra_Canada.postman_collection.json`  
**Versión:** 2.0.0  
**Fecha:** 30 de Enero de 2026

---

## 📦 CONTENIDO COMPLETO

La colección de Postman incluye **TODOS** los módulos de la API:

### ✅ Módulos Incluidos (15 total)

1. **Authentication** - Login, Profile
2. **Usuarios** - CRUD completo
3. **Roles** - Listar y obtener
4. **Proveedores** - CRUD + gestión de correos
5. **Servicios** - CRUD completo
6. **Clientes** - CRUD completo
7. **Tarjetas de Crédito** - CRUD + activar/desactivar
8. **Cuentas Bancarias** - CRUD completo
9. **Pagos** - CRUD + actualización con PDF
10. **Documentos** - Listar, obtener, upload, reprocesar, eliminar
11. **Facturas** - Procesar facturas (actualizado con `usuario_id`)
12. **Correos** - CRUD + generar automático + **enviar con usuario_id**
13. **Webhooks** - Recibir notificaciones
14. **Eventos de Auditoría** - Consultar eventos
15. **Análisis y Reportes** - Dashboard y métricas

---

## 🔄 ACTUALIZACIONES 2026

### ✅ Cambios Implementados

1. **Versión actualizada** a 2.0.0
2. **Descripción actualizada** mencionando `usuario_id`
3. **Endpoint "Enviar Correo"** con descripción del webhook actualizado:
   - URL: `https://n8n.salazargroup.cloud/webhook/gmail_g`
   - Incluye `usuario_id` automáticamente

4. **Endpoint "Procesar Facturas"** actualizado:
   - Ruta corregida: `/pagos/subir-facturas`
   - Payload incluye `usuario_id`
   - Descripción del webhook N8N

---

## 📝 ENDPOINTS CON `usuario_id`

Los siguientes endpoints ahora incluyen `usuario_id` automáticamente:

### 1. Enviar Correo

```
POST /correos/:id/enviar
```

- El `usuario_id` se obtiene del usuario logueado
- Se envía automáticamente al webhook de N8N
- Webhook: `https://n8n.salazargroup.cloud/webhook/gmail_g`

### 2. Subir Facturas

```
POST /pagos/subir-facturas
```

**Payload:**

```json
{
  "usuario_id": 2,
  "facturas": [
    {
      "pdf": "base64...",
      "proveedor_id": 1
    }
  ]
}
```

- Webhook: `https://n8n.salazargroup.cloud/webhook/docu`

### 3. Documento de Estado

```
POST /pagos/documento-estado
```

**Payload:**

```json
{
  "pdf": "base64...",
  "id_pago": 10,
  "usuario_id": 2
}
```

- Webhook: `https://n8n.salazargroup.cloud/webhook/documento_pago`

### 4. Extracto de Banco

```
POST /pagos/subir-extracto-banco
```

**Payload:**

```json
{
  "pdf": "base64...",
  "usuario_id": 2
}
```

- Webhook: `https://n8n.salazargroup.cloud/webhook/docu`

---

## 🚀 CÓMO USAR LA COLECCIÓN

### Paso 1: Importar en Postman

```
1. Abrir Postman
2. File > Import
3. Seleccionar: API_Terra_Canada.postman_collection.json
4. Click "Import"
```

### Paso 2: Configurar Variables

La colección ya incluye variables preconfiguradas:

- `base_url`: `http://localhost:3000/api/v1`
- `jwt_token`: (se configura automáticamente)

### Paso 3: Autenticarse

```
1. Ir a carpeta "1. Authentication"
2. Ejecutar request "Login"
3. El token JWT se guarda automáticamente en la variable jwt_token
```

### Paso 4: Probar Endpoints

Todos los endpoints usan automáticamente el token JWT guardado.

---

## 📊 ESTADÍSTICAS

| Métrica                      | Valor |
| ---------------------------- | ----- |
| **Total de módulos**         | 15    |
| **Total de endpoints**       | ~60+  |
| **Endpoints con usuario_id** | 4     |
| **Webhooks N8N**             | 3     |
| **Versión**                  | 2.0.0 |

---

## 🔐 AUTENTICACIÓN

Todos los endpoints (excepto `/auth/login`) requieren:

```http
Authorization: Bearer {{jwt_token}}
```

El token se configura automáticamente al hacer login.

---

## 📚 DOCUMENTACIÓN RELACIONADA

| Documento                    | Descripción                                  |
| ---------------------------- | -------------------------------------------- |
| `API_ENDPOINTS_REFERENCE.md` | Referencia completa con códigos de respuesta |
| `INTEGRACION_N8N_CORREOS.md` | Detalles del webhook de correos              |
| `MODULO_DOCUMENTOS.md`       | Documentación del módulo de documentos       |
| `README_DOCUMENTACION.md`    | Resumen general de toda la documentación     |

---

## ✅ VERIFICACIÓN

Para verificar que la colección está completa:

1. ✅ Importar en Postman
2. ✅ Verificar que hay 15 carpetas (módulos)
3. ✅ Ejecutar "Login" y verificar que el token se guarda
4. ✅ Probar cualquier endpoint protegido
5. ✅ Verificar que el endpoint "Enviar Correo" tiene descripción actualizada

---

## 🎯 PRÓXIMOS PASOS

1. **Importar** la colección en Postman
2. **Probar** el flujo de autenticación
3. **Verificar** los endpoints con `usuario_id`
4. **Documentar** cualquier endpoint faltante

---

**Actualizado por:** Antigravity AI  
**Fecha:** 30 de Enero de 2026  
**Estado:** ✅ COMPLETO - Todos los módulos incluidos
