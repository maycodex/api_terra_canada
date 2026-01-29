import { z } from 'zod';
import { TipoMoneda, MedioPago, EstadoPago } from '../types/enums';

export const createPagoSchema = z.object({
  monto: z.number().positive(),
  moneda: z.nativeEnum(TipoMoneda),
  medio_pago: z.nativeEnum(MedioPago),
  proveedor_id: z.number().int().positive(),
  usuario_id: z.number().int().positive(),
  tarjeta_id: z.number().int().positive().optional().nullable(),
  cuenta_id: z.number().int().positive().optional().nullable(),
  observaciones: z.string().optional().nullable(),
  cliente_asociado_id: z.number().int().positive().optional().nullable()
});

export const updatePagoSchema = z.object({
  estado: z.nativeEnum(EstadoPago).optional(),
  observaciones: z.string().optional().nullable(),
  fecha_pago: z.string().optional().nullable()
});

export const pagoIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreatePagoInput = z.infer<typeof createPagoSchema>;
export type UpdatePagoInput = z.infer<typeof updatePagoSchema>;
