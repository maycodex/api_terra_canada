# 📚 API TERRA CANADA - REFERENCIA DE ENDPOINTS

**Versión:** 1.0.0  
**Base URL:** `http://localhost:3000/api/v1`  
**Fecha:** 30 de Enero de 2026

---

## 📋 ÍNDICE

1. [Autenticación](#autenticación)
2. [Usuarios](#usuarios)
3. [Roles](#roles)
4. [Servicios](#servicios)
5. [Proveedores](#proveedores)
6. [Clientes](#clientes)
7. [Tarjetas](#tarjetas)
8. [Cuentas](#cuentas)
9. [Pagos](#pagos)
10. [Documentos](#documentos)
11. [Correos](#correos)
12. [Eventos](#eventos)
13. [Análisis](#análisis)
14. [Webhooks](#webhooks)

---

## 🔐 AUTENTICACIÓN

### POST `/auth/login`

**Descripción:** Iniciar sesión  
**Auth:** No requerida

**Request Body:**

```json
{
  "nombre_usuario": "admin",
  "contrasena": "password123"
}
```

**Respuestas:**

- **200 OK** - Login exitoso
  ```json
  {
    "code": 200,
    "estado": true,
    "message": "Login exitoso",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "usuario": {
        "id": 1,
        "nombre_usuario": "admin",
        "rol": "ADMIN"
      }
    }
  }
  ```
- **400 Bad Request** - Credenciales inválidas
- **401 Unauthorized** - Usuario o contraseña incorrectos

---

### POST `/auth/refresh`

**Descripción:** Refrescar token JWT  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Token refrescado
- **401 Unauthorized** - Token inválido o expirado

---

### POST `/auth/logout`

**Descripción:** Cerrar sesión  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Sesión cerrada exitosamente

---

## 👥 USUARIOS

### GET `/usuarios`

**Descripción:** Obtener todos los usuarios  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Lista de usuarios
  ```json
  {
    "code": 200,
    "estado": true,
    "message": "Usuarios obtenidos exitosamente",
    "data": [...]
  }
  ```
- **401 Unauthorized** - No autenticado
- **403 Forbidden** - Sin permisos

---

### GET `/usuarios/:id`

**Descripción:** Obtener usuario por ID  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Usuario encontrado
- **404 Not Found** - Usuario no encontrado

---

### POST `/usuarios`

**Descripción:** Crear nuevo usuario  
**Auth:** Bearer Token (ADMIN)

**Request Body:**

```json
{
  "nombre_usuario": "nuevo_usuario",
  "contrasena": "password123",
  "nombre_completo": "Juan Pérez",
  "correo": "juan@example.com",
  "rol_id": 2
}
```

**Respuestas:**

- **201 Created** - Usuario creado
- **400 Bad Request** - Datos inválidos
- **409 Conflict** - Usuario ya existe

---

### PUT `/usuarios/:id`

**Descripción:** Actualizar usuario  
**Auth:** Bearer Token (ADMIN o propio usuario)

**Respuestas:**

- **200 OK** - Usuario actualizado
- **400 Bad Request** - Datos inválidos
- **404 Not Found** - Usuario no encontrado

---

### DELETE `/usuarios/:id`

**Descripción:** Eliminar usuario (soft delete)  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Usuario eliminado
- **404 Not Found** - Usuario no encontrado

---

### PUT `/usuarios/:id/cambiar-contrasena`

**Descripción:** Cambiar contraseña  
**Auth:** Bearer Token

**Request Body:**

```json
{
  "contrasena_actual": "old_password",
  "contrasena_nueva": "new_password"
}
```

**Respuestas:**

- **200 OK** - Contraseña actualizada
- **400 Bad Request** - Contraseña actual incorrecta

---

## 🎭 ROLES

### GET `/roles`

**Descripción:** Obtener todos los roles  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de roles

---

### GET `/roles/:id`

**Descripción:** Obtener rol por ID  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Rol encontrado
- **404 Not Found** - Rol no encontrado

---

### POST `/roles`

**Descripción:** Crear nuevo rol  
**Auth:** Bearer Token (ADMIN)

**Request Body:**

```json
{
  "nombre": "CUSTOM_ROLE",
  "descripcion": "Rol personalizado"
}
```

**Respuestas:**

- **201 Created** - Rol creado
- **400 Bad Request** - Datos inválidos
- **409 Conflict** - Rol ya existe

---

## 🛠️ SERVICIOS

### GET `/servicios`

**Descripción:** Obtener todos los servicios  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de servicios

---

### POST `/servicios`

**Descripción:** Crear nuevo servicio  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre": "Vuelos",
  "descripcion": "Servicio de vuelos internacionales"
}
```

**Respuestas:**

- **201 Created** - Servicio creado
- **400 Bad Request** - Datos inválidos

---

## 🏢 PROVEEDORES

### GET `/proveedores`

**Descripción:** Obtener todos los proveedores  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de proveedores

---

### GET `/proveedores/:id`

**Descripción:** Obtener proveedor por ID  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Proveedor encontrado
- **404 Not Found** - Proveedor no encontrado

---

### POST `/proveedores`

**Descripción:** Crear nuevo proveedor  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre": "Air Canada",
  "lenguaje": "English",
  "servicio_id": 1
}
```

**Respuestas:**

- **201 Created** - Proveedor creado
- **400 Bad Request** - Datos inválidos

---

### PUT `/proveedores/:id`

**Descripción:** Actualizar proveedor  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Proveedor actualizado
- **404 Not Found** - Proveedor no encontrado

---

### DELETE `/proveedores/:id`

**Descripción:** Eliminar proveedor  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Proveedor eliminado
- **404 Not Found** - Proveedor no encontrado

---

## 👤 CLIENTES

### GET `/clientes`

**Descripción:** Obtener todos los clientes  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de clientes

---

### GET `/clientes/:id`

**Descripción:** Obtener cliente por ID  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Cliente encontrado
- **404 Not Found** - Cliente no encontrado

---

### POST `/clientes`

**Descripción:** Crear nuevo cliente  
**Auth:** Bearer Token (ADMIN, SUPERVISOR, EQUIPO)

**Request Body:**

```json
{
  "nombre": "Juan Pérez",
  "correo": "juan@example.com",
  "telefono": "+1234567890"
}
```

**Respuestas:**

- **201 Created** - Cliente creado
- **400 Bad Request** - Datos inválidos

---

## 💳 TARJETAS

### GET `/tarjetas`

**Descripción:** Obtener todas las tarjetas  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de tarjetas

---

### POST `/tarjetas`

**Descripción:** Crear nueva tarjeta  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "numero_tarjeta": "1234",
  "tipo": "CREDITO",
  "banco": "TD Bank"
}
```

**Respuestas:**

- **201 Created** - Tarjeta creada
- **400 Bad Request** - Datos inválidos

---

## 🏦 CUENTAS

### GET `/cuentas`

**Descripción:** Obtener todas las cuentas bancarias  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de cuentas

---

### POST `/cuentas`

**Descripción:** Crear nueva cuenta  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre_cuenta": "Cuenta Principal",
  "banco": "RBC",
  "numero_cuenta": "1234567890"
}
```

**Respuestas:**

- **201 Created** - Cuenta creada
- **400 Bad Request** - Datos inválidos

---

## 💰 PAGOS

### GET `/pagos`

**Descripción:** Obtener todos los pagos con filtros  
**Auth:** Bearer Token

**Query Parameters:**

- `proveedor_id` (opcional)
- `pagado` (opcional): true/false
- `verificado` (opcional): true/false
- `fecha_desde` (opcional)
- `fecha_hasta` (opcional)

**Respuestas:**

- **200 OK** - Lista de pagos

---

### GET `/pagos/:id`

**Descripción:** Obtener pago por ID  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Pago encontrado
- **404 Not Found** - Pago no encontrado

---

### POST `/pagos`

**Descripción:** Crear nuevo pago  
**Auth:** Bearer Token (ADMIN, SUPERVISOR, EQUIPO)

**Request Body:**

```json
{
  "codigo_reserva": "RES-2026-001",
  "monto": 1500.0,
  "moneda": "CAD",
  "proveedor_id": 1,
  "tarjeta_id": 1,
  "cuenta_id": 1,
  "cliente_ids": [1, 2]
}
```

**Respuestas:**

- **201 Created** - Pago creado
- **400 Bad Request** - Datos inválidos
- **404 Not Found** - Proveedor/Tarjeta/Cuenta no encontrada

---

### PUT `/pagos/:id`

**Descripción:** Actualizar pago  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Pago actualizado
- **404 Not Found** - Pago no encontrado

---

### DELETE `/pagos/:id`

**Descripción:** Eliminar pago  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Pago eliminado
- **404 Not Found** - Pago no encontrado

---

### POST `/pagos/documento-estado`

**Descripción:** Enviar documento de estado de pago a N8N  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "pdf": "base64_string",
  "id_pago": 10,
  "usuario_id": 2
}
```

**Respuestas:**

- **200 OK** - Documento procesado (respuesta del webhook N8N)
- **400 Bad Request** - Datos inválidos o error del webhook

---

### POST `/pagos/subir-facturas`

**Descripción:** Subir múltiples facturas (hasta 3) a N8N  
**Auth:** Bearer Token (ADMIN, SUPERVISOR, EQUIPO)

**Request Body:**

```json
{
  "usuario_id": 2,
  "facturas": [
    {
      "pdf": "base64_string",
      "proveedor_id": 1
    }
  ]
}
```

**Respuestas:**

- **200 OK** - Facturas procesadas (respuesta del webhook N8N)
- **400 Bad Request** - Máximo 3 facturas o error del webhook

---

### POST `/pagos/subir-extracto-banco`

**Descripción:** Subir extracto bancario a N8N  
**Auth:** Bearer Token (ADMIN, SUPERVISOR, EQUIPO)

**Request Body:**

```json
{
  "pdf": "base64_string",
  "usuario_id": 2
}
```

**Respuestas:**

- **200 OK** - Extracto procesado (respuesta del webhook N8N)
- **400 Bad Request** - Error del webhook

---

## 📄 DOCUMENTOS

### GET `/documentos`

**Descripción:** Obtener todos los documentos  
**Auth:** Bearer Token (ADMIN, SUPERVISOR, EQUIPO)

**Respuestas:**

- **200 OK** - Lista de documentos

---

### GET `/documentos/:id`

**Descripción:** Obtener documento por ID con pagos vinculados  
**Auth:** Bearer Token (ADMIN, SUPERVISOR, EQUIPO)

**Respuestas:**

- **200 OK** - Documento encontrado
- **404 Not Found** - Documento no encontrado

---

### POST `/documentos`

**Descripción:** Crear nuevo documento  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "tipo_documento": "FACTURA",
  "nombre_archivo": "factura_RES-2026-001.pdf",
  "url_documento": "https://storage.terracanada.com/facturas/factura.pdf",
  "usuario_id": 2,
  "pago_id": 10
}
```

**Respuestas:**

- **201 Created** - Documento creado
- **400 Bad Request** - Datos inválidos
- **404 Not Found** - Usuario o pago no encontrado

---

### PUT `/documentos/:id`

**Descripción:** Actualizar documento  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre_archivo": "nuevo_nombre.pdf",
  "url_documento": "https://nueva.url/documento.pdf"
}
```

**Respuestas:**

- **200 OK** - Documento actualizado
- **400 Bad Request** - Debe proporcionar al menos un campo
- **404 Not Found** - Documento no encontrado

---

### DELETE `/documentos/:id`

**Descripción:** Eliminar documento  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Documento eliminado
- **404 Not Found** - Documento no encontrado
- **409 Conflict** - Tiene pagos verificados vinculados

---

## 📧 CORREOS

### GET `/correos`

**Descripción:** Obtener todos los correos con filtros  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Query Parameters:**

- `estado` (opcional): BORRADOR, ENVIADO
- `proveedor_id` (opcional)
- `fecha_desde` (opcional)
- `fecha_hasta` (opcional)

**Respuestas:**

- **200 OK** - Lista de correos

---

### GET `/correos/pendientes`

**Descripción:** Obtener correos pendientes (BORRADOR)  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Lista de correos pendientes

---

### GET `/correos/:id`

**Descripción:** Obtener correo por ID  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Correo encontrado
- **404 Not Found** - Correo no encontrado

---

### POST `/correos/generar`

**Descripción:** Generar correos automáticamente para pagos pendientes  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body (opcional):**

```json
{
  "proveedor_id": 1
}
```

**Respuestas:**

- **201 Created** - Correos generados
- **200 OK** - No hay pagos pendientes

---

### POST `/correos`

**Descripción:** Crear correo manualmente  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "proveedor_id": 1,
  "correo_seleccionado": "billing@proveedor.com",
  "asunto": "Notificación de Pagos",
  "cuerpo": "Estimado proveedor...",
  "pago_ids": [1, 2, 3]
}
```

**Respuestas:**

- **201 Created** - Correo creado
- **400 Bad Request** - Datos inválidos o pagos no válidos
- **404 Not Found** - Proveedor no encontrado

---

### PUT `/correos/:id`

**Descripción:** Actualizar borrador de correo  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "asunto": "Nuevo asunto",
  "cuerpo": "Nuevo cuerpo"
}
```

**Respuestas:**

- **200 OK** - Correo actualizado
- **404 Not Found** - Correo no encontrado
- **409 Conflict** - El correo ya fue enviado

---

### POST `/correos/:id/enviar`

**Descripción:** Enviar correo vía N8N (Gmail)  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body (opcional):**

```json
{
  "asunto": "Edición de último momento",
  "cuerpo": "Edición de último momento"
}
```

**Respuestas:**

- **200 OK** - Correo enviado exitosamente
- **400 Bad Request** - Error del webhook N8N
- **404 Not Found** - Correo no encontrado
- **409 Conflict** - Solo se pueden enviar borradores
- **503 Service Unavailable** - No se pudo conectar con N8N

---

### DELETE `/correos/:id`

**Descripción:** Eliminar borrador de correo  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Correo eliminado
- **404 Not Found** - Correo no encontrado
- **409 Conflict** - No se pueden eliminar correos enviados

---

## 📊 EVENTOS

### GET `/eventos`

**Descripción:** Obtener eventos de auditoría  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Query Parameters:**

- `tipo_evento` (opcional)
- `usuario_id` (opcional)
- `tabla_afectada` (opcional)
- `fecha_desde` (opcional)
- `fecha_hasta` (opcional)

**Respuestas:**

- **200 OK** - Lista de eventos

---

### GET `/eventos/:id`

**Descripción:** Obtener evento por ID  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Evento encontrado
- **404 Not Found** - Evento no encontrado

---

## 📈 ANÁLISIS

### GET `/analisis/dashboard`

**Descripción:** Obtener métricas del dashboard  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Métricas del dashboard

---

### GET `/analisis/pagos-por-proveedor`

**Descripción:** Análisis de pagos agrupados por proveedor  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Estadísticas por proveedor

---

### GET `/analisis/tendencias`

**Descripción:** Tendencias de pagos en el tiempo  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Query Parameters:**

- `periodo` (opcional): mensual, semanal, diario

**Respuestas:**

- **200 OK** - Datos de tendencias

---

## 🔗 WEBHOOKS

### POST `/webhooks/n8n`

**Descripción:** Recibir notificaciones de N8N  
**Auth:** API Key

**Respuestas:**

- **200 OK** - Webhook procesado
- **400 Bad Request** - Payload inválido

---

## 📝 CÓDIGOS DE RESPUESTA COMUNES

| Código  | Descripción                                          |
| ------- | ---------------------------------------------------- |
| **200** | OK - Operación exitosa                               |
| **201** | Created - Recurso creado exitosamente                |
| **400** | Bad Request - Datos inválidos o error de validación  |
| **401** | Unauthorized - No autenticado o token inválido       |
| **403** | Forbidden - Sin permisos para esta operación         |
| **404** | Not Found - Recurso no encontrado                    |
| **409** | Conflict - Conflicto (ej: recurso ya existe)         |
| **500** | Internal Server Error - Error del servidor           |
| **503** | Service Unavailable - Servicio externo no disponible |

---

## 🔑 AUTENTICACIÓN

Todos los endpoints (excepto `/auth/login`) requieren un token JWT en el header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 📦 FORMATO DE RESPUESTA ESTÁNDAR

### Respuesta Exitosa

```json
{
  "code": 200,
  "estado": true,
  "message": "Operación exitosa",
  "data": { ... }
}
```

### Respuesta de Error

```json
{
  "code": 400,
  "estado": false,
  "message": "Descripción del error",
  "data": null
}
```

---

**Última actualización:** 30 de Enero de 2026  
**Documentación generada automáticamente**
