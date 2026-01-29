import { query } from '../config/database';
import logger from '../config/logger';

export class CuentasService {
  async getCuentas(id?: number, clienteId?: number) {
    try {
      if (id) {
        const result = await query(
          `SELECT cb.*, c.nombre as cliente_nombre
           FROM cuentas_bancarias cb
           LEFT JOIN clientes c ON cb.cliente_id = c.id
           WHERE cb.id = $1`,
          [id]
        );
        return result.rows[0] || null;
      }

      let sql = `SELECT cb.*, c.nombre as cliente_nombre
                 FROM cuentas_bancarias cb
                 LEFT JOIN clientes c ON cb.cliente_id = c.id
                 WHERE cb.activo = true`;
      const params: any[] = [];

      if (clienteId) {
        sql += ` AND cb.cliente_id = $1`;
        params.push(clienteId);
      }

      sql += ` ORDER BY cb.nombre_banco ASC`;
      const result = await query(sql, params);
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener cuentas:', error);
      throw error;
    }
  }

  async createCuenta(data: {
    numero_cuenta_encriptado: string;
    nombre_banco: string;
    tipo_cuenta: string;
    titular: string;
    cliente_id: number;
    activo?: boolean;
  }) {
    try {
      const cliente = await query('SELECT id FROM clientes WHERE id = $1', [data.cliente_id]);
      if (cliente.rows.length === 0) throw new Error('Cliente no encontrado');

      const result = await query(
        `INSERT INTO cuentas_bancarias (numero_cuenta_encriptado, nombre_banco, tipo_cuenta, titular, cliente_id, activo)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [data.numero_cuenta_encriptado, data.nombre_banco, data.tipo_cuenta, data.titular, data.cliente_id, data.activo !== false]
      );

      logger.info(`Cuenta bancaria creada: ${result.rows[0].nombre_banco} - ${result.rows[0].titular}`);
      return await this.getCuentas(result.rows[0].id);
    } catch (error) {
      logger.error('Error al crear cuenta:', error);
      throw error;
    }
  }

  async updateCuenta(id: number, data: {
    nombre_banco?: string;
    tipo_cuenta?: string;
    titular?: string;
    cliente_id?: number;
    activo?: boolean;
  }) {
    try {
      const existing = await query('SELECT * FROM cuentas_bancarias WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Cuenta no encontrada');

      if (data.cliente_id) {
        const cliente = await query('SELECT id FROM clientes WHERE id = $1', [data.cliente_id]);
        if (cliente.rows.length === 0) throw new Error('Cliente no encontrado');
      }

      const updates: string[] = [];
      const values: any[] = [];
      let paramCount = 1;

      if (data.nombre_banco !== undefined) { updates.push(`nombre_banco = $${paramCount++}`); values.push(data.nombre_banco); }
      if (data.tipo_cuenta !== undefined) { updates.push(`tipo_cuenta = $${paramCount++}`); values.push(data.tipo_cuenta); }
      if (data.titular !== undefined) { updates.push(`titular = $${paramCount++}`); values.push(data.titular); }
      if (data.cliente_id !== undefined) { updates.push(`cliente_id = $${paramCount++}`); values.push(data.cliente_id); }
      if (data.activo !== undefined) { updates.push(`activo = ${paramCount++}`); values.push(data.activo); }

      if (updates.length === 0) return existing.rows[0];

      values.push(id);
      await query(`UPDATE cuentas_bancarias SET ${updates.join(', ')} WHERE id = $${paramCount}`, values);

      logger.info(`Cuenta actualizada: ${data.nombre_banco || existing.rows[0].nombre_banco}`);
      return await this.getCuentas(id);
    } catch (error) {
      logger.error('Error al actualizar cuenta:', error);
      throw error;
    }
  }

  async deleteCuenta(id: number) {
    try {
      const existing = await query('SELECT * FROM cuentas_bancarias WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Cuenta no encontrada');

      const pagosCount = await query('SELECT COUNT(*) as count FROM pagos WHERE cuenta_id = $1', [id]);
      if (parseInt(pagosCount.rows[0].count) > 0) {
        throw new Error('No se puede eliminar la cuenta porque tiene pagos asociados');
      }

      await query('UPDATE cuentas_bancarias SET activo = false WHERE id = $1', [id]);
      logger.info(`Cuenta desactivada: ${existing.rows[0].nombre_banco}`);
      return existing.rows[0];
    } catch (error) {
      logger.error('Error al eliminar cuenta:', error);
      throw error;
    }
  }
}

export const cuentasService = new CuentasService();
