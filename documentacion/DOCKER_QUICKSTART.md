# 🚀 API Terra Canada - Deployment Rápido

## Comandos para Deployment

### 1. Construir imagen

```bash
docker build -t terra-canada-api:latest .
```

### 2. Ejecutar contenedor

```bash
docker run -d \
  --name terra-api \
  -p 3000:3000 \
  --env-file .env \
  --restart unless-stopped \
  terra-canada-api:latest
```

### 3. Verificar

```bash
# Ver logs
docker logs -f terra-api

# Health check
curl http://localhost:3000/health
```

---

## Variables de Entorno Requeridas (.env)

```bash
DATABASE_URL="postgresql://usuario:password@host:puerto/database"
JWT_SECRET="secreto_de_64_caracteres_minimo"
JWT_EXPIRES_IN="24h"
PORT=3000
NODE_ENV=production
```

---

## Comandos Útiles

```bash
# Ver logs
docker logs -f terra-api

# Reiniciar
docker restart terra-api

# Detener
docker stop terra-api

# Eliminar
docker rm terra-api

# Actualizar
docker stop terra-api && docker rm terra-api
docker build -t terra-canada-api:latest .
docker run -d --name terra-api -p 3000:3000 --env-file .env --restart unless-stopped terra-canada-api:latest
```

---

**Documentación completa:** Ver `DEPLOYMENT.md`
