import { Router } from 'express';
import { eventosController } from '../controllers/eventos.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { RolNombre } from '../types/enums';

const router = Router();

/**
 * @swagger
 * /eventos:
 *   get:
 *     summary: Consultar auditoría/eventos del sistema
 *     tags: [Eventos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: tabla
 *         schema:
 *           type: string
 *       - in: query
 *         name: tipo_evento
 *         schema:
 *           type: string
 *       - in: query
 *         name: usuario_id
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 100
 *     responses:
 *       200:
 *         description: Lista de eventos
 */
router.get(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  (req, res) => eventosController.getEventos(req, res)
);

export default router;
