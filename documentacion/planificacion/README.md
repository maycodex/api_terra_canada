# 🌍 API Terra Canada - Sistema de Gestión de Pagos

API RESTful construida con Node.js, TypeScript, Express y Prisma para gestionar pagos a proveedores de servicios turísticos.

---

## 📋 Descripción

Esta API permite a Terra Canada:

- Registrar y controlar pagos a proveedores turísticos
- Gestionar tarjetas de crédito con control de saldo automático
- Procesar documentos (facturas y extractos bancarios) mediante integración con N8N
- Generar y enviar notificaciones por correo a proveedores
- Mantener auditoría completa de operaciones
- Generar análisis y reportes del negocio

---

## 🚀 Inicio Rápido

### Pre-requisitos

- Node.js >= 18.0.0
- PostgreSQL >= 14.0.0
- npm >= 9.0.0

### Instalación

```bash
# 1. Instalar dependencias
npm install

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus configuraciones

# 3. Generar cliente Prisma desde la BD existente
npx prisma db pull
npx prisma generate

# 4. Iniciar servidor en desarrollo
npm run dev
```

El servidor estará disponible en: `http://localhost:3000`

Documentación Swagger: `http://localhost:3000/api-docs`

---

## 📁 Estructura del Proyecto

```
api_terra/
├── src/
│   ├── config/          # Configuraciones (DB, logger, swagger)
│   ├── middlewares/     # Middlewares (auth, RBAC, validación)
│   ├── routes/          # Rutas de la API
│   ├── controllers/     # Controladores
│   ├── services/        # Lógica de negocio
│   ├── schemas/         # Validaciones con Zod
│   ├── types/           # Tipos TypeScript
│   ├── utils/           # Utilidades (JWT, bcrypt, etc.)
│   ├── jobs/            # Tareas programadas
│   └── index.ts         # Punto de entrada
├── prisma/              # Schema de Prisma
├── uploads/             # Archivos subidos
├── logs/                # Archivos de log
└── planificacion/       # Documentación de planificación
```

---

## 🔑 Autenticación

La API usa JSON Web Tokens (JWT) para autenticación.

### Login

```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "your_password"
}
```

### Uso del Token

Incluir en todas las peticiones:

```bash
Authorization: Bearer {token}
```

---

## 👥 Roles y Permisos

| Rol            | Descripción         | Permisos                               |
| -------------- | ------------------- | -------------------------------------- |
| **ADMIN**      | Control total       | Todos los permisos                     |
| **SUPERVISOR** | Gestión operativa   | Casi todos excepto gestión de usuarios |
| **EQUIPO**     | Operaciones básicas | Solo crear pagos con tarjetas          |

---

## 📚 Documentación

### Documentación de Planificación

En la carpeta `planificacion/` encontrarás:

1. **[01_ARQUITECTURA_Y_ESTRUCTURA.md](./planificacion/01_ARQUITECTURA_Y_ESTRUCTURA.md)**
   - Stack tecnológico completo
   - Estructura de carpetas detallada
   - Arquitectura de capas
   - Flujo de peticiones
   - Seguridad y autenticación
   - Integraciones externas (N8N)

2. **[02_ENDPOINTS.md](./planificacion/02_ENDPOINTS.md)**
   - Documentación completa de todos los endpoints
   - Ejemplos de peticiones y respuestas
   - Códigos de estado HTTP
   - Permisos requeridos por endpoint

3. **[03_PLAN_IMPLEMENTACION.md](./planificacion/03_PLAN_IMPLEMENTACION.md)**
   - Lista completa de dependencias
   - Pasos detallados de implementación (14 fases)
   - Plan de verificación
   - Checklist final

### Documentación Interactiva (Swagger)

Una vez iniciado el servidor, accede a:

```
http://localhost:3000/api-docs
```

---

## 🛠️ Scripts NPM

```bash
# Desarrollo
npm run dev              # Iniciar servidor en modo desarrollo

# Producción
npm run build            # Compilar TypeScript a JavaScript
npm start                # Iniciar servidor en producción

# Prisma
npm run prisma:generate  # Generar cliente Prisma
npm run prisma:pull      # Actualizar schema desde BD
npm run prisma:studio    # Abrir Prisma Studio

# Calidad de código
npm run lint             # Ejecutar ESLint
npm run format           # Formatear código con Prettier
```

---

## 🔗 Endpoints Principales

### Autenticación

- `POST /api/v1/auth/login` - Iniciar sesión
- `GET /api/v1/auth/me` - Obtener usuario actual

### Usuarios

- `GET /api/v1/usuarios` - Listar usuarios
- `POST /api/v1/usuarios` - Crear usuario
- `PUT /api/v1/usuarios/:id` - Actualizar usuario

### Pagos (CORE)

- `GET /api/v1/pagos` - Listar pagos
- `POST /api/v1/pagos` - Crear pago
- `GET /api/v1/pagos/:id` - Obtener pago
- `PUT /api/v1/pagos/:id` - Actualizar pago
- `PUT /api/v1/pagos/:id/marcar-pagado` - Marcar como pagado
- `PUT /api/v1/pagos/:id/marcar-verificado` - Marcar como verificado

### Documentos

- `POST /api/v1/documentos` - Subir documento (PDF)
- `GET /api/v1/documentos` - Listar documentos

### Correos

- `GET /api/v1/correos` - Listar correos
- `POST /api/v1/correos/generar` - Generar borradores automáticos
- `POST /api/v1/correos/:id/enviar` - Enviar correo

### Análisis

- `GET /api/v1/analisis/dashboard` - KPIs principales
- `GET /api/v1/analisis/comparativo-medios` - Tarjetas vs Cuentas
- `GET /api/v1/analisis/top-proveedores` - Top proveedores

Ver todos los endpoints en [02_ENDPOINTS.md](./planificacion/02_ENDPOINTS.md)

---

## 🔐 Variables de Entorno

Crear archivo `.env` basado en `.env.example`:

```bash
# Base de datos
DATABASE_URL=postgresql://usuario:password@localhost:5432/terra_canada

# JWT
JWT_SECRET=tu_secreto_super_seguro

# N8N (integración)
N8N_BASE_URL=https://n8n.salazargroup.cloud
N8N_AUTH_TOKEN=tu_token_n8n

# Servidor
PORT=3000
NODE_ENV=development
```

---

## 🧪 Verificación

### Health Check

```bash
GET http://localhost:3000/health

# Respuesta esperada:
{
  "status": "OK",
  "timestamp": "2026-01-29T..."
}
```

### Verificar Conexión a BD

```bash
npx prisma studio
```

Esto abrirá una interfaz web para explorar la base de datos.

---

## 📊 Flujo del Negocio

### 1. Registro de Pago

```
Usuario → Selecciona proveedor, cliente, medio de pago
       → Ingresa monto y código de reserva
       → Sistema descuenta saldo (si es tarjeta)
       → Pago creado con pagado=FALSE
```

### 2. Procesamiento de Documento

```
Usuario → Sube PDF (factura o extracto)
       → Sistema guarda en storage
       → Envía webhook a N8N
       → N8N extrae códigos de reserva
       → Actualiza pagado=TRUE y/o verificado=TRUE
```

### 3. Envío de Correo

```
Sistema → Detecta pagos con pagado=TRUE
        → Agrupa por proveedor
        → Genera borradores automáticos
Usuario → Revisa y edita contenido
        → Confirma envío
        → N8N envía correo vía Gmail
        → gmail_enviado=TRUE
```

---

## 🔧 Integración con N8N

La API se integra con N8N para:

1. **Procesamiento de Documentos**
   - Webhook: `/webhook/procesar-documento`
   - N8N extrae códigos de reserva con OCR
   - Actualiza estados de pagos automáticamente

2. **Envío de Correos**
   - Webhook: `/webhook/enviar-gmail`
   - N8N envía correos a proveedores vía Gmail
   - Retorna confirmación de envío

---

## 📝 Tecnologías

- **Runtime:** Node.js v18+
- **Lenguaje:** TypeScript v5+
- **Framework:** Express.js v4.18+
- **ORM:** Prisma v5+
- **Base de Datos:** PostgreSQL v14+
- **Autenticación:** JWT (jsonwebtoken)
- **Validación:** Zod
- **Documentación:** Swagger/OpenAPI
- **Logging:** Winston
- **Seguridad:** Helmet, bcrypt, CORS, Rate Limiting

---

## 👨‍💻 Desarrollo

### Agregar un Nuevo Endpoint

1. Crear schema de validación en `src/schemas/`
2. Crear servicio en `src/services/`
3. Crear controlador en `src/controllers/`
4. Crear ruta en `src/routes/`
5. Documentar con JSDoc para Swagger
6. Probar con Postman/Thunder Client

### Ejecutar en Modo Desarrollo

```bash
npm run dev
```

Esto usa `nodemon` y `tsx` para recargar automáticamente al detectar cambios.

---

## 🐛 Debugging

Los logs se guardan en la carpeta `logs/`:

```bash
# Ver logs de errores
tail -f logs/error.log

# Ver todos los logs
tail -f logs/combined.log
```

---

## 🚀 Próximos Pasos

1. [ ] Implementar tests unitarios
2. [ ] Implementar tests de integración
3. [ ] Configurar CI/CD
4. [ ] Dockerizar la aplicación
5. [ ] Deploy a producción
6. [ ] Conectar con frontend React

---

## 📄 Licencia

Propiedad de Terra Canada

---

## 📞 Contacto

Para soporte o consultas sobre la API, contactar al equipo de desarrollo.

---

**Versión:** 1.0.0  
**Última actualización:** Enero 2026
