import { Request, Response } from 'express';
import { documentosService } from '../services/documentos.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class DocumentosController {
  /**
   * GET /api/v1/documentos
   * Obtener todos los documentos
   */
  async getAll(req: Request, res: Response): Promise<Response> {
    try {
      const documentos = await documentosService.getDocumentos();
      return sendSuccess(res, HTTP_STATUS.OK, 'Documentos obtenidos exitosamente', documentos);
    } catch (error: any) {
      logger.error('Error en getAll documentos:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al obtener documentos');
    }
  }

  /**
   * GET /api/v1/documentos/:id
   * Obtener un documento específico con pagos vinculados
   */
  async getById(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      
      if (isNaN(id) || id <= 0) {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, 'ID de documento inválido');
      }

      const documento = await documentosService.getDocumentos(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Documento obtenido exitosamente', documento);
    } catch (error: any) {
      logger.error('Error en getById documento:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al obtener documento');
    }
  }

  /**
   * POST /api/v1/documentos
   * Crear un nuevo documento
   */
  async create(req: Request, res: Response): Promise<Response> {
    try {
      const { tipo_documento, nombre_archivo, url_documento, usuario_id, pago_id } = req.body;

      const documento = await documentosService.createDocumento({
        tipo_documento,
        nombre_archivo,
        url_documento,
        usuario_id,
        pago_id: pago_id || null
      });

      logger.info(`Documento creado: ID ${documento?.id}`);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Documento creado exitosamente', documento);
    } catch (error: any) {
      logger.error('Error en create documento:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al crear documento');
    }
  }

  /**
   * PUT /api/v1/documentos/:id
   * Actualizar un documento existente
   */
  async update(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      
      if (isNaN(id) || id <= 0) {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, 'ID de documento inválido');
      }

      const { nombre_archivo, url_documento } = req.body;

      const documento = await documentosService.updateDocumento(id, {
        nombre_archivo,
        url_documento
      });

      logger.info(`Documento actualizado: ID ${id}`);
      return sendSuccess(res, HTTP_STATUS.OK, 'Documento actualizado exitosamente', documento);
    } catch (error: any) {
      logger.error('Error en update documento:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al actualizar documento');
    }
  }

  /**
   * DELETE /api/v1/documentos/:id
   * Eliminar un documento
   */
  async delete(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      
      if (isNaN(id) || id <= 0) {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, 'ID de documento inválido');
      }

      const result = await documentosService.deleteDocumento(id);
      
      logger.info(`Documento eliminado: ID ${id}`);
      return sendSuccess(res, HTTP_STATUS.OK, 'Documento eliminado exitosamente', result);
    } catch (error: any) {
      logger.error('Error en delete documento:', error);
      const status = error.code || HTTP_STATUS.INTERNAL_SERVER_ERROR;
      return sendError(res, status, error.message || 'Error al eliminar documento');
    }
  }
}

export const documentosController = new DocumentosController();
