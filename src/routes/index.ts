import { Router } from 'express';
import authRoutes from './auth.routes';
import rolesRoutes from './roles.routes';
import serviciosRoutes from './servicios.routes';
import clientesRoutes from './clientes.routes';
import proveedoresRoutes from './proveedores.routes';
import usuariosRoutes from './usuarios.routes';
import tarjetasRoutes from './tarjetas.routes';
import cuentasRoutes from './cuentas.routes';
import pagosRoutes from './pagos.routes';
import documentosRoutes from './documentos.routes';
import facturasRoutes from './facturas.routes';
import correosRoutes from './correos.routes';
import eventosRoutes from './eventos.routes';
import analisisRoutes from './analisis.routes';
import webhooksRoutes from './webhooks.routes';

const router = Router();

/**
 * Bienvenida de la API - Sistema Completo Funcional
 */
router.get('/', (_req, res) => {
  res.json({
    message: 'API Terra Canada - Sistema de Gestión de Pagos',
    version: '1.0.0',
    status: 'operational',
    documentation: '/api-docs',
    features: {
      authentication: 'JWT',
      database: 'PostgreSQL',
      audit: 'Eventos automáticos',
      authorization: 'RBAC (Role-Based Access Control)'
    },
    endpoints: {
      auth: '/api/v1/auth',
      usuarios: '/api/v1/usuarios',
      roles: '/api/v1/roles',
      servicios: '/api/v1/servicios',
      proveedores: '/api/v1/proveedores',
      clientes: '/api/v1/clientes',
      tarjetas: '/api/v1/tarjetas',
      cuentas: '/api/v1/cuentas',
      pagos: '/api/v1/pagos',
      documentos: '/api/v1/documentos',
      facturas: '/api/v1/facturas',
      correos: '/api/v1/correos',
      eventos: '/api/v1/eventos',
      analisis: '/api/v1/analisis',
      webhooks: '/api/v1/webhooks'
    }
  });
});

// Rutas
router.use('/auth', authRoutes);
router.use('/roles', rolesRoutes);
router.use('/servicios', serviciosRoutes);
router.use('/clientes', clientesRoutes);
router.use('/proveedores', proveedoresRoutes);
router.use('/usuarios', usuariosRoutes);
router.use('/tarjetas', tarjetasRoutes);
router.use('/cuentas', cuentasRoutes);
router.use('/pagos', pagosRoutes);
router.use('/documentos', documentosRoutes);
router.use('/facturas', facturasRoutes);
router.use('/correos', correosRoutes);
router.use('/eventos', eventosRoutes);
router.use('/analisis', analisisRoutes);
router.use('/webhooks', webhooksRoutes);

export default router;
