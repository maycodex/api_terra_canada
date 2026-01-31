# 📚 API TERRA CANADA - REFERENCIA DE ENDPOINTS

**Versión:** 2.0.0  
**Base URL:** `http://localhost:3000/api/v1`  
**Fecha:** 31 de Enero de 2026  
**Colección Postman:** API_Terra_Canada_v2.0.0_FINAL.postman_collection.json

---

## � RESUMEN

| Métrica                | Valor            |
| ---------------------- | ---------------- |
| **Total de Endpoints** | 68               |
| **Módulos**            | 14               |
| **Webhooks N8N**       | 4                |
| **Autenticación**      | JWT Bearer Token |

---

## �📋 ÍNDICE

1. [Autenticación](#-autenticación) (2 endpoints)
2. [Usuarios](#-usuarios) (5 endpoints)
3. [Roles](#-roles) (5 endpoints)
4. [Proveedores](#-proveedores) (6 endpoints)
5. [Servicios](#️-servicios) (5 endpoints)
6. [Clientes](#-clientes) (5 endpoints)
7. [Tarjetas de Crédito](#-tarjetas-de-crédito) (6 endpoints)
8. [Cuentas Bancarias](#-cuentas-bancarias) (5 endpoints)
9. [Pagos](#-pagos) (11 endpoints)
10. [Documentos](#-documentos) (6 endpoints)
11. [Correos](#-correos) (8 endpoints)
12. [Webhooks](#-webhooks) (1 endpoint)
13. [Eventos de Auditoría](#-eventos-de-auditoría) (1 endpoint)
14. [Análisis y Reportes](#-análisis-y-reportes) (2 endpoints)

---

## 🔐 AUTENTICACIÓN

### POST `/auth/login`

**Descripción:** Iniciar sesión y obtener token JWT  
**Auth:** No requerida

**Request Body:**

```json
{
  "nombre_usuario": "admin",
  "password": "password123"
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
        "nombre_completo": "Administrador",
        "rol": "ADMIN"
      }
    }
  }
  ```
- **400 Bad Request** - Datos inválidos
- **401 Unauthorized** - Credenciales incorrectas

---

### GET `/auth/me`

**Descripción:** Obtener información del usuario autenticado  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Usuario encontrado
  ```json
  {
    "code": 200,
    "estado": true,
    "message": "Usuario obtenido",
    "data": {
      "id": 1,
      "nombre_usuario": "admin",
      "nombre_completo": "Administrador",
      "email": "admin@terracanada.com",
      "rol": {
        "id": 1,
        "nombre": "ADMIN"
      }
    }
  }
  ```
- **401 Unauthorized** - Token inválido o expirado

---

## 👥 USUARIOS

### GET `/usuarios`

**Descripción:** Obtener todos los usuarios  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Lista de usuarios
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
  "password": "Password123!",
  "nombre_completo": "Usuario Nuevo",
  "email": "nuevo@terracanada.com",
  "rol_id": 3
}
```

**Respuestas:**

- **201 Created** - Usuario creado
- **400 Bad Request** - Datos inválidos
- **409 Conflict** - Usuario ya existe

---

### PUT `/usuarios/:id`

**Descripción:** Actualizar usuario  
**Auth:** Bearer Token (ADMIN)

**Request Body:**

```json
{
  "nombre_completo": "Usuario Actualizado",
  "email": "actualizado@terracanada.com"
}
```

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
  "nombre": "CONTADOR",
  "descripcion": "Rol para contadores del sistema"
}
```

**Respuestas:**

- **201 Created** - Rol creado
- **400 Bad Request** - Datos inválidos
- **409 Conflict** - Rol ya existe

---

### PUT `/roles/:id`

**Descripción:** Actualizar rol existente  
**Auth:** Bearer Token (ADMIN)

**Request Body:**

```json
{
  "nombre": "CONTADOR_SENIOR",
  "descripcion": "Rol para contadores senior con más permisos"
}
```

**Respuestas:**

- **200 OK** - Rol actualizado
- **404 Not Found** - Rol no encontrado

---

### DELETE `/roles/:id`

**Descripción:** Eliminar rol  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Rol eliminado
- **404 Not Found** - Rol no encontrado
- **409 Conflict** - Rol tiene usuarios asignados

---

## � PROVEEDORES

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
  "correo1": "billing@aircanada.com",
  "correo2": "payments@aircanada.com"
}
```

**Respuestas:**

- **201 Created** - Proveedor creado
- **400 Bad Request** - Datos inválidos

---

### PUT `/proveedores/:id`

**Descripción:** Actualizar proveedor  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre": "Air Canada Updated",
  "lenguaje": "English"
}
```

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

### POST `/proveedores/:id/correos`

**Descripción:** Agregar correo adicional a proveedor  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "correo": "newmail@aircanada.com",
  "principal": true
}
```

**Respuestas:**

- **200 OK** - Correo agregado
- **404 Not Found** - Proveedor no encontrado

---

## 🛠️ SERVICIOS

### GET `/servicios`

**Descripción:** Obtener todos los servicios  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de servicios

---

### GET `/servicios/:id`

**Descripción:** Obtener servicio por ID  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Servicio encontrado
- **404 Not Found** - Servicio no encontrado

---

### POST `/servicios`

**Descripción:** Crear nuevo servicio  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre": "Hospedaje",
  "descripcion": "Servicio de alojamiento hotelero"
}
```

**Respuestas:**

- **201 Created** - Servicio creado
- **400 Bad Request** - Datos inválidos

---

### PUT `/servicios/:id`

**Descripción:** Actualizar servicio  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre": "Hospedaje Premium"
}
```

**Respuestas:**

- **200 OK** - Servicio actualizado
- **404 Not Found** - Servicio no encontrado

---

### DELETE `/servicios/:id`

**Descripción:** Eliminar servicio  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Servicio eliminado
- **404 Not Found** - Servicio no encontrado

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
  "email": "juan.perez@example.com",
  "telefono": "+1234567890",
  "direccion": "123 Main St, Toronto ON"
}
```

**Respuestas:**

- **201 Created** - Cliente creado
- **400 Bad Request** - Datos inválidos

---

### PUT `/clientes/:id`

**Descripción:** Actualizar cliente  
**Auth:** Bearer Token (ADMIN, SUPERVISOR, EQUIPO)

**Request Body:**

```json
{
  "telefono": "+9876543210"
}
```

**Respuestas:**

- **200 OK** - Cliente actualizado
- **404 Not Found** - Cliente no encontrado

---

### DELETE `/clientes/:id`

**Descripción:** Eliminar cliente  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Cliente eliminado
- **404 Not Found** - Cliente no encontrado

---

## 💳 TARJETAS DE CRÉDITO

### GET `/tarjetas`

**Descripción:** Obtener todas las tarjetas  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de tarjetas

---

### GET `/tarjetas/:id`

**Descripción:** Obtener tarjeta por ID  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Tarjeta encontrada
- **404 Not Found** - Tarjeta no encontrada

---

### POST `/tarjetas`

**Descripción:** Crear nueva tarjeta  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "numero_tarjeta": "4111111111111111",
  "titular": "John Doe",
  "fecha_vencimiento": "2025-12-31",
  "cvv": "123",
  "tipo": "VISA",
  "banco_emisor": "TD Bank",
  "limite_credito": 10000.0
}
```

**Respuestas:**

- **201 Created** - Tarjeta creada
- **400 Bad Request** - Datos inválidos

---

### PUT `/tarjetas/:id`

**Descripción:** Actualizar tarjeta  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "limite_credito": 15000.0
}
```

**Respuestas:**

- **200 OK** - Tarjeta actualizada
- **404 Not Found** - Tarjeta no encontrada

---

### DELETE `/tarjetas/:id`

**Descripción:** Eliminar tarjeta  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Tarjeta eliminada
- **404 Not Found** - Tarjeta no encontrada

---

### PUT `/tarjetas/:id/toggle-activo`

**Descripción:** Activar/Desactivar tarjeta  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Estado actualizado
- **404 Not Found** - Tarjeta no encontrada

---

## 🏦 CUENTAS BANCARIAS

### GET `/cuentas`

**Descripción:** Obtener todas las cuentas bancarias  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Lista de cuentas

---

### GET `/cuentas/:id`

**Descripción:** Obtener cuenta por ID  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Cuenta encontrada
- **404 Not Found** - Cuenta no encontrada

---

### POST `/cuentas`

**Descripción:** Crear nueva cuenta bancaria  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre_cuenta": "Cuenta Principal",
  "banco": "RBC",
  "numero_cuenta": "1234567890",
  "tipo_cuenta": "CORRIENTE"
}
```

**Respuestas:**

- **201 Created** - Cuenta creada
- **400 Bad Request** - Datos inválidos

---

### PUT `/cuentas/:id`

**Descripción:** Actualizar cuenta bancaria  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre_cuenta": "Cuenta Principal Actualizada"
}
```

**Respuestas:**

- **200 OK** - Cuenta actualizada
- **404 Not Found** - Cuenta no encontrada

---

### DELETE `/cuentas/:id`

**Descripción:** Eliminar cuenta bancaria  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Cuenta eliminada
- **404 Not Found** - Cuenta no encontrada

---

## 💰 PAGOS

### GET `/pagos`

**Descripción:** Obtener todos los pagos con filtros opcionales  
**Auth:** Bearer Token

**Query Parameters:**

- `estado` (opcional): PENDIENTE, PAGADO, CANCELADO
- `proveedor_id` (opcional): ID del proveedor
- `fecha_desde` (opcional): Fecha inicio (YYYY-MM-DD)
- `fecha_hasta` (opcional): Fecha fin (YYYY-MM-DD)

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
  "codigo_reserva": "AC12345",
  "proveedor_id": 1,
  "usuario_id": 1,
  "monto": 1500.5,
  "moneda": "CAD",
  "estado": "PENDIENTE",
  "descripcion": "Pago de vuelo YYZ-YVR",
  "tarjeta_id": 1
}
```

**Respuestas:**

- **201 Created** - Pago creado
- **400 Bad Request** - Datos inválidos
- **404 Not Found** - Proveedor/Tarjeta no encontrada

---

### PUT `/pagos/:id`

**Descripción:** Actualizar pago  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "estado": "PAGADO",
  "verificado": true
}
```

**Respuestas:**

- **200 OK** - Pago actualizado
- **404 Not Found** - Pago no encontrado

---

### DELETE `/pagos/:id`

**Descripción:** Cancelar pago  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Pago cancelado
- **404 Not Found** - Pago no encontrado

---

### PUT `/pagos/:id/con-pdf`

**Descripción:** Actualizar pago con archivo PDF  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "estado": "PAGADO",
  "verificado": true,
  "archivo": {
    "nombre": "comprobante_123.pdf",
    "tipo": "application/pdf",
    "base64": "JVBERi0xLjQKJeLjz9MK..."
  }
}
```

**Respuestas:**

- **200 OK** - Pago actualizado con PDF
- **400 Bad Request** - Archivo inválido
- **404 Not Found** - Pago no encontrado

---

### PATCH `/pagos/:id/desactivar`

**Descripción:** Desactivar pago (soft delete)  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Pago desactivado
- **404 Not Found** - Pago no encontrado

---

### PATCH `/pagos/:id/activar`

**Descripción:** Reactivar pago previamente desactivado  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Pago activado
- **404 Not Found** - Pago no encontrado

---

### POST `/pagos/documento-estado`

**Descripción:** Enviar documento de estado de pago a N8N  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)  
**Webhook:** `https://n8n.salazargroup.cloud/webhook/documento_pago`

**Request Body:**

```json
{
  "pdf": "JVBERi0xLjQKJeLjz9MKMSAwIG9iag...",
  "id_pago": 10,
  "usuario_id": 2
}
```

**Respuestas:**

- **200 OK** - Documento procesado por N8N
- **400 Bad Request** - Error del webhook o datos inválidos

---

### POST `/pagos/subir-facturas`

**Descripción:** Subir hasta 3 facturas a N8N para procesamiento  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)  
**Webhook:** `https://n8n.salazargroup.cloud/webhook/docu`

**Request Body:**

```json
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
```

**Respuestas:**

- **200 OK** - Facturas procesadas por N8N
- **400 Bad Request** - Máximo 3 facturas o error del webhook

---

### POST `/pagos/subir-extracto-banco`

**Descripción:** Subir extracto bancario a N8N para procesamiento  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)  
**Webhook:** `https://n8n.salazargroup.cloud/webhook/docu`

**Request Body:**

```json
{
  "pdf": "JVBERi0xLjQKJeLjz9MK...",
  "usuario_id": 2
}
```

**Respuestas:**

- **200 OK** - Extracto procesado por N8N
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

- **200 OK** - Documento encontrado con información de pagos
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

**Tipos de documento:** `FACTURA`, `DOCUMENTO_BANCO`

**Respuestas:**

- **201 Created** - Documento creado
- **400 Bad Request** - Datos inválidos
- **404 Not Found** - Usuario o pago no encontrado

---

### PUT `/documentos/:id`

**Descripción:** Actualizar nombre o URL de documento  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Request Body:**

```json
{
  "nombre_archivo": "factura_corregida.pdf",
  "url_documento": "https://storage.terracanada.com/nueva_url/factura.pdf"
}
```

**Respuestas:**

- **200 OK** - Documento actualizado
- **400 Bad Request** - Debe proporcionar al menos un campo
- **404 Not Found** - Documento no encontrado

---

### POST `/documentos/:id/reprocesar`

**Descripción:** Reprocesar documento (si existe funcionalidad)  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Documento reprocesado
- **404 Not Found** - Documento no encontrado

---

### DELETE `/documentos/:id`

**Descripción:** Eliminar documento  
**Auth:** Bearer Token (ADMIN)

**Respuestas:**

- **200 OK** - Documento eliminado
- **404 Not Found** - Documento no encontrado
- **409 Conflict** - Documento tiene pagos verificados vinculados

---

## 📧 CORREOS

### GET `/correos`

**Descripción:** Obtener todos los correos con filtros  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Query Parameters:**

- `estado` (opcional): BORRADOR, ENVIADO
- `proveedor_id` (opcional): ID del proveedor

**Respuestas:**

- **200 OK** - Lista de correos

---

### GET `/correos/pendientes`

**Descripción:** Obtener solo correos en estado BORRADOR (pendientes de envío)  
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

- **201 Created** - Correos generados exitosamente
- **200 OK** - No hay pagos pendientes para generar correos

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
  "cuerpo": "Nuevo contenido del correo"
}
```

**Respuestas:**

- **200 OK** - Correo actualizado
- **400 Bad Request** - Solo se pueden actualizar borradores
- **404 Not Found** - Correo no encontrado

---

### POST `/correos/:id/enviar`

**Descripción:** Enviar correo vía N8N  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)  
**Webhook:** `https://n8n.salazargroup.cloud/webhook/gmail_g`

**Request Body:**

```json
{
  "usuario_id": 2
}
```

**Nota:** El `usuario_id` se incluye automáticamente para trazabilidad.

**Respuestas:**

- **200 OK** - Correo enviado exitosamente
- **400 Bad Request** - Error del webhook o correo ya enviado
- **404 Not Found** - Correo no encontrado

---

### DELETE `/correos/:id`

**Descripción:** Eliminar borrador de correo  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Respuestas:**

- **200 OK** - Correo eliminado
- **400 Bad Request** - Solo se pueden eliminar borradores
- **404 Not Found** - Correo no encontrado

---

## 🔗 WEBHOOKS

### POST `/webhooks/n8n`

**Descripción:** Recibir notificaciones de N8N  
**Auth:** Token específico de N8N

**Request Body:**

```json
{
  "evento": "documento_procesado",
  "data": {
    "id_pago": 10,
    "estado": "completado"
  }
}
```

**Respuestas:**

- **200 OK** - Webhook procesado
- **400 Bad Request** - Datos inválidos
- **401 Unauthorized** - Token inválido

---

## 📊 EVENTOS DE AUDITORÍA

### GET `/eventos`

**Descripción:** Obtener eventos de auditoría con paginación  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)  
**Función PostgreSQL:** `eventos_get(p_id, p_limite, p_offset)`

**Query Parameters:**

- `tabla` (opcional): Filtrar por tabla (no implementado en función PG)
- `tipo_evento` (opcional): Filtrar por tipo (no implementado en función PG)
- `usuario_id` (opcional): Filtrar por usuario (no implementado en función PG)
- `limit` (opcional, default: 100): Número máximo de eventos
- `offset` (opcional, default: 0): Número de eventos a saltar

**Respuestas:**

- **200 OK** - Lista de eventos con paginación
  ```json
  {
    "code": 200,
    "estado": true,
    "message": "Eventos obtenidos exitosamente",
    "total": 150,
    "limite": 100,
    "offset": 0,
    "data": [
      {
        "id": 1,
        "usuario": {
          "id": 2,
          "nombre_completo": "Admin User",
          "rol": "ADMIN"
        },
        "tipo_evento": "CREAR",
        "entidad_tipo": "pagos",
        "entidad_id": 10,
        "descripcion": "Pago creado",
        "ip_origen": "192.168.1.1",
        "fecha_evento": "2026-01-30T23:00:00Z"
      }
    ]
  }
  ```
- **401 Unauthorized** - No autenticado
- **403 Forbidden** - Sin permisos

---

## 📈 ANÁLISIS Y REPORTES

### GET `/analisis/dashboard`

**Descripción:** Obtener dashboard con estadísticas generales  
**Auth:** Bearer Token

**Respuestas:**

- **200 OK** - Dashboard con estadísticas
  ```json
  {
    "code": 200,
    "estado": true,
    "message": "Dashboard obtenido",
    "data": {
      "total_pagos": 150,
      "total_pendientes": 45,
      "total_pagados": 105,
      "monto_total": 125000.5,
      "monto_pendiente": 35000.0
    }
  }
  ```

---

### GET `/analisis/tendencias`

**Descripción:** Obtener tendencias de pagos  
**Auth:** Bearer Token (ADMIN, SUPERVISOR)

**Query Parameters:**

- `fecha_desde` (opcional): Fecha inicio (YYYY-MM-DD)
- `fecha_hasta` (opcional): Fecha fin (YYYY-MM-DD)
- `proveedor_id` (opcional): ID del proveedor

**Respuestas:**

- **200 OK** - Tendencias de pagos
  ```json
  {
    "code": 200,
    "estado": true,
    "message": "Tendencias obtenidas",
    "data": {
      "por_mes": [...],
      "por_proveedor": [...],
      "por_estado": [...]
    }
  }
  ```

---

## 📝 CÓDIGOS DE RESPUESTA HTTP

| Código  | Significado                                  |
| ------- | -------------------------------------------- |
| **200** | OK - Solicitud exitosa                       |
| **201** | Created - Recurso creado exitosamente        |
| **400** | Bad Request - Datos inválidos                |
| **401** | Unauthorized - No autenticado                |
| **403** | Forbidden - Sin permisos                     |
| **404** | Not Found - Recurso no encontrado            |
| **409** | Conflict - Conflicto (ej: recurso ya existe) |
| **500** | Internal Server Error - Error del servidor   |
| **503** | Service Unavailable - Servicio no disponible |

---

## � AUTENTICACIÓN Y SEGURIDAD

### Bearer Token

Todos los endpoints (excepto `/auth/login`) requieren un token JWT en el header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Roles y Permisos

| Rol            | Permisos                                      |
| -------------- | --------------------------------------------- |
| **ADMIN**      | Acceso total a todos los endpoints            |
| **SUPERVISOR** | Gestión de pagos, correos, documentos         |
| **EQUIPO**     | Creación de pagos y clientes, lectura general |

---

## 🔗 WEBHOOKS N8N

La API integra 4 webhooks con N8N para procesamiento automático:

1. **Enviar Correo:** `https://n8n.salazargroup.cloud/webhook/gmail_g`
2. **Documento de Estado:** `https://n8n.salazargroup.cloud/webhook/documento_pago`
3. **Subir Facturas:** `https://n8n.salazargroup.cloud/webhook/docu`
4. **Extracto Bancario:** `https://n8n.salazargroup.cloud/webhook/docu`

**Nota:** Todos los webhooks incluyen `usuario_id` para trazabilidad.

---

## 📚 RECURSOS ADICIONALES

- **Colección Postman:** `API_Terra_Canada_v2.0.0_FINAL.postman_collection.json`
- **Documentación Swagger:** `http://localhost:3000/api-docs`
- **Health Check:** `http://localhost:3000/health`

---

**Generado por:** Antigravity AI  
**Fecha:** 31 de Enero de 2026  
**Versión:** 2.0.0 Final
