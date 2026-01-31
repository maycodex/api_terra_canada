import { Router } from 'express';
import { webhooksController } from '../controllers/webhooks.controller';
import { validate } from '../middlewares/validate.middleware';
import { webhookN8NDocumentoSchema } from '../schemas/webhooks.schema';

const router = Router();

/**
 * @swagger
 * tags:
 *   - name: Webhooks
 *     description: Webhooks entrantes para recibir notificaciones de servicios externos
 */

/**
 * @swagger
 * /webhooks/n8n/documento-procesado:
 *   post:
 *     summary: Recibir notificación de N8N tras procesar documento
 *     description: |
 *       Endpoint para que N8N notifique cuando termina de procesar un documento.
 *       - OCR extrae códigos de reserva del PDF
 *       - Actualiza automáticamente los pagos encontrados (estado=PAGADO, verificado=TRUE)
 *       - Vincula el documento con los pagos
 *       - Registra códigos no encontrados para revisión manual
 *     tags: [Webhooks]
 *     security:
 *       - n8nToken: []
 *     parameters:
 *       - in: header
 *         name: x-n8n-token
 *         required: true
 *         schema:
 *           type: string
 *         description: Token de autenticación N8N (configurado en .env)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - documento_id
 *               - tipo_procesamiento
 *               - exito
 *               - timestamp
 *             properties:
 *               documento_id:
 *                 type: integer
 *                 example: 123
 *                 description: ID del documento procesado
 *               tipo_procesamiento:
 *                 type: string
 *                 enum: [FACTURA, DOCUMENTO_BANCO]
 *                 example: "FACTURA"
 *               exito:
 *                 type: boolean
 *                 example: true
 *                 description: Si el procesamiento OCR fue exitoso
 *               mensaje:
 *                 type: string
 *                 example: "OCR completado exitosamente"
 *                 description: Mensaje informativo del procesamiento
 *               codigos_encontrados:
 *                 type: array
 *                 description: Lista de códigos de reserva extraídos del documento
 *                 items:
 *                   type: object
 *                   properties:
 *                     codigo_reserva:
 *                       type: string
 *                       example: "AC12345"
 *                     encontrado:
 *                       type: boolean
 *                       example: true
 *                     pago_id:
 *                       type: integer
 *                       example: 501
 *                       description: ID del pago encontrado (opcional)
 *                     observaciones:
 *                       type: string
 *                       example: "Código encontrado en línea 5"
 *               codigos_no_encontrados:
 *                 type: array
 *                 description: Códigos extraídos que no coinciden con ningún pago
 *                 items:
 *                   type: string
 *                 example: ["XYZ999", "ABC000"]
 *               timestamp:
 *                 type: string
 *                 format: date-time
 *                 example: "2026-01-30T04:30:15.234Z"
 *                 description: Fecha/hora del procesamiento
 *     responses:
 *       200:
 *         description: Webhook procesado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Webhook procesado exitosamente"
 *                 data:
 *                   type: object
 *                   properties:
 *                     pagos_actualizados:
 *                       type: integer
 *                       example: 3
 *                       description: Cantidad de pagos actualizados
 *                     pagos_encontrados:
 *                       type: array
 *                       items:
 *                         type: integer
 *                       example: [501, 502, 503]
 *                       description: IDs de los pagos actualizados
 *                     codigos_no_encontrados:
 *                       type: array
 *                       items:
 *                         type: string
 *                       example: ["XYZ999"]
 *                       description: Códigos que no se encontraron en la BD
 *                     errores:
 *                       type: array
 *                       items:
 *                         type: string
 *                       example: []
 *       400:
 *         description: Datos inválidos en el webhook
 *       401:
 *         description: Token N8N no proporcionado
 *       403:
 *         description: Token N8N inválido
 *       500:
 *         description: Error al procesar webhook
 */
router.post(
    '/n8n/documento-procesado',
    validate(webhookN8NDocumentoSchema),
    (req, res, next) => webhooksController.documentoProcesadoN8N(req, res, next)
);

/**
 * @swagger
 * components:
 *   securitySchemes:
 *     n8nToken:
 *       type: apiKey
 *       in: header
 *       name: x-n8n-token
 *       description: Token de autenticación para webhooks de N8N
 */

export default router;
