# 🚀 GUÍA DE DEPLOYMENT - API TERRA CANADA

**Versión:** 2.0.0  
**Fecha:** 31 de Enero de 2026  
**Tipo:** Deployment con Docker (sin docker-compose)

---

## 📋 ÍNDICE

1. [Requisitos Previos](#requisitos-previos)
2. [Preparación del Servidor](#preparación-del-servidor)
3. [Configuración de Variables de Entorno](#configuración-de-variables-de-entorno)
4. [Build de la Imagen Docker](#build-de-la-imagen-docker)
5. [Ejecución del Contenedor](#ejecución-del-contenedor)
6. [Verificación](#verificación)
7. [Gestión del Contenedor](#gestión-del-contenedor)
8. [Troubleshooting](#troubleshooting)
9. [Actualización](#actualización)
10. [Backup y Rollback](#backup-y-rollback)

---

## 📦 REQUISITOS PREVIOS

### En el Servidor:

- ✅ **Docker** instalado (versión 20.10 o superior)
- ✅ **PostgreSQL** accesible (puede ser local o remoto)
- ✅ **Puertos disponibles:** 3000 (o el que prefieras)
- ✅ **Espacio en disco:** Mínimo 2GB
- ✅ **RAM:** Mínimo 512MB (recomendado 1GB)

### Verificar Docker:

```bash
docker --version
# Debe mostrar: Docker version 20.10.x o superior
```

---

## 🖥️ PREPARACIÓN DEL SERVIDOR

### 1. Crear Directorio del Proyecto

```bash
# Crear directorio
mkdir -p /opt/terra-canada-api
cd /opt/terra-canada-api

# Clonar repositorio (o subir archivos)
git clone https://github.com/maycodex/api_terra_canada.git .
```

### 2. Verificar Archivos Necesarios

```bash
ls -la

# Debes ver:
# - Dockerfile
# - .dockerignore
# - package.json
# - src/
# - .env.production.example
```

---

## 🔐 CONFIGURACIÓN DE VARIABLES DE ENTORNO

### 1. Crear Archivo .env

```bash
# Copiar el ejemplo
cp .env.production.example .env

# Editar con tu editor favorito
nano .env
# o
vim .env
```

### 2. Configurar Variables Críticas

**IMPORTANTE:** Cambia estos valores:

```bash
# Base de datos (CAMBIAR)
DATABASE_URL=postgresql://tu_usuario:tu_password@tu_host:5433/terra_canada_v2

# JWT Secret (GENERAR UNO NUEVO)
JWT_SECRET=$(openssl rand -base64 32)

# N8N Webhook Token (GENERAR UNO NUEVO)
N8N_WEBHOOK_TOKEN=$(openssl rand -base64 32)

# CORS (dominio de tu frontend)
CORS_ORIGIN=https://tu-dominio.com
```

### 3. Ejemplo de .env Completo

```bash
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://terra_user:SecurePass123@epanel.salazargroup.cloud:5433/terra_canada_v2?sslmode=require
JWT_SECRET=tu_secreto_generado_con_openssl_32_caracteres_minimo
JWT_EXPIRES_IN=8h
N8N_BASE_URL=https://n8n.salazargroup.cloud
N8N_WEBHOOK_TOKEN=tu_token_n8n_generado_32_caracteres
CORS_ORIGIN=https://app.terracanada.com
LOG_LEVEL=info
BCRYPT_ROUNDS=12
```

### 4. Proteger el Archivo .env

```bash
chmod 600 .env
```

---

## 🏗️ BUILD DE LA IMAGEN DOCKER

### 1. Build de la Imagen

```bash
# Build básico
docker build -t terra-canada-api:2.0.0 .

# Build con tag latest
docker build -t terra-canada-api:2.0.0 -t terra-canada-api:latest .

# Build sin cache (si hay problemas)
docker build --no-cache -t terra-canada-api:2.0.0 .
```

### 2. Verificar la Imagen

```bash
docker images | grep terra-canada-api

# Debes ver algo como:
# terra-canada-api   2.0.0   abc123def456   2 minutes ago   200MB
```

### 3. Inspeccionar la Imagen

```bash
docker inspect terra-canada-api:2.0.0
```

---

## 🚀 EJECUCIÓN DEL CONTENEDOR

### Opción 1: Ejecución Básica

```bash
docker run -d \
  --name terra-canada-api \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  terra-canada-api:2.0.0
```

### Opción 2: Ejecución con Volúmenes (Recomendado)

```bash
docker run -d \
  --name terra-canada-api \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  terra-canada-api:2.0.0
```

### Opción 3: Ejecución con Límites de Recursos

```bash
docker run -d \
  --name terra-canada-api \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  --memory="512m" \
  --cpus="1.0" \
  terra-canada-api:2.0.0
```

### Opción 4: Ejecución con Red Personalizada

```bash
# Crear red
docker network create terra-network

# Ejecutar contenedor
docker run -d \
  --name terra-canada-api \
  --restart unless-stopped \
  --network terra-network \
  -p 3000:3000 \
  --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  terra-canada-api:2.0.0
```

---

## ✅ VERIFICACIÓN

### 1. Ver Logs del Contenedor

```bash
# Ver logs en tiempo real
docker logs -f terra-canada-api

# Ver últimas 100 líneas
docker logs --tail 100 terra-canada-api

# Ver logs con timestamps
docker logs -t terra-canada-api
```

### 2. Verificar Estado del Contenedor

```bash
# Estado general
docker ps | grep terra-canada-api

# Detalles completos
docker inspect terra-canada-api

# Health check
docker inspect --format='{{.State.Health.Status}}' terra-canada-api
```

### 3. Probar Endpoints

```bash
# Health check
curl http://localhost:3000/health

# Debe retornar:
# {"status":"ok","timestamp":"..."}

# Swagger docs
curl http://localhost:3000/api-docs/

# Login (prueba)
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"nombre_usuario":"admin","password":"tu_password"}'
```

### 4. Verificar Conectividad a Base de Datos

```bash
# Entrar al contenedor
docker exec -it terra-canada-api sh

# Dentro del contenedor, verificar conexión
node -e "const {Pool} = require('pg'); const pool = new Pool({connectionString: process.env.DATABASE_URL}); pool.query('SELECT NOW()', (err, res) => {console.log(err ? err : res.rows); pool.end();})"
```

---

## 🔧 GESTIÓN DEL CONTENEDOR

### Comandos Básicos

```bash
# Detener el contenedor
docker stop terra-canada-api

# Iniciar el contenedor
docker start terra-canada-api

# Reiniciar el contenedor
docker restart terra-canada-api

# Ver estadísticas en tiempo real
docker stats terra-canada-api

# Ejecutar comando dentro del contenedor
docker exec -it terra-canada-api sh

# Ver procesos dentro del contenedor
docker top terra-canada-api
```

### Actualizar Variables de Entorno

```bash
# 1. Editar .env
nano .env

# 2. Recrear el contenedor
docker stop terra-canada-api
docker rm terra-canada-api

# 3. Volver a ejecutar con nuevo .env
docker run -d \
  --name terra-canada-api \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  terra-canada-api:2.0.0
```

---

## 🐛 TROUBLESHOOTING

### Problema: Contenedor no inicia

```bash
# Ver logs de error
docker logs terra-canada-api

# Verificar que el puerto no esté en uso
netstat -tulpn | grep 3000

# Verificar variables de entorno
docker exec terra-canada-api env | grep DATABASE_URL
```

### Problema: No conecta a la base de datos

```bash
# Verificar conectividad desde el host
psql -h epanel.salazargroup.cloud -p 5433 -U terra_user -d terra_canada_v2

# Verificar DNS desde el contenedor
docker exec terra-canada-api ping epanel.salazargroup.cloud

# Verificar firewall
telnet epanel.salazargroup.cloud 5433
```

### Problema: Health check falla

```bash
# Ver detalles del health check
docker inspect --format='{{json .State.Health}}' terra-canada-api | jq

# Probar manualmente
docker exec terra-canada-api wget -q -O- http://localhost:3000/health
```

### Problema: Contenedor se reinicia constantemente

```bash
# Ver eventos del contenedor
docker events --filter container=terra-canada-api

# Ver logs completos
docker logs --since 10m terra-canada-api

# Verificar límites de recursos
docker stats terra-canada-api
```

---

## 🔄 ACTUALIZACIÓN

### Actualización con Downtime Mínimo

```bash
# 1. Pull del código actualizado
cd /opt/terra-canada-api
git pull origin main

# 2. Build de nueva imagen
docker build -t terra-canada-api:2.0.1 .

# 3. Detener contenedor actual
docker stop terra-canada-api

# 4. Renombrar contenedor antiguo (backup)
docker rename terra-canada-api terra-canada-api-old

# 5. Ejecutar nuevo contenedor
docker run -d \
  --name terra-canada-api \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  terra-canada-api:2.0.1

# 6. Verificar que funciona
docker logs -f terra-canada-api

# 7. Si todo está bien, eliminar contenedor antiguo
docker rm terra-canada-api-old

# 8. Limpiar imagen antigua (opcional)
docker rmi terra-canada-api:2.0.0
```

---

## 💾 BACKUP Y ROLLBACK

### Backup de Imagen

```bash
# Guardar imagen actual
docker save terra-canada-api:2.0.0 | gzip > terra-canada-api-2.0.0.tar.gz

# Restaurar imagen
gunzip -c terra-canada-api-2.0.0.tar.gz | docker load
```

### Rollback Rápido

```bash
# Si guardaste el contenedor antiguo
docker stop terra-canada-api
docker rm terra-canada-api
docker rename terra-canada-api-old terra-canada-api
docker start terra-canada-api
```

---

## 📊 MONITOREO

### Logs Persistentes

```bash
# Ver logs del volumen
tail -f logs/combined.log
tail -f logs/error.log

# Rotar logs (si crecen mucho)
find logs/ -name "*.log" -size +100M -delete
```

### Métricas del Contenedor

```bash
# CPU y Memoria en tiempo real
docker stats terra-canada-api

# Uso de disco
docker system df

# Espacio usado por el contenedor
docker ps -s | grep terra-canada-api
```

---

## 🔒 SEGURIDAD

### Mejores Prácticas

1. **Nunca expongas el puerto directamente a Internet**
   - Usa un reverse proxy (Nginx, Traefik, Caddy)
   - Configura SSL/TLS

2. **Protege las variables de entorno**

   ```bash
   chmod 600 .env
   chown root:root .env
   ```

3. **Actualiza regularmente**

   ```bash
   docker pull node:18-alpine
   docker build --no-cache -t terra-canada-api:latest .
   ```

4. **Limita recursos**
   - Usa `--memory` y `--cpus` para evitar consumo excesivo

5. **Escanea vulnerabilidades**
   ```bash
   docker scan terra-canada-api:2.0.0
   ```

---

## 📝 COMANDOS RÁPIDOS

```bash
# Build
docker build -t terra-canada-api:2.0.0 .

# Run
docker run -d --name terra-canada-api --restart unless-stopped -p 3000:3000 --env-file .env -v $(pwd)/logs:/app/logs terra-canada-api:2.0.0

# Logs
docker logs -f terra-canada-api

# Stop
docker stop terra-canada-api

# Start
docker start terra-canada-api

# Restart
docker restart terra-canada-api

# Remove
docker stop terra-canada-api && docker rm terra-canada-api

# Clean
docker system prune -a
```

---

## 🆘 SOPORTE

Si encuentras problemas:

1. Revisa los logs: `docker logs terra-canada-api`
2. Verifica la configuración: `docker inspect terra-canada-api`
3. Consulta la documentación: `/documentacion`
4. Contacta al equipo de desarrollo

---

**Generado por:** Antigravity AI  
**Fecha:** 31 de Enero de 2026  
**Versión:** 2.0.0
