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
 *     tags: [Servicios]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de servicios
 */
router.get(
  '/',
  authMiddleware,
  (req, res) => serviciosController.getServicios(req, res)
);

router.get(
  '/:id',
  authMiddleware,
  validate(servicioIdSchema, 'params'),
  (req, res) => serviciosController.getServicios(req, res)
);

router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(createServicioSchema),
  auditMiddleware(TipoEvento.CREAR, 'servicios'),
  (req, res) => serviciosController.createServicio(req, res)
);

router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(servicioIdSchema, 'params'),
  validate(updateServicioSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'servicios'),
  (req, res) => serviciosController.updateServicio(req, res)
);

router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(servicioIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'servicios'),
  (req, res) => serviciosController.deleteServicio(req, res)
);

export default router;
