# 📁 DOCUMENTACIÓN - API TERRA CANADA

**Proyecto:** API Terra Canada v1.0  
**Fecha:** 30 de Enero de 2026  
**Organización:** Completa

---

## 📚 CONTENIDO DE ESTA CARPETA

### **📄 Archivos Markdown (.md)**

| Archivo | Descripción |
|---------|-------------|
| `ANALISIS_COBERTURA.md` | Análisis de cobertura del proyecto y módulos faltantes |
| `CONFIGURACION_COMPLETADA.md` | Guía de configuración inicial completada |
| `CORRECCIONES_SWAGGER.md` | Correcciones aplicadas a la documentación Swagger |
| `DEPLOYMENT.md` | Guía de despliegue a producción |
| `DOCKER_QUICKSTART.md` | Inicio rápido con Docker |
| `DOCUMENTACION_ENDPOINTS.md` | Documentación detallada de endpoints |
| `ENDPOINTS_REALES_COMPLETOS.md` | Lista completa de endpoints implementados |
| `IMPLEMENTACION_COMPLETA.md` | Resumen de implementación completa |
| `INTEGRACIONES_N8N_COMPLETAS.md` | Documentación de integraciones con N8N |
| `INTEGRACION_N8N_CORREOS.md` | Específico de integración de correos |
| `MODULO_CORREOS_COMPLETADO.md` | Documentación del módulo de correos |
| `MODULO_DOCUMENTOS_COMPLETADO.md` | Documentación del módulo de documentos |
| `POSTGRESQL_LOCAL_SETUP.md` | Configuración de PostgreSQL local |
| `SWAGGER_COMPLETADO.md` | Documentación Swagger completa |
| `WEBHOOKS_COMPLETADO.md` | Webhooks implementados (resumen) |
| `WEBHOOKS_DOCUMENTACION_COMPLETA.md` | Documentación completa de webhooks |
| `WEBHOOK_NOTIFICACIONES_PAGOS.md` | Webhook de Intelexia Labs |

---

### **💾 Archivos SQL**

| Archivo | Descripción |
|---------|-------------|
| `SQL ejecutado.sql` | Script SQL principal ejecutado (194KB) |
| `SQL PARCHE.sql` | Parches y correcciones SQL (58KB) |

---

### **📂 Carpetas**

#### **`planificacion/`**
Documentos de planificación inicial del proyecto.

#### **`primera documentacion/`**
Documentación inicial y archivos de referencia (30 archivos).

---

### **🔧 POSTMAN COLLECTION**

#### **`API_Terra_Canada.postman_collection.json`**

Colección completa de Postman con **TODOS los 64 endpoints** de la API organizados en 15 carpetas:

1. **Authentication** (2 endpoints)
2. **Usuarios** (5 endpoints)
3. **Roles** (2 endpoints)
4. **Proveedores** (6 endpoints)
5. **Servicios** (5 endpoints)
6. **Clientes** (5 endpoints)
7. **Tarjetas de Crédito** (6 endpoints)
8. **Cuentas Bancarias** (5 endpoints)
9. **Pagos** (6 endpoints)
10. **Documentos** (5 endpoints)
11. **Facturas** (1 endpoint)
12. **Correos** (8 endpoints)
13. **Webhooks** (1 endpoint)
14. **Eventos de Auditoría** (2 endpoints)
15. **Análisis y Reportes** (2 endpoints)

**Características:**
- ✅ Variables de entorno configuradas
- ✅ Autenticación JWT automática
- ✅ Extracción automática de token al hacer login
- ✅ Ejemplos de request bodies
- ✅ Query parameters documentados

---

## 🚀 CÓMO USAR LA POSTMAN COLLECTION

### **1. Importar en Postman:**

1. Abrir Postman
2. Click en **Import**
3. Seleccionar `API_Terra_Canada.postman_collection.json`
4. Click en **Import**

### **2. Configurar Variables:**

Ir a la colección → **Variables** y configurar:

```
base_url: http://localhost:3000/api/v1
jwt_token: (se llena automáticamente al hacer login)
n8n_webhook_token: tu_token_secreto_n8n
```

### **3. Autenticarse:**

1. Ir a **1. Authentication → Login**
2. Modificar las credenciales si es necesario
3. Click en **Send**
4. El token se guardará automáticamente en `jwt_token`

### **4. Usar Endpoints:**

Todos los demás endpoints usan automáticamente el token JWT. Simplemente:
1. Seleccionar el endpoint deseado
2. Modificar body/parámetros si es necesario
3. Click en **Send**

---

## 📖 DOCUMENTACIÓN POR MÓDULO

### **Para Desarrolladores:**

1. **Inicio Rápido:**
   - `CONFIGURACION_COMPLETADA.md`
   - `DOCKER_QUICKSTART.md`

2. **Implementación:**
   - `IMPLEMENTACION_COMPLETA.md`
   - `ENDPOINTS_REALES_COMPLETOS.md`

3. **Módulos Específicos:**
   - `MODULO_DOCUMENTOS_COMPLETADO.md`
   - `MODULO_CORREOS_COMPLETADO.md`

4. **Integraciones:**
   - `INTEGRACIONES_N8N_COMPLETAS.md`
   - `WEBHOOKS_DOCUMENTACION_COMPLETA.md`

5. **API Testing:**
   - `SWAGGER_COMPLETADO.md`
   - Usar Postman Collection

### **Para DevOps:**

1. **Despliegue:**
   - `DEPLOYMENT.md`
   - `DOCKER_QUICKSTART.md`

2. **Base de Datos:**
   - `POSTGRESQL_LOCAL_SETUP.md`
   - `SQL ejecutado.sql`
   - `SQL PARCHE.sql`

---

## 🌐 SWAGGER UI

La documentación interactiva está disponible en:

```
http://localhost:3000/api-docs
```

**Ventajas de Swagger:**
- ✅ Prueba endpoints directamente
- ✅ Schemas completos
- ✅ Ejemplos de request/response
- ✅ Autenticación JWT integrada

---

## 📊 ESTRUCTURA DE LA API

```
/api/v1
├── /auth                 - Autenticación
├── /usuarios             - Gestión de usuarios
├── /roles                - Gestión de roles
├── /proveedores          - Proveedores de servicios
├── /servicios            - Servicios del sistema
├── /clientes             - Gestión de clientes
├── /tarjetas             - Tarjetas de crédito
├── /cuentas              - Cuentas bancarias
├── /pagos                - Gestión de pagos (núcleo del sistema)
├── /documentos           - Upload y gestión de PDFs
├── /facturas             - Procesamiento con OCR
├── /correos              - Envío de correos automáticos
├── /webhooks             - Webhooks entrantes (N8N)
├── /eventos              - Auditoría del sistema
└── /analisis             - Reportes y estadísticas
```

---

## 🔐 AUTENTICACIÓN

Todos los endpoints (excepto `/auth/login`) requieren JWT:

```http
Authorization: Bearer {token}
```

El token se obtiene al hacer login y tiene una duración de **1 hora**.

---

## 📝 NOTAS IMPORTANTES

### **Variables de Entorno Requeridas:**

Asegúrate de configurar en `.env`:

```bash
# Base de datos
DATABASE_URL=postgresql://...

# JWT
JWT_SECRET=tu_secreto_min_32_caracteres

# N8N
N8N_WEBHOOK_TOKEN=tu_token_secreto_n8n

# Otros...
```

Ver `.env.example` para la lista completa.

### **Archivos SQL:**

- **Ejecutar primero:** `SQL ejecutado.sql`
- **Luego parches:** `SQL PARCHE.sql`

### **Webhooks:**

La API envía webhooks a:
- N8N (facturas, correos, edición de pagos)
- Intelexia Labs (cambios en pagos)

Ver `WEBHOOKS_DOCUMENTACION_COMPLETA.md` para detalles.

---

## ✅ CHECKLIST DE USO

### **Primera Vez:**

- [ ] Configurar PostgreSQL
- [ ] Ejecutar scripts SQL
- [ ] Configurar `.env`
- [ ] Instalar dependencias: `npm install`
- [ ] Iniciar servidor: `npm run dev`
- [ ] Importar Postman Collection
- [ ] Hacer login en Postman
- [ ] Probar un endpoint

### **Desarrollo:**

- [ ] Consultar Swagger para schemas
- [ ] Usar Postman para pruebas
- [ ] Revisar logs en `./logs`
- [ ] Consultar documentación de módulos específicos

### **Testing:**

- [ ] Probar autenticación
- [ ] Verificar RBAC (permisos)
- [ ] Probar flujo completo de pagos
- [ ] Verificar webhooks N8N
- [ ] Probar generación de correos

---

## 📞 RECURSOS

| Recurso | URL/Ubicación |
|---------|---------------|
| **Servidor Local** | `http://localhost:3000` |
| **Swagger UI** | `http://localhost:3000/api-docs` |
| **Health Check** | `http://localhost:3000/health` |
| **Logs** | `./logs/` |
| **Uploads** | `./uploads/` |

---

## 🎯 RESUMEN

Esta carpeta contiene **TODA** la documentación del proyecto API Terra Canada:

- ✅ **17 archivos Markdown** con documentación detallada
- ✅ **2 archivos SQL** para setup de base de datos
- ✅ **1 Postman Collection** con 64 endpoints
- ✅ **2 carpetas** con documentación histórica

**Todo está organizado y listo para usar!** 🚀

---

**Última actualización:** 30 de Enero de 2026  
**Versión de la API:** 1.0.0  
**Estado:** ✅ Producción Ready
