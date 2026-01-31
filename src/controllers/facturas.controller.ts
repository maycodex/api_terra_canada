import { Request, Response, NextFunction } from 'express';
import { n8nClient } from '../utils/n8n.util';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';
import { z } from 'zod';

// Schema para procesar facturas en base64
const procesarFacturasSchema = z.object({
    archivos: z.array(z.object({
        nombre: z.string(),
        tipo: z.string(),
        base64: z.string()
    })).min(1, 'Debe incluir al menos un archivo').max(5, 'Máximo 5 facturas permitidas')
});

export class FacturasController {
    /**
     * POST /api/v1/facturas/procesar
     * Procesar facturas enviando PDFs en base64 a N8N
     */
    async procesar(req: Request, res: Response, next: NextFunction): Promise<Response> {
        try {
            // Validar datos
            const validatedData = procesarFacturasSchema.parse(req.body);

            // Obtener usuario autenticado
            const usuario = (req as any).user;
            if (!usuario) {
                return sendError(res, HTTP_STATUS.UNAUTHORIZED, 'Usuario no autenticado');
            }

            // Obtener IP del cliente
            const ip = req.ip || req.connection.remoteAddress || 'unknown';

            // Preparar datos del usuario
            const usuarioData = {
                nombre: usuario.nombre_completo || usuario.nombre_usuario,
                id: usuario.id,
                tipo: usuario.rol || 'user',
                ip: ip
            };

            // Enviar a N8N
            const resultado = await n8nClient.procesarFacturas(usuarioData, validatedData.archivos);

            logger.info(`Facturas procesadas para usuario ${usuario.id}`, {
                cantidadFacturas: validatedData.archivos.length,
                pagosEncontrados: resultado.facturas?.length || 0
            });

            return sendSuccess(
                res,
                HTTP_STATUS.OK,
                resultado.mensaje || 'Facturas procesadas exitosamente',
                {
                    pagos_encontrados: resultado.facturas || [],
                    total: resultado.facturas?.length || 0
                }
            );
        } catch (error: any) {
            logger.error('Error en procesar facturas:', error);

            // Validación de Zod
            if (error.name === 'ZodError') {
                return sendError(
                    res,
                    HTTP_STATUS.BAD_REQUEST,
                    error.errors[0]?.message || 'Datos inválidos'
                );
            }

            // Errores del webhook N8N
            if (error.message.includes('Máximo 5 facturas')) {
                return sendError(res, HTTP_STATUS.BAD_REQUEST, error.message);
            }

            if (error.message.includes('No se pudo conectar')) {
                return sendError(res, HTTP_STATUS.SERVICE_UNAVAILABLE, error.message);
            }

            // Error del webhook (mensaje personalizado)
            const mensajeError = error.message || 'Error al procesar facturas';
            return sendError(res, HTTP_STATUS.BAD_REQUEST, mensajeError);
        }
    }
}

export const facturasController = new FacturasController();
