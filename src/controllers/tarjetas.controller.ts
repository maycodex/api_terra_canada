import { Request, Response } from 'express';
import { tarjetasService } from '../services/tarjetas.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class TarjetasController {
  async getTarjetas(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      
      const tarjetaId = id ? parseInt(id as string) : undefined;
      
      const tarjetas = await tarjetasService.getTarjetas(tarjetaId);

      if (tarjetaId && !tarjetas) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Tarjeta no encontrada');
      }

      return sendSuccess(res, HTTP_STATUS.OK, tarjetaId ? 'Tarjeta obtenida' : 'Tarjetas obtenidas', tarjetas);
    } catch (error: any) {
      logger.error('Error en getTarjetas:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al obtener tarjetas');
    }
  }

  async createTarjeta(req: Request, res: Response): Promise<Response> {
    try {
      const tarjeta = await tarjetasService.createTarjeta(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Tarjeta creada', tarjeta);
    } catch (error: any) {
      logger.error('Error en createTarjeta:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al crear tarjeta');
    }
  }

  async updateTarjeta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id as string);
      const tarjeta = await tarjetasService.updateTarjeta(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Tarjeta actualizada', tarjeta);
    } catch (error: any) {
      logger.error('Error en updateTarjeta:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al actualizar tarjeta');
    }
  }

  async deleteTarjeta(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id as string);
      const result = await tarjetasService.deleteTarjeta(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Tarjeta eliminada', result);
    } catch (error: any) {
      logger.error('Error en deleteTarjeta:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al eliminar tarjeta');
    }
  }
}

export const tarjetasController = new TarjetasController();
