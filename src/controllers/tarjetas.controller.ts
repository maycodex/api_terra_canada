import { Request, Response } from 'express';
import { tarjetasService } from '../services/tarjetas.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class TarjetasController {
  async getTarjetas(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const { cliente_id } = req.query;
      
      const tarjetaId = id ? parseInt(id) : undefined;
      const clienteId = cliente_id ? parseInt(cliente_id as string) : undefined;
      
      const tarjetas = await tarjetasService.getTarjetas(tarjetaId, clienteId);

      if (tarjetaId && !tarjetas) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Tarjeta no encontrada');
      }

      return sendSuccess(res, HTTP_STATUS.OK, tarjetaId ? 'Tarjeta obtenida' : 'Tarjetas obtenidas', tarjetas);
    } catch (error) {
      logger.error('Error en getTarjetas:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener tarjetas');
    }
  }

  async createTarjeta(req: Request, res: Response): Promise<Response> {
    try {
      const tarjeta = await tarjetasService.createTarjeta(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Tarjeta creada', tarjeta);
    } catch (error: any) {
      logger.error('Error en createTarjeta:', error);
      if (error.message === 'Cliente no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear tarjeta');
    }
  }

  async updateTarjeta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const tarjeta = await tarjetasService.updateTarjeta(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Tarjeta actualizada', tarjeta);
    } catch (error: any) {
      logger.error('Error en updateTarjeta:', error);
      if (error.message === 'Tarjeta no encontrada' || error.message === 'Cliente no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar tarjeta');
    }
  }

  async recargarTarjeta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const { monto } = req.body;
      const tarjeta = await tarjetasService.recargarTarjeta(id, monto);
      return sendSuccess(res, HTTP_STATUS.OK, 'Tarjeta recargada exitosamente', tarjeta);
    } catch (error: any) {
      logger.error('Error en recargarTarjeta:', error);
      if (error.message === 'Tarjeta no encontrada') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message === 'El monto debe ser mayor a 0') {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al recargar tarjeta');
    }
  }

  async deleteTarjeta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      await tarjetasService.deleteTarjeta(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Tarjeta desactivada', null);
    } catch (error: any) {
      logger.error('Error en deleteTarjeta:', error);
      if (error.message === 'Tarjeta no encontrada') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      if (error.message.includes('tiene pagos asociados')) {
        return sendError(res, HTTP_STATUS.CONFLICT, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar tarjeta');
    }
  }
}

export const tarjetasController = new TarjetasController();
