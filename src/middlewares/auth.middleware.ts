import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt.util';
import { sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

/**
 * Middleware de autenticación JWT
 * Verifica que el token sea válido y agrega el usuario al request
 */
export const authMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): Response | void => {
  try {
    // Obtener token del header Authorization
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return sendError(
        res,
        HTTP_STATUS.UNAUTHORIZED,
        'No autorizado: Token no proporcionado'
      );
    }
    
    // Verificar formato: "Bearer {token}"
    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return sendError(
        res,
        HTTP_STATUS.UNAUTHORIZED,
        'No autorizado: Formato de token inválido'
      );
    }
    
    const token = parts[1];
    
    // Verificar y decodificar token
    const decoded = verifyToken(token);
    
    // Agregar usuario al request
    req.user = decoded;
    
    logger.info(`Usuario autenticado: ${decoded.username} (${decoded.roleName})`);
    
    next();
  } catch (error) {
    logger.error('Error en autenticación:', error);
    return sendError(
      res,
      HTTP_STATUS.UNAUTHORIZED,
      'No autorizado: Token inválido o expirado'
    );
  }
};
