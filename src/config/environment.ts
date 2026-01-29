import dotenv from 'dotenv';
dotenv.config();

export const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000'),
  apiVersion: process.env.API_VERSION || 'v1',
  
  database: {
    url: process.env.DATABASE_URL!
  },
  
  jwt: {
    secret: process.env.JWT_SECRET || 'default_secret_CHANGE_IN_PRODUCTION',
    expiresIn: process.env.JWT_EXPIRES_IN || '1h',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
  },
  
  n8n: {
    baseUrl: process.env.N8N_BASE_URL || 'https://n8n.salazargroup.cloud',
    webhookDocumento: process.env.N8N_WEBHOOK_DOCUMENTO || '/webhook/procesar-documento',
    webhookCorreo: process.env.N8N_WEBHOOK_CORREO || '/webhook/enviar-gmail',
    authToken: process.env.N8N_AUTH_TOKEN || ''
  },
  
  upload: {
    dir: process.env.UPLOAD_DIR || './uploads',
    maxSize: parseInt(process.env.MAX_FILE_SIZE || '10485760'), // 10MB
    allowedMimeTypes: process.env.ALLOWED_MIME_TYPES?.split(',') || ['application/pdf']
  },
  
  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:5173'
  },
  
  security: {
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '10'),
    rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 min
    rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100')
  },
  
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    dir: process.env.LOG_DIR || './logs'
  }
};
