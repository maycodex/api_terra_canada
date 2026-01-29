# 🌍 API Terra Canada - Sistema de Gestión de Pagos

API RESTful profesional construida con Node.js, TypeScript, Express y Prisma para gestionar pagos a proveedores de servicios turísticos.

---

## 🚀 Inicio Rápido

### 1. Configurar Variables de Entorno

Copia el archivo `.env.example` a `.env` y configura tus credenciales:

```bash
# Windows PowerShell
Copy-Item .env.example .env
```

**IMPORTANTE:** Edita el archivo `.env` y configura:

- `DATABASE_URL` con tus credenciales de PostgreSQL
- `JWT_SECRET` con un secreto seguro (mínimo 32 caracteres)
- Otros parámetros según tu entorno

### 2. Generar Cliente Prisma

Una vez configurada la base de datos, genera el cliente Prisma:

```bash
npm run prisma:pull    # Genera schema desde la BD existente
npm run prisma:generate # Genera el cliente TypeScript
```

### 3. Iniciar el Servidor

```bash
# Modo desarrollo (con auto-reload)
npm run dev

# Compilar para producción
npm run build

# Iniciar en producción
npm start
```

El servidor estará disponible en: `http://localhost:3000`

---

## 📚 Documentación

### Documentación Interactiva (Swagger)

Una vez iniciado el servidor:

```
http://localhost:3000/api-docs
```

### Health Check

```
http://localhost:3000/health
```

### Documentación de Planificación

Consulta la carpeta `planificacion/` para documentación completa:

- **README.md** - Guía general
- **01_ARQUITECTURA_Y_ESTRUCTURA.md** - Arquitectura y stack tecnológico
- **02_ENDPOINTS.md** - Documentación completa de endpoints
- **03_PLAN_IMPLEMENTACION.md** - Plan de implementación

---

## 🛠️ Scripts Disponibles

```bash
npm run dev              # Desarrollo con auto-reload
npm run build            # Compilar TypeScript
npm start                # Producción
npm run prisma:pull      # Actualizar schema desde BD
npm run prisma:generate  # Generar cliente Prisma
npm run prisma:studio    # Abrir Prisma Studio (GUI)
npm run lint             # Linter ESLint
npm run format           # Formatear código con Prettier
```

---

## 📁 Estructura del Proyecto

```
api_terra/
├── src/
│   ├── config/          # Configuraciones (DB, logger, swagger)
│   ├── middlewares/     # Auth, RBAC, validación, errores
│   ├── routes/          # Rutas de la API
│   ├── controllers/     # Controladores (próximamente)
│   ├── services/        # Lógica de negocio (próximamente)
│   ├── schemas/         # Validaciones Zod (próximamente)
│   ├── types/           # Tipos TypeScript
│   ├── utils/           # Utilidades (JWT, bcrypt, etc.)
│   └── index.ts         # Punto de entrada
├── prisma/              # Schema de Prisma
├── uploads/             # Archivos subidos
├── logs/                # Logs de la aplicación
├── planificacion/       # Documentación de planificación
└── .env                 # Variables de entorno (NO subir a git)
```

---

## 🔐 Autenticación

La API usa JWT (JSON Web Tokens). Para autenticarte:

1. **Login:**

```bash
POST /api/v1/auth/login
{
  "username": "tu_usuario",
  "password": "tu_password"
}
```

2. **Usar el token en requests:**

```bash
Authorization: Bearer {tu_token_jwt}
```

---

## 👥 Roles del Sistema

| Rol            | Descripción   | Permisos                         |
| -------------- | ------------- | -------------------------------- |
| **ADMIN**      | Administrador | Acceso completo                  |
| **SUPERVISOR** | Supervisor    | Todo excepto gestión de usuarios |
| **EQUIPO**     | Operador      | Solo pagos con tarjetas          |

---

## 🔗 Endpoints Principales

### Autenticación

- `POST /api/v1/auth/login` - Iniciar sesión
- `GET /api/v1/auth/me` - Usuario actual

### Otros Módulos

- `/api/v1/usuarios` - Gestión de usuarios
- `/api/v1/roles` - Gestión de roles
- `/api/v1/proveedores` - Proveedores
- `/api/v1/clientes` - Clientes (hoteles)
- `/api/v1/tarjetas` - Tarjetas de crédito
- `/api/v1/cuentas` - Cuentas bancarias
- `/api/v1/pagos` - **CORE** - Gestión de pagos
- `/api/v1/documentos` - Facturas y extractos
- `/api/v1/correos` - Envío de correos
- `/api/v1/analisis` - Análisis y reportes

Ver documentación completa en Swagger o en `planificacion/02_ENDPOINTS.md`

---

## 📊 Estado Actual

✅ Proyecto inicializado  
✅ Dependencias instaladas  
✅ TypeScript configurado  
✅ Prisma configurado  
✅ Estructura de carpetas creada  
✅ Configuraciones (environment, database, logger, swagger)  
✅ Utilidades (JWT, bcrypt, response, upload)  
✅ Middlewares (auth, RBAC, validation, error, audit)  
✅ Archivo principal con servidor Express  
✅ Documentación Swagger configurada

⏳ **Pendiente:**

- Configurar credenciales de base de datos en `.env`
- Generar cliente Prisma
- Implementar controllers y services de cada módu lo
- Implementar schemas de validación Zod
- Crear rutas específicas para cada módulo

---

## 🔧 Configuración de Base de Datos

**IMPORTANTE:** Antes de iniciar el servidor, debes configurar la conexión a PostgreSQL:

1. Edita el archivo `.env`
2. Actualiza `DATABASE_URL`:

```
DATABASE_URL=postgresql://usuario:password@host:5432/nombre_bd
```

3. Ejecuta:

```bash
npm run prisma:pull      # Genera schema desde tu BD
npm run prisma:generate  # Genera cliente TypeScript
```

---

## 🐛 Troubleshooting

### Error: Cannot find module '@prisma/client'

```bash
npm run prisma:generate
```

### Error: Connection refused (base de datos)

- Verifica que PostgreSQL esté corriendo
- Verifica las credenciales en `.env`
- Verifica que la base de datos exista

### Puerto 3000 en uso

Cambia `PORT` en `.env` a otro puerto disponible

---

## 📝 Tecnologías

- **Runtime:** Node.js v18+
- **Lenguaje:** TypeScript v5+
- **Framework:** Express.js
- **ORM:** Prisma
- **BD:** PostgreSQL
- **Auth:** JWT
- **Validación:** Zod
- **Docs:** Swagger/OpenAPI
- **Logging:** Winston

---

## 📄 Licencia

Propiedad de Terra Canada

---

**Versión:** 1.0.0  
**Última actualización:** Enero 2026
