# 📋 Configuración de PostgreSQL Local

## Pre-requisitos

Necesitas tener PostgreSQL instalado localmente. Si no lo tienes:

### Windows

1. Descarga PostgreSQL desde: https://www.postgresql.org/download/windows/
2. Instala con las opciones por defecto
3. Durante la instalación, configura:
   - Usuario: `postgres`
   - Password: (el que elijas, recuérdalo)
   - Puerto: `5432`

### Verificar instalación

```bash
psql --version
```

## Crear la Base de Datos

1. **Conectar a PostgreSQL:**

```bash
psql -U postgres
```

2. **Crear la base de datos:**

```sql
CREATE DATABASE terra_canada_v2;
\c terra_canada_v2
```

3. **Ejecutar el script SQL:**

```sql
-- Copia y pega el contenido de "SQL ejecutado.sql" aquí
-- O ejecuta desde archivo:
\i 'C:/Users/OTHERBRAIN/Documents/api_terra/SQL ejecutado.sql'
```

4. **Verificar que se crearon las tablas:**

```sql
\dt
```

## Configurar la API

1. **Edita el archivo `.env`:**

```bash
DATABASE_URL="postgresql://postgres:TU_PASSWORD@localhost:5432/terra_canada_v2"
```

Reemplaza `TU_PASSWORD` con la contraseña que configuraste.

2. **Genera el cliente Prisma:**

```bash
npm run prisma:pull
npm run prisma:generate
```

3. **Inicia el servidor:**

```bash
npm run dev
```

## Verificar Conexión

```bash
# Health check
curl http://localhost:3000/health

# Documentación
# Abre en navegador: http://localhost:3000/api-docs
```

---

**¡Listo!** El backend ahora funciona con PostgreSQL local sin necesidad de Docker.
