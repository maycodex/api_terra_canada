import { Request, Response } from 'express';
import { cuentasService } from '../services/cuentas.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class CuentasController {
  async getCuentas(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const { cliente_id } = req.query;
      
      const cuentaId = id ? parseInt(id) : undefined;
      const clienteId = cliente_id ? parseInt(cliente_id as string) : undefined;
      
      const cuentas = await cuentasService.getCuentas(cuentaId, clienteId);

      if (cuentaId && !cuentas) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Cuenta no encontrada');
      }

      return sendSuccess(res, HTTP_STATUS.OK, cuentaId ? 'Cuenta obtenida' : 'Cuentas obtenidas', cuentas);
    } catch (error) {
      logger.error('Error en getCuentas:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener cuentas');
    }
  }

  async createCuenta(req: Request, res: Response): Promise<Response> {
    try {
      const cuenta = await cuentasService.createCuenta(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Cuenta creada', cuenta);
    } catch (error: any) {
      logger.error('Error en createCuenta:', error);
      if (error.message === 'Cliente no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear cuenta');
    }
  }

  async updateCuenta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const cuenta = await cuentasService.updateCuenta(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Cuenta actualizada', cuenta);
    } catch (error: any) {
      logger.error('Error en updateCuenta:', error);
      if (error.message === 'Cuenta no encontrada' || error.message === 'Cliente no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar cuenta');
    }
  }

  async deleteCuenta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      await cuentasService.deleteCuenta(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Cuenta desactivada', null);
    } catch (error: any)  {
      logger.error('Error en deleteCuenta:', error);
      if (error.message === 'Cuenta no encontrada') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message.includes('tiene pagos asociados')) {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar cuenta');
    }
  }
}

export const cuentasController = new CuentasController();
