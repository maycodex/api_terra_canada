import { Router } from 'express';
import { serviciosController } from '../controllers/servicios.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createServicioSchema, updateServicioSchema, servicioIdSchema } from '../schemas/servicios.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

/**
 * @swagger
 * /servicios:
 *   get:
 *     summary: Listar todos los servicios
 *     description: Obtiene una lista de todos los servicios disponibles
 *     tags: [Servicios]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de servicios obtenida exitosamente
 *       401:
 *         description: No autenticado
 */
router.get(
  '/',
  authMiddleware,
  (req, res) => serviciosController.getServicios(req, res)
);

/**
 * @swagger
 * /servicios/{id}:
 *   get:
 *     summary: Obtener un servicio por ID
 *     description: Obtiene la información detallada de un servicio específico
 *     tags: [Servicios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio
 *     responses:
 *       200:
 *         description: Servicio encontrado
 *       404:
 *         description: Servicio no encontrado
 *       401:
 *         description: No autenticado
 */
router.get(
  '/:id',
  authMiddleware,
  validate(servicioIdSchema, 'params'),
  (req, res) => serviciosController.getServicios(req, res)
);

/**
 * @swagger
 * /servicios:
 *   post:
 *     summary: Crear un nuevo servicio
 *     description: Crea un nuevo servicio en el sistema
 *     tags: [Servicios]
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
 *                 example: "Hospedaje"
 *               descripcion:
 *                 type: string
 *                 example: "Servicio de alojamiento hotelero"
 *     responses:
 *       201:
 *         description: Servicio creado exitosamente
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
  validate(createServicioSchema),
  auditMiddleware(TipoEvento.CREAR, 'servicios'),
  (req, res) => serviciosController.createServicio(req, res)
);

/**
 * @swagger
 * /servicios/{id}:
 *   put:
 *     summary: Actualizar un servicio existente
 *     description: Actualiza la información de un servicio
 *     tags: [Servicios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio
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
 *         description: Servicio actualizado exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Servicio no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (ADMIN o SUPERVISOR)
 */
router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(servicioIdSchema, 'params'),
  validate(updateServicioSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'servicios'),
  (req, res) => serviciosController.updateServicio(req, res)
);

/**
 * @swagger
 * /servicios/{id}:
 *   delete:
 *     summary: Eliminar un servicio
 *     description: Elimina un servicio del sistema
 *     tags: [Servicios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio
 *     responses:
 *       200:
 *         description: Servicio eliminado exitosamente
 *       404:
 *         description: Servicio no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (solo ADMIN)
 */
router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(servicioIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'servicios'),
  (req, res) => serviciosController.deleteServicio(req, res)
);

export default router;
