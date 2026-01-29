# 🌐 DOCUMENTACIÓN DE ENDPOINTS - API TERRA CANADA

---

## 📋 TABLA DE CONTENIDOS

1. [Autenticación](#autenticación)
2. [Usuarios](#usuarios)
3. [Roles](#roles)
4. [Servicios](#servicios)
5. [Proveedores](#proveedores)
6. [Clientes](#clientes)
7. [Tarjetas de Crédito](#tarjetas-de-crédito)
8. [Cuentas Bancarias](#cuentas-bancarias)
9. [Pagos (CORE)](#pagos-core)
10. [Documentos](#documentos)
11. [Correos](#correos)
12. [Análisis y Reportes](#análisis-y-reportes)
13. [Eventos (Auditoría)](#eventos-auditoría)
14. [Webhooks](#webhooks)

---

## 🔐 AUTENTICACIÓN

Base URL: `/api/v1/auth`

### **POST** `/login`

Iniciar sesión

**Permisos:** Público

**Request Body:**

```json
{
  "username": "admin@terracanada.com",
  "password": "password123"
}
```

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Login exitoso",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "nombre_usuario": "admin@terracanada.com",
      "nombre_completo": "Administrador Sistema",
      "rol": {
        "id": 1,
        "nombre": "ADMIN"
      }
    }
  }
}
```

### **POST** `/refresh`

Renovar token

**Permisos:** Autenticado

**Headers:** `Authorization: Bearer {token}`

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Token renovado",
  "data": {
    "token": "nuevo_token_jwt..."
  }
}
```

### **GET** `/me`

Obtener información del usuario autenticado

**Permisos:** Autenticado

**Headers:** `Authorization: Bearer {token}`

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Usuario obtenido",
  "data": {
    "id": 1,
    "nombre_usuario": "admin",
    "nombre_completo": "Administrador",
    "correo": "admin@terracanada.com",
    "rol": {
      "id": 1,
      "nombre": "ADMIN",
      "descripcion": "Control total del sistema"
    }
  }
}
```

---

## 👤 USUARIOS

Base URL: `/api/v1/usuarios`

### **GET** `/`

Listar todos los usuarios

**Permisos:** ADMIN, SUPERVISOR

**Query Params:**

- `page` (opcional): Número de página (default: 1)
- `limit` (opcional): Registros por página (default: 10)
- `activo` (opcional): true | false

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Usuarios obtenidos",
  "data": {
    "usuarios": [
      {
        "id": 1,
        "nombre_usuario": "admin",
        "correo": "admin@terracanada.com",
        "nombre_completo": "Administrador Sistema",
        "rol": {
          "id": 1,
          "nombre": "ADMIN"
        },
        "activo": true,
        "fecha_creacion": "2026-01-29T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 25,
      "totalPages": 3
    }
  }
}
```

### **GET** `/:id`

Obtener un usuario por ID

**Permisos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Usuario obtenido",
  "data": {
    "id": 1,
    "nombre_usuario": "admin",
    "correo": "admin@terracanada.com",
    "nombre_completo": "Administrador",
    "rol": {
      "id": 1,
      "nombre": "ADMIN"
    },
    "telefono": "+1234567890",
    "activo": true,
    "fecha_creacion": "2026-01-29T00:00:00Z"
  }
}
```

### **POST** `/`

Crear un nuevo usuario

**Permisos:** ADMIN

**Request Body:**

```json
{
  "nombre_usuario": "supervisor1",
  "correo": "supervisor@terracanada.com",
  "contrasena": "password123",
  "nombre_completo": "Juan Pérez",
  "rol_id": 2,
  "telefono": "+1234567890"
}
```

**Response 201:**

```json
{
  "code": 201,
  "estado": true,
  "message": "Usuario creado exitosamente",
  "data": {
    "id": 5,
    "nombre_usuario": "supervisor1",
    "correo": "supervisor@terracanada.com",
    "nombre_completo": "Juan Pérez",
    "rol_id": 2,
    "activo": true
  }
}
```

### **PUT** `/:id`

Actualizar un usuario

**Permisos:** ADMIN

**Request Body:**

```json
{
  "nombre_completo": "Juan Pérez González",
  "telefono": "+1987654321",
  "activo": true
}
```

### **DELETE** `/:id`

Desactivar un usuario (soft delete)

**Permisos:** ADMIN

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Usuario desactivado",
  "data": null
}
```

### **PUT** `/:id/cambiar-password`

Cambiar contraseña de un usuario

**Permisos:** ADMIN o el mismo usuario

**Request Body:**

```json
{
  "password_actual": "old_password",
  "password_nueva": "new_password"
}
```

---

## 🎭 ROLES

Base URL: `/api/v1/roles`

### **GET** `/`

Listar todos los roles

**Permisos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Roles obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "ADMIN",
      "descripcion": "Control total del sistema",
      "fecha_creacion": "2026-01-29T00:00:00Z"
    },
    {
      "id": 2,
      "nombre": "SUPERVISOR",
      "descripcion": "Casi control total excepto gestión de usuarios"
    },
    {
      "id": 3,
      "nombre": "EQUIPO",
      "descripcion": "Operaciones básicas con tarjetas"
    }
  ]
}
```

### **GET** `/:id`

Obtener un rol por ID

### **POST** `/`

Crear un nuevo rol

**Permisos:** ADMIN

### **PUT** `/:id`

Actualizar un rol

**Permisos:** ADMIN

### **DELETE** `/:id`

Eliminar un rol

**Permisos:** ADMIN

---

## 🛠️ SERVICIOS

Base URL: `/api/v1/servicios`

### **GET** `/`

Listar todos los servicios

**Permisos:** Todos

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Servicios obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "Guianza",
      "descripcion": "Servicios de guías turísticos",
      "activo": true
    },
    {
      "id": 2,
      "nombre": "Literie",
      "descripcion": "Servicios de hotelería"
    }
  ]
}
```

### **POST** `/`

Crear un nuevo servicio

**Permisos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "nombre": "Car rental",
  "descripcion": "Alquiler de vehículos",
  "activo": true
}
```

---

## 🏢 PROVEEDORES

Base URL: `/api/v1/proveedores`

### **GET** `/`

Listar todos los proveedores

**Permisos:** Todos

**Query Params:**

- `servicio_id` (opcional): Filtrar por servicio
- `activo` (opcional): true | false

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Proveedores obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "Guías Turísticos Montreal",
      "servicio": {
        "id": 1,
        "nombre": "Guianza"
      },
      "lenguaje": "Français",
      "telefono": "+1514123456",
      "correos": [
        {
          "id": 1,
          "correo": "info@guiasmtl.com",
          "principal": true,
          "activo": true
        }
      ],
      "activo": true
    }
  ]
}
```

### **GET** `/:id`

Obtener un proveedor por ID

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Proveedor obtenido",
  "data": {
    "id": 1,
    "nombre": "Guías Turísticos Montreal",
    "servicio": {
      "id": 1,
      "nombre": "Guianza"
    },
    "lenguaje": "Français",
    "telefono": "+1514123456",
    "descripcion": "Proveedor de guías en Montreal",
    "correos": [
      {
        "id": 1,
        "correo": "info@guiasmtl.com",
        "principal": true,
        "activo": true
      },
      {
        "id": 2,
        "correo": "contacto@guiasmtl.com",
        "principal": false,
        "activo": true
      }
    ],
    "activo": true,
    "fecha_creacion": "2026-01-15T00:00:00Z"
  }
}
```

### **POST** `/`

Crear un nuevo proveedor

**Permisos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "nombre": "Tours Quebec",
  "servicio_id": 5,
  "lenguaje": "English",
  "telefono": "+1418987654",
  "descripcion": "Operador turístico en Quebec",
  "correos": [
    {
      "correo": "info@toursquebec.com",
      "principal": true
    },
    {
      "correo": "ventas@toursquebec.com",
      "principal": false
    }
  ]
}
```

### **PUT** `/:id`

Actualizar un proveedor

**Permisos:** ADMIN, SUPERVISOR

### **DELETE** `/:id`

Desactivar un proveedor

**Permisos:** ADMIN

### **POST** `/:id/correos`

Agregar correo a un proveedor (máximo 4)

**Permisos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "correo": "nuevo@proveedor.com",
  "principal": false
}
```

### **PUT** `/:id/correos/:correo_id`

Actualizar correo de proveedor

### **DELETE** `/:id/correos/:correo_id`

Desactivar correo de proveedor

---

## 🏨 CLIENTES

Base URL: `/api/v1/clientes`

### **GET** `/`

Listar todos los clientes (hoteles)

**Permisos:** Todos

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Clientes obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "Hotel Royal Montreal",
      "ubicacion": "Montreal, QC",
      "telefono": "+1514111222",
      "correo": "reservas@hotelroyal.com",
      "activo": true
    }
  ]
}
```

### **POST** `/`

Crear un nuevo cliente

**Permisos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "nombre": "Hotel Plaza Quebec",
  "ubicacion": "Quebec City, QC",
  "telefono": "+1418333444",
  "correo": "info@hotelplaza.com"
}
```

---

## 💳 TARJETAS DE CRÉDITO

Base URL: `/api/v1/tarjetas`

### **GET** `/`

Listar todas las tarjetas

**Permisos:** ADMIN, SUPERVISOR

**Query Params:**

- `moneda` (opcional): USD | CAD
- `activo` (opcional): true | false

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Tarjetas obtenidas",
  "data": [
    {
      "id": 1,
      "nombre_titular": "Terra Canada Inc.",
      "ultimos_4_digitos": "1234",
      "tipo_tarjeta": "Visa",
      "moneda": "USD",
      "limite_mensual": 50000.0,
      "saldo_disponible": 35000.0,
      "activo": true
    }
  ]
}
```

### **GET** `/:id`

Obtener una tarjeta por ID

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Tarjeta obtenida",
  "data": {
    "id": 1,
    "nombre_titular": "Terra Canada Inc.",
    "ultimos_4_digitos": "1234",
    "tipo_tarjeta": "Visa",
    "moneda": "USD",
    "limite_mensual": 50000.0,
    "saldo_disponible": 35000.0,
    "porcentaje_usado": 30,
    "activo": true,
    "fecha_creacion": "2026-01-01T00:00:00Z",
    "fecha_actualizacion": "2026-01-29T12:34:56Z"
  }
}
```

### **POST** `/`

Crear una nueva tarjeta

**Permisos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "nombre_titular": "Terra Canada - Visa Gold",
  "ultimos_4_digitos": "5678",
  "tipo_tarjeta": "Visa Gold",
  "moneda": "CAD",
  "limite_mensual": 75000.0
}
```

**Response 201:**

```json
{
  "code": 201,
  "estado": true,
  "message": "Tarjeta creada exitosamente",
  "data": {
    "id": 5,
    "nombre_titular": "Terra Canada - Visa Gold",
    "ultimos_4_digitos": "5678",
    "moneda": "CAD",
    "limite_mensual": 75000.0,
    "saldo_disponible": 75000.0,
    "activo": true
  }
}
```

### **PUT** `/:id`

Actualizar una tarjeta

**Permisos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "limite_mensual": 80000.0,
  "activo": true
}
```

### **POST** `/:id/cargar`

Cargar saldo manualmente a una tarjeta

**Permisos:** ADMIN

**Request Body:**

```json
{
  "monto": 5000.0,
  "comentario": "Pago manual de factura"
}
```

### **GET** `/:id/historial`

Ver historial de transacciones de una tarjeta

**Permisos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Historial obtenido",
  "data": {
    "tarjeta": {
      "id": 1,
      "nombre_titular": "Terra Canada Inc.",
      "saldo_actual": 35000.0
    },
    "transacciones": [
      {
        "pago_id": 123,
        "codigo_reserva": "ABC123",
        "monto": 5000.0,
        "fecha": "2026-01-29T10:00:00Z",
        "proveedor": "Tours Quebec"
      }
    ]
  }
}
```

---

## 🏦 CUENTAS BANCARIAS

Base URL: `/api/v1/cuentas`

### **GET** `/`

Listar todas las cuentas bancarias

**Permisos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Cuentas obtenidas",
  "data": [
    {
      "id": 1,
      "nombre_banco": "RBC Royal Bank",
      "nombre_cuenta": "Cuenta Empresarial USD",
      "ultimos_4_digitos": "9876",
      "moneda": "USD",
      "activo": true
    }
  ]
}
```

### **POST** `/`

Crear una nueva cuenta bancaria

**Permisos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "nombre_banco": "Desjardins",
  "nombre_cuenta": "Cuenta Corriente CAD",
  "ultimos_4_digitos": "4321",
  "moneda": "CAD"
}
```

---

## 💰 PAGOS (CORE)

Base URL: `/api/v1/pagos`

### **GET** `/`

Listar todos los pagos

**Permisos:**

- ADMIN, SUPERVISOR: Ver todos
- EQUIPO: Solo sus propios pagos

**Query Params:**

- `page`, `limit`: Paginación
- `proveedor_id`: Filtrar por proveedor
- `pagado`: true | false
- `verificado`: true | false
- `gmail_enviado`: true | false
- `fecha_desde`, `fecha_hasta`: Rango de fechas
- `moneda`: USD | CAD

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Pagos obtenidos",
  "data": {
    "pagos": [
      {
        "id": 1,
        "proveedor": {
          "id": 5,
          "nombre": "Tours Quebec"
        },
        "usuario": {
          "id": 2,
          "nombre_completo": "Juan Supervisor"
        },
        "codigo_reserva": "ABC123",
        "monto": 5000.0,
        "moneda": "USD",
        "descripcion": "Tour para grupo de 15 personas",
        "fecha_esperada_debito": "2026-02-01",
        "tipo_medio_pago": "TARJETA",
        "medio_pago": {
          "id": 1,
          "nombre": "Visa ****1234"
        },
        "clientes": [
          {
            "id": 3,
            "nombre": "Hotel Royal Montreal"
          }
        ],
        "pagado": true,
        "verificado": false,
        "gmail_enviado": false,
        "fecha_pago": "2026-01-29T10:00:00Z",
        "fecha_creacion": "2026-01-28T15:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 156,
      "totalPages": 16
    },
    "resumen": {
      "total_monto": 450000.0,
      "total_pagado": 350000.0,
      "total_pendiente": 100000.0
    }
  }
}
```

### **GET** `/:id`

Obtener un pago por ID

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Pago obtenido",
  "data": {
    "id": 1,
    "proveedor": {
      "id": 5,
      "nombre": "Tours Quebec",
      "servicio": "Excursion"
    },
    "usuario": {
      "id": 2,
      "nombre_completo": "Juan Supervisor"
    },
    "codigo_reserva": "ABC123",
    "monto": 5000.0,
    "moneda": "USD",
    "descripcion": "Tour para grupo de 15 personas",
    "fecha_esperada_debito": "2026-02-01",
    "tipo_medio_pago": "TARJETA",
    "medio_pago": {
      "tipo": "TARJETA",
      "id": 1,
      "nombre": "Visa ****1234",
      "moneda": "USD"
    },
    "clientes": [
      {
        "id": 3,
        "nombre": "Hotel Royal Montreal"
      }
    ],
    "documentos": [
      {
        "id": 10,
        "nombre_archivo": "factura_ABC123.pdf",
        "tipo_documento": "FACTURA",
        "fecha_subida": "2026-01-29T11:00:00Z"
      }
    ],
    "pagado": true,
    "verificado": false,
    "gmail_enviado": false,
    "activo": true,
    "fecha_pago": "2026-01-29T10:00:00Z",
    "fecha_verificacion": null,
    "fecha_creacion": "2026-01-28T15:30:00Z",
    "fecha_actualizacion": "2026-01-29T10:00:00Z"
  }
}
```

### **POST** `/`

Crear un nuevo pago

**Permisos:**

- ADMIN, SUPERVISOR: Pueden usar TARJETA y CUENTA_BANCARIA
- EQUIPO: Solo puede usar TARJETA

**Request Body:**

```json
{
  "proveedor_id": 5,
  "codigo_reserva": "DEF456",
  "monto": 3500.0,
  "moneda": "USD",
  "descripcion": "Excursión Cataratas Niágara",
  "fecha_esperada_debito": "2026-02-05",
  "tipo_medio_pago": "TARJETA",
  "tarjeta_id": 1,
  "clientes_ids": [3, 5]
}
```

**Validaciones:**

- Si `tipo_medio_pago` = "TARJETA": debe incluir `tarjeta_id` y validar saldo
- Si `tipo_medio_pago` = "CUENTA_BANCARIA": debe incluir `cuenta_bancaria_id`
- No pueden enviarse ambos IDs al mismo tiempo
- El monto debe ser positivo
- Los clientes deben existir y estar activos

**Response 201:**

```json
{
  "code": 201,
  "estado": true,
  "message": "Pago creado exitosamente",
  "data": {
    "id": 157,
    "codigo_reserva": "DEF456",
    "monto": 3500.0,
    "proveedor": {
      "nombre": "Tours Quebec"
    },
    "medio_pago": {
      "tipo": "TARJETA",
      "saldo_restante": 31500.0
    },
    "pagado": false,
    "verificado": false
  }
}
```

### **PUT** `/:id`

Actualizar un pago

**Permisos:** ADMIN, SUPERVISOR

**Restricciones:**

- No se puede editar si `verificado = true`
- No se puede cambiar el medio de pago si `pagado = true`

**Request Body:**

```json
{
  "descripcion": "Excursión actualizada con más detalles",
  "fecha_esperada_debito": "2026-02-06"
}
```

### **DELETE** `/:id`

Desactivar un pago (soft delete)

**Permisos:** ADMIN

**Restricciones:**

- No se puede eliminar si `gmail_enviado = true`
- Si era con tarjeta, devuelve el saldo

### **PUT** `/:id/marcar-pagado`

Marcar pago como pagado (manual)

**Permisos:** ADMIN

**Request Body:**

```json
{
  "pagado": true
}
```

### **PUT** `/:id/marcar-verificado`

Marcar pago como verificado (manual)

**Permisos:** ADMIN

**Request Body:**

```json
{
  "verificado": true
}
```

### **GET** `/pendientes-correo`

Obtener pagos pendientes de enviar correo

**Permisos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Pagos pendientes obtenidos",
  "data": {
    "total": 25,
    "por_proveedor": [
      {
        "proveedor": {
          "id": 5,
          "nombre": "Tours Quebec"
        },
        "cantidad_pagos": 10,
        "monto_total": 45000.0,
        "moneda": "USD"
      }
    ]
  }
}
```

---

## 📄 DOCUMENTOS

Base URL: `/api/v1/documentos`

### **GET** `/`

Listar todos los documentos

**Permisos:**

- ADMIN, SUPERVISOR: Ver todos
- EQUIPO: Solo sus documentos

**Query Params:**

- `tipo_documento`: FACTURA | DOCUMENTO_BANCO
- `usuario_id`: Filtrar por usuario
- `pago_id`: Filtrar por pago vinculado

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Documentos obtenidos",
  "data": [
    {
      "id": 1,
      "usuario": {
        "id": 2,
        "nombre_completo": "Juan Supervisor"
      },
      "nombre_archivo": "factura_ABC123.pdf",
      "url_documento": "https://storage.terracanada.com/facturas/factura_ABC123.pdf",
      "tipo_documento": "FACTURA",
      "pagos_vinculados": [
        {
          "id": 123,
          "codigo_reserva": "ABC123"
        }
      ],
      "fecha_subida": "2026-01-29T11:00:00Z"
    }
  ]
}
```

### **POST** `/`

Subir un nuevo documento

**Permisos:** Todos

**Request:** `multipart/form-data`

**Form Fields:**

- `file`: Archivo PDF (max 10MB)
- `tipo_documento`: "FACTURA" | "DOCUMENTO_BANCO"
- `pago_id` (opcional): ID del pago (solo para FACTURA)

**Response 201:**

```json
{
  "code": 201,
  "estado": true,
  "message": "Documento subido exitosamente. Procesando con N8N...",
  "data": {
    "id": 50,
    "nombre_archivo": "extracto_enero_2026.pdf",
    "url_documento": "https://storage.terracanada.com/extractos/extracto_enero_2026.pdf",
    "tipo_documento": "DOCUMENTO_BANCO",
    "webhook_enviado": true
  }
}
```

**Proceso:**

1. Validar archivo (PDF, tamaño)
2. Guardar en storage (local o cloud)
3. Crear registro en BD
4. Enviar webhook a N8N
5. N8N procesa y actualiza pagos

### **GET** `/:id`

Obtener detalles de un documento

### **DELETE** `/:id`

Eliminar un documento

**Permisos:** ADMIN

---

## 📧 CORREOS

Base URL: `/api/v1/correos`

### **GET** `/`

Listar todos los correos

**Permisos:** ADMIN, SUPERVISOR

**Query Params:**

- `estado`: BORRADOR | ENVIADO
- `proveedor_id`: Filtrar por proveedor

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Correos obtenidos",
  "data": [
    {
      "id": 1,
      "proveedor": {
        "id": 5,
        "nombre": "Tours Quebec",
        "lenguaje": "English"
      },
      "correo_seleccionado": "info@toursquebec.com",
      "usuario_envio": {
        "id": 2,
        "nombre_completo": "Juan Supervisor"
      },
      "asunto": "Notificación de Pagos - Enero 2026",
      "estado": "BORRADOR",
      "cantidad_pagos": 10,
      "monto_total": 45000.0,
      "fecha_generacion": "2026-01-29T12:00:00Z",
      "fecha_envio": null
    }
  ]
}
```

### **GET** `/:id`

Obtener detalles de un correo

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Correo obtenido",
  "data": {
    "id": 1,
    "proveedor": {
      "id": 5,
      "nombre": "Tours Quebec",
      "lenguaje": "English",
      "correos_disponibles": [
        {
          "id": 1,
          "correo": "info@toursquebec.com",
          "principal": true
        },
        {
          "id": 2,
          "correo": "ventas@toursquebec.com",
          "principal": false
        }
      ]
    },
    "correo_seleccionado": "info@toursquebec.com",
    "asunto": "Notificación de Pagos - Enero 2026",
    "cuerpo": "Dear Tours Quebec,\n\nWe are pleased to inform you...",
    "estado": "BORRADOR",
    "cantidad_pagos": 10,
    "monto_total": 45000.0,
    "pagos": [
      {
        "id": 123,
        "codigo_reserva": "ABC123",
        "monto": 5000.0,
        "moneda": "USD",
        "cliente": "Hotel Royal Montreal"
      }
    ],
    "fecha_generacion": "2026-01-29T12:00:00Z"
  }
}
```

### **POST** `/generar`

Generar borradores de correos para pagos pendientes

**Permisos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Correos generados exitosamente",
  "data": {
    "correos_generados": 5,
    "proveedores_procesados": [
      {
        "proveedor_id": 5,
        "proveedor_nombre": "Tours Quebec",
        "cantidad_pagos": 10
      }
    ]
  }
}
```

### **PUT** `/:id`

Actualizar borrador de correo

**Permisos:** ADMIN, SUPERVISOR

**Request Body:**

```json
{
  "correo_seleccionado": "ventas@toursquebec.com",
  "asunto": "Actualizado - Notificación de Pagos",
  "cuerpo": "Nuevo contenido del correo..."
}
```

### **POST** `/:id/enviar`

Enviar un correo

**Permisos:** ADMIN, SUPERVISOR

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Correo enviado exitosamente",
  "data": {
    "id": 1,
    "estado": "ENVIADO",
    "fecha_envio": "2026-01-29T14:00:00Z",
    "pagos_actualizados": 10,
    "n8n_response": {
      "success": true,
      "message_id": "gmail-123456"
    }
  }
}
```

---

## 📊 ANÁLISIS Y REPORTES

Base URL: `/api/v1/analisis`

### **GET** `/dashboard`

Obtener KPIs del dashboard

**Permisos:** Todos (con datos filtrados por rol)

**Query Params:**

- `fecha_desde`, `fecha_hasta`: Rango de fechas

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Dashboard obtenido",
  "data": {
    "kpis": {
      "pagos_pendientes": 45,
      "pagos_pagados": 120,
      "pagos_no_verificados": 30,
      "pagos_verificados": 90,
      "correos_pendientes": 5,
      "correos_enviados": 25
    },
    "totales_moneda": {
      "USD": {
        "total": 450000.0,
        "pagado": 350000.0,
        "pendiente": 100000.0
      },
      "CAD": {
        "total": 125000.0,
        "pagado": 95000.0,
        "pendiente": 30000.0
      }
    },
    "saldos_tarjetas": {
      "USD": {
        "total_limite": 100000.0,
        "total_disponible": 65000.0,
        "porcentaje_usado": 35
      },
      "CAD": {
        "total_limite": 75000.0,
        "total_disponible": 50000.0,
        "porcentaje_usado": 33
      }
    }
  }
}
```

### **GET** `/comparativo-medios`

Comparativo de pagos por medio de pago

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Comparativo obtenido",
  "data": {
    "tarjetas": {
      "cantidad": 85,
      "monto_total": 380000.0,
      "porcentaje": 76
    },
    "cuentas_bancarias": {
      "cantidad": 35,
      "monto_total": 120000.0,
      "porcentaje": 24
    }
  }
}
```

### **GET** `/temporal`

Evolución temporal de pagos

**Query Params:**

- `agrupacion`: dia | semana | mes
- `fecha_desde`, `fecha_hasta`

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Análisis temporal obtenido",
  "data": [
    {
      "periodo": "2026-01-01",
      "cantidad_pagos": 25,
      "monto_total": 125000.0
    },
    {
      "periodo": "2026-01-08",
      "cantidad_pagos": 30,
      "monto_total": 150000.0
    }
  ]
}
```

### **GET** `/top-proveedores`

Top proveedores por monto

**Query Params:**

- `limite`: Cantidad (default: 10)

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Top proveedores obtenido",
  "data": [
    {
      "proveedor_id": 5,
      "proveedor_nombre": "Tours Quebec",
      "servicio": "Excursion",
      "cantidad_pagos": 45,
      "monto_total": 225000.0
    }
  ]
}
```

---

## 🔍 EVENTOS (AUDITORÍA)

Base URL: `/api/v1/eventos`

### **GET** `/`

Listar eventos de auditoría

**Permisos:** ADMIN, SUPERVISOR (lectura)

**Query Params:**

- `usuario_id`: Filtrar por usuario
- `tipo_evento`: INICIO_SESION | CREAR | ACTUALIZAR | ELIMINAR | etc.
- `entidad_tipo`: usuarios | pagos | tarjetas | etc.
- `fecha_desde`, `fecha_hasta`

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Eventos obtenidos",
  "data": {
    "eventos": [
      {
        "id": 1234,
        "usuario": {
          "id": 2,
          "nombre_completo": "Juan Supervisor"
        },
        "tipo_evento": "CREAR",
        "entidad_tipo": "pagos",
        "entidad_id": 157,
        "descripcion": "Creado pago ABC123 por $5,000 USD",
        "ip_origen": "192.168.1.100",
        "fecha_evento": "2026-01-29T10:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 5678
    }
  }
}
```

---

## 🔗 WEBHOOKS

Base URL: `/api/v1/webhooks`

### **POST** `/n8n/documento-procesado`

Webhook para recibir resultados de N8N después de procesar documento

**Permisos:** N8N (requiere token especial)

**Headers:**

- `X-N8N-Token`: Token de autenticación de N8N

**Request Body:**

```json
{
  "documento_id": 50,
  "tipo_documento": "DOCUMENTO_BANCO",
  "pagos_procesados": [
    {
      "pago_id": 123,
      "codigo_reserva": "ABC123",
      "encontrado": true,
      "pagado": true,
      "verificado": true
    },
    {
      "pago_id": 124,
      "codigo_reserva": "DEF456",
      "encontrado": true,
      "pagado": true,
      "verificado": true
    }
  ],
  "codigos_no_encontrados": ["XYZ789"]
}
```

**Response 200:**

```json
{
  "code": 200,
  "estado": true,
  "message": "Webhook procesado exitosamente",
  "data": {
    "pagos_actualizados": 2,
    "vinculaciones_creadas": 2
  }
}
```

---

## 📝 NOTAS IMPORTANTES

### **Autenticación**

Todos los endpoints (excepto `/auth/login`) requieren el header:

```
Authorization: Bearer {token_jwt}
```

### **Formato de Fechas**

Todas las fechas están en formato ISO 8601 con zona horaria:

```
2026-01-29T14:30:00Z
```

### **Paginación**

Los endpoints que retornan listas soportan paginación:

```
?page=1&limit=10
```

### **Códigos de Error Comunes**

- **400**: Datos inválidos
- **401**: No autenticado
- **403**: Sin permisos
- **404**: Recurso no encontrado
- **409**: Conflicto (duplicado)
- **500**: Error del servidor

### **Rate Limiting**

- 100 peticiones por 15 minutos (general)
- 5 intentos de login por 15 minutos
