import { z } from 'zod';

export const createClienteSchema = z.object({
  nombre: z.string().min(1).max(100),
  ubicacion: z.string().optional().nullable(),
  telefono: z.string().optional().nullable(),
  correo: z.string().email().optional().nullable(),
  activo: z.boolean().default(true).optional()
});

export const updateClienteSchema = z.object({
  nombre: z.string().min(1).max(100).optional(),
  ubicacion: z.string().optional().nullable(),
  telefono: z.string().optional().nullable(),
  correo: z.string().email().optional().nullable(),
  activo: z.boolean().optional()
});

export const clienteIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateClienteInput = z.infer<typeof createClienteSchema>;
export type UpdateClienteInput = z.infer<typeof updateClienteSchema>;
