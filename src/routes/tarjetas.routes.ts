import { Router } from 'express';
import { tarjetasController } from '../controllers/tarjetas.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createTarjetaSchema, updateTarjetaSchema, tarjetaIdSchema, recargarTarjetaSchema } from '../schemas/tarjetas.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * /tarjetas:
 *   get:
 *     summary: Listar tarjetas de crédito
 *     tags: [Tarjetas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: cliente_id
 *         schema:
 *           type: integer
 *         description: Filtrar por cliente
 *     responses:
 *       200:
 *         description: Lista de tarjetas
 */
router.get('/', authMiddleware, (req, res) => tarjetasController.getTarjetas(req, res));
router.get('/:id', authMiddleware, validate(tarjetaIdSchema, 'params'), (req, res) => tarjetasController.getTarjetas(req, res));

/**
 * @swagger
 * /tarjetas:
 *   post:
 *     summary: Crear tarjeta de crédito
 *     tags: [Tarjetas]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - numero_tarjeta_encriptado
 *               - titular
 *               - tipo
 *               - saldo_asignado
 *               - cliente_id
 *             properties:
 *               numero_tarjeta_encriptado:
 *                 type: string
 *               titular:
 *                 type: string
 *               tipo:
 *                 type: string
 *                 enum: [VISA, MASTERCARD, AMEX, OTRO]
 *               saldo_asignado:
 *                 type: number
 *               cliente_id:
 *                 type: integer
 *               fecha_vencimiento:
 *                 type: string
 *     responses:
 *       201:
 *         description: Tarjeta creada
 */
router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(createTarjetaSchema),
  auditMiddleware(TipoEvento.CREAR, 'tarjetas_credito'),
  (req, res) => tarjetasController.createTarjeta(req, res)
);

router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(tarjetaIdSchema, 'params'),
  validate(updateTarjetaSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'tarjetas_credito'),
  (req, res) => tarjetasController.updateTarjeta(req, res)
);

/**
 * @swagger
 * /tarjetas/{id}/recargar:
 *   post:
 *     summary: Recargar saldo de tarjeta
 *     tags: [Tarjetas]
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
 *               - monto
 *             properties:
 *               monto:
 *                 type: number
 *                 example: 1000
 *     responses:
 *       200:
 *         description: Tarjeta recargada
 */
router.post(
  '/:id/recargar',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(tarjetaIdSchema, 'params'),
  validate(recargarTarjetaSchema),
  auditMiddleware(TipoEvento.RECARGAR, 'tarjetas_credito'),
  (req, res) => tarjetasController.recargarTarjeta(req, res)
);

router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(tarjetaIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'tarjetas_credito'),
  (req, res) => tarjetasController.deleteTarjeta(req, res)
);

export default router;
