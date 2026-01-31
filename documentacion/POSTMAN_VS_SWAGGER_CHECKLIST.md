# ✅ CHECKLIST: POSTMAN vs SWAGGER - Comparación Completa

**Fecha:** 30 de Enero de 2026  
**Versión Postman:** 2.0.0  
**Base URL:** `http://localhost:3000/api/v1`

---

## 📋 RESUMEN EJECUTIVO

| Métrica                  | Valor                     |
| ------------------------ | ------------------------- |
| **Módulos totales**      | 16                        |
| **Endpoints en código**  | ~70+                      |
| **Endpoints en Postman** | ~60                       |
| **Estado**               | ⚠️ REQUIERE ACTUALIZACIÓN |

---

## 1️⃣ AUTENTICACIÓN (auth.routes.ts)

### Endpoints en Código:

| Método | Ruta          | Descripción                 |
| ------ | ------------- | --------------------------- |
| POST   | `/auth/login` | Iniciar sesión              |
| GET    | `/auth/me`    | Obtener usuario autenticado |

### Endpoints en Postman:

| Método | Ruta            | Estado                                |
| ------ | --------------- | ------------------------------------- |
| POST   | `/auth/login`   | ✅ OK                                 |
| GET    | `/auth/profile` | ⚠️ DIFERENTE (debería ser `/auth/me`) |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Cambiar `/auth/profile` a `/auth/me` en Postman

---

## 2️⃣ USUARIOS (usuarios.routes.ts)

### Endpoints en Código:

| Método | Ruta            | Descripción                    |
| ------ | --------------- | ------------------------------ |
| GET    | `/usuarios`     | Listar todos                   |
| GET    | `/usuarios/:id` | Obtener por ID                 |
| POST   | `/usuarios`     | Crear usuario                  |
| PUT    | `/usuarios/:id` | Actualizar usuario             |
| DELETE | `/usuarios/:id` | Eliminar usuario (soft delete) |

### Endpoints en Postman:

| Método | Ruta            | Estado |
| ------ | --------------- | ------ |
| GET    | `/usuarios`     | ✅ OK  |
| GET    | `/usuarios/:id` | ✅ OK  |
| POST   | `/usuarios`     | ✅ OK  |
| PUT    | `/usuarios/:id` | ✅ OK  |
| DELETE | `/usuarios/:id` | ✅ OK  |

### ✅ ESTADO: COMPLETO

---

## 3️⃣ ROLES (roles.routes.ts)

### Endpoints en Código:

| Método | Ruta         | Descripción    |
| ------ | ------------ | -------------- |
| GET    | `/roles`     | Listar todos   |
| GET    | `/roles/:id` | Obtener por ID |
| POST   | `/roles`     | Crear rol      |
| PUT    | `/roles/:id` | Actualizar rol |
| DELETE | `/roles/:id` | Eliminar rol   |

### Endpoints en Postman:

| Método | Ruta         | Estado   |
| ------ | ------------ | -------- |
| GET    | `/roles`     | ✅ OK    |
| GET    | `/roles/:id` | ✅ OK    |
| POST   | `/roles`     | ❌ FALTA |
| PUT    | `/roles/:id` | ❌ FALTA |
| DELETE | `/roles/:id` | ❌ FALTA |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Agregar POST `/roles`
- [ ] Agregar PUT `/roles/:id`
- [ ] Agregar DELETE `/roles/:id`

---

## 4️⃣ PROVEEDORES (proveedores.routes.ts)

### Endpoints en Código:

| Método | Ruta                       | Descripción                |
| ------ | -------------------------- | -------------------------- |
| GET    | `/proveedores`             | Listar todos               |
| GET    | `/proveedores/:id`         | Obtener por ID             |
| POST   | `/proveedores`             | Crear proveedor            |
| PUT    | `/proveedores/:id`         | Actualizar proveedor       |
| DELETE | `/proveedores/:id`         | Eliminar proveedor         |
| POST   | `/proveedores/:id/correos` | Agregar correo a proveedor |

### Endpoints en Postman:

| Método | Ruta                       | Estado |
| ------ | -------------------------- | ------ |
| GET    | `/proveedores`             | ✅ OK  |
| GET    | `/proveedores/:id`         | ✅ OK  |
| POST   | `/proveedores`             | ✅ OK  |
| PUT    | `/proveedores/:id`         | ✅ OK  |
| DELETE | `/proveedores/:id`         | ✅ OK  |
| POST   | `/proveedores/:id/correos` | ✅ OK  |

### ✅ ESTADO: COMPLETO

---

## 5️⃣ SERVICIOS (servicios.routes.ts)

### Endpoints en Código:

| Método | Ruta             | Descripción         |
| ------ | ---------------- | ------------------- |
| GET    | `/servicios`     | Listar todos        |
| GET    | `/servicios/:id` | Obtener por ID      |
| POST   | `/servicios`     | Crear servicio      |
| PUT    | `/servicios/:id` | Actualizar servicio |
| DELETE | `/servicios/:id` | Eliminar servicio   |

### Endpoints en Postman:

| Método | Ruta             | Estado |
| ------ | ---------------- | ------ |
| GET    | `/servicios`     | ✅ OK  |
| GET    | `/servicios/:id` | ✅ OK  |
| POST   | `/servicios`     | ✅ OK  |
| PUT    | `/servicios/:id` | ✅ OK  |
| DELETE | `/servicios/:id` | ✅ OK  |

### ✅ ESTADO: COMPLETO

---

## 6️⃣ CLIENTES (clientes.routes.ts)

### Endpoints en Código:

| Método | Ruta            | Descripción        |
| ------ | --------------- | ------------------ |
| GET    | `/clientes`     | Listar todos       |
| GET    | `/clientes/:id` | Obtener por ID     |
| POST   | `/clientes`     | Crear cliente      |
| PUT    | `/clientes/:id` | Actualizar cliente |
| DELETE | `/clientes/:id` | Eliminar cliente   |

### Endpoints en Postman:

| Método | Ruta            | Estado |
| ------ | --------------- | ------ |
| GET    | `/clientes`     | ✅ OK  |
| GET    | `/clientes/:id` | ✅ OK  |
| POST   | `/clientes`     | ✅ OK  |
| PUT    | `/clientes/:id` | ✅ OK  |
| DELETE | `/clientes/:id` | ✅ OK  |

### ✅ ESTADO: COMPLETO

---

## 7️⃣ TARJETAS (tarjetas.routes.ts)

### Endpoints en Código:

| Método | Ruta                          | Descripción        |
| ------ | ----------------------------- | ------------------ |
| GET    | `/tarjetas`                   | Listar todas       |
| GET    | `/tarjetas/:id`               | Obtener por ID     |
| POST   | `/tarjetas`                   | Crear tarjeta      |
| PUT    | `/tarjetas/:id`               | Actualizar tarjeta |
| DELETE | `/tarjetas/:id`               | Eliminar tarjeta   |
| PUT    | `/tarjetas/:id/toggle-activo` | Activar/Desactivar |

### Endpoints en Postman:

| Método | Ruta                          | Estado |
| ------ | ----------------------------- | ------ |
| GET    | `/tarjetas`                   | ✅ OK  |
| GET    | `/tarjetas/:id`               | ✅ OK  |
| POST   | `/tarjetas`                   | ✅ OK  |
| PUT    | `/tarjetas/:id`               | ✅ OK  |
| DELETE | `/tarjetas/:id`               | ✅ OK  |
| PUT    | `/tarjetas/:id/toggle-activo` | ✅ OK  |

### ✅ ESTADO: COMPLETO

---

## 8️⃣ CUENTAS BANCARIAS (cuentas.routes.ts)

### Endpoints en Código:

| Método | Ruta           | Descripción       |
| ------ | -------------- | ----------------- |
| GET    | `/cuentas`     | Listar todas      |
| GET    | `/cuentas/:id` | Obtener por ID    |
| POST   | `/cuentas`     | Crear cuenta      |
| PUT    | `/cuentas/:id` | Actualizar cuenta |
| DELETE | `/cuentas/:id` | Eliminar cuenta   |

### Endpoints en Postman:

| Método | Ruta           | Estado |
| ------ | -------------- | ------ |
| GET    | `/cuentas`     | ✅ OK  |
| GET    | `/cuentas/:id` | ✅ OK  |
| POST   | `/cuentas`     | ✅ OK  |
| PUT    | `/cuentas/:id` | ✅ OK  |
| DELETE | `/cuentas/:id` | ✅ OK  |

### ✅ ESTADO: COMPLETO

---

## 9️⃣ PAGOS (pagos.routes.ts)

### Endpoints en Código:

| Método | Ruta                          | Descripción                      |
| ------ | ----------------------------- | -------------------------------- |
| GET    | `/pagos`                      | Listar con filtros               |
| GET    | `/pagos/:id`                  | Obtener por ID                   |
| POST   | `/pagos`                      | Crear pago                       |
| PUT    | `/pagos/:id`                  | Actualizar pago                  |
| DELETE | `/pagos/:id`                  | Cancelar pago                    |
| PATCH  | `/pagos/:id/desactivar`       | Desactivar pago                  |
| PATCH  | `/pagos/:id/activar`          | Activar pago                     |
| POST   | `/pagos/documento-estado`     | Enviar documento de estado (N8N) |
| POST   | `/pagos/subir-facturas`       | Subir facturas (N8N)             |
| POST   | `/pagos/subir-extracto-banco` | Subir extracto bancario (N8N)    |

### Endpoints en Postman:

| Método | Ruta                          | Estado                  |
| ------ | ----------------------------- | ----------------------- |
| GET    | `/pagos`                      | ✅ OK                   |
| GET    | `/pagos/:id`                  | ✅ OK                   |
| POST   | `/pagos`                      | ✅ OK                   |
| PUT    | `/pagos/:id`                  | ✅ OK                   |
| DELETE | `/pagos/:id`                  | ✅ OK                   |
| PUT    | `/pagos/:id/con-pdf`          | ⚠️ EXTRA (no en código) |
| PATCH  | `/pagos/:id/desactivar`       | ❌ FALTA                |
| PATCH  | `/pagos/:id/activar`          | ❌ FALTA                |
| POST   | `/pagos/documento-estado`     | ❌ FALTA                |
| POST   | `/pagos/subir-facturas`       | ❌ FALTA                |
| POST   | `/pagos/subir-extracto-banco` | ❌ FALTA                |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Agregar PATCH `/pagos/:id/desactivar`
- [ ] Agregar PATCH `/pagos/:id/activar`
- [ ] Agregar POST `/pagos/documento-estado` (con `usuario_id`)
- [ ] Agregar POST `/pagos/subir-facturas` (con `usuario_id`)
- [ ] Agregar POST `/pagos/subir-extracto-banco` (con `usuario_id`)
- [ ] Revisar si `/pagos/:id/con-pdf` es necesario

---

## 🔟 DOCUMENTOS (documentos.routes.ts)

### Endpoints en Código:

| Método | Ruta              | Descripción          |
| ------ | ----------------- | -------------------- |
| GET    | `/documentos`     | Listar todos         |
| GET    | `/documentos/:id` | Obtener por ID       |
| POST   | `/documentos`     | Crear documento      |
| PUT    | `/documentos/:id` | Actualizar documento |
| DELETE | `/documentos/:id` | Eliminar documento   |

### Endpoints en Postman:

| Método | Ruta                         | Estado                                   |
| ------ | ---------------------------- | ---------------------------------------- |
| GET    | `/documentos`                | ✅ OK                                    |
| GET    | `/documentos/:id`            | ✅ OK (nombre: "Obtener Documento")      |
| POST   | `/documentos/upload`         | ⚠️ DIFERENTE (debería ser `/documentos`) |
| POST   | `/documentos/:id/reprocesar` | ⚠️ EXTRA (no en código)                  |
| DELETE | `/documentos/:id`            | ✅ OK                                    |
| PUT    | `/documentos/:id`            | ❌ FALTA                                 |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Cambiar POST `/documentos/upload` a POST `/documentos`
- [ ] Cambiar body de `formdata` a `JSON` con campos: `tipo_documento`, `nombre_archivo`, `url_documento`, `usuario_id`, `pago_id`
- [ ] Agregar PUT `/documentos/:id`
- [ ] Revisar si `/documentos/:id/reprocesar` es necesario

---

## 1️⃣1️⃣ FACTURAS (facturas.routes.ts)

### Endpoints en Código:

| Método | Ruta                 | Descripción                     |
| ------ | -------------------- | ------------------------------- |
| POST   | `/facturas/procesar` | Procesar facturas (webhook N8N) |

### Endpoints en Postman:

| Método | Ruta                 | Estado                                                   |
| ------ | -------------------- | -------------------------------------------------------- |
| POST   | `/facturas/procesar` | ⚠️ RUTA INCORRECTA (debería ser `/pagos/subir-facturas`) |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Mover endpoint a módulo "Pagos"
- [ ] Cambiar ruta a `/pagos/subir-facturas`
- [ ] Actualizar payload para incluir `usuario_id`

---

## 1️⃣2️⃣ CORREOS (correos.routes.ts)

### Endpoints en Código:

| Método | Ruta                  | Descripción                          |
| ------ | --------------------- | ------------------------------------ |
| GET    | `/correos`            | Listar con filtros                   |
| GET    | `/correos/pendientes` | Obtener pendientes                   |
| GET    | `/correos/:id`        | Obtener por ID                       |
| POST   | `/correos/generar`    | Generar automáticamente              |
| POST   | `/correos`            | Crear manualmente                    |
| PUT    | `/correos/:id`        | Actualizar borrador                  |
| POST   | `/correos/:id/enviar` | Enviar correo (N8N con `usuario_id`) |
| DELETE | `/correos/:id`        | Eliminar borrador                    |

### Endpoints en Postman:

| Método | Ruta                  | Estado                                           |
| ------ | --------------------- | ------------------------------------------------ |
| GET    | `/correos`            | ✅ OK                                            |
| GET    | `/correos/pendientes` | ❌ FALTA                                         |
| GET    | `/correos/:id`        | ✅ OK                                            |
| POST   | `/correos/generar`    | ✅ OK (nombre: "Generar Correo Automático")      |
| POST   | `/correos`            | ✅ OK (nombre: "Crear Correo Manual")            |
| PUT    | `/correos/:id`        | ✅ OK (nombre: "Actualizar Correo")              |
| POST   | `/correos/:id/enviar` | ✅ OK (descripción actualizada con `usuario_id`) |
| DELETE | `/correos/:id`        | ✅ OK                                            |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Agregar GET `/correos/pendientes`

---

## 1️⃣3️⃣ WEBHOOKS (webhooks.routes.ts)

### Endpoints en Código:

| Método | Ruta            | Descripción                   |
| ------ | --------------- | ----------------------------- |
| POST   | `/webhooks/n8n` | Recibir notificaciones de N8N |

### Endpoints en Postman:

| Método | Ruta            | Estado                         |
| ------ | --------------- | ------------------------------ |
| POST   | `/webhooks/n8n` | ✅ OK (si existe en colección) |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Verificar si existe en colección

---

## 1️⃣4️⃣ EVENTOS (eventos.routes.ts)

### Endpoints en Código:

| Método | Ruta       | Descripción                 |
| ------ | ---------- | --------------------------- |
| GET    | `/eventos` | Listar eventos de auditoría |

### Endpoints en Postman:

| Método | Ruta       | Estado                                             |
| ------ | ---------- | -------------------------------------------------- |
| GET    | `/eventos` | ✅ OK (si existe en módulo "Eventos de Auditoría") |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Verificar si existe en colección

---

## 1️⃣5️⃣ ANÁLISIS (analisis.routes.ts)

### Endpoints en Código:

| Método | Ruta                   | Descripción         |
| ------ | ---------------------- | ------------------- |
| GET    | `/analisis/dashboard`  | Dashboard general   |
| GET    | `/analisis/tendencias` | Tendencias de pagos |

### Endpoints en Postman:

| Método | Ruta                   | Estado                                            |
| ------ | ---------------------- | ------------------------------------------------- |
| GET    | `/analisis/dashboard`  | ✅ OK (si existe en módulo "Análisis y Reportes") |
| GET    | `/analisis/tendencias` | ✅ OK (si existe)                                 |

### ⚠️ ACCIONES REQUERIDAS:

- [ ] Verificar si existen en colección

---

## 📊 RESUMEN DE ACCIONES

### 🔴 CRÍTICO (Endpoints faltantes importantes):

1. **Pagos - Webhooks N8N:**
   - [ ] POST `/pagos/documento-estado` (con `usuario_id`)
   - [ ] POST `/pagos/subir-facturas` (con `usuario_id`)
   - [ ] POST `/pagos/subir-extracto-banco` (con `usuario_id`)

2. **Pagos - Activar/Desactivar:**
   - [ ] PATCH `/pagos/:id/desactivar`
   - [ ] PATCH `/pagos/:id/activar`

3. **Documentos:**
   - [ ] PUT `/documentos/:id`
   - [ ] Corregir POST `/documentos` (cambiar de formdata a JSON)

### 🟡 IMPORTANTE (Endpoints faltantes):

4. **Roles:**
   - [ ] POST `/roles`
   - [ ] PUT `/roles/:id`
   - [ ] DELETE `/roles/:id`

5. **Correos:**
   - [ ] GET `/correos/pendientes`

### 🟢 MENOR (Correcciones):

6. **Auth:**
   - [ ] Cambiar GET `/auth/profile` a `/auth/me`

7. **Facturas:**
   - [ ] Mover a módulo Pagos y actualizar ruta

---

## 📝 PRIORIDAD DE ACTUALIZACIÓN

### Alta Prioridad:

1. Agregar webhooks de Pagos (documento-estado, subir-facturas, subir-extracto-banco)
2. Agregar endpoints de activar/desactivar pagos
3. Corregir endpoint de documentos

### Media Prioridad:

4. Agregar CRUD completo de Roles
5. Agregar GET `/correos/pendientes`

### Baja Prioridad:

6. Corregir `/auth/profile` a `/auth/me`
7. Reorganizar módulo de Facturas

---

## ✅ PRÓXIMOS PASOS

1. **Actualizar colección de Postman** con endpoints faltantes
2. **Verificar payloads** de todos los endpoints
3. **Probar** cada endpoint actualizado
4. **Documentar** cambios en README

---

**Generado por:** Antigravity AI  
**Fecha:** 30 de Enero de 2026  
**Estado:** ⚠️ REQUIERE ACTUALIZACIÓN
