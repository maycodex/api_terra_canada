import { query, getClient } from '../config/database';
import logger from '../config/logger';

export class PagosService {
  async getPagos(id?: number, filters?: { proveedor_id?: number; estado?: string; fecha_desde?: string; fecha_hasta?: string }) {
    try {
      if (id) {
        const result = await query(
          `SELECT p.*, 
                  pr.nombre as proveedor_nombre,
                  u.nombre_usuario as usuario_nombre,
                  t.titular as tarjeta_titular,
                  cb.nombre_banco as cuenta_banco,
                  c.nombre as cliente_nombre
           FROM pagos p
           LEFT JOIN proveedores pr ON p.proveedor_id = pr.id
           LEFT JOIN usuarios u ON p.usuario_id = u.id
           LEFT JOIN tarjetas_credito t ON p.tarjeta_id = t.id
           LEFT JOIN cuentas_bancarias cb ON p.cuenta_id = cb.id
           LEFT JOIN clientes c ON p.cliente_asociado_id = c.id
           WHERE p.id = $1`,
          [id]
        );
        return result.rows[0] || null;
      }

      let sql = `SELECT p.*, 
                        pr.nombre as proveedor_nombre,
                        u.nombre_usuario as usuario_nombre,
                        t.titular as tarjeta_titular,
                        cb.nombre_banco as cuenta_banco
                 FROM pagos p
                 LEFT JOIN proveedores pr ON p.proveedor_id = pr.id
                 LEFT JOIN usuarios u ON p.usuario_id = u.id
                 LEFT JOIN tarjetas_credito t ON p.tarjeta_id = t.id
                 LEFT JOIN cuentas_bancarias cb ON p.cuenta_id = cb.id
                 WHERE 1=1`;
      
      const params: any[] = [];
      let paramCount = 1;

      if (filters?.proveedor_id) {
        sql += ` AND p.proveedor_id = $${paramCount++}`;
        params.push(filters.proveedor_id);
      }
      if (filters?.estado) {
        sql += ` AND p.estado = $${paramCount++}`;
        params.push(filters.estado);
      }
      if (filters?.fecha_desde) {
        sql += ` AND p.fecha_creacion >= $${paramCount++}`;
        params.push(filters.fecha_desde);
      }
      if (filters?.fecha_hasta) {
        sql += ` AND p.fecha_creacion <= $${paramCount++}`;
        params.push(filters.fecha_hasta);
      }

      sql += ` ORDER BY p.fecha_creacion DESC LIMIT 100`;

      const result = await query(sql, params);
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener pagos:', error);
      throw error;
    }
  }

  async createPago(data: {
    monto: number;
    moneda: string;
    medio_pago: string;
    proveedor_id: number;
    usuario_id: number;
    tarjeta_id?: number | null;
    cuenta_id?: number | null;
    observaciones?: string | null;
    cliente_asociado_id?: number | null;
  }) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      // Validaciones
      const proveedor = await client.query('SELECT id FROM proveedores WHERE id = $1', [data.proveedor_id]);
      if (proveedor.rows.length === 0) throw new Error('Proveedor no encontrado');

      const usuario = await client.query('SELECT id FROM usuarios WHERE id = $1', [data.usuario_id]);
      if (usuario.rows.length === 0) throw new Error('Usuario no encontrado');

      // Si es pago con tarjeta, validar y descontar saldo
      if (data.tarjeta_id) {
        const tarjeta = await client.query('SELECT * FROM tarjetas_credito WHERE id = $1', [data.tarjeta_id]);
        if (tarjeta.rows.length === 0) throw new Error('Tarjeta no encontrada');
        
        if (parseFloat(tarjeta.rows[0].saldo_disponible) < data.monto) {
          throw new Error('Saldo insuficiente en la tarjeta');
        }

        // Descontar saldo
        await client.query(
          'UPDATE tarjetas_credito SET saldo_disponible = saldo_disponible - $1 WHERE id = $2',
          [data.monto, data.tarjeta_id]
        );
      }

      // Si cuenta bancaria, validar que existe
      if (data.cuenta_id) {
        const cuenta = await client.query('SELECT id FROM cuentas_bancarias WHERE id = $1', [data.cuenta_id]);
        if (cuenta.rows.length === 0) throw new Error('Cuenta bancaria no encontrada');
      }

      // Crear pago
      const result = await client.query(
        `INSERT INTO pagos (monto, moneda, medio_pago, proveedor_id, usuario_id, tarjeta_id, cuenta_id, 
                            observaciones, cliente_asociado_id, estado, fecha_creacion)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'PENDIENTE', CURRENT_TIMESTAMP) RETURNING *`,
        [data.monto, data.moneda, data.medio_pago, data.proveedor_id, data.usuario_id,
         data.tarjeta_id || null, data.cuenta_id || null, data.observaciones || null, data.cliente_asociado_id || null]
      );

      await client.query('COMMIT');
      logger.info(`Pago creado: ID ${result.rows[0].id} - Monto: ${data.monto} ${data.moneda}`);
      
      return await this.getPagos(result.rows[0].id);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error al crear pago:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  async updatePago(id: number, data: { estado?: string; observaciones?: string | null; fecha_pago?: string | null }) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      const existing = await client.query('SELECT * FROM pagos WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Pago no encontrado');

      // Si se cancela un pago con tarjeta, devolver el saldo
      if (data.estado === 'CANCELADO' && existing.rows[0].estado !== 'CANCELADO' && existing.rows[0].tarjeta_id) {
        await client.query(
          'UPDATE tarjetas_credito SET saldo_disponible = saldo_disponible + $1 WHERE id = $2',
          [existing.rows[0].monto, existing.rows[0].tarjeta_id]
        );
      }

      const updates: string[] = [];
      const values: any[] = [];
      let paramCount = 1;

      if (data.estado !== undefined) { updates.push(`estado = $${paramCount++}`); values.push(data.estado); }
      if (data.observaciones !== undefined) { updates.push(`observaciones = $${paramCount++}`); values.push(data.observaciones); }
      if (data.fecha_pago !== undefined) { updates.push(`fecha_pago = $${paramCount++}`); values.push(data.fecha_pago); }

      if (updates.length === 0) {
        await client.query('COMMIT');
        return existing.rows[0];
      }

      values.push(id);
      await client.query(`UPDATE pagos SET ${updates.join(', ')} WHERE id = $${paramCount}`, values);

      await client.query('COMMIT');
      logger.info(`Pago actualizado: ID ${id}`);
      
      return await this.getPagos(id);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error al actualizar pago:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  async deletePago(id: number) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      const existing = await client.query('SELECT * FROM pagos WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Pago no encontrado');

      if (existing.rows[0].estado === 'COMPLETADO') {
        throw new Error('No se puede eliminar un pago completado');
      }

      // Si tiene tarjeta, devolver saldo
      if (existing.rows[0].tarjeta_id && existing.rows[0].estado !== 'CANCELADO') {
        await client.query(
          'UPDATE tarjetas_credito SET saldo_disponible = saldo_disponible + $1 WHERE id = $2',
          [existing.rows[0].monto, existing.rows[0].tarjeta_id]
        );
      }

      await client.query('UPDATE pagos SET estado = $1 WHERE id = $2', ['CANCELADO', id]);

      await client.query('COMMIT');
      logger.info(`Pago cancelado: ID ${id}`);
      
      return existing.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error al eliminar pago:', error);
      throw error;
    } finally {
      client.release();
    }
  }
}

export const pagosService = new PagosService();
