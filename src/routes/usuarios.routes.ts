import { Router } from 'express';
import { usuariosController } from '../controllers/usuarios.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createUsuarioSchema, updateUsuarioSchema, usuarioIdSchema } from '../schemas/usuarios.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * /usuarios:
 *   get:
 *     summary: Listar todos los usuarios
 *     description: Obtiene una lista de todos los usuarios del sistema
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de usuarios obtenida exitosamente
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos
 */
router.get(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  (req, res) => usuariosController.getUsuarios(req, res)
);

/**
 * @swagger
 * /usuarios/{id}:
 *   get:
 *     summary: Obtener un usuario por ID
 *     description: Obtiene la información detallada de un usuario específico
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario
 *     responses:
 *       200:
 *         description: Usuario encontrado
 *       404:
 *         description: Usuario no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos
 */
router.get(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(usuarioIdSchema, 'params'),
  (req, res) => usuariosController.getUsuarios(req, res)
);

/**
 * @swagger
 * /usuarios:
 *   post:
 *     summary: Crear un nuevo usuario
 *     description: Crea un nuevo usuario en el sistema con contraseña hasheada
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nombre_usuario
 *               - password
 *               - nombre_completo
 *               - rol_id
 *             properties:
 *               nombre_usuario:
 *                 type: string
 *                 example: "jdoe"
 *               password:
 *                 type: string
 *                 example: "Password123!"
 *               nombre_completo:
 *                 type: string
 *                 example: "John Doe"
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "john@example.com"
 *               rol_id:
 *                 type: integer
 *                 example: 1
 *     responses:
 *       201:
 *         description: Usuario creado exitosamente
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (solo ADMIN)
 */
router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(createUsuarioSchema),
  auditMiddleware(TipoEvento.CREAR, 'usuarios'),
  (req, res) => usuariosController.createUsuario(req, res)
);

/**
 * @swagger
 * /usuarios/{id}:
 *   put:
 *     summary: Actualizar un usuario existente
 *     description: Actualiza la información de un usuario. Si se proporciona password, se hashea automáticamente
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario a actualizar
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre_usuario:
 *                 type: string
 *               password:
 *                 type: string
 *                 description: Nueva contraseña (se hasheará automáticamente)
 *               nombre_completo:
 *                 type: string
 *               email:
 *                 type: string
 *                 format: email
 *               rol_id:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Usuario actualizado exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Usuario no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (solo ADMIN)
 */
router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(usuarioIdSchema, 'params'),
  validate(updateUsuarioSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'usuarios'),
  (req, res) => usuariosController.updateUsuario(req, res)
);

/**
 * @swagger
 * /usuarios/{id}:
 *   delete:
 *     summary: Eliminar un usuario (soft delete)
 *     description: Desactiva un usuario marcándolo como inactivo (no se elimina físicamente)
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario a eliminar
 *     responses:
 *       200:
 *         description: Usuario eliminado (desactivado) exitosamente
 *       404:
 *         description: Usuario no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (solo ADMIN)
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(usuarioIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'usuarios'),
  (req, res) => usuariosController.deleteUsuario(req, res)
);

export default router;
