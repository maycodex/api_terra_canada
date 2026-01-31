# 🐳 DOCKER DEPLOYMENT - API TERRA CANADA

**Versión:** 2.0.0  
**Imagen Base:** node:18-alpine  
**Multi-stage Build:** ✅ Optimizado

---

## 🚀 QUICK START

### 1. Configurar Variables de Entorno

```bash
cp .env.production.example .env
nano .env  # Editar con tus valores
```

### 2. Build y Run

```bash
# Build
docker build -t terra-canada-api:2.0.0 .

# Run
docker run -d \
  --name terra-canada-api \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  terra-canada-api:2.0.0
```

### 3. Verificar

```bash
# Ver logs
docker logs -f terra-canada-api

# Health check
curl http://localhost:3000/health
```

---

## 📦 CARACTERÍSTICAS DEL DOCKERFILE

### Multi-Stage Build

- **Stage 1 (Builder):** Compila TypeScript a JavaScript
- **Stage 2 (Production):** Imagen optimizada solo con lo necesario

### Optimizaciones

- ✅ Imagen base Alpine (ligera)
- ✅ Usuario no-root (seguridad)
- ✅ dumb-init para manejo de señales
- ✅ Health check integrado
- ✅ Solo dependencias de producción
- ✅ Cache de capas optimizado

### Tamaño de Imagen

- **Builder:** ~800MB (temporal)
- **Production:** ~200MB (final)

---

## 🔧 CONFIGURACIÓN

### Variables de Entorno Requeridas

```bash
# Críticas
DATABASE_URL=postgresql://user:pass@host:port/db
JWT_SECRET=tu_secreto_seguro_32_caracteres
PORT=3000

# Opcionales
LOG_LEVEL=info
CORS_ORIGIN=https://tu-dominio.com
```

### Volúmenes Recomendados

```bash
-v $(pwd)/logs:/app/logs        # Logs persistentes
-v $(pwd)/uploads:/app/uploads  # Archivos subidos
```

### Puertos

- **3000:** API HTTP (configurable con PORT)

---

## 🛠️ COMANDOS ÚTILES

### Build

```bash
# Build básico
docker build -t terra-canada-api:2.0.0 .

# Build sin cache
docker build --no-cache -t terra-canada-api:2.0.0 .

# Build con múltiples tags
docker build -t terra-canada-api:2.0.0 -t terra-canada-api:latest .
```

### Run

```bash
# Básico
docker run -d --name terra-canada-api -p 3000:3000 --env-file .env terra-canada-api:2.0.0

# Con volúmenes
docker run -d --name terra-canada-api -p 3000:3000 --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  terra-canada-api:2.0.0

# Con límites de recursos
docker run -d --name terra-canada-api -p 3000:3000 --env-file .env \
  --memory="512m" --cpus="1.0" \
  terra-canada-api:2.0.0
```

### Gestión

```bash
# Ver logs
docker logs -f terra-canada-api

# Entrar al contenedor
docker exec -it terra-canada-api sh

# Ver estadísticas
docker stats terra-canada-api

# Reiniciar
docker restart terra-canada-api

# Detener
docker stop terra-canada-api

# Eliminar
docker rm terra-canada-api
```

---

## 🔍 TROUBLESHOOTING

### Contenedor no inicia

```bash
# Ver logs de error
docker logs terra-canada-api

# Verificar variables de entorno
docker exec terra-canada-api env
```

### No conecta a la base de datos

```bash
# Verificar conectividad
docker exec terra-canada-api ping tu-db-host

# Probar conexión PostgreSQL
docker exec terra-canada-api node -e "const {Pool} = require('pg'); const pool = new Pool({connectionString: process.env.DATABASE_URL}); pool.query('SELECT NOW()', (err, res) => {console.log(err ? err : res.rows); pool.end();})"
```

### Health check falla

```bash
# Ver estado del health check
docker inspect --format='{{json .State.Health}}' terra-canada-api | jq

# Probar manualmente
docker exec terra-canada-api wget -O- http://localhost:3000/health
```

---

## 🔒 SEGURIDAD

### Mejores Prácticas Implementadas

1. ✅ Usuario no-root (nodejs:1001)
2. ✅ Imagen base Alpine (menos superficie de ataque)
3. ✅ Multi-stage build (sin código fuente en producción)
4. ✅ dumb-init (manejo correcto de procesos)
5. ✅ Health check (detección de problemas)
6. ✅ .dockerignore (archivos sensibles excluidos)

### Recomendaciones Adicionales

```bash
# Escanear vulnerabilidades
docker scan terra-canada-api:2.0.0

# Actualizar imagen base regularmente
docker pull node:18-alpine
docker build --no-cache -t terra-canada-api:2.0.0 .

# No exponer directamente a Internet
# Usar reverse proxy (Nginx/Caddy) con SSL/TLS
```

---

## 📊 MONITOREO

### Health Check

El contenedor incluye un health check automático:

```bash
# Ver estado
docker inspect --format='{{.State.Health.Status}}' terra-canada-api

# Posibles estados:
# - starting: Iniciando
# - healthy: Saludable
# - unhealthy: Con problemas
```

### Logs

```bash
# Logs en tiempo real
docker logs -f terra-canada-api

# Últimas 100 líneas
docker logs --tail 100 terra-canada-api

# Logs con timestamps
docker logs -t terra-canada-api

# Logs desde hace 1 hora
docker logs --since 1h terra-canada-api
```

### Métricas

```bash
# CPU, Memoria, Red, Disco
docker stats terra-canada-api

# Formato personalizado
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" terra-canada-api
```

---

## 🔄 ACTUALIZACIÓN

### Actualización Sin Downtime

```bash
# 1. Build nueva versión
docker build -t terra-canada-api:2.0.1 .

# 2. Detener contenedor actual
docker stop terra-canada-api

# 3. Renombrar (backup)
docker rename terra-canada-api terra-canada-api-old

# 4. Ejecutar nueva versión
docker run -d --name terra-canada-api -p 3000:3000 --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  terra-canada-api:2.0.1

# 5. Verificar
docker logs -f terra-canada-api

# 6. Si todo OK, eliminar antiguo
docker rm terra-canada-api-old
docker rmi terra-canada-api:2.0.0
```

---

## 💾 BACKUP

### Backup de Imagen

```bash
# Guardar imagen
docker save terra-canada-api:2.0.0 | gzip > terra-canada-api-2.0.0.tar.gz

# Restaurar imagen
gunzip -c terra-canada-api-2.0.0.tar.gz | docker load
```

### Backup de Volúmenes

```bash
# Backup de logs
tar -czf logs-backup-$(date +%Y%m%d).tar.gz logs/

# Backup de uploads
tar -czf uploads-backup-$(date +%Y%m%d).tar.gz uploads/
```

---

## 🌐 REVERSE PROXY

### Nginx (Recomendado)

```nginx
server {
    listen 80;
    server_name api.terracanada.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.terracanada.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Caddy (Más Simple)

```
api.terracanada.com {
    reverse_proxy localhost:3000
}
```

---

## 📝 SCRIPT DE DEPLOYMENT

Usa el script automatizado:

```bash
# Hacer ejecutable
chmod +x deploy.sh

# Ejecutar
./deploy.sh
```

El script hace:

1. ✅ Verifica Docker
2. ✅ Verifica .env
3. ✅ Hace backup del contenedor antiguo
4. ✅ Build de nueva imagen
5. ✅ Ejecuta contenedor
6. ✅ Verifica health check
7. ✅ Muestra información útil

---

## 🆘 SOPORTE

### Logs de Error

```bash
# Ver solo errores
docker logs terra-canada-api 2>&1 | grep ERROR

# Exportar logs
docker logs terra-canada-api > logs-export.txt 2>&1
```

### Información del Sistema

```bash
# Info del contenedor
docker inspect terra-canada-api

# Info de la imagen
docker inspect terra-canada-api:2.0.0

# Uso de recursos
docker stats --no-stream terra-canada-api
```

---

## 📚 RECURSOS

- **Documentación completa:** `DEPLOYMENT.md`
- **Variables de entorno:** `.env.production.example`
- **Colección Postman:** `documentacion/API_Terra_Canada_v2.0.0_FINAL.postman_collection.json`
- **Swagger:** `http://localhost:3000/api-docs`

---

**Generado por:** Antigravity AI  
**Fecha:** 31 de Enero de 2026  
**Versión:** 2.0.0
