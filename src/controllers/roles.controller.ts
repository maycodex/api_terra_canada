import { Request, Response } from 'express';
import { rolesService } from '../services/roles.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class RolesController {
  /**
   * GET /roles o /roles/:id
   */
  async getRoles(req: Request, res: Response): Promise<Response> {
    try {
      const id = req.params.id ? parseInt(req.params.id) : undefined;
      const roles = await rolesService.getRoles(id);

      if (id && !roles) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Rol no encontrado');
      }

      return sendSuccess(
        res,
        HTTP_STATUS.OK,
        id ? 'Rol obtenido exitosamente' : 'Roles obtenidos exitosamente',
        roles
      );
    } catch (error) {
      logger.error('Error en getRoles:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener roles');
    }
  }

  /**
   * POST /roles
   */
  async createRol(req: Request, res: Response): Promise<Response> {
    try {
      const rol = await rolesService.createRol(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Rol creado exitosamente', rol);
    } catch (error: any) {
      logger.error('Error en createRol:', error);
      
      if (error.message === 'Ya existe un rol con ese nombre') {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear rol');
    }
  }

  /**
   * PUT /roles/:id
   */
  async updateRol(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const rol = await rolesService.updateRol(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Rol actualizado exitosamente', rol);
    } catch (error: any) {
      logger.error('Error en updateRol:', error);
      
      if (error.message === 'Rol no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      
      if (error.message === 'Ya existe un rol con ese nombre') {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar rol');
    }
  }

  /**
   * DELETE /roles/:id
   */
  async deleteRol(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      await rolesService.deleteRol(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Rol eliminado exitosamente', null);
    } catch (error: any) {
      logger.error('Error en deleteRol:', error);
      
      if (error.message === 'Rol no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      
      if (error.message === 'No se puede eliminar el rol porque tiene usuarios asociados') {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar rol');
    }
  }
}

export const rolesController = new RolesController();
