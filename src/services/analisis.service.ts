import { query } from '../config/database';
import logger from '../config/logger';

export class AnalisisService {
  async getDashboard() {
    try {
      const [pagosStats, tarjetasStats, proveedoresStats, clientesStats] = await Promise.all([
        // Estadísticas de pagos
        query(`SELECT 
                 COUNT(*) as total_pagos,
                 COALESCE(SUM(monto), 0) as monto_total,
                 COUNT(CASE WHEN estado = 'PENDIENTE' THEN 1 END) as pendientes,
                 COUNT(CASE WHEN estado = 'COMPLETADO' THEN 1 END) as completados
               FROM pagos`),
        
        // Estadísticas de tarjetas
        query(`SELECT 
                 COUNT(*) as total_tarjetas,
                 COALESCE(SUM(saldo_asignado), 0) as saldo_total_asignado,
                 COALESCE(SUM(saldo_disponible), 0) as saldo_total_disponible
               FROM tarjetas_credito WHERE activo = true`),
        
        // Proveedores
        query(`SELECT COUNT(*) as total_proveedores FROM proveedores WHERE activo = true`),
        
        // Clientes
        query(`SELECT COUNT(*) as total_clientes FROM clientes WHERE activo = true`)
      ]);

      return {
        pagos: pagosStats.rows[0],
        tarjetas: tarjetasStats.rows[0],
        proveedores: proveedoresStats.rows[0],
        clientes: clientesStats.rows[0]
      };
    } catch (error) {
      logger.error('Error al obtener dashboard:', error);
      throw error;
    }
  }

  async getReportePagos(filters?: { fecha_desde?: string; fecha_hasta?: string; proveedor_id?: number }) {
    try {
      let sql = `SELECT 
                   p.id, p.monto, p.moneda, p.medio_pago, p.estado, p.fecha_creacion,
                   pr.nombre as proveedor_nombre,
                   u.nombre_usuario,
                   t.titular as tarjeta_titular
                 FROM pagos p
                 LEFT JOIN proveedores PR ON p.proveedor_id = pr.id
                 LEFT JOIN usuarios u ON p.usuario_id = u.id
                 LEFT JOIN tarjetas_credito t ON p.tarjeta_id = t.id
                 WHERE 1=1`;
      
      const params: any[] = [];
      let paramCount = 1;

      if (filters?.fecha_desde) {
        sql += ` AND p.fecha_creacion >= $${paramCount++}`;
        params.push(filters.fecha_desde);
      }
      if (filters?.fecha_hasta) {
        sql += ` AND p.fecha_creacion <= $${paramCount++}`;
        params.push(filters.fecha_hasta);
      }
      if (filters?.proveedor_id) {
        sql += ` AND p.proveedor_id = $${paramCount++}`;
        params.push(filters.proveedor_id);
      }

      sql += ` ORDER BY p.fecha_creacion DESC`;

      const result = await query(sql, params);
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener reporte de pagos:', error);
      throw error;
    }
  }
}

export const analisisService = new AnalisisService();
