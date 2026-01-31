import { Request, Response } from 'express';
import { cuentasService } from '../services/cuentas.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class CuentasController {
  async getCuentas(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      
      const cuentaId = id ? parseInt(id as string) : undefined;
      
      const cuentas = await cuentasService.getCuentas(cuentaId);

      if (cuentaId && !cuentas) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Cuenta no encontrada');
      }

      return sendSuccess(res, HTTP_STATUS.OK, cuentaId ? 'Cuenta obtenida' : 'Cuentas obtenidas', cuentas);
    } catch (error: any) {
      logger.error('Error en getCuentas:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al obtener cuentas');
    }
  }

  async createCuenta(req: Request, res: Response): Promise<Response> {
    try {
      const cuenta = await cuentasService.createCuenta(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Cuenta creada', cuenta);
    } catch (error: any) {
      logger.error('Error en createCuenta:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al crear cuenta');
    }
  }

  async updateCuenta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id as string);
      const cuenta = await cuentasService.updateCuenta(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Cuenta actualizada', cuenta);
    } catch (error: any) {
      logger.error('Error en updateCuenta:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al actualizar cuenta');
    }
  }

  async deleteCuenta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id as string);
      const result = await cuentasService.deleteCuenta(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Cuenta eliminada', result);
    } catch (error: any) {
      logger.error('Error en deleteCuenta:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al eliminar cuenta');
    }
  }
}

export const cuentasController = new CuentasController();
