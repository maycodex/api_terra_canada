import { query } from '../config/database';
import logger from '../config/logger';

// Interfaz para la respuesta de las funciones PostgreSQL
interface PostgreSQLResponse {
  code: number;
  estado: boolean;
  message: string;
  data: any;
}

export class PagosService {
  /**
   * GET: Obtener todos los pagos o uno específico
   * Usa la función PostgreSQL: pagos_get(p_id)
   */
  async getPagos(id?: number) {
    try {
      let result;
      
      if (id) {
        // Obtener un pago específico
        result = await query('SELECT pagos_get($1) as response', [id]);
      } else {
        // Obtener todos los pagos
        result = await query('SELECT pagos_get() as response');
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
      logger.error('Error al obtener pagos:', error);
      throw error;
    }
  }

  /**
   * POST: Crear un nuevo pago
   * Usa la función PostgreSQL: pagos_post(...)
   * 
   * Esta función:
   * - Valida proveedor, usuario, tarjeta/cuenta
   * - Descuenta saldo de tarjeta (si aplica)
   * - Vincula clientes
   * - Retorna el pago completo con todas las relaciones
   */
  async createPago(data: {
    proveedor_id: number;
    usuario_id: number;
    codigo_reserva: string;
    monto: number;
    moneda: 'USD' | 'CAD';
    tipo_medio_pago: 'TARJETA' | 'CUENTA_BANCARIA';
    tarjeta_id?: number | null;
    cuenta_bancaria_id?: number | null;
    clientes_ids?: number[] | null;
    descripcion?: string | null;
    fecha_esperada_debito?: string | null;
  }) {
    try {
      // Convertir clientes_ids a formato PostgreSQL array
      const clientesArray = data.clientes_ids && data.clientes_ids.length > 0
        ? `{${data.clientes_ids.join(',')}}`
        : null;

      const result = await query(
        `SELECT pagos_post(
          $1,  -- proveedor_id
          $2,  -- usuario_id
          $3,  -- codigo_reserva
          $4,  -- monto
          $5::tipo_moneda,  -- moneda
          $6::tipo_medio_pago,  -- tipo_medio_pago
          $7,  -- tarjeta_id
          $8,  -- cuenta_bancaria_id
          $9::BIGINT[],  -- clientes_ids
          $10,  -- descripcion
          $11  -- fecha_esperada_debito
        ) as response`,
        [
          data.proveedor_id,
          data.usuario_id,
          data.codigo_reserva,
          data.monto,
          data.moneda,
          data.tipo_medio_pago,
          data.tarjeta_id || null,
          data.cuenta_bancaria_id || null,
          clientesArray,
          data.descripcion || null,
          data.fecha_esperada_debito || null
        ]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        error.data = response.data; // Para incluir saldo_disponible en errores
        throw error;
      }

      logger.info(`Pago creado: ${data.codigo_reserva} - Monto: ${data.monto} ${data.moneda}`);
      
      // Enviar datos del pago al webhook de N8N (no bloquear si falla)
      try {
        const { n8nClient } = await import('../utils/n8n.util');
        const webhookResult = await n8nClient.notificarPagoWebhook(response.data, 'CREAR');
        
        if (webhookResult.success) {
          logger.info(`Pago ${response.data.id} enviado al webhook N8N exitosamente`);
        } else {
          logger.warn(`Pago ${response.data.id} creado pero falló envío a webhook N8N: ${webhookResult.error}`);
        }
      } catch (webhookError: any) {
        // No fallar la operación si el webhook falla
        logger.error(`Error al notificar pago al webhook N8N:`, webhookError.message);
      }
      
      return response.data;
    } catch (error: any) {
      logger.error('Error al crear pago:', error);
      throw error;
    }
  }

  /**
   * PUT: Actualizar un pago existente
   * Usa la función PostgreSQL: pagos_put(...)
   * 
   * Validaciones de la función PostgreSQL:
   * - No se puede editar un pago verificado
   * - No se puede cambiar el monto si es con tarjeta (ya se descontó)
   * - Si se marca verificado=true, automáticamente marca pagado=true
   */
  async updatePago(id: number, data: {
    monto?: number;
    descripcion?: string | null;
    fecha_esperada_debito?: string | null;
    pagado?: boolean;
    verificado?: boolean;
    gmail_enviado?: boolean;
    activo?: boolean;
  }) {
    try {
      const result = await query(
        `SELECT pagos_put(
          $1,  -- id
          $2,  -- monto
          $3,  -- descripcion
          $4,  -- fecha_esperada_debito
          $5,  -- pagado
          $6,  -- verificado
          $7,  -- gmail_enviado
          $8   -- activo
        ) as response`,
        [
          id,
          data.monto !== undefined ? data.monto : null,
          data.descripcion !== undefined ? data.descripcion : null,
          data.fecha_esperada_debito !== undefined ? data.fecha_esperada_debito : null,
          data.pagado !== undefined ? data.pagado : null,
          data.verificado !== undefined ? data.verificado : null,
          data.gmail_enviado !== undefined ? data.gmail_enviado : null,
          data.activo !== undefined ? data.activo : null
        ]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      logger.info(`Pago actualizado: ID ${id}`);
      
      // Enviar datos del pago actualizado al webhook de N8N
      try {
        const { n8nClient } = await import('../utils/n8n.util');
        const webhookResult = await n8nClient.notificarPagoWebhook(response.data, 'ACTUALIZAR');
        
        if (webhookResult.success) {
          logger.info(`Pago ${id} actualizado enviado al webhook N8N`);
        } else {
          logger.warn(`Pago ${id} actualizado pero falló envío a webhook N8N: ${webhookResult.error}`);
        }
      } catch (webhookError: any) {
        logger.error(`Error al notificar actualización al webhook N8N:`, webhookError.message);
      }
      
      return response.data;
    } catch (error: any) {
      logger.error('Error al actualizar pago:', error);
      throw error;
    }
  }

  /**
   * DELETE: Eliminar un pago
   * Usa la función PostgreSQL: pagos_delete(p_id)
   * 
   * Validaciones de la función PostgreSQL:
   * - No se puede eliminar si gmail_enviado = true
   * - Si es pago con tarjeta, DEVUELVE el monto al saldo
   * - Elimina relaciones con clientes
   */
  async deletePago(id: number) {
    try {
      const result = await query(
        'SELECT pagos_delete($1) as response',
        [id]
      );

      const response: PostgreSQLResponse = result.rows[0].response;

      if (!response.estado) {
        const error = new Error(response.message) as any;
        error.code = response.code;
        throw error;
      }

      logger.info(`Pago eliminado: ${response.data?.codigo_reserva} - Monto devuelto: ${response.data?.monto_devuelto || 0}`);
      
      // Enviar notificación de eliminación al webhook de N8N
      try {
        const { n8nClient } = await import('../utils/n8n.util');
        const webhookResult = await n8nClient.notificarPagoWebhook({
          id: id,
          ...response.data
        }, 'ELIMINAR');
        
        if (webhookResult.success) {
          logger.info(`Eliminación de pago ${id} enviada al webhook N8N`);
        } else {
          logger.warn(`Pago ${id} eliminado pero falló envío a webhook N8N: ${webhookResult.error}`);
        }
      } catch (webhookError: any) {
        logger.error(`Error al notificar eliminación al webhook N8N:`, webhookError.message);
      }
      
      return response.data;
    } catch (error: any) {
      logger.error('Error al eliminar pago:', error);
      throw error;
    }
  }
}

export const pagosService = new PagosService();
