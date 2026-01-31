import { z } from 'zod';

// Schema basado en las funciones PostgreSQL pagos_*
export const createPagoSchema = z.object({
  proveedor_id: z.number().int().positive(),
  usuario_id: z.number().int().positive(),
  codigo_reserva: z.string().min(1).max(50),
  monto: z.number().positive(),
  moneda: z.enum(['USD', 'CAD']),
  tipo_medio_pago: z.enum(['TARJETA', 'CUENTA_BANCARIA']),
  tarjeta_id: z.number().int().positive().optional().nullable(),
  cuenta_bancaria_id: z.number().int().positive().optional().nullable(),
  clientes_ids: z.array(z.number().int().positive()).optional().nullable(),
  descripcion: z.string().optional().nullable(),
  fecha_esperada_debito: z.string().optional().nullable() // formato: YYYY-MM-DD
});

export const updatePagoSchema = z.object({
  monto: z.number().positive().optional(),
  descripcion: z.string().optional().nullable(),
  fecha_esperada_debito: z.string().optional().nullable(),
  pagado: z.boolean().optional(),
  verificado: z.boolean().optional(),
  gmail_enviado: z.boolean().optional(),
  activo: z.boolean().optional()
});

export const pagoIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreatePagoInput = z.infer<typeof createPagoSchema>;
export type UpdatePagoInput = z.infer<typeof updatePagoSchema>;
