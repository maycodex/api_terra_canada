import { Router } from 'express';
import { rolesController } from '../controllers/roles.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createRolSchema, updateRolSchema, rolIdSchema } from '../schemas/roles.schema';
import { RolNombre } from '../types/enums';
import { TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * /roles:
 *   get:
 *     summary: Listar todos los roles
 *     tags: [Roles]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de roles
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  (req, res) => rolesController.getRoles(req, res)
);

/**
 * @swagger
 * /roles/{id}:
 *   get:
 *     summary: Obtener un rol por ID
 *     tags: [Roles]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del rol
 *     responses:
 *       200:
 *         description: Rol encontrado
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.get(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(rolIdSchema, 'params'),
  (req, res) => rolesController.getRoles(req, res)
);

/**
 * @swagger
 * /roles:
 *   post:
 *     summary: Crear un nuevo rol
 *     tags: [Roles]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nombre
 *             properties:
 *               nombre:
 *                 type: string
 *                 example: CONTADOR
 *               descripcion:
 *                 type: string
 *                 example: Rol para personal de contabilidad
 *     responses:
 *       201:
 *         description: Rol creado
 *       409:
 *         description: Rol ya existe
 */
router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(createRolSchema),
  auditMiddleware(TipoEvento.CREAR, 'roles'),
  (req, res) => rolesController.createRol(req, res)
);

/**
 * @swagger
 * /roles/{id}:
 *   put:
 *     summary: Actualizar un rol
 *     tags: [Roles]
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
 *               nombre:
 *                 type: string
 *               descripcion:
 *                 type: string
 *     responses:
 *       200:
 *         description: Rol actualizado
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(rolIdSchema, 'params'),
  validate(updateRolSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'roles'),
  (req, res) => rolesController.updateRol(req, res)
);

/**
 * @swagger
 * /roles/{id}:
 *   delete:
 *     summary: Eliminar un rol
 *     tags: [Roles]
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
 *         description: Rol eliminado
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       409:
 *         description: Rol tiene usuarios asociados
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(rolIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'roles'),
  (req, res) => rolesController.deleteRol(req, res)
);

export default router;
