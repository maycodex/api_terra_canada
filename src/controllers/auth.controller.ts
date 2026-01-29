import { Request, Response } from 'express';
import { authService } from '../services/auth.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class AuthController {
  /**
   * Login
   */
  async login(req: Request, res: Response): Promise<Response> {
    try {
      const { username, password } = req.body;

      const result = await authService.login(username, password);

      if (!result) {
        return sendError(
          res,
          HTTP_STATUS.UNAUTHORIZED,
          'Credenciales inválidas'
        );
      }

      return sendSuccess(
        res,
        HTTP_STATUS.OK,
        'Login exitoso',
        result
      );
    } catch (error) {
      logger.error('Error en login controller:', error);
      return sendError(
        res,
        HTTP_STATUS.INTERNAL_SERVER_ERROR,
        'Error al procesar login'
      );
    }
  }

  /**
   * Obtener usuario autenticado
   */
  async getMe(req: Request, res: Response): Promise<Response> {
    try {
      if (!req.user) {
        return sendError(
          res,
          HTTP_STATUS.UNAUTHORIZED,
          'Usuario no autenticado'
        );
      }

      const usuario = await authService.getMe(req.user.userId);

      if (!usuario) {
        return sendError(
          res,
          HTTP_STATUS.NOT_FOUND,
          'Usuario no encontrado'
        );
      }

      return sendSuccess(
        res,
        HTTP_STATUS.OK,
        'Usuario obtenido',
        usuario
      );
    } catch (error) {
      logger.error('Error en getMe controller:', error);
      return sendError(
        res,
        HTTP_STATUS.INTERNAL_SERVER_ERROR,
        'Error al obtener usuario'
      );
    }
  }
}

export const authController = new AuthController();
