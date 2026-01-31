import { Router } from 'express';
import { documentosController } from '../controllers/documentos.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createDocumentoSchema, updateDocumentoSchema, documentoIdSchema } from '../schemas/documentos.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * tags:
 *   - name: Documentos
 *     description: |
 *       CRUD de documentos usando funciones PostgreSQL.
 *       
 *       ## 📋 TIPOS DE DOCUMENTO
 *       - **FACTURA**: Documento de factura, puede vincularse a un pago
 *       - **DOCUMENTO_BANCO**: Extracto bancario
 *       
 *       ## 🔗 FUNCIONES PostgreSQL
 *       - `documentos_get(id)` - Obtener todos o uno específico
 *       - `documentos_post(tipo, nombre, url, usuario_id, pago_id)` - Crear
 *       - `documentos_put(id, nombre, url)` - Actualizar
 *       - `documentos_delete(id)` - Eliminar
 */

/**
 * @swagger
 * /documentos:
 *   get:
 *     summary: Obtener todos los documentos
 *     description: |
 *       Retorna lista de todos los documentos con información del usuario que los subió
 *       y la cantidad de pagos vinculados.
 *       
 *       ## 🗄️ FUNCIÓN PostgreSQL
 *       ```sql
 *       SELECT documentos_get();
 *       ```
 *     tags: [Documentos]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de documentos
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
 *                 message:
 *                   type: string
 *                   example: "Documentos obtenidos exitosamente"
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                         example: 1
 *                       tipo_documento:
 *                         type: string
 *                         enum: [FACTURA, DOCUMENTO_BANCO]
 *                         example: "FACTURA"
 *                       nombre_archivo:
 *                         type: string
 *                         example: "factura_RES-2026-001.pdf"
 *                       url_documento:
 *                         type: string
 *                         example: "https://storage.terracanada.com/facturas/2026/01/factura.pdf"
 *                       usuario_subida:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: integer
 *                             example: 2
 *                           nombre_completo:
 *                             type: string
 *                             example: "Juan Pérez"
 *                       pagos_vinculados:
 *                         type: integer
 *                         example: 3
 *                       fecha_subida:
 *                         type: string
 *                         format: date-time
 */
router.get(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  (req, res) => documentosController.getAll(req, res)
);

/**
 * @swagger
 * /documentos/{id}:
 *   get:
 *     summary: Obtener un documento específico
 *     description: |
 *       Retorna un documento con información completa incluyendo los pagos vinculados.
 *       
 *       ## 🗄️ FUNCIÓN PostgreSQL
 *       ```sql
 *       SELECT documentos_get(1);
 *       ```
 *     tags: [Documentos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del documento
 *         example: 1
 *     responses:
 *       200:
 *         description: Documento encontrado
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
 *                 message:
 *                   type: string
 *                   example: "Documento obtenido exitosamente"
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     tipo_documento:
 *                       type: string
 *                       example: "FACTURA"
 *                     nombre_archivo:
 *                       type: string
 *                       example: "factura_RES-2026-001.pdf"
 *                     url_documento:
 *                       type: string
 *                       example: "https://storage.terracanada.com/facturas/2026/01/factura.pdf"
 *                     usuario_subida:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: integer
 *                         nombre_completo:
 *                           type: string
 *                     pagos_vinculados:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: integer
 *                           codigo_reserva:
 *                             type: string
 *                           monto:
 *                             type: number
 *                           pagado:
 *                             type: boolean
 *                           verificado:
 *                             type: boolean
 *                     fecha_subida:
 *                       type: string
 *                       format: date-time
 *       404:
 *         description: Documento no encontrado
 */
router.get(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  validate(documentoIdSchema, 'params'),
  (req, res) => documentosController.getById(req, res)
);

/**
 * @swagger
 * /documentos:
 *   post:
 *     summary: Crear un nuevo documento
 *     description: |
 *       Crea un nuevo documento en el sistema. Si se proporciona `pago_id`,
 *       se vincula automáticamente al pago especificado.
 *       
 *       ## 🗄️ FUNCIÓN PostgreSQL
 *       ```sql
 *       SELECT documentos_post(
 *         'FACTURA',
 *         'factura_RES-2026-001.pdf',
 *         'https://storage.terracanada.com/facturas/2026/01/factura.pdf',
 *         2,   -- usuario_id
 *         10   -- pago_id (opcional)
 *       );
 *       ```
 *       
 *       ## ⚠️ VALIDACIONES
 *       - El usuario debe existir
 *       - Si se proporciona pago_id, el pago debe existir
 *     tags: [Documentos]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - tipo_documento
 *               - nombre_archivo
 *               - url_documento
 *               - usuario_id
 *             properties:
 *               tipo_documento:
 *                 type: string
 *                 enum: [FACTURA, DOCUMENTO_BANCO]
 *                 description: Tipo de documento
 *                 example: "FACTURA"
 *               nombre_archivo:
 *                 type: string
 *                 description: Nombre del archivo
 *                 example: "factura_RES-2026-001.pdf"
 *               url_documento:
 *                 type: string
 *                 description: URL donde está almacenado el documento
 *                 example: "https://storage.terracanada.com/facturas/2026/01/factura.pdf"
 *               usuario_id:
 *                 type: integer
 *                 description: ID del usuario que sube el documento
 *                 example: 2
 *               pago_id:
 *                 type: integer
 *                 description: ID del pago a vincular (opcional)
 *                 example: 10
 *           examples:
 *             factura_con_pago:
 *               summary: Factura vinculada a pago
 *               value:
 *                 tipo_documento: "FACTURA"
 *                 nombre_archivo: "factura_RES-2026-001.pdf"
 *                 url_documento: "https://storage.terracanada.com/facturas/factura.pdf"
 *                 usuario_id: 2
 *                 pago_id: 10
 *             documento_banco:
 *               summary: Documento de banco sin vincular
 *               value:
 *                 tipo_documento: "DOCUMENTO_BANCO"
 *                 nombre_archivo: "extracto_enero_2026.pdf"
 *                 url_documento: "https://storage.terracanada.com/banco/extracto.pdf"
 *                 usuario_id: 2
 *     responses:
 *       201:
 *         description: Documento creado exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Usuario o pago no encontrado
 */
router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(createDocumentoSchema),
  auditMiddleware(TipoEvento.CREAR, 'documentos'),
  (req, res) => documentosController.create(req, res)
);

/**
 * @swagger
 * /documentos/{id}:
 *   put:
 *     summary: Actualizar un documento
 *     description: |
 *       Actualiza el nombre o URL de un documento existente.
 *       Solo se actualizan los campos proporcionados.
 *       
 *       ## 🗄️ FUNCIÓN PostgreSQL
 *       ```sql
 *       SELECT documentos_put(
 *         1,                      -- id
 *         'nuevo_nombre.pdf',     -- nombre_archivo (opcional)
 *         'https://nueva.url/...' -- url_documento (opcional)
 *       );
 *       ```
 *     tags: [Documentos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del documento
 *         example: 1
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre_archivo:
 *                 type: string
 *                 description: Nuevo nombre del archivo
 *                 example: "factura_actualizada.pdf"
 *               url_documento:
 *                 type: string
 *                 description: Nueva URL del documento
 *                 example: "https://storage.terracanada.com/nueva_url/factura.pdf"
 *           examples:
 *             cambiar_nombre:
 *               summary: Cambiar solo nombre
 *               value:
 *                 nombre_archivo: "factura_corregida.pdf"
 *             cambiar_url:
 *               summary: Cambiar solo URL
 *               value:
 *                 url_documento: "https://nueva.url/documento.pdf"
 *             cambiar_ambos:
 *               summary: Cambiar ambos campos
 *               value:
 *                 nombre_archivo: "nuevo_nombre.pdf"
 *                 url_documento: "https://nueva.url/documento.pdf"
 *     responses:
 *       200:
 *         description: Documento actualizado exitosamente
 *       400:
 *         description: Debe proporcionar al menos un campo
 *       404:
 *         description: Documento no encontrado
 */
router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(documentoIdSchema, 'params'),
  validate(updateDocumentoSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'documentos'),
  (req, res) => documentosController.update(req, res)
);

/**
 * @swagger
 * /documentos/{id}:
 *   delete:
 *     summary: Eliminar un documento
 *     description: |
 *       Elimina un documento y sus vinculaciones con pagos.
 *       
 *       ## 🗄️ FUNCIÓN PostgreSQL
 *       ```sql
 *       SELECT documentos_delete(1);
 *       ```
 *       
 *       ## ⚠️ RESTRICCIONES
 *       - No se puede eliminar si tiene pagos VERIFICADOS vinculados
 *       - Se eliminan automáticamente las vinculaciones con pagos no verificados
 *     tags: [Documentos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del documento
 *         example: 1
 *     responses:
 *       200:
 *         description: Documento eliminado exitosamente
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
 *                 message:
 *                   type: string
 *                   example: "Documento eliminado exitosamente"
 *                 data:
 *                   type: object
 *                   properties:
 *                     nombre_archivo:
 *                       type: string
 *                       example: "factura_eliminada.pdf"
 *       404:
 *         description: Documento no encontrado
 *       409:
 *         description: No se puede eliminar, tiene pagos verificados vinculados
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(documentoIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'documentos'),
  (req, res) => documentosController.delete(req, res)
);

export default router;
