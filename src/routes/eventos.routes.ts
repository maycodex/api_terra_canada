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
 *     description: Obtiene eventos de auditoría usando la función eventos_get de PostgreSQL con paginación
 *     tags: [Eventos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: tabla
 *         schema:
 *           type: string
 *         description: Filtrar por tabla (actualmente no implementado en función PG)
 *       - in: query
 *         name: tipo_evento
 *         schema:
 *           type: string
 *         description: Filtrar por tipo de evento (actualmente no implementado en función PG)
 *       - in: query
 *         name: usuario_id
 *         schema:
 *           type: integer
 *         description: Filtrar por ID de usuario (actualmente no implementado en función PG)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 100
 *         description: Número máximo de eventos a retornar
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *         description: Número de eventos a saltar (para paginación)
 *     responses:
 *       200:
 *         description: Lista de eventos con información de paginación
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 estado:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Eventos obtenidos exitosamente"
 *                 total:
 *                   type: integer
 *                   example: 150
 *                 limite:
 *                   type: integer
 *                   example: 100
 *                 offset:
 *                   type: integer
 *                   example: 0
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 */
router.get(
  '/',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  (req, res) => eventosController.getEventos(req, res)
);

export default router;
