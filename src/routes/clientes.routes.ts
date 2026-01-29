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
 *     tags: [Clientes]
 *     security:
 *       - bearerAuth: []
 */
router.get('/', authMiddleware, (req, res) => clientesController.getClientes(req, res));

router.get('/:id', authMiddleware, validate(clienteIdSchema, 'params'), (req, res) => clientesController.getClientes(req, res));

router.post(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(createClienteSchema),
  auditMiddleware(TipoEvento.CREAR, 'clientes'),
  (req, res) => clientesController.createCliente(req, res)
);

router.put(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  validate(clienteIdSchema, 'params'),
  validate(updateClienteSchema),
  auditMiddleware(TipoEvento.ACTUALIZAR, 'clientes'),
  (req, res) => clientesController.updateCliente(req, res)
);

router.delete(
  '/:id',
  authMiddleware,
  requireRole(RolNombre.ADMIN),
  validate(clienteIdSchema, 'params'),
  auditMiddleware(TipoEvento.ELIMINAR, 'clientes'),
  (req, res) => clientesController.deleteCliente(req, res)
);

export default router;
