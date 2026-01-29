import { z } from 'zod';

export const createTarjetaSchema = z.object({
  numero_tarjeta_encriptado: z.string().min(1),
  titular: z.string().min(1).max(100),
  tipo: z.enum(['VISA', 'MASTERCARD', 'AMEX', 'OTRO']),
  saldo_asignado: z.number().min(0),
  saldo_disponible: z.number().min(0).optional(),
  cliente_id: z.number().int().positive(),
  fecha_vencimiento: z.string().optional().nullable(),
  activo: z.boolean().default(true).optional()
});

export const updateTarjetaSchema = z.object({
  titular: z.string().min(1).max(100).optional(),
  tipo: z.enum(['VISA', 'MASTERCARD', 'AMEX', 'OTRO']).optional(),
  saldo_asignado: z.number().min(0).optional(),
  cliente_id: z.number().int().positive().optional(),
  fecha_vencimiento: z.string().optional().nullable(),
  activo: z.boolean().optional()
});

export const recargarTarjetaSchema = z.object({
  monto: z.number().positive()
});

export const tarjetaIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateTarjetaInput = z.infer<typeof createTarjetaSchema>;
export type UpdateTarjetaInput = z.infer<typeof updateTarjetaSchema>;
export type RecargarTarjetaInput = z.infer<typeof recargarTarjetaSchema>;
