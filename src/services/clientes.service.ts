import { query } from '../config/database';
import logger from '../config/logger';

export class ClientesService {
  async getClientes(id?: number) {
    try {
      if (id) {
        const result = await query('SELECT * FROM clientes WHERE id = $1', [id]);
        return result.rows[0] || null;
      }
      const result = await query('SELECT * FROM clientes WHERE activo = true ORDER BY nombre ASC');
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener clientes:', error);
      throw error;
    }
  }

  async createCliente(data: { nombre: string; ubicacion?: string | null; telefono?: string | null; correo?: string | null; activo?: boolean }) {
    try {
      const result = await query(
        'INSERT INTO clientes (nombre, ubicacion, telefono, correo, activo) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [data.nombre, data.ubicacion || null, data.telefono || null, data.correo || null, data.activo !== false]
      );

      logger.info(`Cliente creado: ${result.rows[0].nombre}`);
      return result.rows[0];
    } catch (error) {
      logger.error('Error al crear cliente:', error);
      throw error;
    }
  }

  async updateCliente(id: number, data: { nombre?: string; ubicacion?: string | null; telefono?: string | null; correo?: string | null; activo?: boolean }) {
    try {
      const existing = await query('SELECT * FROM clientes WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Cliente no encontrado');

      const updates: string[] = [];
      const values: any[] = [];
      let paramCount = 1;

      if (data.nombre !== undefined) {
        updates.push(`nombre = $${paramCount++}`);
        values.push(data.nombre);
      }
      if (data.ubicacion !== undefined) {
        updates.push(`ubicacion = $${paramCount++}`);
        values.push(data.ubicacion);
      }
      if (data.telefono !== undefined) {
        updates.push(`telefono = $${paramCount++}`);
        values.push(data.telefono);
      }
      if (data.correo !== undefined) {
        updates.push(`correo = $${paramCount++}`);
        values.push(data.correo);
      }
      if (data.activo !== undefined) {
        updates.push(`activo = $${paramCount++}`);
        values.push(data.activo);
      }

      if (updates.length === 0) return existing.rows[0];

      values.push(id);
      const result = await query(
        `UPDATE clientes SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`,
        values
      );

      logger.info(`Cliente actualizado: ${result.rows[0].nombre}`);
      return result.rows[0];
    } catch (error) {
      logger.error('Error al actualizar cliente:', error);
      throw error;
    }
  }

  async deleteCliente(id: number) {
    try {
      const existing = await query('SELECT * FROM clientes WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Cliente no encontrado');

      // Soft delete
      const result = await query(
        'UPDATE clientes SET activo = false WHERE id = $1 RETURNING *',
        [id]
      );

      logger.info(`Cliente desactivado: ${existing.rows[0].nombre}`);
      return result.rows[0];
    } catch (error) {
      logger.error('Error al eliminar cliente:', error);
      throw error;
    }
  }
}

export const clientesService = new ClientesService();
