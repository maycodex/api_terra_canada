import { Router } from 'express';
import { cuentasController } from '../controllers/cuentas.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createCuentaSchema, updateCuentaSchema, cuentaIdSchema } from '../schemas/cuentas.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

router.get('/', authMiddleware, (req, res) => cuentasController.getCuentas(req, res));
router.get('/:id', authMiddleware, validate(cuentaIdSchema, 'params'), (req, res) => cuentasController.getCuentas(req, res));

router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(createCuentaSchema),
  auditMiddleware(TipoEvento.CREAR, 'cuentas_bancarias'),
  (req, res) => cuentasController.createCuenta(req, res)
);

router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(cuentaIdSchema, 'params'),
  validate(updateCuentaSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'cuentas_bancarias'),
  (req, res) => cuentasController.updateCuenta(req, res)
);

router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(cuentaIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'cuentas_bancarias'),
  (req, res) => cuentasController.deleteCuenta(req, res)
);

export default router;
