import { query } from '../config/database';
import logger from '../config/logger';

// Interfaz para la respuesta de las funciones PostgreSQL
interface PostgreSQLResponse {
  code: number;
  estado: boolean;
  message: string;
  data: any;
}

export class CuentasService {
  /**
   * GET: Obtener todas las cuentas o una específica
   * Usa la función PostgreSQL: cuentas_bancarias_get(p_id)
   */
  async getCuentas(id?: number) {
    try {
      let result;
      
      if (id) {
        // Obtener una cuenta específica
        result = await query('SELECT cuentas_bancarias_get($1) as response', [id]);
      } else {
        // Obtener todas las cuentas
        result = await query('SELECT cuentas_bancarias_get() as response');
      }

      const response: PostgreSQLResponse = result.rows[0].response;
      
      // Si hubo error en la función PostgreSQL, lanzar excepción
      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      return response.data;
    } catch (error: any) {
      logger.error('Error al obtener cuentas:', error);
      throw error;
    }
  }

  /**
   * POST: Crear una nueva cuenta bancaria
   * Usa la función PostgreSQL: cuentas_bancarias_post(...)
   */
  async createCuenta(data: {
    nombre_banco: string;
    nombre_cuenta: string;
    ultimos_4_digitos: string;
    moneda: 'USD' | 'CAD';
    activo?: boolean;
  }) {
    try {
      const result = await query(
        `SELECT cuentas_bancarias_post($1, $2, $3, $4::tipo_moneda, $5) as response`,
        [
          data.nombre_banco,
          data.nombre_cuenta,
          data.ultimos_4_digitos,
          data.moneda,
          data.activo !== false
        ]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      logger.info(`Cuenta bancaria creada: ${data.nombre_banco} - ${data.nombre_cuenta}`);
      return response.data;
    } catch (error: any) {
      logger.error('Error al crear cuenta:', error);
      throw error;
    }
  }

  /**
   * PUT: Actualizar una cuenta bancaria existente
   * Usa la función PostgreSQL: cuentas_bancarias_put(...)
   */
  async updateCuenta(id: number, data: {
    nombre_banco?: string;
    nombre_cuenta?: string;
    activo?: boolean;
  }) {
    try {
      const result = await query(
        `SELECT cuentas_bancarias_put($1, $2, $3, $4) as response`,
        [
          id,
          data.nombre_banco || null,
          data.nombre_cuenta || null,
          data.activo !== undefined ? data.activo : null
        ]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      logger.info(`Cuenta bancaria actualizada: ${data.nombre_banco || 'ID ' + id}`);
      return response.data;
    } catch (error: any) {
      logger.error('Error al actualizar cuenta:', error);
      throw error;
    }
  }

  /**
   * DELETE: Eliminar una cuenta bancaria (soft delete)
   * Usa la función PostgreSQL: cuentas_bancarias_delete(p_id)
   */
  async deleteCuenta(id: number) {
    try {
      const result = await query(
        'SELECT cuentas_bancarias_delete($1) as response',
        [id]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      logger.info(`Cuenta bancaria eliminada: ${response.data?.nombre_banco} (${response.data?.nombre_cuenta})`);
      return response.data;
    } catch (error: any) {
      logger.error('Error al eliminar cuenta:', error);
      throw error;
    }
  }
}

export const cuentasService = new CuentasService();
