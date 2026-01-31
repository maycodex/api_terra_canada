import { z } from 'zod';
import { EstadoCorreo } from '../types/enums';

/**
 * Schema para generar correos automáticamente
 * Busca pagos con pagado=TRUE y gmail_enviado=FALSE
 */
export const generarCorreosSchema = z.object({
    // Opcionalmente filtrar por proveedor específico
    proveedor_id: z.number().int().positive().optional()
});

/**
 * Schema para crear un correo manualmente
 */
export const createCorreoSchema = z.object({
    proveedor_id: z.number().int().positive(),
    correo_seleccionado: z.string().email({
        message: 'Correo electrónico inválido'
    }),
    asunto: z.string().min(1, 'El asunto es obligatorio').max(255),
    cuerpo: z.string().min(1, 'El cuerpo del correo es obligatorio'),
    pago_ids: z.array(z.number().int().positive()).min(1, 'Debe incluir al menos un pago')
});

/**
 * Schema para actualizar un borrador de correo
 */
export const updateCorreoSchema = z.object({
    correo_seleccionado: z.string().email().optional(),
    asunto: z.string().min(1).max(255).optional(),
    cuerpo: z.string().min(1).optional()
});

/**
 * Schema para enviar un correo
 * No requiere body adicional, solo el ID del correo
 */
export const enviarCorreoSchema = z.object({
    // Opcionalmente permitir edición de último momento
    asunto: z.string().min(1).max(255).optional(),
    cuerpo: z.string().min(1).optional()
});

/**
 * Schema para validar ID de correo
 */
export const correoIdSchema = z.object({
    id: z.string().transform((val) => {
        const parsed = parseInt(val, 10);
        if (isNaN(parsed)) {
            throw new Error('ID de correo inválido');
        }
        return parsed;
    })
});

/**
 * Schema para filtros de búsqueda de correos
 */
export const correoFiltersSchema = z.object({
    estado: z.nativeEnum(EstadoCorreo).optional(),
    proveedor_id: z.string().transform((val) => parseInt(val, 10)).optional(),
    fecha_desde: z.string().datetime().optional(),
    fecha_hasta: z.string().datetime().optional()
}).optional();

// Tipos exportados
export type GenerarCorreosInput = z.infer<typeof generarCorreosSchema>;
export type CreateCorreoInput = z.infer<typeof createCorreoSchema>;
export type UpdateCorreoInput = z.infer<typeof updateCorreoSchema>;
export type EnviarCorreoInput = z.infer<typeof enviarCorreoSchema>;
export type CorreoFilters = z.infer<typeof correoFiltersSchema>;
