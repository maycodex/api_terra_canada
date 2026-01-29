import { Router } from 'express';
import { pagosController } from '../controllers/pagos.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createPagoSchema, updatePagoSchema, pagoIdSchema } from '../schemas/pagos.schema';
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
router.get('/:id', authMiddleware, validate(pagoIdSchema, 'params'), (req, res) => pagosController.getPagos(req, res));

/**
 * @swagger
 * /pagos:
 *   post:
 *     summary: Crear nuevo pago
 *     description: Crea un pago y descuenta automáticamente del saldo de la tarjeta si aplica
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
 *               - monto
 *               - moneda
 *               - medio_pago
 *               - proveedor_id
 *               - usuario_id
 *             properties:
 *               monto:
 *                 type: number
 *                 example: 500
 *               moneda:
 *                 type: string
 *                 enum: [USD, CAD, MXN, EUR]
 *               medio_pago:
 *                 type: string
 *                 enum: [TARJETA_CREDITO, CUENTA_BANCARIA, EFECTIVO, TRANSFERENCIA]
 *               proveedor_id:
 *                 type: integer
 *               usuario_id:
 *                 type: integer
 *               tarjeta_id:
 *                 type: integer
 *                 nullable: true
 *               cuenta_id:
 *                 type: integer
 *                 nullable: true
 *               observaciones:
 *                 type: string
 *     responses:
 *       201:
 *         description: Pago creado
 *       400:
 *         description: Saldo insuficiente
 */
router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  validate(createPagoSchema),
  auditMiddleware(TipoEvento.CREAR, 'pagos'),
  (req, res) => pagosController.createPago(req, res)
);

router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(pagoIdSchema, 'params'),
  validate(updatePagoSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'pagos'),
  (req, res) => pagosController.updatePago(req, res)
);

router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(pagoIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'pagos'),
  (req, res) => pagosController.deletePago(req, res)
);

export default router;
