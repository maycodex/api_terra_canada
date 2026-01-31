# ================================
# Stage 1: Builder
# ================================
FROM node:18-alpine AS builder

# Instalar dependencias del sistema necesarias para compilación
RUN apk add --no-cache python3 make g++

# Configurar directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias (incluyendo devDependencies para compilar)
RUN npm ci --legacy-peer-deps

# Copiar código fuente
COPY . .

# Compilar TypeScript a JavaScript
RUN npm run build

# Limpiar archivos innecesarios
RUN rm -rf src tests *.md

# ================================
# Stage 2: Production
# ================================
FROM node:18-alpine AS production

# Metadata
LABEL maintainer="Terra Canada Team"
LABEL description="API Terra Canada - Sistema de Gestión de Pagos v2.0.0"
LABEL version="2.0.0"

# Instalar dumb-init para manejo correcto de señales
RUN apk add --no-cache dumb-init

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Configurar directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar solo dependencias de producción
RUN npm ci --only=production --legacy-peer-deps && \
    npm cache clean --force

# Copiar el código compilado desde el stage builder
COPY --from=builder /app/dist ./dist

# Crear directorios necesarios
RUN mkdir -p logs uploads && \
    chown -R nodejs:nodejs /app

# Cambiar a usuario no-root
USER nodejs

# Exponer puerto
EXPOSE 3000

# Variables de entorno por defecto (se pueden sobreescribir)
ENV NODE_ENV=production \
    PORT=3000 \
    API_VERSION=v1 \
    LOG_LEVEL=info \
    LOG_DIR=/app/logs \
    UPLOAD_DIR=/app/uploads

# Health check mejorado
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Usar dumb-init para manejo correcto de señales
ENTRYPOINT ["dumb-init", "--"]

# Comando para iniciar la aplicación
CMD ["node", "dist/index.js"]
