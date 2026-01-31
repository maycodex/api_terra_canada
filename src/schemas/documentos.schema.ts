import { z } from 'zod';

/**
 * Tipos de documento válidos (según función PostgreSQL)
 */
export const TipoDocumentoEnum = z.enum(['FACTURA', 'DOCUMENTO_BANCO']);

/**
 * Schema para crear un nuevo documento
 * POST /documentos
 * 
 * Campos requeridos:
 * - tipo_documento: 'FACTURA' | 'DOCUMENTO_BANCO'
 * - nombre_archivo: string
 * - url_documento: string
 * - usuario_id: number
 * 
 * Campo opcional:
 * - pago_id: number (para vincular directamente a un pago)
 */
export const createDocumentoSchema = z.object({
  tipo_documento: TipoDocumentoEnum,
  nombre_archivo: z.string().min(1, 'El nombre del archivo es obligatorio'),
  url_documento: z.string().min(1, 'La URL del documento es obligatoria'),
  usuario_id: z.number().int().positive('El ID del usuario es obligatorio'),
  pago_id: z.number().int().positive().optional().nullable()
});

/**
 * Schema para actualizar un documento
 * PUT /documentos/:id
 * 
 * Campos opcionales:
 * - nombre_archivo: string
 * - url_documento: string
 */
export const updateDocumentoSchema = z.object({
  nombre_archivo: z.string().min(1, 'El nombre del archivo no puede estar vacío').optional(),
  url_documento: z.string().min(1, 'La URL del documento no puede estar vacía').optional()
}).refine(
  (data) => data.nombre_archivo || data.url_documento,
  { message: 'Debe proporcionar al menos un campo para actualizar' }
);

/**
 * Schema para validar el ID del documento
 */
export const documentoIdSchema = z.object({
  id: z.string().transform((val) => {
    const parsed = parseInt(val, 10);
    if (isNaN(parsed) || parsed <= 0) {
      throw new Error('ID de documento inválido');
    }
    return parsed;
  })
});

// Tipos exportados
export type CreateDocumentoInput = z.infer<typeof createDocumentoSchema>;
export type UpdateDocumentoInput = z.infer<typeof updateDocumentoSchema>;
