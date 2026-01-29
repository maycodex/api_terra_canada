import { Request, Response } from 'express';
import { serviciosService } from '../services/servicios.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class ServiciosController {
  async getServicios(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const servicioId = id ? parseInt(id) : undefined;
      const servicios = await serviciosService.getServicios(servicioId);

      if (servicioId && !servicios) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Servicio no encontrado');
      }

      return sendSuccess(
        res,
        HTTP_STATUS.OK,
       servicioId ? 'Servicio obtenido' : 'Servicios obtenidos',
        servicios
      );
    } catch (error) {
      logger.error('Error en getServicios:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener servicios');
    }
  }

  async createServicio(req: Request, res: Response): Promise<Response> {
    try {
      const servicio = await serviciosService.createServicio(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Servicio creado', servicio);
    } catch (error: any) {
      logger.error('Error en createServicio:', error);
      if (error.message === 'Ya existe un servicio con ese nombre') {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear servicio');
    }
  }

  async updateServicio(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const servicio = await serviciosService.updateServicio(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Servicio actualizado', servicio);
    } catch (error: any) {
      logger.error('Error en updateServicio:', error);
      if (error.message === 'Servicio no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message === 'Ya existe un servicio con ese nombre') {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar servicio');
    }
  }

  async deleteServicio(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      await serviciosService.deleteServicio(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Servicio eliminado', null);
    } catch (error: any) {
      logger.error('Error en deleteServicio:', error);
      if (error.message === 'Servicio no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message ===  'No se puede eliminar el servicio porque tiene proveedores asociados') {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar servicio');
    }
  }
}

export const serviciosController = new ServiciosController();
