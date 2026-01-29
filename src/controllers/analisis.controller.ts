import { Request, Response } from 'express';
import { analisisService } from '../services/analisis.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class AnalisisController {
  async getDashboard(req: Request, res: Response): Promise<Response> {
    try {
      const dashboard = await analisisService.getDashboard();
      return sendSuccess(res, HTTP_STATUS.OK, 'Dashboard obtenido', dashboard);
    } catch (error) {
      logger.error('Error en getDashboard:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener dashboard');
    }
  }

  async getReportePagos(req: Request, res: Response): Promise<Response> {
    try {
      const { fecha_desde, fecha_hasta, proveedor_id } = req.query;
      
      const filters = {
        fecha_desde: fecha_desde as string,
        fecha_hasta: fecha_hasta as string,
        proveedor_id: proveedor_id ? parseInt(proveedor_id as string) : undefined
      };
      
      const reporte = await analisisService.getReportePagos(filters);
      return sendSuccess(res, HTTP_STATUS.OK, 'Reporte de pagos generado', reporte);
    } catch (error) {
      logger.error('Error en getReportePagos:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al generar reporte');
    }
  }
}

export const analisisController = new AnalisisController();
