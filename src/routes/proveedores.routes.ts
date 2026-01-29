import { Router } from 'express';
import { proveedoresController } from '../controllers/proveedores.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createProveedorSchema, updateProveedorSchema, proveedorIdSchema, correoProveedorSchema } from '../schemas/proveedores.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

router.get('/', authMiddleware, (req, res) => proveedoresController.getProveedores(req, res));
router.get('/:id', authMiddleware, validate(proveedorIdSchema, 'params'), (req, res) => proveedoresController.getProveedores(req, res));

router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(createProveedorSchema),
  auditMiddleware(TipoEvento.CREAR, 'proveedores'),
  (req, res) => proveedoresController.createProveedor(req, res)
);

router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(proveedorIdSchema, 'params'),
  validate(updateProveedorSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'proveedores'),
  (req, res) => proveedoresController.updateProveedor(req, res)
);

router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(proveedorIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'proveedores'),
  (req, res) => proveedoresController.deleteProveedor(req, res)
);

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
