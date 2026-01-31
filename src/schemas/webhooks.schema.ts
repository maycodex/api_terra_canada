import { z } from 'zod';

/**
 * Schema para webhook de N8N cuando procesa un documento
 */
export const webhookN8NDocumentoSchema = z.object({
    documento_id: z.number().int().positive(),
    tipo_procesamiento: z.enum(['FACTURA', 'DOCUMENTO_BANCO']),
    exito: z.boolean(),
    mensaje: z.string().optional(),
    codigos_encontrados: z.array(
        z.object({
            codigo_reserva: z.string(),
            encontrado: z.boolean(),
            pago_id: z.number().int().positive().optional(),
            observaciones: z.string().optional()
        })
    ).optional(),
    codigos_no_encontrados: z.array(z.string()).optional(),
    timestamp: z.string()
});

/**
 * Inferir tipo TypeScript del schema
 */
export type WebhookN8NDocumentoInput = z.infer<typeof webhookN8NDocumentoSchema>;

/**
 * Schema para validar token de N8N en headers
 */
export const n8nTokenHeaderSchema = z.object({
    'x-n8n-token': z.string().min(1, 'Token N8N requerido')
});
