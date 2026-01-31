import { Request, Response, NextFunction } from 'express';
import { webhooksService } from '../services/webhooks.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class WebhooksController {
    /**
     * POST /api/v1/webhooks/n8n/documento-procesado
     * Recibir notificación de N8N cuando termina de procesar un documento
     */
    async documentoProcesadoN8N(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            // Validar token N8N
            const token = req.headers['x-n8n-token'] as string;

            if (!token) {
                logger.warn('Intento de acceso a webhook N8N sin token');
                return sendError(res, HTTP_STATUS.UNAUTHORIZED, 'Token N8N requerido');
            }

            if (!webhooksService.validateN8NToken(token)) {
                logger.warn('Intento de acceso a webhook N8N con token inválido', {
                    ip: req.ip,
                    token: token.substring(0, 10) + '...'
                });
                return sendError(res, HTTP_STATUS.FORBIDDEN, 'Token N8N inválido');
            }

            // Los datos ya vienen validados por el middleware de Zod
            const resultados = await webhooksService.procesarDocumentoN8N(req.body);

            logger.info('Webhook N8N procesado correctamente', {
                documento_id: req.body.documento_id,
                pagos_actualizados: resultados.pagos_actualizados
            });

            return sendSuccess(
                res,
                HTTP_STATUS.OK,
                'Webhook procesado exitosamente',
                resultados
            );
        } catch (error: any) {
            logger.error('Error en webhook N8N:', error);

            if (error.message.includes('no encontrado')) {
                return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
            }

            return sendError(
                res,
                HTTP_STATUS.INTERNAL_SERVER_ERROR,
                'Error al procesar webhook',
                { error: error.message }
            );
        }
    }
}

export const webhooksController = new WebhooksController();
