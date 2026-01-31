import { query } from '../config/database';
import logger from '../config/logger';

export class EventosService {
  /**
   * Obtener eventos usando la función eventos_get de PostgreSQL
   * @param filters - Filtros opcionales (actualmente solo se usa limit y offset)
   * @param id - ID del evento específico (opcional)
   */
  async getEventos(filters?: { 
    tabla?: string; 
    tipo_evento?: string; 
    usuario_id?: number; 
    fecha_desde?: string; 
    fecha_hasta?: string; 
    limit?: number;
    offset?: number;
  }, id?: number) {
    try {
      const limite = filters?.limit || 100;
      const offset = filters?.offset || 0;
      
      // Llamar a la función eventos_get de PostgreSQL
      const sql = 'SELECT eventos_get($1, $2, $3) as result';
      const params = [
        id || null,
        limite,
        offset
      ];

      const result = await query(sql, params);
      
      if (result.rows.length > 0 && result.rows[0].result) {
        const response = result.rows[0].result;
        
        // Si la función retorna un error, lanzarlo
        if (!response.estado) {
          throw new Error(response.message);
        }
        
        // Retornar los datos
        return response;
      }
      
      return {
        code: 200,
        estado: true,
        message: 'No se encontraron eventos',
        data: [],
        total: 0
      };
    } catch (error) {
      logger.error('Error al obtener eventos:', error);
      throw error;
    }
  }

  /**
   * Obtener un evento específico por ID
   * @param id - ID del evento
   */
  async getEventoById(id: number) {
    try {
      const sql = 'SELECT eventos_get($1, $2, $3) as result';
      const params = [id, 100, 0];

      const result = await query(sql, params);
      
      if (result.rows.length > 0 && result.rows[0].result) {
        const response = result.rows[0].result;
        
        if (!response.estado) {
          return null;
        }
        
        return response.data;
      }
      
      return null;
    } catch (error) {
      logger.error('Error al obtener evento por ID:', error);
      throw error;
    }
  }
}

export const eventosService = new EventosService();
