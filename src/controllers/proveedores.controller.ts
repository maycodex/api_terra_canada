import { Request, Response } from 'express';
import { proveedoresService } from '../services/proveedores.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class ProveedoresController {
  async getProveedores(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const { servicio_id } = req.query;
      
      const proveedorId = id ? parseInt(id) : undefined;
      const servicioId = servicio_id ? parseInt(servicio_id as string) : undefined;
      
      const proveedores = await proveedoresService.getProveedores(proveedorId, servicioId);

      if (proveedorId && !proveedores) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Proveedor no encontrado');
      }

      return sendSuccess(
        res,
        HTTP_STATUS.OK,
        proveedorId ? 'Proveedor obtenido' : 'Proveedores obtenidos',
        proveedores
      );
    } catch (error) {
      logger.error('Error en getProveedores:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener proveedores');
    }
  }

  async createProveedor(req: Request, res: Response): Promise<Response> {
    try {
      const proveedor = await proveedoresService.createProveedor(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Proveedor creado', proveedor);
    } catch (error: any) {
      logger.error('Error en createProveedor:', error);
      if (error.message === 'Servicio no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear proveedor');
    }
  }

  async updateProveedor(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const proveedor = await proveedoresService.updateProveedor(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Proveedor actualizado', proveedor);
    } catch (error: any) {
      logger.error('Error en updateProveedor:', error);
      if (error.message === 'Proveedor no encontrado' || error.message === 'Servicio no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar proveedor');
    }
  }

  async deleteProveedor(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      await proveedoresService.deleteProveedor(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Proveedor desactivado', null);
    } catch (error: any) {
      logger.error('Error en deleteProveedor:', error);
      if (error.message === 'Proveedor no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar proveedor');
    }
  }

  async addCorreo(req: Request, res: Response): Promise<Response> {
    try {
      const proveedorId = parseInt(req.params.id);
      const { correo, principal } = req.body;
      
      const nuevoCorreo = await proveedoresService.addCorreo(proveedorId, correo, principal);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Correo agregado', nuevoCorreo);
    } catch (error: any) {
      logger.error('Error en addCorreo:', error);
      if (error.message === 'Proveedor no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message === 'Máximo 4 correos permitidos por proveedor') {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al agregar correo');
    }
  }
}

export const proveedoresController = new ProveedoresController();
