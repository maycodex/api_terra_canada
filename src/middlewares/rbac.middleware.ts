import { Request, Response, NextFunction } from 'express';
import { RolNombre, PERMISOS } from '../types/enums';
import { sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

/**
 * Middleware RBAC (Role-Based Access Control)
 * Verifica que el usuario tenga el rol necesario para acceder a un recurso
 */
export const requireRole = (...allowedRoles: RolNombre[]) => {
  return (req: Request, res: Response, next: NextFunction): Response | void => {
    try {
      // Verificar que el usuario esté autenticado
      if (!req.user) {
        return sendError(
          res,
          HTTP_STATUS.UNAUTHORIZED,
          'Usuario no autenticado'
        );
      }
      
      const userRole = req.user.roleName as RolNombre;
      
      // Verificar si el rol del usuario está en los roles permitidos
      if (!allowedRoles.includes(userRole)) {
        logger.warn(
          `Acceso denegado: Usuario ${req.user.username} (${userRole}) intentó acceder a recurso que requiere ${allowedRoles.join(' o ')}`
        );
        
        return sendError(
          res,
          HTTP_STATUS.FORBIDDEN,
          `Acceso denegado: Se requiere rol ${allowedRoles.join(' o ')}`
        );
      }
      
      logger.info(
        `Acceso permitido: Usuario ${req.user.username} (${userRole})`
      );
      
      next();
    } catch (error) {
      logger.error('Error en verificación de rol:', error);
      return sendError(
        res,
        HTTP_STATUS.INTERNAL_SERVER_ERROR,
        'Error al verificar permisos'
      );
    }
  };
};

/**
 * Verificar si el usuario tiene un permiso específico en un módulo
 */
export const hasPermission = (
  roleName: RolNombre,
  module: keyof typeof PERMISOS.ADMIN,
  permission: string
): boolean => {
  const rolePermissions = PERMISOS[roleName];
  if (!rolePermissions) return false;
  
  const modulePermissions = rolePermissions[module] as readonly string[];
  return modulePermissions.includes(permission);
};
