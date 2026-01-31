import { z } from 'zod';

/**
 * Schema para enviar documento de pago
 * Endpoint: POST /pagos/documento-estado
 */
export const documentoEstadoSchema = z.object({
  pdf: z.string().min(1, 'El PDF en base64 es obligatorio'),
  id_pago: z.number().int().positive('El ID del pago debe ser positivo'),
  usuario_id: z.number().int().positive('El ID del usuario es obligatorio')
});

/**
 * Schema para subir múltiples facturas (hasta 3)
 * Endpoint: POST /pagos/subir-facturas
 */
export const subirFacturasSchema = z.object({
  modulo: z.literal('factura').optional().default('factura'),
  usuario_id: z.number().int().positive('El ID del usuario es obligatorio'),
  facturas: z.array(z.object({
    pdf: z.string().min(1, 'El PDF en base64 es obligatorio'),
    proveedor_id: z.number().int().positive('El ID del proveedor debe ser positivo')
  })).min(1, 'Debe enviar al menos 1 factura').max(3, 'Máximo 3 facturas permitidas')
});

/**
 * Schema para subir extracto de banco (1 PDF)
 * Endpoint: POST /pagos/subir-extracto-banco
 */
export const subirExtractoBancoSchema = z.object({
  pdf: z.string().min(1, 'El PDF en base64 es obligatorio'),
  usuario_id: z.number().int().positive('El ID del usuario es obligatorio')
});

export type DocumentoEstadoInput = z.infer<typeof documentoEstadoSchema>;
export type SubirFacturasInput = z.infer<typeof subirFacturasSchema>;
export type SubirExtractoBancoInput = z.infer<typeof subirExtractoBancoSchema>;
