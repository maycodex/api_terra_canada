import { Router } from 'express';
import { analisisController } from '../controllers/analisis.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { requireRole } from '../middlewares/rbac.middleware';
import { RolNombre } from '../types/enums';

const router = Router();

/**
 * @swagger
 * /analisis/dashboard:
 *   get:
 *     summary: Obtener dashboard con estadísticas generales
 *     tags: [Análisis]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard con estadísticas
 */
router.get('/dashboard', authMiddleware, (req, res) => analisisController.getDashboard(req, res));

/**
 * @swagger
 * /analisis/reportes/pagos:
 *   get:
 *     summary: Generar reporte de pagos
 *     tags: [Análisis]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: fecha_desde
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: fecha_hasta
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: proveedor_id
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Reporte generado
 */
router.get(
  '/reportes/pagos',
  authMiddleware,
  requireRole(RolNombre.ADMIN, RolNombre.SUPERVISOR),
  (req, res) => analisisController.getReportePagos(req, res)
);

export default router;
