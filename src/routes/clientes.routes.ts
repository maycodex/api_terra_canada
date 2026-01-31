import { Router } from 'express';
import { clientesController } from '../controllers/clientes.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createClienteSchema, updateClienteSchema, clienteIdSchema } from '../schemas/clientes.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * /clientes:
 *   get:
 *     summary: Listar todos los clientes
 *     description: Obtiene una lista de todos los clientes registrados
 *     tags: [Clientes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de clientes obtenida exitosamente
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos
 */
router.get(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  (req, res) => clientesController.getClientes(req, res)
);

/**
 * @swagger
 * /clientes/{id}:
 *   get:
 *     summary: Obtener un cliente por ID
 *     description: Obtiene la información detallada de un cliente específico
 *     tags: [Clientes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del cliente
 *     responses:
 *       200:
 *         description: Cliente encontrado
 *       404:
 *         description: Cliente no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos
 */
router.get(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  validate(clienteIdSchema, 'params'),
  (req, res) => clientesController.getClientes(req, res)
);

/**
 * @swagger
 * /clientes:
 *   post:
 *     summary: Crear un nuevo cliente
 *     description: Registra un nuevo cliente en el sistema
 *     tags: [Clientes]
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
 *                 example: "Juan Pérez"
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "juan.perez@example.com"
 *               telefono:
 *                 type: string
 *                 example: "+1234567890"
 *               direccion:
 *                 type: string
 *                 example: "123 Main St, Toronto ON"
 *               notas:
 *                 type: string
 *                 example: "Cliente frecuente"
 *     responses:
 *       201:
 *         description: Cliente creado exitosamente
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos
 */
router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  validate(createClienteSchema),
  auditMiddleware(TipoEvento.CREAR, 'clientes'),
  (req, res) => clientesController.createCliente(req, res)
);

/**
 * @swagger
 * /clientes/{id}:
 *   put:
 *     summary: Actualizar un cliente existente
 *     description: Actualiza la información de un cliente
 *     tags: [Clientes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del cliente
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *               email:
 *                 type: string
 *                 format: email
 *               telefono:
 *                 type: string
 *               direccion:
 *                 type: string
 *               notas:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cliente actualizado exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Cliente no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos
 */
router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR, RolNombre.EQUIPO),
  validate(clienteIdSchema, 'params'),
  validate(updateClienteSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'clientes'),
  (req, res) => clientesController.updateCliente(req, res)
);

/**
 * @swagger
 * /clientes/{id}:
 *   delete:
 *     summary: Eliminar un cliente
 *     description: Elimina un cliente del sistema
 *     tags: [Clientes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del cliente
 *     responses:
 *       200:
 *         description: Cliente eliminado exitosamente
 *       404:
 *         description: Cliente no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(clienteIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'clientes'),
  (req, res) => clientesController.deleteCliente(req, res)
);

export default router;
