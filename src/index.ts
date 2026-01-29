import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';

import { config } from './config/environment';
import logger from './config/logger';
import swaggerSpec from './config/swagger';
import routes from './routes';
import { errorMiddleware, notFoundMiddleware } from './middlewares/error.middleware';

const app: Application = express();

// ============================================
// MIDDLEWARES GLOBALES
// ============================================

// Seguridad con Helmet
app.use(helmet());

// CORS
app.use(cors({ 
  origin: config.cors.origin,
  credentials: true
}));

// Body parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging HTTP con Morgan
if (config.nodeEnv === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined', {
    stream: {
      write: (message: string) => logger.info(message.trim())
    }
  }));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: config.security.rateLimitWindowMs, // 15 minutos
  max: config.security.rateLimitMaxRequests, // 100 requests por ventana
  message: {
    code: 429,
    estado: false,
    message: 'Demasiadas peticiones desde esta IP, intente más tarde',
    data: null
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Rate limiting especial para login (más restrictivo)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 5, // 5 intentos
  message: {
    code: 429,
    estado: false,
    message: 'Demasiados intentos de login, intente más tarde',
    data: null
  },
  skipSuccessfulRequests: true,
});
app.use('/api/v1/auth/login', loginLimiter);

// ============================================
// DOCUMENTACIÓN SWAGGER
// ============================================
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'API Terra Canada - Documentación'
}));

// ============================================
// HEALTH CHECK
// ============================================
app.get('/health', (_req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: config.nodeEnv,
    version: '1.0.0'
  });
});

// ============================================
// RUTAS DE LA API
// ============================================
app.use(`/api/${config.apiVersion}`, routes);

// ============================================
// MANEJO DE ERRORES
// ============================================
// Ruta no encontrada (404)
app.use(notFoundMiddleware);

// Error handler global (debe ir al final)
app.use(errorMiddleware);

// ============================================
// INICIAR SERVIDOR
// ============================================
const PORT = config.port;

app.listen(PORT, () => {
  logger.info('='.repeat(50));
  logger.info(`🚀 Servidor corriendo en puerto ${PORT}`);
  logger.info(`📚 Documentación disponible en http://localhost:${PORT}/api-docs`);
  logger.info(`🏥 Health check en http://localhost:${PORT}/health`);
  logger.info(`🌍 Entorno: ${config.nodeEnv}`);
  logger.info(`🔐 JWT Secret configurado: ${config.jwt.secret.substring(0, 10)}***`);
  logger.info(`📊 Base de datos: ${config.database.url.split('@')[1] || 'Configurada'}`);
  logger.info('='.repeat(50));
});

// Manejo de errores no capturados
process.on('unhandledRejection', (reason: any) => {
  logger.error('Unhandled Promise Rejection:', reason);
});

process.on('uncaughtException', (error: Error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

export default app;
