import { z } from 'zod';

export const createServicioSchema = z.object({
  nombre: z.string().min(1).max(50),
  descripcion: z.string().optional().nullable(),
  activo: z.boolean().default(true).optional()
});

export const updateServicioSchema = z.object({
  nombre: z.string().min(1).max(50).optional(),
  descripcion: z.string().optional().nullable(),
  activo: z.boolean().optional()
});

export const servicioIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateServicioInput = z.infer<typeof createServicioSchema>;
export type UpdateServicioInput = z.infer<typeof updateServicioSchema>;
