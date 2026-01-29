import { query } from '../config/database';
import logger from '../config/logger';

export class RolesService {
  async getRoles(id?: number) {
    try {
      if (id) {
        const result = await query('SELECT * FROM roles WHERE id = $1', [id]);
        return result.rows[0] || null;
      }
      
      const result = await query('SELECT * FROM roles ORDER BY id ASC');
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener roles:', error);
      throw error;
    }
  }

  async createRol(data: { nombre: string; descripcion?: string | null }) {
    try {
      // Verificar si ya existe
      const existing = await query('SELECT id FROM roles WHERE nombre = $1', [data.nombre]);
      if (existing.rows.length > 0) {
        throw new Error('Ya existe un rol con ese nombre');
      }

      const result = await query(
        'INSERT INTO roles (nombre, descripcion) VALUES ($1, $2) RETURNING *',
        [data.nombre, data.descripcion || null]
      );

      logger.info(`Rol creado: ${result.rows[0].nombre}`);
      return result.rows[0];
    } catch (error) {
      logger.error('Error al crear rol:', error);
      throw error;
    }
  }

  async updateRol(id: number, data: { nombre?: string; descripcion?: string | null }) {
    try {
      // Verificar que existe
      const existing = await query('SELECT * FROM roles WHERE id = $1', [id]);
      if (existing.rows.length === 0) {
        throw new Error('Rol no encontrado');
      }

      // Si se cambia el nombre, verificar que no exista otro con ese nombre
      if (data.nombre && data.nombre !== existing.rows[0].nombre) {
        const duplicate = await query('SELECT id FROM roles WHERE nombre = $1', [data.nombre]);
        if (duplicate.rows.length > 0) {
          throw new Error('Ya existe un rol con ese nombre');
        }
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

      if (updates.length === 0) {
        return existing.rows[0];
      }

      values.push(id);
      const result = await query(
        `UPDATE roles SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`,
        values
      );

      logger.info(`Rol actualizado: ${result.rows[0].nombre}`);
      return result.rows[0];
    } catch (error) {
      logger.error('Error al actualizar rol:', error);
      throw error;
    }
  }

  async deleteRol(id: number) {
    try {
      // Verificar que existe
      const existing = await query('SELECT * FROM roles WHERE id = $1', [id]);
      if (existing.rows.length === 0) {
        throw new Error('Rol no encontrado');
      }

      // Verificar si hay usuarios con este rol
      const usersCount = await query('SELECT COUNT(*) as count FROM usuarios WHERE rol_id = $1', [id]);
      if (parseInt(usersCount.rows[0].count) > 0) {
        throw new Error('No se puede eliminar el rol porque tiene usuarios asociados');
      }

      await query('DELETE FROM roles WHERE id = $1', [id]);
      logger.info(`Rol eliminado: ${existing.rows[0].nombre}`);
      return existing.rows[0];
    } catch (error) {
      logger.error('Error al eliminar rol:', error);
      throw error;
    }
  }
}

export const rolesService = new RolesService();
