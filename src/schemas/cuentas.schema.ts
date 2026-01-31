import { z } from 'zod';

// Schema basado en las funciones PostgreSQL cuentas_bancarias_*
export const createCuentaSchema = z.object({
  nombre_banco: z.string().min(1).max(100),
  nombre_cuenta: z.string().min(1).max(100),
  ultimos_4_digitos: z.string().length(4).regex(/^\d{4}$/, 'Deben ser exactamente 4 dígitos numéricos'),
  moneda: z.enum(['USD', 'CAD']),
  activo: z.boolean().default(true).optional()
});

export const updateCuentaSchema = z.object({
  nombre_banco: z.string().min(1).max(100).optional(),
  nombre_cuenta: z.string().min(1).max(100).optional(),
  activo: z.boolean().optional()
});

export const cuentaIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateCuentaInput = z.infer<typeof createCuentaSchema>;
export type UpdateCuentaInput = z.infer<typeof updateCuentaSchema>;
