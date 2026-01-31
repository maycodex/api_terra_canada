#!/bin/bash

# ================================
# SCRIPT DE DEPLOYMENT AUTOMATIZADO
# API Terra Canada v2.0.0
# ================================

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
APP_NAME="terra-canada-api"
VERSION="2.0.0"
PORT="3000"
MEMORY_LIMIT="512m"
CPU_LIMIT="1.0"

# Funciones
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "================================"
echo "  API TERRA CANADA DEPLOYMENT"
echo "  Version: $VERSION"
echo "================================"
echo ""

# 1. Verificar Docker
print_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    exit 1
fi
print_success "Docker encontrado: $(docker --version)"

# 2. Verificar archivo .env
print_info "Verificando archivo .env..."
if [ ! -f .env ]; then
    print_error "Archivo .env no encontrado"
    print_info "Copia .env.production.example a .env y configúralo"
    exit 1
fi
print_success "Archivo .env encontrado"

# 3. Verificar variables críticas
print_info "Verificando variables de entorno críticas..."
source .env

if [ -z "$DATABASE_URL" ]; then
    print_error "DATABASE_URL no está configurada en .env"
    exit 1
fi

if [ "$JWT_SECRET" == "CAMBIAR_ESTE_SECRETO_SUPER_SEGURO_EN_PRODUCCION_MIN_32_CARACTERES_ALEATORIOS" ]; then
    print_warning "JWT_SECRET no ha sido cambiado. Usa un secreto seguro en producción."
fi

print_success "Variables de entorno verificadas"

# 4. Detener contenedor existente (si existe)
print_info "Verificando contenedor existente..."
if docker ps -a | grep -q $APP_NAME; then
    print_warning "Contenedor existente encontrado. Deteniendo..."
    docker stop $APP_NAME 2>/dev/null || true
    
    # Backup del contenedor antiguo
    print_info "Creando backup del contenedor antiguo..."
    docker rename $APP_NAME ${APP_NAME}-backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
    
    print_success "Contenedor antiguo respaldado"
fi

# 5. Limpiar imágenes antiguas (opcional)
print_info "Limpiando imágenes antiguas..."
docker image prune -f > /dev/null 2>&1 || true

# 6. Build de la imagen
print_info "Construyendo imagen Docker..."
docker build -t ${APP_NAME}:${VERSION} -t ${APP_NAME}:latest .

if [ $? -eq 0 ]; then
    print_success "Imagen construida exitosamente"
else
    print_error "Error al construir la imagen"
    exit 1
fi

# 7. Crear directorios para volúmenes
print_info "Creando directorios para volúmenes..."
mkdir -p logs uploads
chmod 755 logs uploads
print_success "Directorios creados"

# 8. Crear red (si no existe)
print_info "Verificando red Docker..."
if ! docker network ls | grep -q terra-network; then
    docker network create terra-network
    print_success "Red terra-network creada"
else
    print_info "Red terra-network ya existe"
fi

# 9. Ejecutar contenedor
print_info "Iniciando contenedor..."
docker run -d \
  --name $APP_NAME \
  --restart unless-stopped \
  --network terra-network \
  -p ${PORT}:3000 \
  --env-file .env \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  --memory="${MEMORY_LIMIT}" \
  --cpus="${CPU_LIMIT}" \
  ${APP_NAME}:${VERSION}

if [ $? -eq 0 ]; then
    print_success "Contenedor iniciado exitosamente"
else
    print_error "Error al iniciar el contenedor"
    exit 1
fi

# 10. Esperar a que el servicio esté listo
print_info "Esperando a que el servicio esté listo..."
sleep 5

# 11. Verificar health check
print_info "Verificando health check..."
for i in {1..30}; do
    if curl -f http://localhost:${PORT}/health > /dev/null 2>&1; then
        print_success "Health check OK"
        break
    fi
    
    if [ $i -eq 30 ]; then
        print_error "Health check falló después de 30 intentos"
        print_info "Mostrando logs del contenedor:"
        docker logs --tail 50 $APP_NAME
        exit 1
    fi
    
    sleep 2
done

# 12. Mostrar información del contenedor
echo ""
echo "================================"
print_success "DEPLOYMENT COMPLETADO"
echo "================================"
echo ""
print_info "Información del contenedor:"
docker ps | grep $APP_NAME

echo ""
print_info "Endpoints disponibles:"
echo "  - Health Check: http://localhost:${PORT}/health"
echo "  - API Docs:     http://localhost:${PORT}/api-docs"
echo "  - API Base:     http://localhost:${PORT}/api/v1"

echo ""
print_info "Comandos útiles:"
echo "  - Ver logs:     docker logs -f $APP_NAME"
echo "  - Detener:      docker stop $APP_NAME"
echo "  - Reiniciar:    docker restart $APP_NAME"
echo "  - Estadísticas: docker stats $APP_NAME"

echo ""
print_warning "Recuerda configurar un reverse proxy (Nginx/Caddy) con SSL/TLS para producción"

# 13. Limpiar contenedores de backup antiguos (opcional)
print_info "Limpiando backups antiguos (más de 7 días)..."
docker ps -a | grep "${APP_NAME}-backup" | awk '{print $1}' | while read container_id; do
    created=$(docker inspect -f '{{.Created}}' $container_id)
    created_timestamp=$(date -d "$created" +%s)
    now_timestamp=$(date +%s)
    age_days=$(( ($now_timestamp - $created_timestamp) / 86400 ))
    
    if [ $age_days -gt 7 ]; then
        print_info "Eliminando backup antiguo: $container_id"
        docker rm $container_id > /dev/null 2>&1 || true
    fi
done

echo ""
print_success "¡Deployment completado exitosamente!"
