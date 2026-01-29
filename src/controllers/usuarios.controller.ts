import { Request, Response } from 'express';
import { usuariosService } from '../services/usuarios.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class UsuariosController {
  async getUsuarios(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const usuarioId = id ? parseInt(id) : undefined;
      const usuarios = await usuariosService.getUsuarios(usuarioId);

      if (usuarioId && !usuarios) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Usuario no encontrado');
      }

      return sendSuccess(res, HTTP_STATUS.OK, usuarioId ? 'Usuario obtenido' : 'Usuarios obtenidos', usuarios);
    } catch (error) {
      logger.error('Error en getUsuarios:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener usuarios');
    }
  }

  async createUsuario(req: Request, res: Response): Promise<Response> {
    try {
      const usuario = await usuariosService.createUsuario(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Usuario creado', usuario);
    } catch (error: any) {
      logger.error('Error en createUsuario:', error);
      if (error.message.includes('Ya existe')) {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      if (error.message === 'Rol no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear usuario');
    }
  }

  async updateUsuario(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const usuario = await usuariosService.updateUsuario(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Usuario actualizado', usuario);
    } catch (error: any) {
      logger.error('Error en updateUsuario:', error);
      if (error.message === 'Usuario no encontrado' || error.message === 'Rol no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message.includes('Ya existe')) {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar usuario');
    }
  }

  async deleteUsuario(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      await usuariosService.deleteUsuario(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Usuario desactivado', null);
    } catch (error: any) {
      logger.error('Error en deleteUsuario:', error);
      if (error.message === 'Usuario no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar usuario');
    }
  }
}

export const usuariosController = new UsuariosController();
