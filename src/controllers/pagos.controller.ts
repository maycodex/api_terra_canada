import { Request, Response } from 'express';
import { pagosService } from '../services/pagos.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class PagosController {
  async getPagos(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const { proveedor_id, estado, fecha_desde, fecha_hasta } = req.query;
      
      const pagoId = id ? parseInt(id) : undefined;
      const filters = {
        proveedor_id: proveedor_id ? parseInt(proveedor_id as string) : undefined,
        estado: estado as string,
        fecha_desde: fecha_desde as string,
        fecha_hasta: fecha_hasta as string
      };
      
      const pagos = await pagosService.getPagos(pagoId, filters);

      if (pagoId && !pagos) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Pago no encontrado');
      }

      return sendSuccess(res, HTTP_STATUS.OK, pagoId ? 'Pago obtenido' : 'Pagos obtenidos', pagos);
    } catch (error) {
      logger.error('Error en getPagos:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener pagos');
    }
  }

  async createPago(req: Request, res: Response): Promise<Response> {
    try {
      const pago = await pagosService.createPago(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Pago creado exitosamente', pago);
    } catch (error: any) {
      logger.error('Error en createPago:', error);
      if (error.message.includes('no encontrad')) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message === 'Saldo insuficiente en la tarjeta') {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear pago');
    }
  }

  async updatePago(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const pago = await pagosService.updatePago(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Pago actualizado', pago);
    } catch (error: any) {
      logger.error('Error en updatePago:', error);
      if (error.message === 'Pago no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar pago');
    }
  }

  async deletePago(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      await pagosService.deletePago(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Pago cancelado', null);
    } catch (error: any) {
      logger.error('Error en deletePago:', error);
      if (error.message === 'Pago no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message === 'No se puede eliminar un pago completado') {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar pago');
    }
  }
}

export const pagosController = new PagosController();
