import { Router } from 'express';
import { correosController } from '../controllers/correos.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { auditMiddleware } from '../middlewares/audit.middleware';
import { validate } from '../middlewares/validate.middleware';
import {
    generarCorreosSchema,
    createCorreoSchema,
    updateCorreoSchema,
    enviarCorreoSchema,
    correoIdSchema
} from '../schemas/correos.schema';
import { RolNombre, TipoEvento } from '../types/enums';

const router = Router();

/**
 * @swagger
 * /correos:
 *   get:
 *     summary: Listar correos con filtros opcionales
 *     tags: [Correos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: estado
 *         schema:
 *           type: string
 *           enum: [BORRADOR, ENVIADO]
 *       - in: query
 *         name: proveedor_id
 *         schema:
 *           type: integer
 *       - in: query
 *         name: fecha_desde
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: fecha_hasta
 *         schema:
 *           type: string
 *           format: date-time
 *     responses:
 *       200:
 *         description: Lista de correos
 */
router.get(
    '/',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
    (req, res, next) => correosController.getAll(req, res, next)
);

/**
 * @swagger
 * /correos/pendientes:
 *   get:
 *     summary: Obtener correos pendientes de envío (BORRADOR)
 *     tags: [Correos]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de correos pendientes
 */
router.get(
    '/pendientes',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
    (req, res, next) => correosController.getPendientes(req, res, next)
);

/**
 * @ swagger
 * /correos/{id}:
 *   get:
 *     summary: Obtener un correo por ID
 *     tags: [Correos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Correo encontrado
 *       404:
 *         description: Correo no encontrado
 */
router.get(
    '/:id',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
    validate(correoIdSchema, 'params'),
    (req, res, next) => correosController.getById(req, res, next)
);

/**
 * @swagger
 * /correos/generar:
 *   post:
 *     summary: Generar correos automáticamente para pagos pendientes
 *     description: |
 *       Busca todos los pagos con pagado=TRUE y gmail_enviado=FALSE,
 *       los agrupa por proveedor y genera un borrador de correo por cada proveedor.
 *     tags: [Correos]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               proveedor_id:
 *                 type: integer
 *                 description: Opcionalmente filtrar por un proveedor específico
 *     responses:
 *       201:
 *         description: Correos generados exitosamente
 *       200:
 *         description: No hay pagos pendientes de envío
 */
router.post(
    '/generar',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
    validate(generarCorreosSchema),
    auditMiddleware(TipoEvento.CREAR, 'correos'),
    (req, res, next) => correosController.generar(req, res, next)
);

/**
 * @swagger
 * /correos:
 *   post:
 *     summary: Crear un correo manualmente
 *     description: Permite crear un correo seleccionando manualmente los pagos a incluir
 *     tags: [Correos]
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
 *               - correo_seleccionado
 *               - asunto
 *               - cuerpo
 *               - pago_ids
 *             properties:
 *               proveedor_id:
 *                 type: integer
 *               correo_seleccionado:
 *                 type: string
 *                 format: email
 *                 description: Uno de los correos del proveedor
 *               asunto:
 *                 type: string
 *               cuerpo:
 *                 type: string
 *               pago_ids:
 *                 type: array
 *                 items:
 *                   type: integer
 *     responses:
 *       201:
 *         description: Correo creado exitosamente
 *       400:
 *         description: Datos inválidos
 */
router.post(
    '/',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
    validate(createCorreoSchema),
    auditMiddleware(TipoEvento.CREAR, 'correos'),
    (req, res, next) => correosController.create(req, res, next)
);

/**
 * @swagger
 * /correos/{id}:
 *   put:
 *     summary: Actualizar un borrador de correo
 *     description: Solo se pueden editar correos en estado BORRADOR
 *     tags: [Correos]
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
 *             properties:
 *               correo_seleccionado:
 *                 type: string
 *                 format: email
 *               asunto:
 *                 type: string
 *               cuerpo:
 *                 type: string
 *     responses:
 *       200:
 *         description: Correo actualizado exitosamente
 *       404:
 *         description: Correo no encontrado
 *       409:
 *         description: El correo ya fue enviado
 */
router.put(
    '/:id',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
    validate(correoIdSchema, 'params'),
    validate(updateCorreoSchema),
    auditMiddleware(TipoEvento.ACTUALIZAR, 'correos'),
    (req, res, next) => correosController.update(req, res, next)
);

/**
 * @swagger
 * /correos/{id}/enviar:
 *   post:
 *     summary: Enviar un correo
 *     description: |
 *       Cambia el estado del correo a ENVIADO, envía el correo via N8N
 *       y actualiza gmail_enviado=TRUE en todos los pagos incluidos.
 *     tags: [Correos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               asunto:
 *                 type: string
 *                 description: Edición de último momento del asunto
 *               cuerpo:
 *                 type: string
 *                 description: Edición de último momento del cuerpo
 *     responses:
 *       200:
 *         description: Correo enviado exitosamente
 *       404:
 *         description: Correo no encontrado
 *       409:
 *         description: El correo ya fue enviado
 *       503:
 *         description: Error al comunicarse con el servicio de correo
 */
router.post(
    '/:id/enviar',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
    validate(correoIdSchema, 'params'),
    validate(enviarCorreoSchema),
    auditMiddleware(TipoEvento.ENVIAR_CORREO, 'correos'),
    (req, res, next) => correosController.enviar(req, res, next)
);

/**
 * @swagger
 * /correos/{id}:
 *   delete:
 *     summary: Eliminar un borrador de correo
 *     description: Solo se pueden eliminar correos en estado BORRADOR
 *     tags: [Correos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Correo eliminado exitosamente
 *       404:
 *         description: Correo no encontrado
 *       409:
 *         description: No se pueden eliminar correos enviados
 */
router.delete(
    '/:id',
    authMiddleware,
    requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
    validate(correoIdSchema, 'params'),
    auditMiddleware(TipoEvento.ELIMINAR, 'correos'),
    (req, res, next) => correosController.delete(req, res, next)
);

export default router;
