import { Request, Response } from 'express';
import { pagosService } from '../services/pagos.service';
import { n8nClient } from '../utils/n8n.util';
import { sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class DocumentosPagoController {

  /**
   * ENDPOINT 1: Enviar documento de pago
   * POST /pagos/documento-estado
   * 
   * FLUJO:
   * 1. Front envía: { pdf, id_pago, usuario_id }
   * 2. Back obtiene datos del pago (incluyendo codigo_reserva)
   * 3. Back envía al webhook: { pdf, id_pago, codigo_reserva, usuario_id }
   * 4. Webhook responde: { codigo, mensaje }
   * 5. Back retorna esa respuesta al front
   */
  async enviarDocumentoEstado(req: Request, res: Response): Promise<Response> {
    try {
      const { pdf, id_pago, usuario_id } = req.body;

      if (!pdf || !id_pago || !usuario_id) {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, 'El PDF, ID del pago y usuario_id son obligatorios');
      }

      // Obtener datos completos del pago
      const pagoData = await pagosService.getPagos(id_pago);
      
      if (!pagoData) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Pago no encontrado');
      }

      // Enviar al webhook de N8N
      const webhookResult = await n8nClient.enviarDocumentoPago({
        pdf: pdf,
        id_pago: id_pago,
        codigo_reserva: pagoData.codigo_reserva,
        usuario_id: usuario_id
      });

      // Retornar exactamente la respuesta del webhook al front
      return res.status(webhookResult.codigo || webhookResult.code || 200).json(webhookResult);

    } catch (error: any) {
      logger.error('Error en enviarDocumentoEstado:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, error.message || 'Error al procesar documento');
    }
  }

  /**
   * ENDPOINT 2: Subir múltiples facturas (hasta 3)
   * POST /pagos/subir-facturas
   * 
   * FLUJO:
   * 1. Front envía: { modulo: "factura", usuario_id, facturas: [{pdf, proveedor_id}] }
   * 2. Back envía al webhook con usuario_id
   * 3. Webhook responde: { codigo, codigos_reserva: [...] }
   * 4. Back retorna esa respuesta al front
   */
  async subirFacturas(req: Request, res: Response): Promise<Response> {
    try {
      const { facturas, usuario_id } = req.body;

      if (!usuario_id) {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, 'El usuario_id es obligatorio');
      }

      if (!facturas || !Array.isArray(facturas) || facturas.length === 0) {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, 'Debe enviar al menos 1 factura');
      }

      if (facturas.length > 3) {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, 'Máximo 3 facturas permitidas');
      }

      // Preparar facturas para el webhook
      const facturasParaWebhook = facturas.map((factura: { pdf: string; proveedor_id: number }) => ({
        pdf: factura.pdf,
        proveedor_id: factura.proveedor_id
      }));

      // Enviar al webhook con usuario_id
      const webhookResult = await n8nClient.enviarFacturasMultiples(facturasParaWebhook, usuario_id);

      // Retornar exactamente la respuesta del webhook
      return res.status(webhookResult.codigo || webhookResult.code || 200).json(webhookResult);

    } catch (error: any) {
      logger.error('Error en subirFacturas:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, error.message || 'Error al procesar facturas');
    }
  }

  /**
   * ENDPOINT 3: Subir extracto de banco (1 PDF)
   * POST /pagos/subir-extracto-banco
   * 
   * FLUJO:
   * 1. Front envía: { pdf, usuario_id }
   * 2. Back envía al webhook: { modulo: "Banco", pdf, usuario_id }
   * 3. Webhook responde: { codigo, codigos_reserva: [...] }
   * 4. Back retorna esa respuesta al front
   */
  async subirExtractoBanco(req: Request, res: Response): Promise<Response> {
    try {
      const { pdf, usuario_id } = req.body;

      if (!pdf || !usuario_id) {
        return sendError(res, HTTP_STATUS.BAD_REQUEST, 'El PDF y usuario_id son obligatorios');
      }

      // Enviar al webhook con usuario_id
      const webhookResult = await n8nClient.enviarExtractoBanco(pdf, usuario_id);

      // Retornar exactamente la respuesta del webhook
      return res.status(webhookResult.codigo || webhookResult.code || 200).json(webhookResult);

    } catch (error: any) {
      logger.error('Error en subirExtractoBanco:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, error.message || 'Error al procesar extracto');
    }
  }
}

export const documentosPagoController = new DocumentosPagoController();
