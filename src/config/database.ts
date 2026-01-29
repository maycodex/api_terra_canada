import { Pool } from 'pg';
import { config } from './environment';
import logger from './logger';

// Crear pool de conexiones a PostgreSQL
const pool = new Pool({
  connectionString: config.database.url,
  max: 20, // Máximo 20 conexiones
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Event listeners
pool.on('connect', () => {
  logger.info('Nueva conexión a PostgreSQL establecida');
});

pool.on('error', (err) => {
  logger.error('Error inesperado en pool de PostgreSQL:', err);
});

// Función helper para queries
export const query = async (text: string, params?: any[]) => {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    logger.debug('Query ejecutada', { text, duration, rows: result.rowCount });
    return result;
  } catch (error) {
    logger.error('Error en query:', { text, error });
    throw error;
  }
};

// Función para obtener cliente del pool (para transacciones)
export const getClient = () => pool.connect();

// Cerrar pool al terminar
process.on('SIGINT', async () => {
  await pool.end();
  logger.info('Pool de PostgreSQL cerrado');
  process.exit();
});

process.on('SIGTERM', async () => {
  await pool.end();
  logger.info('Pool de PostgreSQL cerrado');
  process.exit();
});

export default pool;
