import { query } from '../config/database';
import logger from '../config/logger';

export class EventosService {
  async getEventos(filters?: { tabla?: string; tipo_evento?: string; usuario_id?: number; fecha_desde?: string; fecha_hasta?: string; limit?: number }) {
    try {
      let sql = `SELECT e.*, u.nombre_usuario
                 FROM eventos e
                 LEFT JOIN usuarios u ON e.usuario_id = u.id
                 WHERE 1=1`;
      
      const params: any[] = [];
      let paramCount = 1;

      if (filters?.tabla) {
        sql += ` AND e.tabla = $${paramCount++}`;
        params.push(filters.tabla);
      }
      if (filters?.tipo_evento) {
        sql += ` AND e.tipo_evento = $${paramCount++}`;
        params.push(filters.tipo_evento);
      }
      if (filters?.usuario_id) {
        sql += ` AND e.usuario_id = $${paramCount++}`;
        params.push(filters.usuario_id);
      }
      if (filters?.fecha_desde) {
        sql += ` AND e.fecha_creacion >= $${paramCount++}`;
        params.push(filters.fecha_desde);
      }
      if (filters?.fecha_hasta) {
        sql += ` AND e.fecha_creacion <= $${paramCount++}`;
        params.push(filters.fecha_hasta);
      }

      sql += ` ORDER BY e.fecha_creacion DESC LIMIT $${paramCount}`;
      params.push(filters?.limit || 100);

      const result = await query(sql, params);
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener eventos:', error);
      throw error;
    }
  }
}

export const eventosService = new EventosService();
