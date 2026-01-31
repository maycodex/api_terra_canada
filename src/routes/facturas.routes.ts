import { Router } from 'express';
import { facturasController } from '../controllers/facturas.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { auditMiddleware } from '../middlewares/audit.middleware';
import { RolNombre, TipoEvento } from '../types/enums';

const router = Router();

/**
 * @swagger
 * /facturas/procesar:
 *   post:
 *     summary: Procesar facturas enviando PDFs en base64 a N8N
 *     description: |
 *       Envía hasta 5 facturas en formato PDF (base64) a N8N para procesamiento OCR.
 *       N8N extrae códigos de reserva y retorna los pagos encontrados.
 *     tags: [Facturas]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - archivos
 *             properties:
 *               archivos:
 *                 type: array
 *                 minItems: 1
 *                 maxItems: 5
 *                 items:
 *                   type: object
 *                   required:
 *                     - nombre
 *                     - tipo
 *                     - base64
 *                   properties:
 *                     nombre:
 *                       type: string
 *                       example: "NA - 39331961285.2025-01-31.pdf"
 *                     tipo:
 *                       type: string
 *                       example: "application/pdf"
 *                     base64:
 *                       type: string
 *                       description: Contenido del PDF en base64
 *     responses:
 *       200:
 *         description: Facturas procesadas exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 estado:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Pagos encontrados"
 *                 data:
 *                   type: object
 *                   properties:
 *                     pagos_encontrados:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           cod:
 *                             type: integer
 *                     total:
 *                       type: integer
 *       400:
 *         description: Error al procesar facturas
 *       503:
 *         description: Servicio de procesamiento no disponible
 */
router.post(
    '/procesar',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
    auditMiddleware(TipoEvento.SUBIR_DOCUMENTO, 'facturas'),
    (req, res, next) => facturasController.procesar(req, res, next)
);

export default router;
