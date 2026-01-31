# 🏗️ ARQUITECTURA Y ESTRUCTURA DE LA API - TERRA CANADA

---

## 📑 TABLA DE CONTENIDOS

1. [Visión General](#visión-general)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Estructura de Carpetas](#estructura-de-carpetas)
4. [Arquitectura de la API](#arquitectura-de-la-api)
5. [Base de Datos](#base-de-datos)
6. [Seguridad y Autenticación](#seguridad-y-autenticación)
7. [Integraciones Externas](#integraciones-externas)
8. [Variables de Entorno](#variables-de-entorno)

---

## 🎯 VISIÓN GENERAL

API RESTful construida con Node.js para gestionar el sistema de pagos de Terra Canada, incluyendo:

- Gestión de usuarios, roles y permisos
- Registro y seguimiento de pagos a proveedores
- Control de medios de pago (tarjetas y cuentas bancarias)
- Procesamiento automático de documentos (facturas y extractos)
- Generación y envío de correos electrónicos
- Auditoría completa de operaciones
- Análisis y reportes

---

## 🛠️ STACK TECNOLÓGICO

### **Backend Framework**

- **Node.js** v18+ (Runtime)
- **Express.js** v4.18+ (Framework web)
- **TypeScript** v5.0+ (Lenguaje tipado)

### **ORM y Base de Datos**

- **Prisma ORM** v5.0+ (Object-Relational Mapping)
- **PostgreSQL** v14+ (Base de datos)

### **Autenticación y Seguridad**

- **jsonwebtoken** (JWT para autenticación)
- **bcrypt** (Hash de contraseñas)
- **helmet** (Headers de seguridad)
- **cors** (Control de acceso CORS)
- **express-rate-limit** (Limitación de peticiones)

### **Validación y Documentación**

- **Zod** (Validación de datos)
- **Swagger/OpenAPI** (Documentación de API)
- **swagger-ui-express** (UI de documentación)

### **Utilidades**

- **dotenv** (Variables de entorno)
- **winston** (Logging)
- **morgan** (HTTP request logger)
- **axios** (Cliente HTTP para N8N)
- **date-fns** (Manipulación de fechas)
- **multer** (Upload de archivos)
- **nodemailer** (Envío de correos - backup)

### **Desarrollo**

- **nodemon** (Auto-reload en desarrollo)
- **tsx** (Ejecutar TypeScript directamente)
- **eslint** (Linter)
- **prettier** (Formateo de código)

---

## 📁 ESTRUCTURA DE CARPETAS

```
api_terra/
│
├── prisma/                          # Configuración de Prisma
│   ├── schema.prisma               # Esquema de base de datos
│   └── seeds/                      # Datos iniciales
│       ├── roles.seed.ts
│       └── servicios.seed.ts
│
├── src/                            # Código fuente
│   │
│   ├── config/                     # Configuraciones
│   │   ├── database.ts            # Configuración de Prisma
│   │   ├── environment.ts         # Variables de entorno
│   │   ├── logger.ts              # Configuración de Winston
│   │   └── swagger.ts             # Configuración de Swagger
│   │
│   ├── middlewares/               # Middlewares
│   │   ├── auth.middleware.ts    # Verificación de JWT
│   │   ├── rbac.middleware.ts    # Control de roles
│   │   ├── audit.middleware.ts   # Registro de auditoría
│   │   ├── error.middleware.ts   # Manejo de errores
│   │   └── validate.middleware.ts # Validación con Zod
│   │
│   ├── routes/                    # Rutas de la API
│   │   ├── index.ts              # Router principal
│   │   ├── auth.routes.ts        # Autenticación
│   │   ├── usuarios.routes.ts    # Usuarios
│   │   ├── roles.routes.ts       # Roles
│   │   ├── servicios.routes.ts   # Servicios
│   │   ├── proveedores.routes.ts # Proveedores
│   │   ├── clientes.routes.ts    # Clientes
│   │   ├── tarjetas.routes.ts    # Tarjetas de crédito
│   │   ├── cuentas.routes.ts     # Cuentas bancarias
│   │   ├── pagos.routes.ts       # Pagos (CORE)
│   │   ├── documentos.routes.ts  # Documentos
│   │   ├── correos.routes.ts     # Envíos de correos
│   │   ├── analisis.routes.ts    # Análisis y reportes
│   │   ├── eventos.routes.ts     # Auditoría
│   │   └── webhooks.routes.ts    # Webhooks para N8N
│   │
│   ├── controllers/               # Controladores
│   │   ├── auth.controller.ts
│   │   ├── usuarios.controller.ts
│   │   ├── roles.controller.ts
│   │   ├── servicios.controller.ts
│   │   ├── proveedores.controller.ts
│   │   ├── clientes.controller.ts
│   │   ├── tarjetas.controller.ts
│   │   ├── cuentas.controller.ts
│   │   ├── pagos.controller.ts
│   │   ├── documentos.controller.ts
│   │   ├── correos.controller.ts
│   │   ├── analisis.controller.ts
│   │   ├── eventos.controller.ts
│   │   └── webhooks.controller.ts
│   │
│   ├── services/                  # Servicios (lógica de negocio)
│   │   ├── auth.service.ts
│   │   ├── usuarios.service.ts
│   │   ├── roles.service.ts
│   │   ├── servicios.service.ts
│   │   ├── proveedores.service.ts
│   │   ├── clientes.service.ts
│   │   ├── tarjetas.service.ts
│   │   ├── cuentas.service.ts
│   │   ├── pagos.service.ts
│   │   ├── documentos.service.ts
│   │   ├── correos.service.ts
│   │   ├── analisis.service.ts
│   │   ├── eventos.service.ts
│   │   └── n8n.service.ts        # Integración con N8N
│   │
│   ├── schemas/                   # Esquemas de validación Zod
│   │   ├── auth.schema.ts
│   │   ├── usuarios.schema.ts
│   │   ├── roles.schema.ts
│   │   ├── servicios.schema.ts
│   │   ├── proveedores.schema.ts
│   │   ├── clientes.schema.ts
│   │   ├── tarjetas.schema.ts
│   │   ├── cuentas.schema.ts
│   │   ├── pagos.schema.ts
│   │   ├── documentos.schema.ts
│   │   └── correos.schema.ts
│   │
│   ├── types/                     # Tipos TypeScript
│   │   ├── express.d.ts          # Extensión de Request
│   │   ├── enums.ts              # Enums del sistema
│   │   └── interfaces.ts         # Interfaces compartidas
│   │
│   ├── utils/                     # Utilidades
│   │   ├── jwt.util.ts           # Generación/verificación JWT
│   │   ├── bcrypt.util.ts        # Hash de contraseñas
│   │   ├── response.util.ts      # Formateador de respuestas
│   │   ├── date.util.ts          # Utilidades de fecha
│   │   └── upload.util.ts        # Configuración de Multer
│   │
│   ├── jobs/                      # Tareas programadas
│   │   ├── reset-tarjetas.job.ts # Reset mensual de tarjetas
│   │   └── generar-correos.job.ts # Generación automática de correos
│   │
│   └── index.ts                   # Punto de entrada de la app
│
├── uploads/                       # Archivos subidos (temporal)
│   ├── facturas/
│   └── documentos_banco/
│
├── logs/                          # Archivos de log
│   ├── error.log
│   ├── combined.log
│   └── audit.log
│
├── tests/                         # Tests (opcional)
│   ├── unit/
│   └── integration/
│
├── .env.example                   # Ejemplo de variables de entorno
├── .env                          # Variables de entorno (no subir a git)
├── .gitignore                    # Archivos ignorados por git
├── .eslintrc.json                # Configuración de ESLint
├── .prettierrc                   # Configuración de Prettier
├── tsconfig.json                 # Configuración de TypeScript
├── package.json                  # Dependencias del proyecto
├── package-lock.json             # Lock de dependencias
└── README.md                     # Documentación del proyecto
```

---

## 🏛️ ARQUITECTURA DE LA API

### **Patrón de Arquitectura: Layered Architecture (Capas)**

```
┌─────────────────────────────────────────────────────┐
│                   CLIENT REQUEST                    │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│              MIDDLEWARE LAYER                        │
│  • CORS                                             │
│  • Helmet (Security Headers)                        │
│  • Rate Limiting                                    │
│  • Authentication (JWT)                             │
│  • Authorization (RBAC)                             │
│  • Validation (Zod)                                 │
│  • Audit Log                                        │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│                 ROUTING LAYER                       │
│  • Define endpoints                                 │
│  • Map to controllers                               │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│              CONTROLLER LAYER                       │
│  • Parse request                                    │
│  • Call service layer                               │
│  • Format response                                  │
│  • Handle HTTP status codes                         │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│               SERVICE LAYER                         │
│  • Business logic                                   │
│  • Data validation                                  │
│  • Call database through Prisma                     │
│  • Call external services (N8N)                     │
│  • Transaction management                           │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│              DATABASE LAYER (Prisma)                │
│  • Execute queries                                  │
│  • Handle database connections                      │
│  • Manage transactions                              │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│                 PostgreSQL DATABASE                 │
└─────────────────────────────────────────────────────┘
```

### **Flujo de una Petición Típica**

```
1. Cliente hace petición → POST /api/pagos

2. Middleware de autenticación verifica JWT
   ↓
3. Middleware RBAC verifica permisos del rol
   ↓
4. Middleware de validación verifica datos (Zod)
   ↓
5. Router envía a Controller (pagos.controller.ts)
   ↓
6. Controller llama a Service (pagos.service.ts)
   ↓
7. Service ejecuta lógica de negocio:
   - Valida saldo de tarjeta
   - Descuenta saldo si es tarjeta
   - Crea registro de pago con Prisma
   - Crea relación con clientes
   ↓
8. Middleware de auditoría registra la acción
   ↓
9. Controller formatea respuesta JSON
   ↓
10. Respuesta al cliente: { code: 201, data: {...} }
```

---

## 🗄️ BASE DE DATOS

### **Prisma Schema**

Prisma generará el schema automáticamente desde la base de datos PostgreSQL existente usando:

```bash
npx prisma db pull
```

Esto creará `prisma/schema.prisma` basado en las tablas definidas en `SQL ejecutado.sql`.

### **Configuración de Prisma**

```typescript
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Los modelos se generarán automáticamente desde la BD
```

### **Tablas Principales**

1. **roles** - Catálogo de roles (Admin, Supervisor, Equipo)
2. **servicios** - Catálogo de servicios turísticos
3. **usuarios** - Usuarios del sistema
4. **proveedores** - Proveedores de servicios
5. **proveedor_correos** - Correos de proveedores (máx 4)
6. **clientes** - Hoteles/clientes
7. **tarjetas_credito** - Tarjetas con control de saldo
8. **cuentas_bancarias** - Cuentas sin control de saldo
9. **pagos** - Tabla principal (CORE)
10. **pago_cliente** - Relación N:N pagos-clientes
11. **documentos** - Facturas y extractos bancarios
12. **documento_pago** - Relación N:N documentos-pagos
13. **envios_correos** - Correos generados
14. **envio_correo_detalle** - Detalle de pagos en correos
15. **eventos** - Auditoría

---

## 🔒 SEGURIDAD Y AUTENTICACIÓN

### **JWT (JSON Web Tokens)**

```typescript
// Estructura del JWT
{
  "userId": 123,
  "username": "admin@terracanada.com",
  "roleId": 1,
  "roleName": "ADMIN",
  "iat": 1234567890,
  "exp": 1234571490  // Expira en 1 hora
}
```

### **Flujo de Autenticación**

```
1. Usuario hace login → POST /api/auth/login
   Body: { username, password }

2. Sistema verifica credenciales en BD
   ↓
3. Si válido, genera JWT
   ↓
4. Retorna token al cliente
   Response: { token: "eyJhbGc..." }

5. Cliente incluye token en siguientes peticiones
   Headers: { Authorization: "Bearer eyJhbGc..." }

6. Middleware verifica token en cada petición
```

### **Control de Acceso por Rol (RBAC)**

```typescript
// Permisos por rol
ADMIN = {
  usuarios: ["create", "read", "update", "delete"],
  pagos: ["create", "read", "update", "delete", "verify"],
  tarjetas: ["create", "read", "update", "delete", "use"],
  cuentas: ["create", "read", "update", "delete", "use"],
  correos: ["read", "send"],
  // ... todos los permisos
};

SUPERVISOR = {
  usuarios: ["read"], // NO puede crear/eliminar
  pagos: ["create", "read", "update", "delete", "verify"],
  tarjetas: ["create", "read", "update", "delete", "use"],
  cuentas: ["create", "read", "update", "delete", "use"],
  correos: ["read", "send"],
  // ...
};

EQUIPO = {
  usuarios: [], // Sin acceso
  pagos: ["create", "read"], // Solo sus propios pagos
  tarjetas: ["read", "use"], // Solo puede usar, no crear
  cuentas: [], // NO puede usar cuentas bancarias
  correos: [], // NO puede enviar correos
  // ...
};
```

### **Headers de Seguridad (Helmet)**

```typescript
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security: max-age=31536000
- Content-Security-Policy: default-src 'self'
```

### **Rate Limiting**

```typescript
// Límite de peticiones por IP
- 100 peticiones por 15 minutos (general)
- 5 intentos de login por 15 minutos
```

---

## 🔌 INTEGRACIONES EXTERNAS

### **N8N (Automatización)**

#### **1. Webhook - Procesamiento de Documentos**

```
Endpoint N8N: POST https://n8n.salazargroup.cloud/webhook/procesar-documento
Authorization: Basic [token]

Request Body:
{
  "documento_id": 123,
  "url_documento": "https://storage.terracanada.com/facturas/ABC123.pdf",
  "tipo_documento": "FACTURA" | "DOCUMENTO_BANCO"
}

Response:
{
  "success": true,
  "pagos_procesados": [
    {
      "pago_id": 456,
      "codigo_reserva": "ABC123",
      "pagado": true,
      "verificado": true
    }
  ]
}
```

#### **2. Webhook - Envío de Correos**

```
Endpoint N8N: POST https://n8n.salazargroup.cloud/webhook/enviar-gmail
Authorization: Basic [token]

Request Body:
{
  "info_correo": {
    "destinatario": "proveedor@example.com",
    "asunto": "Notificación de Pagos - 29/01/2026",
    "cuerpo": "Estimado proveedor..."
  },
  "info_pagos": [
    {
      "codigo_reserva": "ABC123",
      "monto": 5000.00,
      "moneda": "USD",
      "cliente": "Hotel Royal"
    }
  ]
}

Response:
{
  "success": true,
  "message_id": "gmail-123456"
}
```

---

## 🌍 VARIABLES DE ENTORNO

```bash
# .env
# ============================================
# SERVIDOR
# ============================================
NODE_ENV=development
PORT=3000
API_VERSION=v1

# ============================================
# BASE DE DATOS
# ============================================
DATABASE_URL=postgresql://usuario:password@localhost:5432/terra_canada

# ============================================
# JWT
# ============================================
JWT_SECRET=tu_secreto_super_seguro_aqui_cambiar_en_produccion
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# ============================================
# N8N WEBHOOKS
# ============================================
N8N_BASE_URL=https://n8n.salazargroup.cloud
N8N_WEBHOOK_DOCUMENTO=/webhook/procesar-documento
N8N_WEBHOOK_CORREO=/webhook/enviar-gmail
N8N_AUTH_TOKEN=Basic [token_base64]

# ============================================
# UPLOAD DE ARCHIVOS
# ============================================
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760  # 10MB en bytes
ALLOWED_MIME_TYPES=application/pdf

# ============================================
# STORAGE (Opcional - para cloud)
# ============================================
STORAGE_TYPE=local  # local | s3 | cloudinary
# Si es S3:
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_S3_BUCKET=
# AWS_REGION=

# ============================================
# CORREO (Backup - si N8N falla)
# ============================================
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@terracanada.com
SMTP_PASS=password_app

# ============================================
# LOGS
# ============================================
LOG_LEVEL=info  # debug | info | warn | error
LOG_DIR=./logs

# ============================================
# SEGURIDAD
# ============================================
BCRYPT_ROUNDS=10
RATE_LIMIT_WINDOW_MS=900000  # 15 minutos
RATE_LIMIT_MAX_REQUESTS=100

# ============================================
# CORS
# ============================================
CORS_ORIGIN=http://localhost:5173  # URL del frontend React
```

---

## 📊 FORMATO DE RESPUESTAS

Todas las respuestas de la API seguirán este formato estándar:

```typescript
// Respuesta exitosa
{
  "code": 200,
  "estado": true,
  "message": "Operación exitosa",
  "data": {
    // Datos solicitados
  }
}

// Respuesta de error
{
  "code": 400,
  "estado": false,
  "message": "Descripción del error",
  "data": null,
  "errors": [  // Opcional, para errores de validación
    {
      "field": "nombre",
      "message": "El nombre es requerido"
    }
  ]
}
```

### **Códigos HTTP Utilizados**

- **200** - OK (éxito)
- **201** - Created (recurso creado)
- **400** - Bad Request (datos inválidos)
- **401** - Unauthorized (no autenticado)
- **403** - Forbidden (sin permisos)
- **404** - Not Found (recurso no encontrado)
- **409** - Conflict (duplicado)
- **500** - Internal Server Error (error del servidor)

---

## 🎯 PRÓXIMOS PASOS

1. ✅ Revisar esta documentación
2. Revisar el documento de [Endpoints](./02_ENDPOINTS.md)
3. Revisar el documento de [Plan de Implementación](./03_PLAN_IMPLEMENTACION.md)
4. Inicializar el proyecto y comenzar desarrollo
