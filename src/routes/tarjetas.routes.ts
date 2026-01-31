import { Router } from 'express';
import { tarjetasController } from '../controllers/tarjetas.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createTarjetaSchema, updateTarjetaSchema, tarjetaIdSchema } from '../schemas/tarjetas.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * /tarjetas:
 *   get:
 *     summary: Listar todas las tarjetas de crédito
 *     description: Obtiene una lista de todas las tarjetas de crédito registradas
 *     tags: [Tarjetas]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de tarjetas obtenida exitosamente
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.get(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  (req, res) => tarjetasController.getTarjetas(req, res)
);

/**
 * @swagger
 * /tarjetas/{id}:
 *   get:
 *     summary: Obtener una tarjeta por ID
 *     description: Obtiene la información detallada de una tarjeta específica
 *     tags: [Tarjetas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la tarjeta
 *     responses:
 *       200:
 *         description: Tarjeta encontrada
 *       404:
 *         description: Tarjeta no encontrada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos
 */
router.get(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(tarjetaIdSchema, 'params'),
  (req, res) => tarjetasController.getTarjetas(req, res)
);

/**
 * @swagger
 * /tarjetas:
 *   post:
 *     summary: Crear una nueva tarjeta de crédito
 *     description: Registra una nueva tarjeta de crédito usando funciones PostgreSQL
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
 *               - nombre_titular
 *               - ultimos_4_digitos
 *               - moneda
 *               - limite_mensual
 *             properties:
 *               nombre_titular:
 *                 type: string
 *                 example: "Juan Pérez"
 *                 description: Nombre completo del titular de la tarjeta
 *               ultimos_4_digitos:
 *                 type: string
 *                 pattern: '^\d{4}$'
 *                 example: "1234"
 *                 description: Últimos 4 dígitos de la tarjeta (exactamente 4 números)
 *               moneda:
 *                 type: string
 *                 enum: [USD, CAD]
 *                 example: "USD"
 *                 description: Moneda de la tarjeta
 *               limite_mensual:
 *                 type: number
 *                 example: 5000.00
 *                 description: Límite mensual de crédito
 *               tipo_tarjeta:
 *                 type: string
 *                 example: "Visa"
 *                 description: Tipo de tarjeta (Visa, Mastercard, etc.)
 *               activo:
 *                 type: boolean
 *                 example: true
 *                 description: Estado activo de la tarjeta
 *     responses:
 *       201:
 *         description: Tarjeta creada exitosamente
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
 *                   example: "Tarjeta creada"
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     nombre_titular:
 *                       type: string
 *                       example: "Juan Pérez"
 *                     ultimos_4_digitos:
 *                       type: string
 *                       example: "1234"
 *                     moneda:
 *                       type: string
 *                       example: "USD"
 *                     limite_mensual:
 *                       type: number
 *                       example: 5000.00
 *                     saldo_disponible:
 *                       type: number
 *                       example: 5000.00
 *                     tipo_tarjeta:
 *                       type: string
 *                       example: "Visa"
 *                     activo:
 *                       type: boolean
 *                       example: true
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(createTarjetaSchema),
  auditMiddleware(TipoEvento.CREAR, 'tarjetas_credito'),
  (req, res) => tarjetasController.createTarjeta(req, res)
);

/**
 * @swagger
 * /tarjetas/{id}:
 *   put:
 *     summary: Actualizar una tarjeta existente
 *     description: Actualiza la información de una tarjeta de crédito usando funciones PostgreSQL
 *     tags: [Tarjetas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la tarjeta
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre_titular:
 *                 type: string
 *                 example: "Juan Carlos Pérez"
 *                 description: Nombre completo del titular
 *               limite_mensual:
 *                 type: number
 *                 example: 6000.00
 *                 description: Nuevo límite mensual (ajusta saldo proporcionalmente)
 *               tipo_tarjeta:
 *                 type: string
 *                 example: "Visa Platinum"
 *                 description: Tipo de tarjeta
 *               activo:
 *                 type: boolean
 *                 example: true
 *                 description: Estado activo
 *     responses:
 *       200:
 *         description: Tarjeta actualizada exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Tarjeta no encontrada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
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
 * /tarjetas/{id}:
 *   delete:
 *     summary: Eliminar tarjeta (soft delete)
 *     description: Desactiva una tarjeta marcándola como inactiva
 *     tags: [Tarjetas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la tarjeta
 *     responses:
 *       200:
 *         description: Tarjeta eliminada (desactivada) exitosamente
 *       404:
 *         description: Tarjeta no encontrada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (solo ADMIN)
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(tarjetaIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'tarjetas_credito'),
  (req, res) => tarjetasController.deleteTarjeta(req, res)
);

export default router;
