import { query, getClient } from '../config/database';
import logger from '../config/logger';

export class ProveedoresService {
  async getProveedores(id?: number, servicioId?: number) {
    try {
      if (id) {
        const result = await query(
          `SELECT p.*, s.nombre as servicio_nombre,
                  json_agg(
                    json_build_object(
                      'id', pc.id,
                      'correo', pc.correo,
                      'principal', pc.principal,
                      'activo', pc.activo
                    ) ORDER BY pc.principal DESC, pc.id ASC
                  ) FILTER (WHERE pc.id IS NOT NULL AND pc.activo = true) as correos
           FROM proveedores p
           LEFT JOIN servicios s ON p.servicio_id = s.id
           LEFT JOIN proveedor_correos pc ON p.id = pc.proveedor_id
           WHERE p.id = $1
           GROUP BY p.id, s.nombre`,
          [id]
        );
        return result.rows[0] || null;
      }

      let sql = `SELECT p.*, s.nombre as servicio_nombre,
                        json_agg(
                          json_build_object(
                            'id', pc.id,
                            'correo', pc.correo,
                            'principal', pc.principal
                          ) ORDER BY pc.principal DESC, pc.id ASC
                        ) FILTER (WHERE pc.id IS NOT NULL AND pc.activo = true) as correos
                 FROM proveedores p
                 LEFT JOIN servicios s ON p.servicio_id = s.id
                 LEFT JOIN proveedor_correos pc ON p.id = pc.proveedor_id AND pc.activo = true
                 WHERE p.activo = true`;
      
      const params: any[] = [];
      if (servicioId) {
        sql += ` AND p.servicio_id = $1`;
        params.push(servicioId);
      }

      sql += ` GROUP BY p.id, s.nombre ORDER BY p.nombre ASC`;

      const result = await query(sql, params);
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener proveedores:', error);
      throw error;
    }
  }

  async createProveedor(data: {
    nombre: string;
    servicio_id: number;
    lenguaje?: string | null;
    telefono?: string | null;
    descripcion?: string | null;
    correos?: Array<{ correo: string; principal: boolean }>;
    activo?: boolean;
  }) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      // Verificar que el servicio existe
      const servicio = await client.query('SELECT id FROM servicios WHERE id = $1', [data.servicio_id]);
      if (servicio.rows.length === 0) throw new Error('Servicio no encontrado');

      // Crear proveedor
      const proveedorResult = await client.query(
        `INSERT INTO proveedores (nombre, servicio_id, lenguaje, telefono, descripcion, activo)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [data.nombre, data.servicio_id, data.lenguaje || null, data.telefono || null, 
         data.descripcion || null, data.activo !== false]
      );

      const proveedor = proveedorResult.rows[0];

      // Crear correos si existen
      if (data.correos && data.correos.length > 0) {
        for (const correo of data.correos) {
          await client.query(
            'INSERT INTO proveedor_correos (proveedor_id, correo, principal, activo) VALUES ($1, $2, $3, true)',
            [proveedor.id, correo.correo, correo.principal]
          );
        }
      }

      await client.query('COMMIT');
      logger.info(`Proveedor creado: ${proveedor.nombre}`);

      // Retornar con correos
      return await this.getProveedores(proveedor.id);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error al crear proveedor:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  async updateProveedor(id: number, data: {
    nombre?: string;
    servicio_id?: number;
    lenguaje?: string | null;
    telefono?: string | null;
    descripcion?: string | null;
    activo?: boolean;
  }) {
    try {
      const existing = await query('SELECT * FROM proveedores WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Proveedor no encontrado');

      if (data.servicio_id) {
        const servicio = await query('SELECT id FROM servicios WHERE id = $1', [data.servicio_id]);
        if (servicio.rows.length === 0) throw new Error('Servicio no encontrado');
      }

      const updates: string[] = [];
      const values: any[] = [];
      let paramCount = 1;

      if (data.nombre !== undefined) { updates.push(`nombre = $${paramCount++}`); values.push(data.nombre); }
      if (data.servicio_id !== undefined) { updates.push(`servicio_id = $${paramCount++}`); values.push(data.servicio_id); }
      if (data.lenguaje !== undefined) { updates.push(`lenguaje = $${paramCount++}`); values.push(data.lenguaje); }
      if (data.telefono !== undefined) { updates.push(`telefono = $${paramCount++}`); values.push(data.telefono); }
      if (data.descripcion !== undefined) { updates.push(`descripcion = $${paramCount++}`); values.push(data.descripcion); }
      if (data.activo !== undefined) { updates.push(`activo = $${paramCount++}`); values.push(data.activo); }

      if (updates.length === 0) return existing.rows[0];

      values.push(id);
      await query(`UPDATE proveedores SET ${updates.join(', ')} WHERE id = $${paramCount}`, values);

      logger.info(`Proveedor actualizado: ${data.nombre || existing.rows[0].nombre}`);
      return await this.getProveedores(id);
    } catch (error) {
      logger.error('Error al actualizar proveedor:', error);
      throw error;
    }
  }

  async deleteProveedor(id: number) {
    try {
      const existing = await query('SELECT * FROM proveedores WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Proveedor no encontrado');

      await query('UPDATE proveedores SET activo = false WHERE id = $1', [id]);
      logger.info(`Proveedor desactivado: ${existing.rows[0].nombre}`);
      return existing.rows[0];
    } catch (error) {
      logger.error('Error al eliminar proveedor:', error);
      throw error;
    }
  }

  async addCorreo(proveedorId: number, correo: string, principal: boolean) {
    try {
      const proveedor = await query('SELECT id FROM proveedores WHERE id = $1', [proveedorId]);
      if (proveedor.rows.length === 0) throw new Error('Proveedor no encontrado');

      const correosCount = await query(
        'SELECT COUNT(*) as count FROM proveedor_correos WHERE proveedor_id = $1 AND activo = true',
        [proveedorId]
      );
      if (parseInt(correosCount.rows[0].count) >= 4) {
        throw new Error('Máximo 4 correos permitidos por proveedor');
      }

      const result = await query(
        'INSERT INTO proveedor_correos (proveedor_id, correo, principal, activo) VALUES ($1, $2, $3, true) RETURNING *',
        [proveedorId, correo, principal]
      );

      logger.info(`Correo agregado al proveedor ${proveedorId}: ${correo}`);
      return result.rows[0];
    } catch (error) {
      logger.error('Error al agregar correo:', error);
      throw error;
    }
  }
}

export const proveedoresService = new ProveedoresService();
