import { Router } from 'express';
import { pagosController } from '../controllers/pagos.controller';
import { documentosPagoController } from '../controllers/documentos-pago.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createPagoSchema, updatePagoSchema, pagoIdSchema } from '../schemas/pagos.schema';
import { documentoEstadoSchema, subirFacturasSchema, subirExtractoBancoSchema } from '../schemas/documentos-pago.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();



/**
 * @swagger
 * /pagos:
 *   get:
 *     summary: Listar pagos con filtros
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: proveedor_id
 *         schema:
 *           type: integer
 *       - in: query
 *         name: estado
 *         schema:
 *           type: string
 *           enum: [PENDIENTE, COMPLETADO, CANCELADO]
 *       - in: query
 *         name: fecha_desde
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: fecha_hasta
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Lista de pagos
 */
router.get('/', authMiddleware, (req, res) => pagosController.getPagos(req, res));

/**
 * @swagger
 * /pagos/{id}:
 *   get:
 *     summary: Obtener un pago por ID
 *     description: Obtiene la información detallada de un pago específico con relaciones
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del pago
 *     responses:
 *       200:
 *         description: Pago encontrado
 *       404:
 *         description: Pago no encontrado
 *       401:
 *         description: No autenticado
 */
router.get('/:id', authMiddleware, validate(pagoIdSchema, 'params'), (req, res) => pagosController.getPagos(req, res));

/**
 * @swagger
 * /pagos:
 *   post:
 *     summary: Crear nuevo pago
 *     description: Crea un pago usando funciones PostgreSQL. Descuenta automáticamente el saldo si es TARJETA.
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - proveedor_id
 *               - usuario_id
 *               - codigo_reserva
 *               - monto
 *               - moneda
 *               - tipo_medio_pago
 *             properties:
 *               proveedor_id:
 *                 type: integer
 *                 example: 2
 *                 description: ID del proveedor activo
 *               usuario_id:
 *                 type: integer
 *                 example: 2
 *                 description: ID del usuario activo
 *               codigo_reserva:
 *                 type: string
 *                 example: "RES-2026-004"
 *                 description: Código único de reserva (1-50 caracteres)
 *               monto:
 *                 type: number
 *                 example: 500.00
 *                 description: Monto del pago (mayor a 0)
 *               moneda:
 *                 type: string
 *                 enum: [USD, CAD]
 *                 example: "USD"
 *                 description: Moneda del pago
 *               tipo_medio_pago:
 *                 type: string
 *                 enum: [TARJETA, CUENTA_BANCARIA]
 *                 example: "TARJETA"
 *                 description: Tipo de medio de pago
 *               tarjeta_id:
 *                 type: integer
 *                 example: 1
 *                 nullable: true
 *                 description: ID de tarjeta (obligatorio si tipo_medio_pago = TARJETA)
 *               cuenta_bancaria_id:
 *                 type: integer
 *                 example: 1
 *                 nullable: true
 *                 description: ID de cuenta bancaria (obligatorio si tipo_medio_pago = CUENTA_BANCARIA)
 *               clientes_ids:
 *                 type: array
 *                 items:
 *                   type: integer
 *                 example: [1, 2]
 *                 description: Array de IDs de clientes asociados
 *               descripcion:
 *                 type: string
 *                 example: "Pago de servicio de guía turística"
 *                 nullable: true
 *               fecha_esperada_debito:
 *                 type: string
 *                 format: date
 *                 example: "2026-02-15"
 *                 nullable: true
 *                 description: Fecha esperada de débito (YYYY-MM-DD)
 *     responses:
 *       201:
 *         description: Pago creado exitosamente
 *       400:
 *         description: Datos inválidos o campo obligatorio faltante
 *       409:
 *         description: Código de reserva duplicado o saldo insuficiente
 *       404:
 *         description: Proveedor, usuario, tarjeta o cuenta no encontrados
 */
router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  validate(createPagoSchema),
  auditMiddleware(TipoEvento.CREAR, 'pagos'),
  (req, res) => pagosController.createPago(req, res)
);

/**
 * @swagger
 * /pagos/{id}:
 *   put:
 *     summary: Actualizar un pago existente
 *     description: Actualiza un pago usando funciones PostgreSQL. No se puede editar si ya está verificado.
 *     tags: [Pagos]
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
 *             properties:
 *               monto:
 *                 type: number
 *                 example: 600.00
 *                 description: Nuevo monto (NO se puede cambiar si es pago con tarjeta)
 *               descripcion:
 *                 type: string
 *                 example: "Descripción actualizada"
 *                 nullable: true
 *               fecha_esperada_debito:
 *                 type: string
 *                 format: date
 *                 example: "2026-03-01"
 *                 nullable: true
 *               pagado:
 *                 type: boolean
 *                 example: true
 *                 description: Marcar como pagado
 *               verificado:
 *                 type: boolean
 *                 example: true
 *                 description: Marcar como verificado (auto-marca pagado = true)
 *               gmail_enviado:
 *                 type: boolean
 *                 example: false
 *               activo:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: Pago actualizado exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Pago no encontrado
 *       409:
 *         description: No se puede editar (ya verificado o intento de cambiar monto con tarjeta)
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(pagoIdSchema, 'params'),
  validate(updatePagoSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'pagos'),
  (req, res) => pagosController.updatePago(req, res)
);

/**
 * @swagger
 * /pagos/{id}:
 *   delete:
 *     summary: Cancelar un pago
 *     description: Cambia el estado del pago a CANCELADO (no se elimina físicamente)
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del pago
 *     responses:
 *       200:
 *         description: Pago cancelado exitosamente
 *       404:
 *         description: Pago no encontrado
 *       409:
 *         description: No se puede cancelar un pago ya completado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(pagoIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'pagos'),
  (req, res) => pagosController.deletePago(req, res)
);

/**
 * @swagger
 * /pagos/{id}/desactivar:
 *   patch:
 *     summary: Desactivar un pago
 *     description: Cambia el estado activo del pago a false (soft delete). El pago no se elimina, solo se desactiva.
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del pago a desactivar
 *     responses:
 *       200:
 *         description: Pago desactivado exitosamente
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
 *                   example: "Pago desactivado exitosamente"
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     estados:
 *                       type: object
 *                       properties:
 *                         activo:
 *                           type: boolean
 *                           example: false
 *       404:
 *         description: Pago no encontrado
 *       409:
 *         description: No se puede desactivar (ya verificado)
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.patch(
  '/:id/desactivar',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(pagoIdSchema, 'params'),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'pagos'),
  (req, res) => pagosController.desactivarPago(req, res)
);

/**
 * @swagger
 * /pagos/{id}/activar:
 *   patch:
 *     summary: Activar un pago
 *     description: Cambia el estado activo del pago a true. Reactiva un pago previamente desactivado.
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del pago a activar
 *     responses:
 *       200:
 *         description: Pago activado exitosamente
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
 *                   example: "Pago activado exitosamente"
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     estados:
 *                       type: object
 *                       properties:
 *                         activo:
 *                           type: boolean
 *                           example: true
 *       404:
 *         description: Pago no encontrado
 *       409:
 *         description: No se puede activar (ya verificado)
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.patch(
  '/:id/activar',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(pagoIdSchema, 'params'),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'pagos'),
  (req, res) => pagosController.activarPago(req, res)
);

/**
 * @swagger
 * /pagos/{id}/con-pdf:
 *   put:
 *     summary: Actualizar estado/verificado de un pago con PDF adjunto
 *     description: |
 *       Solo para ADMIN. Permite editar estado y verificado de un pago adjuntando un PDF.
 *       El PDF se envía a N8N para procesamiento/almacenamiento.
 *       La actualización en BD solo ocurre si N8N responde exitosamente.
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - archivo
 *             properties:
 *               estado:
 *                 type: string
 *                 enum: [PENDIENTE, PAGADO, CANCELADO]
 *               verificado:
 *                 type: boolean
 *               archivo:
 *                 type: object
 *                 required:
 *                   - nombre
 *                   - tipo
 *                   - base64
 *                 properties:
 *                   nombre:
 *                     type: string
 *                     example: "comprobante_123.pdf"
 *                   tipo:
 *                     type: string
 *                     example: "application/pdf"
 *                   base64:
 *                     type: string
 *                     description: Contenido del PDF en base64
 *     responses:
 *       200:
 *         description: Pago actualizado exitosamente
 *       400:
 *         description: Datos inválidos o error del servicio
 *       404:
 *         description: Pago no encontrado
 *       503:
 *         description: Servicio de procesamiento no disponible
 */
// NOTA: Esta ruta está comentada temporalmente hasta reimplementar updateConPDF
// router.put(
//   '/:id/con-pdf',
//   authMiddleware,
//   requireRole(RolNombre.ADMIN),
//   validate(pagoIdSchema, 'params'),
//   auditMiddleware(TipoEvento.ACTUALIZAR, 'pagos'),
//   (req, res) => pagosController.updateConPDF(req, res)
// );

/**
 * @swagger
 * /pagos/documento-estado:
 *   post:
 *     summary: Enviar documento de pago al webhook
 *     description: |
 *       ## 📋 FLUJO
 *       1. Front envía: { pdf, id_pago, usuario_id }
 *       2. Back obtiene datos del pago (incluyendo codigo_reserva)
 *       3. Back envía al webhook: { pdf, id_pago, codigo_reserva, usuario_id }
 *       4. Webhook responde: { codigo, mensaje }
 *       5. Back retorna esa respuesta EXACTA al front
 *       
 *       ## 🔗 WEBHOOK
 *       URL: `https://n8n.salazargroup.cloud/webhook/documento_pago`
 *       
 *       ## 📤 PAYLOAD QUE RECIBE EL WEBHOOK
 *       ```json
 *       {
 *         "pdf": "base64...",
 *         "id_pago": 2,
 *         "codigo_reserva": "23445634",
 *         "usuario_id": 5
 *       }
 *       ```
 *       
 *       ## 📥 RESPUESTA DEL WEBHOOK (se retorna al front)
 *       ```json
 *       {
 *         "codigo": "200",
 *         "mensaje": "el codigo de reserva fue encontrado"
 *       }
 *       ```
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - pdf
 *               - id_pago
 *               - usuario_id
 *             properties:
 *               pdf:
 *                 type: string
 *                 description: PDF del documento en base64
 *                 example: "JVBERi0xLjQKJeLjz9MKMSAwIG9..."
 *               id_pago:
 *                 type: integer
 *                 description: ID del pago
 *                 example: 2
 *               usuario_id:
 *                 type: integer
 *                 description: ID del usuario que realiza la acción
 *                 example: 5
 *     responses:
 *       200:
 *         description: Webhook procesó correctamente el documento
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 codigo:
 *                   type: string
 *                   example: "200"
 *                 mensaje:
 *                   type: string
 *                   example: "el codigo de reserva fue encontrado"
 *       400:
 *         description: Error del webhook
 *       404:
 *         description: Pago no encontrado
 */
router.post(
  '/documento-estado',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(documentoEstadoSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'pagos'),
  (req, res) => documentosPagoController.enviarDocumentoEstado(req, res)
);

/**
 * @swagger
 * /pagos/subir-facturas:
 *   post:
 *     summary: Subir múltiples facturas (hasta 3 PDFs)
 *     description: |
 *       ## 📋 FLUJO
 *       1. Front envía: { modulo: "factura", usuario_id, facturas: [{pdf, proveedor_id}] }
 *       2. Back envía al webhook: { modulo: "factura", usuario_id, facturas: [...] }
 *       3. Webhook procesa los PDFs y extrae códigos
 *       4. Webhook responde: { codigo, codigos_reserva: [...] }
 *       5. Back retorna esa respuesta EXACTA al front
 *       
 *       ## 🔗 WEBHOOK
 *       URL: `https://n8n.salazargroup.cloud/webhook/docu`
 *       
 *       ## 📤 PAYLOAD QUE RECIBE EL WEBHOOK
 *       ```json
 *       {
 *         "modulo": "factura",
 *         "usuario_id": 5,
 *         "facturas": [
 *           { "pdf": "base64...", "proveedor_id": 2 },
 *           { "pdf": "base64...", "proveedor_id": 3 }
 *         ]
 *       }
 *       ```
 *       
 *       ## 📥 RESPUESTA DEL WEBHOOK (se retorna al front)
 *       ```json
 *       {
 *         "codigo": 200,
 *         "codigos_reserva": [324, 234234]
 *       }
 *       ```
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - usuario_id
 *               - facturas
 *             properties:
 *               modulo:
 *                 type: string
 *                 enum: [factura]
 *                 description: Tipo de módulo (opcional, default "factura")
 *                 example: "factura"
 *               usuario_id:
 *                 type: integer
 *                 description: ID del usuario que realiza la acción
 *                 example: 5
 *               facturas:
 *                 type: array
 *                 minItems: 1
 *                 maxItems: 3
 *                 items:
 *                   type: object
 *                   required:
 *                     - pdf
 *                     - proveedor_id
 *                   properties:
 *                     pdf:
 *                       type: string
 *                       description: PDF de la factura en base64
 *                       example: "JVBERi0xLjQK..."
 *                     proveedor_id:
 *                       type: integer
 *                       description: ID del proveedor asociado
 *                       example: 2
 *     responses:
 *       200:
 *         description: Facturas procesadas exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 codigo:
 *                   type: integer
 *                   example: 200
 *                 codigos_reserva:
 *                   type: array
 *                   items:
 *                     type: integer
 *                   example: [324, 234234]
 *       400:
 *         description: Error al procesar las facturas
 */
router.post(
  '/subir-facturas',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  validate(subirFacturasSchema),
  auditMiddleware(TipoEvento.CREAR, 'documentos'),
  (req, res) => documentosPagoController.subirFacturas(req, res)
);

/**
 * @swagger
 * /pagos/subir-extracto-banco:
 *   post:
 *     summary: Subir extracto de banco (1 PDF)
 *     description: |
 *       ## 📋 FLUJO
 *       1. Front envía: { pdf, usuario_id }
 *       2. Back envía al webhook: { modulo: "Banco", pdf, usuario_id }
 *       3. Webhook procesa el PDF y extrae códigos
 *       4. Webhook responde: { codigo, codigos_reserva: [...] }
 *       5. Back retorna esa respuesta EXACTA al front
 *       
 *       ## 🔗 WEBHOOK
 *       URL: `https://n8n.salazargroup.cloud/webhook/docu`
 *       
 *       ## 📤 PAYLOAD QUE RECIBE EL WEBHOOK
 *       ```json
 *       {
 *         "modulo": "Banco",
 *         "pdf": "base64...",
 *         "usuario_id": 5
 *       }
 *       ```
 *       
 *       ## 📥 RESPUESTA DEL WEBHOOK (se retorna al front)
 *       ```json
 *       {
 *         "codigo": 200,
 *         "codigos_reserva": [213423, 23423, 234234]
 *       }
 *       ```
 *     tags: [Pagos]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - pdf
 *               - usuario_id
 *             properties:
 *               pdf:
 *                 type: string
 *                 description: PDF del extracto bancario en base64
 *                 example: "JVBERi0xLjQK..."
 *               usuario_id:
 *                 type: integer
 *                 description: ID del usuario que realiza la acción
 *                 example: 5
 *     responses:
 *       200:
 *         description: Extracto procesado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 codigo:
 *                   type: integer
 *                   example: 200
 *                 codigos_reserva:
 *                   type: array
 *                   items:
 *                     type: integer
 *                   example: [213423, 23423, 234234]
 *       400:
 *         description: Error al procesar el extracto
 */
router.post(
  '/subir-extracto-banco',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  validate(subirExtractoBancoSchema),
  auditMiddleware(TipoEvento.CREAR, 'documentos'),
  (req, res) => documentosPagoController.subirExtractoBanco(req, res)
);

export default router;
