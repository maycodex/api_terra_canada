# 🐳 Guía de Deployment con Docker

## ⚡ Deployment Rápido

### 1. Configurar Variables de Entorno

Edita el archivo `.env`:

```bash
DATABASE_URL="postgresql://admin:password@tu-servidor:5433/terra_canada_v2"
JWT_SECRET="tu_secreto_super_seguro_de_64_caracteres_minimo"
JWT_EXPIRES_IN="24h"
PORT=3000
NODE_ENV=production
```

### 2. Construir la Imagen

```bash
docker build -t terra-canada-api:latest .
```

### 3. Ejecutar el Contenedor

```bash
docker run -d \
  --name terra-api \
  -p 3000:3000 \
  --env-file .env \
  --restart unless-stopped \
  terra-canada-api:latest
```

### 4. Verificar que Funciona

```bash
# Ver logs
docker logs -f terra-api

# Health check
curl http://localhost:3000/health

# Swagger docs
# Abrir: http://localhost:3000/api-docs
```

---

## 📝 Comandos Útiles

```bash
# Ver logs en tiempo real
docker logs -f terra-api

# Ver logs de las últimas 100 líneas
docker logs --tail 100 terra-api

# Detener el contenedor
docker stop terra-api

# Iniciar el contenedor
docker start terra-api

# Reiniciar el contenedor
docker restart terra-api

# Eliminar el contenedor
docker stop terra-api && docker rm terra-api

# Ver estado del contenedor
docker ps | grep terra-api

# Ejecutar comandos dentro del contenedor
docker exec -it terra-api sh

# Ver uso de recursos
docker stats terra-api
```

---

## 🔄 Actualizar la Aplicación

```bash
# 1. Pull cambios del repositorio
git pull origin main

# 2. Detener y eliminar contenedor actual
docker stop terra-api
docker rm terra-api

# 3. Eliminar imagen antigua (opcional)
docker rmi terra-canada-api:latest

# 4. Construir nueva imagen
docker build -t terra-canada-api:latest .

# 5. Ejecutar nuevo contenedor
docker run -d \
  --name terra-api \
  -p 3000:3000 \
  --env-file .env \
  --restart unless-stopped \
  terra-canada-api:latest

# 6. Verificar logs
docker logs -f terra-api
```

---

## ☁️ Deployment en Servidor VPS

### Conectar por SSH

```bash
ssh usuario@tu-servidor-ip
```

### Instalar Docker (si no está instalado)

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### Clonar Repositorio

```bash
git clone https://github.com/tu-usuario/api_terra.git
cd api_terra
```

### Crear archivo .env

```bash
nano .env
# Pega tus variables de entorno
# Ctrl+X, Y, Enter para guardar
```

### Construir y Ejecutar

```bash
docker build -t terra-canada-api:latest .

docker run -d \
  --name terra-api \
  -p 3000:3000 \
  --env-file .env \
  --restart unless-stopped \
  terra-canada-api:latest
```

### Configurar Firewall

```bash
# Permitir puerto 3000
sudo ufw allow 3000/tcp
sudo ufw enable
```

---

## 🌐 Deployment en Cloud (Dockerfile only)

### Railway

1. Conecta tu repositorio GitHub
2. Railway detecta automáticamente el `Dockerfile`
3. Configura variables de entorno en el dashboard
4. Click "Deploy"

### Render

1. New → Web Service
2. Conecta tu repositorio
3. **Docker** será detectado automáticamente
4. Agrega variables de entorno
5. Click "Create Web Service"

### DigitalOcean App Platform

1. Create App → GitHub
2. Tipo: **Docker**
3. Variables de entorno
4. Plan: Basic ($5/mes)
5. Deploy

---

## 🔒 Seguridad

### 1. Generar JWT Secret Seguro

```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 2. Usar HTTPS con Nginx

Instala Nginx como reverse proxy:

```bash
sudo apt install nginx certbot python3-certbot-nginx

sudo nano /etc/nginx/sites-available/terra-api
```

Configuración Nginx:

```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Activar y obtener SSL:

```bash
sudo ln -s /etc/nginx/sites-available/terra-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo certbot --nginx -d tu-dominio.com
```

---

## 🐛 Troubleshooting

### El contenedor no inicia

```bash
# Ver logs completos
docker logs terra-api

# Ejecutar en modo interactivo para debug
docker run -it --rm --env-file .env terra-canada-api:latest sh
```

### Error de conexión a base de datos

```bash
# Verificar conectividad desde el contenedor
docker run -it --rm terra-canada-api:latest sh
# Dentro del contenedor:
ping tu-bd-host
```

### Puerto 3000 ya en uso

```bash
# Ver qué usa el puerto
sudo lsof -i :3000

# O cambiar puerto en .env y al ejecutar:
docker run -d --name terra-api -p 3001:3000 --env-file .env terra-canada-api:latest
```

### Limpiar todo Docker (cuidado!)

```bash
# Detener todos los contenedores
docker stop $(docker ps -aq)

# Eliminar todos los contenedores
docker rm $(docker ps -aq)

# Eliminar imágenes sin usar
docker image prune -a
```

---

## 📊 Monitoreo

### Health Check Manual

```bash
curl http://localhost:3000/health
```

### Ver Métricas del Contenedor

```bash
docker stats terra-api
```

### Logs Persistentes

```bash
# Guardar logs en archivo
docker logs terra-api > api-logs.txt

# Ver logs de última hora con timestamps
docker logs --since 1h --timestamps terra-api
```

---

## ✅ Checklist de Deployment

- [ ] Archivo `.env` con credenciales de producción
- [ ] `JWT_SECRET` generado de forma segura (64+ caracteres)
- [ ] Base de datos accesible y probada
- [ ] Docker instalado en el servidor
- [ ] Firewall configurado (puerto 3000)
- [ ] Nginx + HTTPS configurado (recomendado)
- [ ] Health check funcionando: `curl http://localhost:3000/health`
- [ ] Swagger accesible: `http://localhost:3000/api-docs`
- [ ] Logs monitoreados: `docker logs -f terra-api`

---

**¡Tu API está lista para producción!** 🎉

Para soporte: Revisa los logs con `docker logs terra-api`
