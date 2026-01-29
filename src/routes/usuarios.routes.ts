import { Router } from 'express';
import { usuariosController } from '../controllers/usuarios.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { validate } from '../middlewares/validate.middleware';
import { createUsuarioSchema, updateUsuarioSchema, usuarioIdSchema } from '../schemas/usuarios.schema';
import { RolNombre, TipoEvento } from '../types/enums';
import { auditMiddleware } from '../middlewares/audit.middleware';

const router = Router();

router.get('/', authMiddleware, requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR), (req, res) => usuariosController.getUsuarios(req, res));
router.get('/:id', authMiddleware, requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR), validate(usuarioIdSchema, 'params'), (req, res) => usuariosController.getUsuarios(req, res));

router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(createUsuarioSchema),
  auditMiddleware(TipoEvento.CREAR, 'usuarios'),
  (req, res) => usuariosController.createUsuario(req, res)
);

router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(usuarioIdSchema, 'params'),
  validate(updateUsuarioSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'usuarios'),
  (req, res) => usuariosController.updateUsuario(req, res)
);

router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(usuarioIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'usuarios'),
  (req, res) => usuariosController.deleteUsuario(req, res)
);

export default router;
