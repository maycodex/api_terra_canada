import { Router } from 'express';
import { documentosPagoController } from '../controllers/documentos-pago.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { cambiarEstadoConPDFSchema } from '../schemas/documentos-pago.schema';
import { pagoIdSchema } from '../schemas/pagos.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();


/**
 * @swagger
 * tags:
 *   - name: Documentos Pago
 *     description: |
 *       Endpoints para procesar documentos (PDFs) con webhooks de N8N.
 *       
 *       ## 📋 FLUJO GENERAL
 *       1. El Frontend envía un PDF (base64) al endpoint
 *       2. El Backend obtiene los datos necesarios y los envía al webhook de N8N
 *       3. N8N procesa el documento y responde con código 200 o 400
 *       4. El Backend retorna la respuesta del webhook al Frontend
 *       5. El Frontend usa pagos_put() para actualizar el estado (si aplica)
 *       
 *       ## 🔗 WEBHOOKS
 *       - documento_pago: https://n8n.salazargroup.cloud/webhook/documento_pago
 *       - docu (facturas/banco): https://n8n.salazargroup.cloud/webhook/docu
 */

/**
 * @swagger
 * /pagos/{id}/documento-estado:
 *   post:
 *     summary: Enviar documento para cambiar estado de pago
 *     description: |
 *       ## 📋 FLUJO
 *       1. Front envía: id_pago, pdf (base64), y qué estado cambiar
 *       2. Back obtiene TODOS los datos del pago
 *       3. Back envía al webhook: `https://n8n.salazargroup.cloud/webhook/documento_pago`
 *       4. Webhook responde 200 o 400 con data adicional
 *       5. Back retorna esa respuesta EXACTA al front
 *       6. El webhook de N8N es quien usa `pagos_put()` para cambiar el estado
 *       
 *       ## ⚠️ VALIDACIONES
 *       - No se puede verificar si el pago NO está marcado como pagado
 *       - Solo se puede especificar UNO: cambiar_pagado O cambiar_verificado
 *       
 *       ## 📤 PAYLOAD QUE RECIBE EL WEBHOOK
 *       ```json
 *       {
 *         "pago": { ...todos los datos del pago... },
 *         "pdf": "base64...",
 *         "accion": "MARCAR_PAGADO" | "MARCAR_VERIFICADO",
 *         "cambiar_pagado": true/false,
 *         "cambiar_verificado": true/false,
 *         "timestamp": "2026-01-30T21:00:00Z"
 *       }
 *       ```
 *     tags: [Documentos Pago]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del pago
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - pdf
 *             properties:
 *               pdf:
 *                 type: string
 *                 description: PDF del documento en base64
 *                 example: "JVBERi0xLjQKJeLjz9MKMSAwIG9..."
 *               cambiar_pagado:
 *                 type: boolean
 *                 description: Si se quiere marcar el pago como PAGADO
 *                 example: true
 *               cambiar_verificado:
 *                 type: boolean
 *                 description: Si se quiere marcar el pago como VERIFICADO (requiere que ya esté pagado)
 *                 example: false
 *           examples:
 *             marcar_pagado:
 *               summary: Marcar como pagado
 *               value:
 *                 pdf: "JVBERi0xLjQK..."
 *                 cambiar_pagado: true
 *             marcar_verificado:
 *               summary: Marcar como verificado
 *               value:
 *                 pdf: "JVBERi0xLjQK..."
 *                 cambiar_verificado: true
 *     responses:
 *       200:
 *         description: Webhook procesó correctamente el documento
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 mensaje:
 *                   type: string
 *                   example: "Documento procesado correctamente"
 *                 codigo_generado:
 *                   type: string
 *                   example: "DOC-2026-ABC123"
 *                 data:
 *                   type: object
 *                   description: Data adicional del webhook
 *       400:
 *         description: Error del webhook al procesar el documento
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 code:
 *                   type: integer
 *                   example: 400
 *                 mensaje:
 *                   type: string
 *                   example: "Error al procesar el documento"
 *       404:
 *         description: Pago no encontrado
 *       409:
 *         description: No se puede verificar un pago que no está pagado
 */
router.post(
  '/:id/documento-estado',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(pagoIdSchema, 'params'),
  validate(cambiarEstadoConPDFSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'pagos'),
  (req, res) => documentosPagoController.enviarDocumentoEstado(req, res)
);

export default router;
