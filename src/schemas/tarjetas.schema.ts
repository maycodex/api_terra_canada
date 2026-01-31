import { z } from 'zod';

// Schema basado en las funciones PostgreSQL tarjetas_credito_*
export const createTarjetaSchema = z.object({
  nombre_titular: z.string().min(1).max(100),
  ultimos_4_digitos: z.string().length(4).regex(/^\d{4}$/, 'Deben ser exactamente 4 dígitos numéricos'),
  moneda: z.enum(['USD', 'CAD']),
  limite_mensual: z.number().positive(),
  tipo_tarjeta: z.string().min(1).max(50).default('Visa').optional(),
  activo: z.boolean().default(true).optional()
});

export const updateTarjetaSchema = z.object({
  nombre_titular: z.string().min(1).max(100).optional(),
  limite_mensual: z.number().positive().optional(),
  tipo_tarjeta: z.string().min(1).max(50).optional(),
  activo: z.boolean().optional()
});

export const tarjetaIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateTarjetaInput = z.infer<typeof createTarjetaSchema>;
export type UpdateTarjetaInput = z.infer<typeof updateTarjetaSchema>;
