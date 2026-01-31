import { query } from '../config/database';
import logger from '../config/logger';

interface PostgresResponse {
  code: number;
  estado: boolean;
  message: string;
  data: any;
}

export class DocumentosService {
  /**
   * Obtener documentos - Usa documentos_get()
   * Si se pasa ID, obtiene un documento específico
   * Si no se pasa ID, obtiene todos los documentos
   */
  async getDocumentos(id?: number): Promise<any> {
    try {
      const result = await query(
        'SELECT documentos_get($1) as response',
        [id || null]
      );

      const response: PostgresResponse = result.rows[0]?.response;

      if (!response) {
        throw { code: 500, message: 'Error al obtener respuesta de la base de datos' };
      }

      if (!response.estado) {
        throw { code: response.code, message: response.message };
      }

      return response.data;
    } catch (error: any) {
      logger.error('Error en getDocumentos:', error);
      throw error;
    }
  }

  /**
   * Crear documento - Usa documentos_post()
   * 
   * @param data - Datos del documento:
   *   - tipo_documento: 'FACTURA' | 'DOCUMENTO_BANCO'
   *   - nombre_archivo: string
   *   - url_documento: string
   *   - usuario_id: number
   *   - pago_id?: number (opcional, para vincular directamente)
   */
  async createDocumento(data: {
    tipo_documento: string;
    nombre_archivo: string;
    url_documento: string;
    usuario_id: number;
    pago_id?: number;
  }) {
    try {
      logger.info('Creando documento:', {
        tipo: data.tipo_documento,
        nombre: data.nombre_archivo,
        usuario: data.usuario_id,
        pago: data.pago_id
      });

      const result = await query(
        'SELECT documentos_post($1, $2, $3, $4, $5) as response',
        [
          data.tipo_documento,
          data.nombre_archivo,
          data.url_documento,
          data.usuario_id,
          data.pago_id || null
        ]
      );

      const response: PostgresResponse = result.rows[0]?.response;

      if (!response) {
        throw { code: 500, message: 'Error al obtener respuesta de la base de datos' };
      }

      if (!response.estado) {
        throw { code: response.code, message: response.message };
      }

      logger.info(`Documento creado exitosamente: ID ${response.data?.id}`);
      return response.data;
    } catch (error: any) {
      logger.error('Error en createDocumento:', error);
      throw error;
    }
  }

  /**
   * Actualizar documento - Usa documentos_put()
   * 
   * @param id - ID del documento
   * @param data - Datos a actualizar (opcionales):
   *   - nombre_archivo?: string
   *   - url_documento?: string
   */
  async updateDocumento(
    id: number,
    data: {
      nombre_archivo?: string;
      url_documento?: string;
    }
  ) {
    try {
      logger.info(`Actualizando documento ${id}:`, data);

      const result = await query(
        'SELECT documentos_put($1, $2, $3) as response',
        [
          id,
          data.nombre_archivo || null,
          data.url_documento || null
        ]
      );

      const response: PostgresResponse = result.rows[0]?.response;

      if (!response) {
        throw { code: 500, message: 'Error al obtener respuesta de la base de datos' };
      }

      if (!response.estado) {
        throw { code: response.code, message: response.message };
      }

      logger.info(`Documento ${id} actualizado exitosamente`);
      return response.data;
    } catch (error: any) {
      logger.error('Error en updateDocumento:', error);
      throw error;
    }
  }

  /**
   * Eliminar documento - Usa documentos_delete()
   * 
   * @param id - ID del documento a eliminar
   */
  async deleteDocumento(id: number) {
    try {
      logger.info(`Eliminando documento ${id}`);

      const result = await query(
        'SELECT documentos_delete($1) as response',
        [id]
      );

      const response: PostgresResponse = result.rows[0]?.response;

      if (!response) {
        throw { code: 500, message: 'Error al obtener respuesta de la base de datos' };
      }

      if (!response.estado) {
        throw { code: response.code, message: response.message };
      }

      logger.info(`Documento ${id} eliminado exitosamente`);
      return response.data;
    } catch (error: any) {
      logger.error('Error en deleteDocumento:', error);
      throw error;
    }
  }
}

export const documentosService = new DocumentosService();
