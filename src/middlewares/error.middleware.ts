import { Request, Response, NextFunction } from 'express';
import logger from '../config/logger';
import { sendError, HTTP_STATUS } from '../utils/response.util';

/**
 * Middleware global de manejo de errores
 * Debe ser el último middleware en la cadena
 */
export const errorMiddleware = (
  error: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): Response => {
  // Log del error
  logger.error('Error no manejado:', {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method,
    user: req.user?.username || 'No autenticado'
  });
  
  // Enviar respuesta de error genérica
  return sendError(
    res,
    HTTP_STATUS.INTERNAL_SERVER_ERROR,
    'Error interno del servidor'
  );
};

/**
 * Middleware para capturar rutas no encontradas
 */
export const notFoundMiddleware = (
  req: Request,
  res: Response
): Response => {
  logger.warn(`Ruta no encontrada: ${req.method} ${req.url}`);
  
  return sendError(
    res,
    HTTP_STATUS.NOT_FOUND,
    `Ruta no encontrada: ${req.method} ${req.url}`
  );
};
