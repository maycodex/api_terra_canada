import { Request, Response, NextFunction } from 'express';
import { correosService } from '../services/correos.service';
import {
    generarCorreosSchema,
    createCorreoSchema,
    updateCorreoSchema,
    enviarCorreoSchema,
    correoFiltersSchema
} from '../schemas/correos.schema';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class CorreosController {
    /**
     * GET /api/v1/correos
     * Obtener lista de correos con filtros opcionales
     */
    async getAll(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            const filters = correoFiltersSchema.parse(req.query);
            const correos = await correosService.getCorreos(undefined, filters);

            return sendSuccess(res, HTTP_STATUS.OK, 'Correos obtenidos exitosamente', correos);
        } catch (error: any) {
            logger.error('Error en getAll correos:', error);
            return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener correos');
        }
    }

    /**
     * GET /api/v1/correos/:id
     * Obtener un correo específico con detalles completos
     */
    async getById(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            // El middleware validate ya transformó req.params.id a number
            const id = req.params.id as unknown as number;
            const correo = await correosService.getCorreos(id);

            if (!correo) {
                return sendError(res, HTTP_STATUS.NOT_FOUND, 'Correo no encontrado');
            }

            return sendSuccess(res, HTTP_STATUS.OK, 'Correo obtenido exitosamente', correo);
        } catch (error: any) {
            logger.error('Error en getById correo:', error);
            return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener correo');
        }
    }

    /**
     * POST /api/v1/correos/generar
     * Generar correos automáticamente para pagos pendientes
     */
    async generar(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            const validatedData = generarCorreosSchema.parse(req.body);
            const usuarioId = (req as any).user?.id;

            if (!usuarioId) {
                return sendError(res, HTTP_STATUS.UNAUTHORIZED, 'Usuario no autenticado');
            }

            const resultado = await correosService.generarCorreos(usuarioId, validatedData.proveedor_id);

            logger.info(`Correos generados por usuario ${usuarioId}`, {
                cantidad: resultado.correosGenerados
            });

            if (resultado.correosGenerados === 0) {
                return sendSuccess(res, HTTP_STATUS.OK, resultado.mensaje, resultado);
            }

            return sendSuccess(
                res,
                HTTP_STATUS.CREATED,
                `${resultado.correosGenerados} correo(s) generado(s) exitosamente`,
                resultado
            );
        } catch (error: any) {
            logger.error('Error en generar correos:', error);
            return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al generar correos');
        }
    }

    /**
     * POST /api/v1/correos
     * Crear un correo manualmente
     */
    async create(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            const validatedData = createCorreoSchema.parse(req.body);
            const usuarioId = (req as any).user?.id;

            if (!usuarioId) {
                return sendError(res, HTTP_STATUS.UNAUTHORIZED, 'Usuario no autenticado');
            }

            const correo = await correosService.createCorreo({
                ...validatedData,
                usuario_id: usuarioId
            });

            logger.info(`Correo creado manualmente por usuario ${usuarioId}`, {
                correoId: correo.id
            });

            return sendSuccess(res, HTTP_STATUS.CREATED, 'Correo creado exitosamente', correo);
        } catch (error: any) {
            logger.error('Error en create correo:', error);

            if (error.message.includes('no encontrado')) {
                return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
            }
            if (error.message.includes('no pertenece') || error.message.includes('no están pagados')) {
                return sendError(res, HTTP_STATUS.BAD_REQUEST, error.message);
            }

            return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear correo');
        }
    }

    /**
     * PUT /api/v1/correos/:id
     * Actualizar un borrador de correo
     */
    async update(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            // El middleware validate ya transformó req.params.id a number
            const id = req.params.id as unknown as number;
            const validatedData = updateCorreoSchema.parse(req.body);

            const correo = await correosService.updateCorreo(id, validatedData);

            logger.info(`Correo actualizado: ID ${id}`);

            return sendSuccess(res, HTTP_STATUS.OK, 'Correo actualizado exitosamente', correo);
        } catch (error: any) {
            logger.error('Error en update correo:', error);

            if (error.message === 'Correo no encontrado') {
                return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
            }
            if (error.message.includes('Solo se pueden editar')) {
                return sendError(res, HTTP_STATUS.CONFLICT, error.message);
            }
            if (error.message.includes('no es válido')) {
                return sendError(res, HTTP_STATUS.BAD_REQUEST, error.message);
            }

            return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar correo');
        }
    }

    /**
     * POST /api/v1/correos/:id/enviar
     * Enviar un correo (cambiar a estado ENVIADO y enviar via N8N)
     */
    async enviar(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            // El middleware validate ya transformó req.params.id a number
            const id = req.params.id as unknown as number;
            const validatedData = enviarCorreoSchema.parse(req.body);

            const correo = await correosService.enviarCorreo(id, validatedData);

            logger.info(`Correo enviado: ID ${id}`, {
                destinatario: correo.correo_seleccionado,
                cantidadPagos: correo.cantidad_pagos
            });

            return sendSuccess(res, HTTP_STATUS.OK, 'Correo enviado exitosamente', correo);
        } catch (error: any) {
            logger.error('Error en enviar correo:', error);

            if (error.message === 'Correo no encontrado') {
                return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
            }
            if (error.message.includes('Solo se pueden enviar')) {
                return sendError(res, HTTP_STATUS.CONFLICT, error.message);
            }

            // Errores específicos del webhook N8N
            // El mensaje ya viene del webhook, así que lo propagamos directamente
            if (error.message.includes('No se pudo conectar')) {
                return sendError(res, HTTP_STATUS.SERVICE_UNAVAILABLE, error.message);
            }

            // Cualquier otro error del webhook (incluido el mensaje personalizado del webhook)
            // Si tiene un mensaje específico, lo mostramos al usuario
            const mensajeError = error.message || 'Error al enviar correo';

            return sendError(
                res,
                HTTP_STATUS.BAD_REQUEST,
                mensajeError
            );
        }
    }

    /**
     * DELETE /api/v1/correos/:id
     * Eliminar un borrador de correo
     */
    async delete(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            // El middleware validate ya transformó req.params.id a number
            const id = req.params.id as unknown as number;

            const correo = await correosService.deleteCorreo(id);

            logger.info(`Correo eliminado: ID ${id}`);

            return sendSuccess(res, HTTP_STATUS.OK, 'Correo eliminado exitosamente', correo);
        } catch (error: any) {
            logger.error('Error en delete correo:', error);

            if (error.message === 'Correo no encontrado') {
                return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
            }
            if (error.message.includes('No se pueden eliminar')) {
                return sendError(res, HTTP_STATUS.CONFLICT, error.message);
            }

            return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar correo');
        }
    }

    /**
     * GET /api/v1/correos/pendientes
     * Obtener solo los correos en estado BORRADOR
     */
    async getPendientes(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            const correos = await correosService.getCorreos(undefined, { estado: 'BORRADOR' });

            return sendSuccess(
                res,
                HTTP_STATUS.OK,
                `${correos.length} correo(s) pendiente(s) de envío`,
                correos
            );
        } catch (error: any) {
            logger.error('Error en getPendientes correos:', error);
            return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener correos pendientes');
        }
    }
}

export const correosController = new CorreosController();
