import { Router } from 'express';
import { cuentasController } from '../controllers/cuentas.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createCuentaSchema, updateCuentaSchema, cuentaIdSchema } from '../schemas/cuentas.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * /cuentas:
 *   get:
 *     summary: Listar todas las cuentas bancarias
 *     description: Obtiene una lista de todas las cuentas bancarias registradas
 *     tags: [Cuentas Bancarias]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de cuentas obtenida exitosamente
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.get(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  (req, res) => cuentasController.getCuentas(req, res)
);

/**
 * @swagger
 * /cuentas/{id}:
 *   get:
 *     summary: Obtener una cuenta bancaria por ID
 *     description: Obtiene la información detallada de una cuenta bancaria específica
 *     tags: [Cuentas Bancarias]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la cuenta
 *     responses:
 *       200:
 *         description: Cuenta encontrada
 *       404:
 *         description: Cuenta no encontrada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos
 */
router.get(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(cuentaIdSchema, 'params'),
  (req, res) => cuentasController.getCuentas(req, res)
);

/**
 * @swagger
 * /cuentas:
 *   post:
 *     summary: Crear una nueva cuenta bancaria
 *     description: Registra una nueva cuenta bancaria usando funciones PostgreSQL
 *     tags: [Cuentas Bancarias]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nombre_banco
 *               - nombre_cuenta
 *               - ultimos_4_digitos
 *               - moneda
 *             properties:
 *               nombre_banco:
 *                 type: string
 *                 example: "TD Canada Trust"
 *                 description: Nombre del banco
 *               nombre_cuenta:
 *                 type: string
 *                 example: "Business Checking Account"
 *                 description: Descripción o nombre de la cuenta
 *               ultimos_4_digitos:
 *                 type: string
 *                 pattern: '^\\d{4}$'
 *                 example: "5678"
 *                 description: Últimos 4 dígitos de la cuenta (exactamente 4 números)
 *               moneda:
 *                 type: string
 *                 enum: [USD, CAD]
 *                 example: "CAD"
 *                 description: Moneda de la cuenta
 *               activo:
 *                 type: boolean
 *                 example: true
 *                 description: Estado activo de la cuenta
 *     responses:
 *       201:
 *         description: Cuenta creada exitosamente
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
  validate(createCuentaSchema),
  auditMiddleware(TipoEvento.CREAR, 'cuentas_bancarias'),
  (req, res) => cuentasController.createCuenta(req, res)
);

/**
 * @swagger
 * /cuentas/{id}:
 *   put:
 *     summary: Actualizar una cuenta bancaria existente
 *     description: Actualiza la información de una cuenta bancaria usando funciones PostgreSQL
 *     tags: [Cuentas Bancarias]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la cuenta
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre_banco:
 *                 type: string
 *                 example: "Banco Nacional de Canadá"
 *                 description: Nombre del banco
 *               nombre_cuenta:
 *                 type: string
 *                 example: "Premium Business Account"
 *                 description: Descripción de la cuenta
 *               activo:
 *                 type: boolean
 *                 example: true
 *                 description: Estado activo
 *     responses:
 *       200:
 *         description: Cuenta actualizada exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Cuenta no encontrada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(cuentaIdSchema, 'params'),
  validate(updateCuentaSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'cuentas_bancarias'),
  (req, res) => cuentasController.updateCuenta(req, res)
);

/**
 * @swagger
 * /cuentas/{id}:
 *   delete:
 *     summary: Eliminar cuenta bancaria (soft delete)
 *     description: Desactiva una cuenta bancaria marcándola como inactiva
 *     tags: [Cuentas Bancarias]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la cuenta
 *     responses:
 *       200:
 *         description: Cuenta eliminada (desactivada) exitosamente
 *       404:
 *         description: Cuenta no encontrada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (solo ADMIN)
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(cuentaIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'cuentas_bancarias'),
  (req, res) => cuentasController.deleteCuenta(req, res)
);

export default router;
