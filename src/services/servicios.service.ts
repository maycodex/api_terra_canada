import { query } from '../config/database';
import logger from '../config/logger';

export class ServiciosService {
  async getServicios(id?: number) {
    try {
      if (id) {
        const result = await query('SELECT * FROM servicios WHERE id = $1', [id]);
        return result.rows[0] || null;
      }
      const result = await query('SELECT * FROM servicios ORDER BY nombre ASC');
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener servicios:', error);
      throw error;
    }
  }

  async createServicio(data: { nombre: string; descripcion?: string | null; activo?: boolean }) {
    try {
      const existing = await query('SELECT id FROM servicios WHERE nombre = $1', [data.nombre]);
      if (existing.rows.length > 0) throw new Error('Ya existe un servicio con ese nombre');

      const result = await query(
        'INSERT INTO servicios (nombre, descripcion, activo) VALUES ($1, $2, $3) RETURNING *',
        [data.nombre, data.descripcion || null, data.activo !== false]
      );

      logger.info(`Servicio creado: ${result.rows[0].nombre}`);
      return result.rows[0];
    } catch (error) {
      logger.error('Error al crear servicio:', error);
      throw error;
    }
  }

  async updateServicio(id: number, data: { nombre?: string; descripcion?: string | null; activo?: boolean }) {
    try {
      const existing = await query('SELECT * FROM servicios WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Servicio no encontrado');

      if (data.nombre && data.nombre !== existing.rows[0].nombre) {
        const duplicate = await query('SELECT id FROM servicios WHERE nombre = $1', [data.nombre]);
        if (duplicate.rows.length > 0) throw new Error('Ya existe un servicio con ese nombre');
      }

      const updates: string[] = [];
      const values: any[] = [];
      let paramCount = 1;

      if (data.nombre !== undefined) {
        updates.push(`nombre = $${paramCount++}`);
        values.push(data.nombre);
      }
      if (data.descripcion !== undefined) {
        updates.push(`descripcion = $${paramCount++}`);
        values.push(data.descripcion);
      }
      if (data.activo !== undefined) {
        updates.push(`activo = $${paramCount++}`);
        values.push(data.activo);
      }

      if (updates.length === 0) return existing.rows[0];

      values.push(id);
      const result = await query(
        `UPDATE servicios SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`,
        values
      );

      logger.info(`Servicio actualizado: ${result.rows[0].nombre}`);
      return result.rows[0];
    } catch (error) {
      logger.error('Error al actualizar servicio:', error);
      throw error;
    }
  }

  async deleteServicio(id: number) {
    try {
      const existing = await query('SELECT * FROM servicios WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Servicio no encontrado');

      const proveedoresCount = await query('SELECT COUNT(*) as count FROM proveedores WHERE servicio_id = $1', [id]);
      if (parseInt(proveedoresCount.rows[0].count) > 0) {
        throw new Error('No se puede eliminar el servicio porque tiene proveedores asociados');
      }

      await query('DELETE FROM servicios WHERE id = $1', [id]);
      logger.info(`Servicio eliminado: ${existing.rows[0].nombre}`);
      return existing.rows[0];
    } catch (error) {
      logger.error('Error al eliminar servicio:', error);
      throw error;
    }
  }
}

export const serviciosService = new ServiciosService();
