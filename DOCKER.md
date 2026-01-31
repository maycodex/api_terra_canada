# 🚀 API TERRA CANADA - DEPLOYMENT

**Versión:** 2.0.0

---

## 📦 DEPLOYMENT CON DOCKER

### 1. Configurar Variables de Entorno

Crear archivo `.env` en la raíz del proyecto:

```bash
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://usuario:password@host:5433/terra_canada_v2
JWT_SECRET=tu_secreto_seguro_minimo_32_caracteres
JWT_EXPIRES_IN=8h
N8N_BASE_URL=https://n8n.salazargroup.cloud
N8N_WEBHOOK_TOKEN=tu_token_n8n_seguro
CORS_ORIGIN=https://tu-dominio.com
LOG_LEVEL=info
```

### 2. Build

```bash
docker build -t terra-canada-api:2.0.0 .
```

### 3. Run

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

### 4. Verificar

```bash
docker logs -f terra-canada-api
curl http://localhost:3000/health
```

---

## 🔧 COMANDOS ÚTILES

```bash
# Ver logs
docker logs -f terra-canada-api

# Reiniciar
docker restart terra-canada-api

# Detener
docker stop terra-canada-api

# Eliminar
docker rm terra-canada-api
```

---

## 📚 ENDPOINTS

- **Health:** `http://localhost:3000/health`
- **Swagger:** `http://localhost:3000/api-docs`
- **API:** `http://localhost:3000/api/v1`

---

## 🔐 GENERAR SECRETOS

```bash
# JWT Secret
openssl rand -base64 32

# N8N Token
openssl rand -base64 32
```
