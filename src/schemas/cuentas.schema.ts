import { z } from 'zod';

export const createCuentaSchema = z.object({
  numero_cuenta_encriptado: z.string().min(1),
  nombre_banco: z.string().min(1).max(100),
  tipo_cuenta: z.enum(['AHORROS', 'CORRIENTE', 'OTRO']),
  titular: z.string().min(1).max(100),
  cliente_id: z.number().int().positive(),
  activo: z.boolean().default(true).optional()
});

export const updateCuentaSchema = z.object({
  nombre_banco: z.string().min(1).max(100).optional(),
  tipo_cuenta: z.enum(['AHORROS', 'CORRIENTE', 'OTRO']).optional(),
  titular: z.string().min(1).max(100).optional(),
  cliente_id: z.number().int().positive().optional(),
  activo: z.boolean().optional()
});

export const cuentaIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateCuentaInput = z.infer<typeof createCuentaSchema>;
export type UpdateCuentaInput = z.infer<typeof updateCuentaSchema>;
