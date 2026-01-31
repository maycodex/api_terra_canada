import { query, getClient } from '../config/database';
import logger from '../config/logger';
import { WebhookN8NDocumentoInput } from '../schemas/webhooks.schema';

export class WebhooksService {
    /**
     * Procesar webhook de N8N cuando termina de procesar un documento
     * Actualiza estados de pagos según códigos encontrados
     */
    async procesarDocumentoN8N(data: WebhookN8NDocumentoInput) {
        const client = await getClient();

        try {
            await client.query('BEGIN');

            logger.info(`Procesando webhook N8N para documento ${data.documento_id}`, {
                tipo: data.tipo_procesamiento,
                exito: data.exito,
                codigosEncontrados: data.codigos_encontrados?.length || 0
            });

            // Actualizar estado del documento
            await client.query(
                `UPDATE documentos SET 
         estado_procesamiento = $1,
         fecha_procesamiento = NOW()
         WHERE id = $2`,
                [data.exito ? 'COMPLETADO' : 'ERROR', data.documento_id]
            );

            const resultados = {
                pagos_actualizados: 0,
                pagos_encontrados: [] as number[],
                codigos_no_encontrados: data.codigos_no_encontrados || [],
                errores: [] as string[]
            };

            // Procesar códigos encontrados
            if (data.exito && data.codigos_encontrados && data.codigos_encontrados.length > 0) {
                for (const codigo of data.codigos_encontrados) {
                    try {
                        // Buscar pago por código de reserva
                        const pagoResult = await client.query(
                            `SELECT id, estado, verificado FROM pagos 
               WHERE codigo_reserva = $1 
               AND estado != 'CANCELADO'
               LIMIT 1`,
                            [codigo.codigo_reserva]
                        );

                        if (pagoResult.rows.length > 0) {
                            const pago = pagoResult.rows[0];

                            // Actualizar pago: marcar como pagado y verificado
                            await client.query(
                                `UPDATE pagos SET 
                 pagado = TRUE,
                 verificado = TRUE,
                 estado = 'PAGADO',
                 documento_id = $1
                 WHERE id = $2`,
                                [data.documento_id, pago.id]
                            );

                            resultados.pagos_actualizados++;
                            resultados.pagos_encontrados.push(pago.id);

                            logger.info(`Pago ${pago.id} actualizado por webhook N8N`, {
                                codigo_reserva: codigo.codigo_reserva,
                                documento_id: data.documento_id
                            });
                        } else {
                            // Código no encontrado en BD
                            resultados.codigos_no_encontrados.push(codigo.codigo_reserva);

                            logger.warn(`Código de reserva no encontrado: ${codigo.codigo_reserva}`, {
                                documento_id: data.documento_id
                            });
                        }
                    } catch (error: any) {
                        logger.error(`Error procesando código ${codigo.codigo_reserva}`, error);
                        resultados.errores.push(`Error en ${codigo.codigo_reserva}: ${error.message}`);
                    }
                }
            }

            // Registrar en tabla de auditoría si hay códigos no encontrados
            if (resultados.codigos_no_encontrados.length > 0) {
                await client.query(
                    `INSERT INTO eventos_auditoria 
           (tipo_evento, tabla_afectada, datos_adicionales, usuario_id)
           VALUES ($1, $2, $3, $4)`,
                    [
                        'CODIGOS_NO_ENCONTRADOS',
                        'documentos',
                        JSON.stringify({
                            documento_id: data.documento_id,
                            codigos: resultados.codigos_no_encontrados
                        }),
                        null // Sistema
                    ]
                );
            }

            await client.query('COMMIT');

            logger.info(`Webhook N8N procesado exitosamente`, {
                documento_id: data.documento_id,
                pagos_actualizados: resultados.pagos_actualizados,
                codigos_no_encontrados: resultados.codigos_no_encontrados.length
            });

            return resultados;
        } catch (error) {
            await client.query('ROLLBACK');
            logger.error('Error al procesar webhook N8N:', error);
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Verificar token N8N
     */
    validateN8NToken(token: string): boolean {
        const validToken = process.env.N8N_WEBHOOK_TOKEN || 'default-n8n-token';
        return token === validToken;
    }
}

export const webhooksService = new WebhooksService();
