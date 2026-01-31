import { Router } from 'express';
import { proveedoresController } from '../controllers/proveedores.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createProveedorSchema, updateProveedorSchema, proveedorIdSchema, correoProveedorSchema } from '../schemas/proveedores.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * /proveedores:
 *   get:
 *     summary: Listar todos los proveedores
 *     description: Obtiene una lista de todos los proveedores con sus correos asociados
 *     tags: [Proveedores]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de proveedores obtenida exitosamente
 *       401:
 *         description: No autenticado
 */
router.get(
  '/',
  authMiddleware,
  (req, res) => proveedoresController.getProveedores(req, res)
);

/**
 * @swagger
 * /proveedores/{id}:
 *   get:
 *     summary: Obtener un proveedor por ID
 *     description: Obtiene la información detallada de un proveedor específico incluyendo sus correos
 *     tags: [Proveedores]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del proveedor
 *     responses:
 *       200:
 *         description: Proveedor encontrado
 *       404:
 *         description: Proveedor no encontrado
 *       401:
 *         description: No autenticado
 */
router.get(
  '/:id',
  authMiddleware,
  validate(proveedorIdSchema, 'params'),
  (req, res) => proveedoresController.getProveedores(req, res)
);

/**
 * @swagger
 * /proveedores:
 *   post:
 *     summary: Crear un nuevo proveedor
 *     description: Crea un nuevo proveedor con hasta 4 correos electrónicos
 *     tags: [Proveedores]
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
 *               - lenguaje
 *             properties:
 *               nombre:
 *                 type: string
 *                 example: "Air Canada"
 *               lenguaje:
 *                 type: string
 *                 enum: [Español, English, Français]
 *                 example: "English"
 *               correo1:
 *                 type: string
 *                 format: email
 *                 example: "billing@aircanada.com"
 *               correo2:
 *                 type: string
 *                 format: email
 *               correo3:
 *                 type: string
 *                 format: email
 *               correo4:
 *                 type: string
 *                 format: email
 *     responses:
 *       201:
 *         description: Proveedor creado exitosamente
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
  validate(createProveedorSchema),
  auditMiddleware(TipoEvento.CREAR, 'proveedores'),
  (req, res) => proveedoresController.createProveedor(req, res)
);

/**
 * @swagger
 * /proveedores/{id}:
 *   put:
 *     summary: Actualizar un proveedor existente
 *     description: Actualiza información de un proveedor
 *     tags: [Proveedores]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del proveedor
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *               lenguaje:
 *                 type: string
 *                 enum: [Español, English, Français]
 *               correo1:
 *                 type: string
 *                 format: email
 *               correo2:
 *                 type: string
 *                 format: email
 *               correo3:
 *                 type: string
 *                 format: email
 *               correo4:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: Proveedor actualizado exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Proveedor no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(proveedorIdSchema, 'params'),
  validate(updateProveedorSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'proveedores'),
  (req, res) => proveedoresController.updateProveedor(req, res)
);

/**
 * @swagger
 * /proveedores/{id}:
 *   delete:
 *     summary: Eliminar un proveedor
 *     description: Elimina un proveedor del sistema
 *     tags: [Proveedores]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del proveedor
 *     responses:
 *       200:
 *         description: Proveedor eliminado exitosamente
 *       404:
 *         description: Proveedor no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (solo ADMIN)
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(proveedorIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'proveedores'),
  (req, res) => proveedoresController.deleteProveedor(req, res)
);

/**
 * @swagger
 * /proveedores/{id}/correos:
 *   post:
 *     summary: Agregar correo electrónico a un proveedor
 *     description: Agrega un nuevo correo electrónico a un proveedor existente (máximo 4 correos)
 *     tags: [Proveedores]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del proveedor
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - correo
 *               - principal
 *             properties:
 *               correo:
 *                 type: string
 *                 format: email
 *                 example: "payments@provider.com"
 *               principal:
 *                 type: boolean
 *                 description: Indica si este es el correo principal
 *                 example: true
 *     responses:
 *       201:
 *         description: Correo agregado exitosamente
 *       400:
 *         description: Datos inválidos o máximo de correos alcanzado
 *       404:
 *         description: Proveedor no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.post(
  '/:id/correos',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(proveedorIdSchema, 'params'),
  validate(correoProveedorSchema),
  auditMiddleware(TipoEvento.CREAR, 'proveedor_correos'),
  (req, res) => proveedoresController.addCorreo(req, res)
);

export default router;
