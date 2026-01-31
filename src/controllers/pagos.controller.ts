import { Request, Response } from 'express';
import { pagosService } from '../services/pagos.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class PagosController {
  async getPagos(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      
      const pagoId = id ? parseInt(id as string) : undefined;
      
      const pagos = await pagosService.getPagos(pagoId);

      if (pagoId && !pagos) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Pago no encontrado');
      }

      return sendSuccess(res, HTTP_STATUS.OK, pagoId ? 'Pago obtenido' : 'Pagos obtenidos', pagos);
    } catch (error: any) {
      logger.error('Error en getPagos:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al obtener pagos');
    }
  }

  async createPago(req: Request, res: Response): Promise<Response> {
    try {
      const pago = await pagosService.createPago(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Pago creado exitosamente', pago);
    } catch (error: any) {
      logger.error('Error en createPago:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      
      // Incluir data adicional en la respuesta (ej: saldo_disponible)
      if (error.data) {
        return sendError(res, status, error.message, error.data);
      }
      
      return sendError(res, status, error.message || 'Error al crear pago');
    }
  }

  async updatePago(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id as string);
      const pago = await pagosService.updatePago(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Pago actualizado', pago);
    } catch (error: any) {
      logger.error('Error en updatePago:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al actualizar pago');
    }
  }

  async deletePago(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id as string);
      const result = await pagosService.deletePago(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Pago eliminado', result);
    } catch (error: any) {
      logger.error('Error en deletePago:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al eliminar pago');
    }
  }

  /**
   * Desactivar un pago (soft delete)
   * Usa la función PUT con activo: false
   */
  async desactivarPago(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id as string);
      const pago = await pagosService.updatePago(id, { activo: false });
      return sendSuccess(res, HTTP_STATUS.OK, 'Pago desactivado exitosamente', pago);
    } catch (error: any) {
      logger.error('Error en desactivarPago:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al desactivar pago');
    }
  }

  /**
   * Activar un pago
   * Usa la función PUT con activo: true
   */
  async activarPago(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id as string);
      const pago = await pagosService.updatePago(id, { activo: true });
      return sendSuccess(res, HTTP_STATUS.OK, 'Pago activado exitosamente', pago);
    } catch (error: any) {
      logger.error('Error en activarPago:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al activar pago');
    }
  }
}

export const pagosController = new PagosController();
