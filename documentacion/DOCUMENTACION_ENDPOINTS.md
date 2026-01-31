# 📚 Documentación Completa de Endpoints - API Terra Canada

**Base URL:** `http://localhost:3000/api/v1`  
**Documentación Swagger:** `http://localhost:3000/api-docs`  
**Autenticación:** JWT Bearer Token (excepto login)

---

## 🔐 1. Autenticación (Auth)

### 1.1 Login

**Endpoint:** `POST /auth/login`  
**Autenticación:** No requerida  
**Descripción:** Iniciar sesión y obtener token JWT

**Request Body:**

```json
{
  "username": "admin",
  "password": "password123"
}
```

**Response 200 - Éxito:**

```json
{
  "success": true,
  "message": "Login exitoso",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "nombre_usuario": "admin",
      "nombre_completo": "Administrador del Sistema",
      "correo": "admin@terracanada.com",
      "rol": {
        "id": 1,
        "nombre": "ADMIN",
        "descripcion": "Administrador con acceso total"
      }
    }
  }
}
```

**Response 401 - Credenciales inválidas:**

```json
{
  "success": false,
  "message": "Credenciales inválidas"
}
```

---

### 1.2 Obtener Usuario Autenticado

**Endpoint:** `GET /auth/me`  
**Autenticación:** Bearer Token requerido  
**Roles permitidos:** Todos

**Headers:**

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response 200:**

```json
{
  "success": true,
  "message": "Usuario obtenido",
  "data": {
    "id": 1,
    "nombre_usuario": "admin",
    "nombre_completo": "Administrador del Sistema",
    "correo": "admin@terracanada.com",
    "telefono": "+1234567890",
    "activo": true,
    "rol": {
      "id": 1,
      "nombre": "ADMIN",
      "descripcion": "Administrador con acceso total"
    },
    "fecha_creacion": "2024-01-15T10:30:00.000Z",
    "fecha_actualizacion": "2024-01-20T15:45:00.000Z"
  }
}
```

---

## 👥 2. Usuarios

### 2.1 Listar Usuarios

**Endpoint:** `GET /usuarios`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "success": true,
  "message": "Usuarios obtenidos",
  "data": [
    {
      "id": 1,
      "nombre_usuario": "admin",
      "nombre_completo": "Administrador",
      "correo": "admin@terracanada.com",
      "telefono": "+1234567890",
      "rol_id": 1,
      "rol_nombre": "ADMIN",
      "activo": true,
      "fecha_creacion": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

---

### 2.2 Obtener Usuario por ID

**Endpoint:** `GET /usuarios/:id`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "success": true,
  "message": "Usuario obtenido",
  "data": {
    "id": 1,
    "nombre_usuario": "admin",
    "nombre_completo": "Administrador",
    "correo": "admin@terracanada.com",
    "telefono": "+1234567890",
    "rol_id": 1,
    "activo": true,
    "fecha_creacion": "2024-01-15T10:30:00.000Z",
    "fecha_actualizacion": "2024-01-20T15:45:00.000Z",
    "rol_nombre": "ADMIN",
    "rol_descripcion": "Administrador con acceso total"
  }
}
```

---

### 2.3 Crear Usuario

**Endpoint:** `POST /usuarios`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN

**Request Body:**

```json
{
  "nombre_usuario": "jdoe",
  "nombre_completo": "John Doe",
  "correo": "jdoe@example.com",
  "telefono": "+1234567890",
  "contrasena": "Password123!",
  "rol_id": 3,
  "activo": true
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Usuario creado",
  "data": {
    "id": 5,
    "nombre_usuario": "jdoe",
    "nombre_completo": "John Doe",
    "correo": "jdoe@example.com",
    "telefono": "+1234567890",
    "rol_id": 3,
    "activo": true
  }
}
```

**Response 409 - Usuario ya existe:**

```json
{
  "success": false,
  "message": "Ya existe un usuario con ese nombre de usuario o correo"
}
```

---

### 2.4 Actualizar Usuario

**Endpoint:** `PUT /usuarios/:id`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN

**Request Body:**

```json
{
  "nombre_completo": "John Doe Updated",
  "telefono": "+9876543210",
  "activo": true
}
```

**Response 200:**

```json
{
  "success": true,
  "message": "Usuario actualizado",
  "data": {
    "id": 5,
    "nombre_usuario": "jdoe",
    "nombre_completo": "John Doe Updated",
    "telefono": "+9876543210"
  }
}
```

---

### 2.5 Eliminar Usuario (Soft Delete)

**Endpoint:** `DELETE /usuarios/:id`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN

**Response 200:**

```json
{
  "success": true,
  "message": "Usuario desactivado",
  "data": null
}
```

---

## 🎭 3. Roles

### 3.1 Listar Roles

**Endpoint:** `GET /roles`  
**Autenticación:** Bearer Token  
**Roles permitidos:** Todos

**Response 200:**

```json
{
  "success": true,
  "message": "Roles obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "ADMIN",
      "descripcion": "Administrador con acceso total"
    },
    {
      "id": 2,
      "nombre": "SUPERVISOR",
      "descripcion": "Supervisor con acceso a gestión"
    },
    {
      "id": 3,
      "nombre": "EQUIPO",
      "descripcion": "Miembro del equipo - acceso limitado"
    }
  ]
}
```

---

### 3.2 Crear Rol

**Endpoint:** `POST /roles`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN

**Request Body:**

```json
{
  "nombre": "CONTADOR",
  "descripcion": "Contador con acceso a reportes financieros"
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Rol creado",
  "data": {
    "id": 4,
    "nombre": "CONTADOR",
    "descripcion": "Contador con acceso a reportes financieros"
  }
}
```

---

## 🏢 4. Servicios

### 4.1 Listar Servicios

**Endpoint:** `GET /servicios`  
**Autenticación:** Bearer Token  
**Roles permitidos:** Todos

**Response 200:**

```json
{
  "success": true,
  "message": "Servicios obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "Netflix",
      "descripcion": "Servicio de streaming",
      "activo": true
    },
    {
      "id": 2,
      "nombre": "Spotify",
      "descripcion": "Servicio de música",
      "activo": true
    }
  ]
}
```

---

### 4.2 Crear Servicio

**Endpoint:** `POST /servicios`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "nombre": "Disney+",
  "descripcion": "Servicio de streaming Disney",
  "activo": true
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Servicio creado",
  "data": {
    "id": 3,
    "nombre": "Disney+",
    "descripcion": "Servicio de streaming Disney",
    "activo": true
  }
}
```

---

## 🤝 5. Proveedores

### 5.1 Listar Proveedores

**Endpoint:** `GET /proveedores`  
**Query Parameters:** `?servicio_id=1` (opcional)  
**Autenticación:** Bearer Token  
**Roles permitidos:** Todos

**Response 200:**

```json
{
  "success": true,
  "message": "Proveedores obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "Proveedor Netflix USA",
      "servicio_id": 1,
      "servicio_nombre": "Netflix",
      "lenguaje": "Inglés",
      "telefono": "+1-800-123-4567",
      "descripcion": "Proveedor principal de cuentas Netflix",
      "activo": true,
      "correos": [
        {
          "id": 1,
          "correo": "contact@netflix-provider.com",
          "principal": true
        },
        {
          "id": 2,
          "correo": "support@netflix-provider.com",
          "principal": false
        }
      ]
    }
  ]
}
```

---

### 5.2 Crear Proveedor

**Endpoint:** `POST /proveedores`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "nombre": "Proveedor Spotify Premium",
  "servicio_id": 2,
  "lenguaje": "Español",
  "telefono": "+1-900-555-0100",
  "descripcion": "Proveedor de cuentas Spotify Premium",
  "correos": [
    {
      "correo": "ventas@spotify-pro.com",
      "principal": true
    },
    {
      "correo": "soporte@spotify-pro.com",
      "principal": false
    }
  ],
  "activo": true
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Proveedor creado",
  "data":{
    "id": 5,
    "nombre": "Proveedor Spotify Premium",
    "servicio_id": 2,
    "servicio_nombre": "Spotify",
    "correos": [...]
  }
}
```

---

### 5.3 Agregar Correo a Proveedor

**Endpoint:** `POST /proveedores/:id/correos`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "correo": "nuevo@proveedor.com",
  "principal": false
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Correo agregado",
  "data": {
    "id": 10,
    "proveedor_id": 1,
    "correo": "nuevo@proveedor.com",
    "principal": false,
    "activo": true
  }
}
```

**Response 409 - Límite excedido:**

```json
{
  "success": false,
  "message": "Máximo 4 correos permitidos por proveedor"
}
```

---

## 👨‍👩‍👧‍👦 6. Clientes

### 6.1 Listar Clientes

**Endpoint:** `GET /clientes`  
**Autenticación:** Bearer Token  
**Roles permitidos:** Todos

**Response 200:**

```json
{
  "success": true,
  "message": "Clientes obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "Cliente VIP 1",
      "ubicacion": "Toronto, Canadá",
      "telefono": "+1-416-555-0100",
      "correo": "cliente1@example.com",
      "activo": true
    }
  ]
}
```

---

### 6.2 Crear Cliente

**Endpoint:** `POST /clientes`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "nombre": "Nuevo Cliente Premium",
  "ubicacion": "Vancouver, Canadá",
  "telefono": "+1-604-555-0200",
  "correo": "premium@example.com",
  "activo": true
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Cliente creado",
  "data": {
    "id": 10,
    "nombre": "Nuevo Cliente Premium",
    "ubicacion": "Vancouver, Canadá",
    "telefono": "+1-604-555-0200",
    "correo": "premium@example.com",
    "activo": true
  }
}
```

---

## 💳 7. Tarjetas de Crédito

### 7.1 Listar Tarjetas

**Endpoint:** `GET /tarjetas`  
**Query Parameters:** `?cliente_id=1` (opcional)  
**Autenticación:** Bearer Token  
**Roles permitidos:** Todos

**Response 200:**

```json
{
  "success": true,
  "message": "Tarjetas obtenidas",
  "data": [
    {
      "id": 1,
      "numero_tarjeta_encriptado": "****1234",
      "titular": "John Doe",
      "tipo": "VISA",
      "saldo_asignado": 5000.0,
      "saldo_disponible": 3450.5,
      "cliente_id": 1,
      "cliente_nombre": "Cliente VIP 1",
      "fecha_vencimiento": "2025-12-31",
      "activo": true
    }
  ]
}
```

---

### 7.2 Crear Tarjeta

**Endpoint:** `POST /tarjetas`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "numero_tarjeta_encriptado": "****5678",
  "titular": "Jane Smith",
  "tipo": "MASTERCARD",
  "saldo_asignado": 3000.0,
  "cliente_id": 1,
  "fecha_vencimiento": "2026-06-30",
  "activo": true
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Tarjeta creada",
  "data": {
    "id": 5,
    "titular": "Jane Smith",
    "tipo": "MASTERCARD",
    "saldo_asignado": 3000.0,
    "saldo_disponible": 3000.0,
    "cliente_nombre": "Cliente VIP 1"
  }
}
```

---

### 7.3 Recargar Saldo de Tarjeta

**Endpoint:** `POST /tarjetas/:id/recargar`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "monto": 1000.0
}
```

**Response 200:**

```json
{
  "success": true,
  "message": "Tarjeta recargada exitosamente",
  "data": {
    "id": 1,
    "titular": "John Doe",
    "saldo_asignado": 6000.0,
    "saldo_disponible": 4450.5
  }
}
```

---

## 🏦 8. Cuentas Bancarias

### 8.1 Listar Cuentas

**Endpoint:** `GET /cuentas`  
**Query Parameters:** `?cliente_id=1` (opcional)  
**Autenticación:** Bearer Token  
**Roles permitidos:** Todos

**Response 200:**

```json
{
  "success": true,
  "message": "Cuentas obtenidas",
  "data": [
    {
      "id": 1,
      "numero_cuenta_encriptado": "****9876",
      "nombre_banco": "TD Canada Trust",
      "tipo_cuenta": "CORRIENTE",
      "titular": "Empresa Terra Canada",
      "cliente_id": 1,
      "cliente_nombre": "Cliente VIP 1",
      "activo": true
    }
  ]
}
```

---

### 8.2 Crear Cuenta Bancaria

**Endpoint:** `POST /cuentas`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "numero_cuenta_encriptado": "****4321",
  "nombre_banco": "Scotiabank",
  "tipo_cuenta": "AHORROS",
  "titular": "Empresa Terra Canada",
  "cliente_id": 1,
  "activo": true
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Cuenta creada",
  "data": {
    "id": 3,
    "numero_cuenta_encriptado": "****4321",
    "nombre_banco": "Scotiabank",
    "tipo_cuenta": "AHORROS",
    "titular": "Empresa Terra Canada",
    "cliente_nombre": "Cliente VIP 1"
  }
}
```

---

## 💰 9. Pagos (CORE del Sistema)

### 9.1 Listar Pagos

**Endpoint:** `GET /pagos`  
**Query Parameters:**

- `proveedor_id` (opcional)
- `estado` (opcional): PENDIENTE, COMPLETADO, CANCELADO
- `fecha_desde` (opcional): YYYY-MM-DD
- `fecha_hasta` (opcional): YYYY-MM-DD

**Autenticación:** Bearer Token  
**Roles permitidos:** Todos

**Response 200:**

```json
{
  "success": true,
  "message": "Pagos obtenidos",
  "data": [
    {
      "id": 1,
      "monto": 150.0,
      "moneda": "USD",
      "medio_pago": "TARJETA_CREDITO",
      "estado": "COMPLETADO",
      "proveedor_id": 1,
      "proveedor_nombre": "Proveedor Netflix USA",
      "usuario_id": 1,
      "usuario_nombre": "admin",
      "tarjeta_id": 1,
      "tarjeta_titular": "John Doe",
      "cuenta_id": null,
      "cuenta_banco": null,
      "cliente_asociado_id": 1,
      "observaciones": "Pago mensual Netflix",
      "fecha_creacion": "2024-01-15T10:30:00.000Z",
      "fecha_pago": "2024-01-15T10:35:00.000Z"
    }
  ]
}
```

---

### 9.2 Crear Pago

**Endpoint:** `POST /pagos`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR, EQUIPO

**Descripción:** Crea un pago y **automáticamente descuenta el saldo** de la tarjeta si se usa medio de pago TARJETA_CREDITO.

**Request Body:**

```json
{
  "monto": 250.0,
  "moneda": "USD",
  "medio_pago": "TARJETA_CREDITO",
  "proveedor_id": 1,
  "usuario_id": 1,
  "tarjeta_id": 1,
  "cuenta_id": null,
  "observaciones": "Pago por servicio premium",
  "cliente_asociado_id": 1
}
```

**Response 201:**

```json
{
  "success": true,
  "message": "Pago creado exitosamente",
  "data": {
    "id": 25,
    "monto": 250.0,
    "moneda": "USD",
    "medio_pago": "TARJETA_CREDITO",
    "estado": "PENDIENTE",
    "proveedor_nombre": "Proveedor Netflix USA",
    "tarjeta_titular": "John Doe"
  }
}
```

**Response 400 - Saldo Insuficiente:**

```json
{
  "success": false,
  "message": "Saldo insuficiente en la tarjeta"
}
```

---

### 9.3 Actualizar Pago

**Endpoint:** `PUT /pagos/:id`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "estado": "COMPLETADO",
  "observaciones": "Pago verificado y completado",
  "fecha_pago": "2024-01-20T14:30:00.000Z"
}
```

**Response 200:**

```json
{
  "success": true,
  "message": "Pago actualizado",
  "data": {
    "id": 25,
    "estado": "COMPLETADO",
    "fecha_pago": "2024-01-20T14:30:00.000Z"
  }
}
```

---

### 9.4 Cancelar Pago

**Endpoint:** `DELETE /pagos/:id`  
**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Descripción:** Cancela el pago y **devuelve automáticamente el saldo** a la tarjeta si se usó tarjeta de crédito.

**Response 200:**

```json
{
  "success": true,
  "message": "Pago cancelado",
  "data": null
}
```

**Response 409 - No se puede cancelar:**

```json
{
  "success": false,
  "message": "No se puede eliminar un pago completado"
}
```

---

## 📊 10. Análisis y Reportes

### 10.1 Dashboard

**Endpoint:** `GET /analisis/dashboard`  
**Autenticación:** Bearer Token  
**Roles permitidos:** Todos

**Response 200:**

```json
{
  "success": true,
  "message": "Dashboard obtenido",
  "data": {
    "pagos": {
      "total_pagos": 150,
      "monto_total": "45750.00",
      "pendientes": 5,
      "completados": 145
    },
    "tarjetas": {
      "total_tarjetas": 25,
      "saldo_total_asignado": "125000.00",
      "saldo_total_disponible": "87350.50"
    },
    "proveedores": {
      "total_proveedores": 15
    },
    "clientes": {
      "total_clientes": 8
    }
  }
}
```

---

### 10.2 Reporte de Pagos

**Endpoint:** `GET /analisis/reportes/pagos`  
**Query Parameters:**

- `fecha_desde` (opcional): YYYY-MM-DD
- `fecha_hasta` (opcional): YYYY-MM-DD
- `proveedor_id` (opcional)

**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "success": true,
  "message": "Reporte de pagos generado",
  "data": [
    {
      "id": 1,
      "monto": 150.0,
      "moneda": "USD",
      "medio_pago": "TARJETA_CREDITO",
      "estado": "COMPLETADO",
      "fecha_creacion": "2024-01-15T10:30:00.000Z",
      "proveedor_nombre": "Proveedor Netflix USA",
      "usuario_nombre": "admin",
      "tarjeta_titular": "John Doe"
    }
  ]
}
```

---

## 📝 11. Eventos (Auditoría)

### 11.1 Consultar Eventos

**Endpoint:** `GET /eventos`  
**Query Parameters:**

- `tabla` (opcional): nombre de tabla
- `tipo_evento` (opcional): CREAR, ACTUALIZAR, ELIMINAR
- `usuario_id` (opcional)
- `fecha_desde` (opcional)
- `fecha_hasta` (opcional)
- `limit` (opcional, default: 100)

**Autenticación:** Bearer Token  
**Roles permitidos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "success": true,
  "message": "Eventos obtenidos",
  "data": [
    {
      "id": 150,
      "tipo_evento": "CREAR",
      "tabla": "pagos",
      "registro_id": 25,
      "datos_anteriores": null,
      "datos_nuevos": "{\"monto\": 250.00, \"estado\": \"PENDIENTE\"}",
      "usuario_id": 1,
      "nombre_usuario": "admin",
      "fecha": "2024-01-20T14:30:00.000Z"
    }
  ]
}
```

---

## 🔒 Códigos de Respuesta HTTP

| Código | Descripción                                   |
| ------ | --------------------------------------------- |
| 200    | OK - Solicitud exitosa                        |
| 201    | Created - Recurso creado                      |
| 400    | Bad Request - Datos inválidos                 |
| 401    | Unauthorized - Token inválido o ausente       |
| 403    | Forbidden - Sin permisos suficientes          |
| 404    | Not Found - Recurso no encontrado             |
| 409    | Conflict - Conflicto (duplicado, restricción) |
| 500    | Internal Server Error - Error del servidor    |

---

## 🎭 Roles y Permisos

| Módulo      | ADMIN           | SUPERVISOR      | EQUIPO         |
| ----------- | --------------- | --------------- | -------------- |
| Usuarios    | CRUD            | Read            | -              |
| Roles       | CRUD            | -               | -              |
| Servicios   | CRUD            | CRUD            | Read           |
| Proveedores | CRUD            | CRUD            | Read           |
| Clientes    | CRUD            | CRUD            | Read           |
| Tarjetas    | CRUD + Recargar | CRUD + Recargar | Read + Use     |
| Cuentas     | CRUD            | CRUD            | -              |
| Pagos       | CRUD            | CRUD            | Create + Read  |
| Eventos     | Read            | Read            | -              |
| Análisis    | Read            | Read            | Read (propios) |

---

## 💡 Notas Importantes

1. **Autenticación:** Todos los endpoints (excepto login) requieren header `Authorization: Bearer <token>`

2. **Control de Saldos:** El sistema gestiona automáticamente los saldos de tarjetas:
   - Al crear pago con tarjeta: descuenta saldo_disponible
   - Al cancelar pago: devuelve saldo_disponible
   - Al recargar tarjeta: aumenta saldo_asignado y saldo_disponible

3. **Auditoría:** Todas las operaciones CUD (Create, Update, Delete) se registran automáticamente en la tabla eventos

4. **Soft Delete:** Las eliminaciones son lógicas (activo = false), no físicas

5. **Transacciones:** Los pagos usan transacciones SQL para garantizar consistencia

6. **Límites:**
   - Máximo 4 correos por proveedor
   - Máximo 100 registros por consulta (configurable vía query param limit)

---

**Versión:** 1.0.0  
**Última actualización:** 2024-01-29  
**Contacto:** Equipo Terra Canada
