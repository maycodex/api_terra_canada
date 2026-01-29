# 🚀 PLAN DE IMPLEMENTACIÓN - API TERRA CANADA

---

## 📋 ÍNDICE

1. [Resumen del Proyecto](#resumen-del-proyecto)
2. [Pre-requisitos](#pre-requisitos)
3. [Dependencias del Proyecto](#dependencias-del-proyecto)
4. [Pasos de Implementación](#pasos-de-implementación)
5. [Configuración de Variables de Entorno](#configuración-de-variables-de-entorno)
6. [Scripts NPM](#scripts-npm)
7. [Plan de Verificación](#plan-de-verificación)

---

## 🎯 RESUMEN DEL PROYECTO

Construir una API RESTful completa con Node.js, TypeScript, Express, y Prisma para gestionar el sistema de pagos de Terra Canada. La API incluirá:

- Autenticación JWT con control de roles (ADMIN, SUPERVISOR, EQUIPO)
- CRUD completo para todas las entidades del negocio
- Integración con N8N para procesamiento de documentos y envío de correos
- Sistema de auditoría completo
- Documentación automática con Swagger
- Control de saldo de tarjetas de crédito en tiempo real

---

## 📦 PRE-REQUISITOS

### Software Requerido

1. **Node.js** v18 o superior

   ```bash
   node --version  # Debe ser >= 18.0.0
   ```

2. **npm** v9 o superior

   ```bash
   npm --version
   ```

3. **PostgreSQL** v14 o superior (ya debe estar instalado con la BD)

   ```bash
   psql --version
   ```

4. **Git** (para control de versiones)
   ```bash
   git --version
   ```

### Base de Datos

La base de datos PostgreSQL debe estar creada y ejecutada con el script `SQL ejecutado.sql` que contiene:

- Todas las tablas definidas
- Tipos ENUM
- Funciones CRUD existentes (roles_get, servicios_get, etc.)
- Triggers
- Datos iniciales (roles y servicios)

---

## 📦 DEPENDENCIAS DEL PROYECTO

### Dependencias de Producción

```json
{
  "dependencies": {
    "@prisma/client": "^5.8.0",
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "dotenv": "^16.3.1",
    "jsonwebtoken": "^9.0.2",
    "bcrypt": "^5.1.1",
    "zod": "^3.22.4",
    "winston": "^3.11.0",
    "morgan": "^1.10.0",
    "express-rate-limit": "^7.1.5",
    "axios": "^1.6.5",
    "date-fns": "^3.0.6",
    "multer": "^1.4.5-lts.1",
    "swagger-ui-express": "^5.0.0",
    "swagger-jsdoc": "^6.2.8"
  }
}
```

### Dependencias de Desarrollo

```json
{
  "devDependencies": {
    "@types/node": "^20.10.6",
    "@types/express": "^4.17.21",
    "@types/cors": "^2.8.17",
    "@types/bcrypt": "^5.0.2",
    "@types/jsonwebtoken": "^9.0.5",
    "@types/morgan": "^1.9.9",
    "@types/multer": "^1.4.11",
    "@types/swagger-ui-express": "^4.1.6",
    "@types/swagger-jsdoc": "^6.0.4",
    "typescript": "^5.3.3",
    "prisma": "^5.8.0",
    "tsx": "^4.7.0",
    "nodemon": "^3.0.2",
    "eslint": "^8.56.0",
    "@typescript-eslint/parser": "^6.17.0",
    "@typescript-eslint/eslint-plugin": "^6.17.0",
    "prettier": "^3.1.1"
  }
}
```

---

## 🛠️ PASOS DE IMPLEMENTACIÓN

### **FASE 1: CONFIGURACIÓN INICIAL DEL PROYECTO**

#### Paso 1.1: Inicializar proyecto Node.js

```bash
# Ya estás en c:\Users\OTHERBRAIN\Documents\api_terra
npm init -y
```

Esto creará un `package.json` básico.

#### Paso 1.2: Configurar TypeScript

```bash
# Instalar TypeScript
npm install -D typescript @types/node tsx

# Crear tsconfig.json
npx tsc --init
```

Configurar `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

#### Paso 1.3: Instalar todas las dependencias

**Dependencias de producción:**

```bash
npm install express cors helmet dotenv jsonwebtoken bcrypt zod winston morgan express-rate-limit axios date-fns multer swagger-ui-express swagger-jsdoc @prisma/client
```

**Dependencias de desarrollo:**

```bash
npm install -D @types/express @types/cors @types/bcrypt @types/jsonwebtoken @types/morgan @types/multer @types/swagger-ui-express @types/swagger-jsdoc nodemon prisma eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin prettier
```

#### Paso 1.4: Crear estructura de carpetas

```bash
# Crear todas las carpetas necesarias
mkdir -p src/config src/middlewares src/routes src/controllers src/services src/schemas src/types src/utils src/jobs prisma/seeds uploads/facturas uploads/documentos_banco logs tests/unit tests/integration
```

#### Paso 1.5: Configurar Git

```bash
git init
```

Crear `.gitignore`:

```
node_modules/
dist/
.env
logs/
uploads/
*.log
.DS_Store
```

### **FASE 2: CONFIGURACIÓN DE PRISMA**

#### Paso 2.1: Inicializar Prisma

```bash
npx prisma init
```

Esto creará:

- `prisma/schema.prisma`
- `.env` con DATABASE_URL

#### Paso 2.2: Configurar conexión a la base de datos

Editar `.env`:

```
DATABASE_URL="postgresql://usuario:password@localhost:5432/terra_canada"
```

#### Paso 2.3: Generar Schema desde la BD existente

```bash
npx prisma db pull
```

Esto generará automáticamente todos los modelos en `prisma/schema.prisma` basándose en las tablas existentes.

#### Paso 2.4: Generar Cliente Prisma

```bash
npx prisma generate
```

Esto generará el cliente Prisma en `node_modules/@prisma/client`.

### **FASE 3: CONFIGURACIÓN INICIAL**

#### Paso 3.1: Crear archivo de configuración de entorno

Crear `src/config/environment.ts`:

```typescript
import dotenv from "dotenv";
dotenv.config();

export const config = {
  nodeEnv: process.env.NODE_ENV || "development",
  port: parseInt(process.env.PORT || "3000"),
  apiVersion: process.env.API_VERSION || "v1",

  database: {
    url: process.env.DATABASE_URL!,
  },

  jwt: {
    secret: process.env.JWT_SECRET || "default_secret_CHANGE_IN_PRODUCTION",
    expiresIn: process.env.JWT_EXPIRES_IN || "1h",
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "7d",
  },

  n8n: {
    baseUrl: process.env.N8N_BASE_URL || "https://n8n.salazargroup.cloud",
    webhookDocumento:
      process.env.N8N_WEBHOOK_DOCUMENTO || "/webhook/procesar-documento",
    webhookCorreo: process.env.N8N_WEBHOOK_CORREO || "/webhook/enviar-gmail",
    authToken: process.env.N8N_AUTH_TOKEN || "",
  },

  upload: {
    dir: process.env.UPLOAD_DIR || "./uploads",
    maxSize: parseInt(process.env.MAX_FILE_SIZE || "10485760"),
    allowedMimeTypes: process.env.ALLOWED_MIME_TYPES?.split(",") || [
      "application/pdf",
    ],
  },

  cors: {
    origin: process.env.CORS_ORIGIN || "http://localhost:5173",
  },

  security: {
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || "10"),
    rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || "900000"),
    rateLimitMaxRequests: parseInt(
      process.env.RATE_LIMIT_MAX_REQUESTS || "100",
    ),
  },

  logging: {
    level: process.env.LOG_LEVEL || "info",
    dir: process.env.LOG_DIR || "./logs",
  },
};
```

#### Paso 3.2: Crear configuración de Base de Datos (Prisma Client)

Crear `src/config/database.ts`:

```typescript
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient({
  log: ["query", "error", "warn"],
});

export default prisma;
```

#### Paso 3.3: Crear configuración de Logger (Winston)

Crear `src/config/logger.ts`:

```typescript
import winston from "winston";
import { config } from "./environment";

const logger = winston.createLogger({
  level: config.logging.level,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json(),
  ),
  transports: [
    new winston.transports.File({
      filename: `${config.logging.dir}/error.log`,
      level: "error",
    }),
    new winston.transports.File({
      filename: `${config.logging.dir}/combined.log`,
    }),
  ],
});

if (config.nodeEnv !== "production") {
  logger.add(
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple(),
      ),
    }),
  );
}

export default logger;
```

### **FASE 4: IMPLEMENTACIÓN DE UTILIDADES**

#### Paso 4.1: Utilidad JWT

Crear `src/utils/jwt.util.ts`

#### Paso 4.2: Utilidad Bcrypt

Crear `src/utils/bcrypt.util.ts`

#### Paso 4.3: Utilidad de Respuestas

Crear `src/utils/response.util.ts`

#### Paso 4.4: Configuración de Multer (Upload)

Crear `src/utils/upload.util.ts`

### **FASE 5: MIDDLEWARES**

#### Paso 5.1: Middleware de Autenticación

Crear `src/middlewares/auth.middleware.ts`

#### Paso 5.2: Middleware RBAC (Control de Roles)

Crear `src/middlewares/rbac.middleware.ts`

#### Paso 5.3: Middleware de Validación (Zod)

Crear `src/middlewares/validate.middleware.ts`

#### Paso 5.4: Middleware de Auditoría

Crear `src/middlewares/audit.middleware.ts`

#### Paso 5.5: Middleware de Errores

Crear `src/middlewares/error.middleware.ts`

### **FASE 6: SCHEMAS DE VALIDACIÓN (ZOD)**

Crear todos los schemas en `src/schemas/`:

- `auth.schema.ts`
- `usuarios.schema.ts`
- `roles.schema.ts`
- `servicios.schema.ts`
- `proveedores.schema.ts`
- `clientes.schema.ts`
- `tarjetas.schema.ts`
- `cuentas.schema.ts`
- `pagos.schema.ts`
- `documentos.schema.ts`
- `correos.schema.ts`

### **FASE 7: IMPLEMENTACIÓN DE SERVICIOS**

Crear servicios (lógica de negocio) en `src/services/`:

- `auth.service.ts` - Autenticación y login
- `usuarios.service.ts` - Gestión de usuarios
- `roles.service.ts` - Gestión de roles
- `servicios.service.ts` - Gestión de servicios
- `proveedores.service.ts` - Gestión de proveedores
- `clientes.service.ts` - Gestión de clientes
- `tarjetas.service.ts` - Gestión de tarjetas (con control de saldo)
- `cuentas.service.ts` - Gestión de cuentas bancarias
- `pagos.service.ts` - **CORE** - Gestión de pagos
- `documentos.service.ts` - Gestión de documentos
- `correos.service.ts` - Generación y envío de correos
- `analisis.service.ts` - Análisis y reportes
- `eventos.service.ts` - Auditoría
- `n8n.service.ts` - Integración con N8N

### **FASE 8: IMPLEMENTACIÓN DE CONTROLADORES**

Crear controladores en `src/controllers/`:

- `auth.controller.ts`
- `usuarios.controller.ts`
- `roles.controller.ts`
- `servicios.controller.ts`
- `proveedores.controller.ts`
- `clientes.controller.ts`
- `tarjetas.controller.ts`
- `cuentas.controller.ts`
- `pagos.controller.ts`
- `documentos.controller.ts`
- `correos.controller.ts`
- `analisis.controller.ts`
- `eventos.controller.ts`
- `webhooks.controller.ts`

### **FASE 9: IMPLEMENTACIÓN DE RUTAS**

Crear rutas en `src/routes/`:

- `auth.routes.ts`
- `usuarios.routes.ts`
- `roles.routes.ts`
- `servicios.routes.ts`
- `proveedores.routes.ts`
- `clientes.routes.ts`
- `tarjetas.routes.ts`
- `cuentas.routes.ts`
- `pagos.routes.ts`
- `documentos.routes.ts`
- `correos.routes.ts`
- `analisis.routes.ts`
- `eventos.routes.ts`
- `webhooks.routes.ts`
- `index.ts` - Router principal que combina todas las rutas

### **FASE 10: CONFIGURACIÓN DE SWAGGER**

#### Paso 10.1: Crear configuración de Swagger

Crear `src/config/swagger.ts`

#### Paso 10.2: Documentar endpoints con JSDoc

Agregar comentarios JSDoc en cada archivo de rutas para generar documentación automática.

### **FASE 11: TAREAS PROGRAMADAS (JOBS)**

#### Paso 11.1: Job de Reset Mensual de Tarjetas

Crear `src/jobs/reset-tarjetas.job.ts`

Este job debe ejecutarse el día 1 de cada mes para resetear los saldos de las tarjetas.

#### Paso 11.2: Job de Generación de Correos

Crear `src/jobs/generar-correos.job.ts`

Este job puede ejecutarse cada 5-10 minutos para detectar pagos con `pagado=true` y `gmail_enviado=false` y generar borradores de correos.

### **FASE 12: ARCHIVO PRINCIPAL**

#### Paso 12.1: Crear `src/index.ts`

```typescript
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import swaggerUi from "swagger-ui-express";

import { config } from "./config/environment";
import logger from "./config/logger";
import routes from "./routes";
import { errorMiddleware } from "./middlewares/error.middleware";
import swaggerSpec from "./config/swagger";

const app = express();

// Middlewares globales
app.use(helmet());
app.use(cors({ origin: config.cors.origin }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(
  morgan("combined", {
    stream: { write: (message) => logger.info(message.trim()) },
  }),
);

// Rate limiting
const limiter = rateLimit({
  windowMs: config.security.rateLimitWindowMs,
  max: config.security.rateLimitMaxRequests,
  message: "Demasiadas peticiones desde esta IP, intente más tarde",
});
app.use(limiter);

// Documentación Swagger
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Rutas de la API
app.use(`/api/${config.apiVersion}`, routes);

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "OK", timestamp: new Date() });
});

// Middleware de errores (debe ir al final)
app.use(errorMiddleware);

// Iniciar servidor
app.listen(config.port, () => {
  logger.info(`🚀 Servidor corriendo en puerto ${config.port}`);
  logger.info(
    `📚 Documentación disponible en http://localhost:${config.port}/api-docs`,
  );
  logger.info(`🌍 Entorno: ${config.nodeEnv}`);
});
```

### **FASE 13: CONFIGURAR SCRIPTS NPM**

Editar `package.json` para agregar scripts:

```json
{
  "scripts": {
    "dev": "nodemon --exec tsx src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "prisma:generate": "prisma generate",
    "prisma:pull": "prisma db pull",
    "prisma:studio": "prisma studio",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  }
}
```

### **FASE 14: CREAR ARCHIVO .ENV**

Crear `.env.example` como plantilla:

```bash
# SERVIDOR
NODE_ENV=development
PORT=3000
API_VERSION=v1

# BASE DE DATOS
DATABASE_URL=postgresql://usuario:password@localhost:5432/terra_canada

# JWT
JWT_SECRET=cambiar_este_secreto_en_produccion
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# N8N
N8N_BASE_URL=https://n8n.salazargroup.cloud
N8N_WEBHOOK_DOCUMENTO=/webhook/procesar-documento
N8N_WEBHOOK_CORREO=/webhook/enviar-gmail
N8N_AUTH_TOKEN=

# UPLOAD
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760
ALLOWED_MIME_TYPES=application/pdf

# CORS
CORS_ORIGIN=http://localhost:5173

# SEGURIDAD
BCRYPT_ROUNDS=10
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# LOGS
LOG_LEVEL=info
LOG_DIR=./logs
```

Copiar a `.env` y personalizar.

---

## ✅ PLAN DE VERIFICACIÓN

### 1. **Verificación de Instalación**

```bash
# Verificar que Node.js esté instalado
node --version

# Verificar que todas las dependencias se instalaron
npm list

# Verificar que Prisma puede conectarse a la BD
npx prisma db pull

# Verificar que el cliente Prisma se generó
npx prisma generate
```

### 2. **Verificación de Compilación TypeScript**

```bash
# Compilar el proyecto
npm run build

# Verificar que la carpeta dist/ se creó
ls dist/
```

### 3. **Verificación del Servidor**

```bash
# Iniciar servidor en modo desarrollo
npm run dev

# El servidor debe iniciar en http://localhost:3000
# Verificar en navegador: http://localhost:3000/health
# Debe retornar: {"status":"OK","timestamp":"..."}
```

### 4. **Verificación de Documentación Swagger**

```bash
# Con el servidor corriendo, visitar:
# http://localhost:3000/api-docs

# Debe mostrar la interfaz de Swagger UI con todos los endpoints
```

### 5. **Pruebas Funcionales (Postman/Thunder Client)**

#### 5.1. Autenticación

```bash
POST http://localhost:3000/api/v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "password_del_admin"
}

# Debe retornar un token JWT
```

#### 5.2. Obtener Roles (sin autenticación)

```bash
GET http://localhost:3000/api/v1/roles

# Debe retornar error 401 (Unauthorized)
```

#### 5.3. Obtener Roles (con autenticación)

```bash
GET http://localhost:3000/api/v1/roles
Authorization: Bearer {token_del_login}

# Debe retornar la lista de roles
```

#### 5.4. Crear un Pago (CORE)

```bash
POST http://localhost:3000/api/v1/pagos
Authorization: Bearer {token}
Content-Type: application/json

{
  "proveedor_id": 1,
  "codigo_reserva": "TEST123",
  "monto": 5000.00,
  "moneda": "USD",
  "descripcion": "Pago de prueba",
  "tipo_medio_pago": "TARJETA",
  "tarjeta_id": 1,
  "clientes_ids": [1]
}

# Debe:
# 1. Validar saldo de tarjeta
# 2. Crear el pago
# 3. Descontar saldo de tarjeta
# 4. Crear relación con clientes
# 5. Registrar en auditoría
```

#### 5.6. Subir Documento

```bash
POST http://localhost:3000/api/v1/documentos
Authorization: Bearer {token}
Content-Type: multipart/form-data
Form Data:
  - file: [archivo.pdf]
  - tipo_documento: FACTURA
  - pago_id: 1

# Debe:
# 1. Validar archivo PDF
# 2. Guardar en uploads/
# 3. Crear registro en BD
# 4. Enviar webhook a N8N
```

### 6. **Verificación de Prisma Studio**

```bash
# Abrir Prisma Studio para ver los datos
npx prisma studio

# Verificar que se pueden ver las tablas y datos
```

### 7. **Verificación de Logs**

```bash
# Verificar que los logs se están generando
ls logs/

# Debe existir:
# - error.log
# - combined.log

# Ver logs en tiempo real
tail -f logs/combined.log
```

### 8. **Pruebas de Integración con N8N (Simulación)**

Para probar la integración con N8N sin tener el servidor N8N disponible, se puede:

1. Crear un endpoint mock en `tests/n8n-mock-server.ts`
2. Configurar `.env` para apuntar al mock
3. Probar el flujo completo de subida de documento

### 9. **Verificación de Control de Acceso (RBAC)**

Crear usuarios con diferentes roles y verificar que:

- **ADMIN**: Puede hacer todo
- **SUPERVISOR**: Puede hacer casi todo excepto gestionar usuarios
- **EQUIPO**: Solo puede crear pagos con tarjetas y ver sus propios datos

---

## 📝 CHECKLIST FINAL

Antes de considerar la API completa, verificar:

- [ ] Todas las dependencias instaladas correctamente
- [ ] Prisma conectado a la BD y schema generado
- [ ] TypeScript compilando sin errores
- [ ] Servidor inicia correctamente
- [ ] Endpoint `/health` responde
- [ ] Documentación Swagger disponible
- [ ] Login funciona y retorna JWT
- [ ] Middleware de autenticación funciona
- [ ] RBAC funciona correctamente
- [ ] Se pueden crear pagos con tarjetas (y se descuenta saldo)
- [ ] Se pueden crear pagos con cuentas bancarias (sin descuento)
- [ ] Subida de documentos funciona
- [ ] Webhook a N8N se envía correctamente
- [ ] Logs se generan correctamente
- [ ] Auditoría registra todas las acciones
- [ ] Todos los endpoints documentados en Swagger

---

## 🎯 PRÓXIMOS PASOS DESPUÉS DE LA IMPLEMENTACIÓN

1. **Testing**: Escribir tests unitarios e integración
2. **Deployment**: Configurar para producción (Docker, CI/CD)
3. **Monitoreo**: Configurar herramientas de monitoreo (PM2, New Relic, etc.)
4. **Optimización**: Analizar performance y optimizar queries
5. **Documentación de Usuario**: Crear guía de uso para el frontend
6. **Frontend**: Construir interfaz React que consuma esta API

---

## 📞 SOPORTE

Para cualquier problema durante la implementación:

1. Revisar logs en `logs/error.log`
2. Verificar variables de entorno en `.env`
3. Asegurarse de que la BD esté corriendo
4. Verificar que Prisma está conectado: `npx prisma studio`
