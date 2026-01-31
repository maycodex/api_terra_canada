import { query } from '../config/database';
import logger from '../config/logger';

// Interfaz para la respuesta de las funciones PostgreSQL
interface PostgreSQLResponse {
  code: number;
  estado: boolean;
  message: string;
  data: any;
}

export class TarjetasService {
  /**
   * GET: Obtener todas las tarjetas o una específica
   * Usa la función PostgreSQL: tarjetas_credito_get(p_id)
   */
  async getTarjetas(id?: number) {
    try {
      let result;
      
      if (id) {
        // Obtener una tarjeta específica
        result = await query('SELECT tarjetas_credito_get($1) as response', [id]);
      } else {
        // Obtener todas las tarjetas
        result = await query('SELECT tarjetas_credito_get() as response');
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
      logger.error('Error al obtener tarjetas:', error);
      throw error;
    }
  }

  /**
   * POST: Crear una nueva tarjeta
   * Usa la función PostgreSQL: tarjetas_credito_post(...)
   */
  async createTarjeta(data: {
    nombre_titular: string;
    ultimos_4_digitos: string;
    moneda: 'USD' | 'CAD';
    limite_mensual: number;
    tipo_tarjeta?: string;
    activo?: boolean;
  }) {
    try {
      const result = await query(
        `SELECT tarjetas_credito_post($1, $2, $3::tipo_moneda, $4, $5, $6) as response`,
        [
          data.nombre_titular,
          data.ultimos_4_digitos,
          data.moneda,
          data.limite_mensual,
          data.tipo_tarjeta || 'Visa',
          data.activo !== false
        ]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      logger.info(`Tarjeta creada: ${data.nombre_titular} - Límite: ${data.limite_mensual} ${data.moneda}`);
      return response.data;
    } catch (error: any) {
      logger.error('Error al crear tarjeta:', error);
      throw error;
    }
  }

  /**
   * PUT: Actualizar una tarjeta existente
   * Usa la función PostgreSQL: tarjetas_credito_put(...)
   */
  async updateTarjeta(id: number, data: {
    nombre_titular?: string;
    limite_mensual?: number;
    tipo_tarjeta?: string;
    activo?: boolean;
  }) {
    try {
      const result = await query(
        `SELECT tarjetas_credito_put($1, $2, $3, $4, $5) as response`,
        [
          id,
          data.nombre_titular || null,
          data.limite_mensual || null,
          data.tipo_tarjeta || null,
          data.activo !== undefined ? data.activo : null
        ]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      logger.info(`Tarjeta actualizada: ${data.nombre_titular || 'ID ' + id}`);
      return response.data;
    } catch (error: any) {
      logger.error('Error al actualizar tarjeta:', error);
      throw error;
    }
  }

  /**
   * DELETE: Eliminar una tarjeta (soft delete)
   * Usa la función PostgreSQL: tarjetas_credito_delete(p_id)
   */
  async deleteTarjeta(id: number) {
    try {
      const result = await query(
        'SELECT tarjetas_credito_delete($1) as response',
        [id]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      logger.info(`Tarjeta eliminada: ${response.data?.nombre_titular} (${response.data?.ultimos_4_digitos})`);
      return response.data;
    } catch (error: any) {
      logger.error('Error al eliminar tarjeta:', error);
      throw error;
    }
  }
}

export const tarjetasService = new TarjetasService();
