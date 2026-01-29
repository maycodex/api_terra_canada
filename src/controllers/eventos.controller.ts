import { Request, Response } from 'express';
import { eventosService } from '../services/eventos.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class EventosController {
  async getEventos(req: Request, res: Response): Promise<Response> {
    try {
      const { tabla, tipo_evento, usuario_id, fecha_desde, fecha_hasta, limit } = req.query;
      
      const filters = {
        tabla: tabla as string,
        tipo_evento: tipo_evento as string,
        usuario_id: usuario_id ? parseInt(usuario_id as string) : undefined,
        fecha_desde: fecha_desde as string,
        fecha_hasta: fecha_hasta as string,
        limit: limit ? parseInt(limit as string) : undefined
      };
      
      const eventos = await eventosService.getEventos(filters);
      return sendSuccess(res, HTTP_STATUS.OK, 'Eventos obtenidos', eventos);
    } catch (error) {
      logger.error('Error en getEventos:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener eventos');
    }
  }
}

export const eventosController = new EventosController();
