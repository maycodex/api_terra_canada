import { query } from '../config/database';
import logger from '../config/logger';

export class TarjetasService {
  async getTarjetas(id?: number, clienteId?: number) {
    try {
      if (id) {
        const result = await query(
          `SELECT t.*, c.nombre as cliente_nombre
           FROM tarjetas_credito t
           LEFT JOIN clientes c ON t.cliente_id = c.id
           WHERE t.id = $1`,
          [id]
        );
        return result.rows[0] || null;
      }

      let sql = `SELECT t.*, c.nombre as cliente_nombre
                 FROM tarjetas_credito t
                 LEFT JOIN clientes c ON t.cliente_id = c.id
                 WHERE t.activo = true`;
      const params: any[] = [];

      if (clienteId) {
        sql += ` AND t.cliente_id = $1`;
        params.push(clienteId);
      }

      sql += ` ORDER BY t.titular ASC`;
      const result = await query(sql, params);
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener tarjetas:', error);
      throw error;
    }
  }

  async createTarjeta(data: {
    numero_tarjeta_encriptado: string;
    titular: string;
    tipo: string;
    saldo_asignado: number;
    saldo_disponible?: number;
    cliente_id: number;
    fecha_vencimiento?: string | null;
    activo?: boolean;
  }) {
    try {
      // Verificar que el cliente existe
      const cliente = await query('SELECT id FROM clientes WHERE id = $1', [data.cliente_id]);
      if (cliente.rows.length === 0) throw new Error('Cliente no encontrado');

      const saldoDisponible = data.saldo_disponible !== undefined ? data.saldo_disponible : data.saldo_asignado;

      const result = await query(
        `INSERT INTO tarjetas_credito (numero_tarjeta_encriptado, titular, tipo, saldo_asignado, 
                                       saldo_disponible, cliente_id, fecha_vencimiento, activo)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
        [data.numero_tarjeta_encriptado, data.titular, data.tipo, data.saldo_asignado,
         saldoDisponible, data.cliente_id, data.fecha_vencimiento || null, data.activo !== false]
      );

      logger.info(`Tarjeta creada: ${result.rows[0].titular} - Saldo: ${result.rows[0].saldo_asignado}`);
      return await this.getTarjetas(result.rows[0].id);
    } catch (error) {
      logger.error('Error al crear tarjeta:', error);
      throw error;
    }
  }

  async updateTarjeta(id: number, data: {
    titular?: string;
    tipo?: string;
    saldo_asignado?: number;
    cliente_id?: number;
    fecha_vencimiento?: string | null;
    activo?: boolean;
  }) {
    try {
      const existing = await query('SELECT * FROM tarjetas_credito WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Tarjeta no encontrada');

      if (data.cliente_id) {
        const cliente = await query('SELECT id FROM clientes WHERE id = $1', [data.cliente_id]);
        if (cliente.rows.length === 0) throw new Error('Cliente no encontrado');
      }

      const updates: string[] = [];
      const values: any[] = [];
      let paramCount = 1;

      if (data.titular !== undefined) { updates.push(`titular = $${paramCount++}`); values.push(data.titular); }
      if (data.tipo !== undefined) { updates.push(`tipo = $${paramCount++}`); values.push(data.tipo); }
      if (data.saldo_asignado !== undefined) {
        updates.push(`saldo_asignado = $${paramCount++}`);
        values.push(data.saldo_asignado);
        // Ajustar también el saldo disponible proporcionalmente
        const diff = data.saldo_asignado - existing.rows[0].saldo_asignado;
        updates.push(`saldo_disponible = saldo_disponible + $${paramCount++}`);
        values.push(diff);
      }
      if (data.cliente_id !== undefined) { updates.push(`cliente_id = $${paramCount++}`); values.push(data.cliente_id); }
      if (data.fecha_vencimiento !== undefined) { updates.push(`fecha_vencimiento = $${paramCount++}`); values.push(data.fecha_vencimiento); }
      if (data.activo !== undefined) { updates.push(`activo = $${paramCount++}`); values.push(data.activo); }

      if (updates.length === 0) return existing.rows[0];

      values.push(id);
      await query(`UPDATE tarjetas_credito SET ${updates.join(', ')} WHERE id = $${paramCount}`, values);

      logger.info(`Tarjeta actualizada: ${data.titular || existing.rows[0].titular}`);
      return await this.getTarjetas(id);
    } catch (error) {
      logger.error('Error al actualizar tarjeta:', error);
      throw error;
    }
  }

  async recargarTarjeta(id: number, monto: number) {
    try {
      const existing = await query('SELECT * FROM tarjetas_credito WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Tarjeta no encontrada');

      if (monto <= 0) throw new Error('El monto debe ser mayor a 0');

      const result = await query(
        `UPDATE tarjetas_credito 
         SET saldo_asignado = saldo_asignado + $1, 
             saldo_disponible = saldo_disponible + $1
         WHERE id = $2
         RETURNING *`,
        [monto, id]
      );

      logger.info(`Tarjeta recargada: ${result.rows[0].titular} - Monto: ${monto}`);
      return await this.getTarjetas(id);
    } catch (error) {
      logger.error('Error al recargar tarjeta:', error);
      throw error;
    }
  }

  async deleteTarjeta(id: number) {
    try {
      const existing = await query('SELECT * FROM tarjetas_credito WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Tarjeta no encontrada');

      // Verificar que no tenga pagos asociados
      const pagosCount = await query('SELECT COUNT(*) as count FROM pagos WHERE tarjeta_id = $1', [id]);
      if (parseInt(pagosCount.rows[0].count) > 0) {
        throw new Error('No se puede eliminar la tarjeta porque tiene pagos asociados');
      }

      await query('UPDATE tarjetas_credito SET activo = false WHERE id = $1', [id]);
      logger.info(`Tarjeta desactivada: ${existing.rows[0].titular}`);
      return existing.rows[0];
    } catch (error) {
      logger.error('Error al eliminar tarjeta:', error);
      throw error;
    }
  }
}

export const tarjetasService = new TarjetasService();
