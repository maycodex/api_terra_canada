import { z } from 'zod';

export const correoProveedorSchema = z.object({
  correo: z.string().email(),
  principal: z.boolean().default(false)
});

export const createProveedorSchema = z.object({
  nombre: z.string().min(1).max(100),
  servicio_id: z.number().int().positive(),
  lenguaje: z.string().optional().nullable(),
  telefono: z.string().optional().nullable(),
  descripcion: z.string().optional().nullable(),
  correos: z.array(correoProveedorSchema).max(4, 'Máximo 4 correos permitidos').optional(),
  activo: z.boolean().default(true).optional()
});

export const updateProveedorSchema = z.object({
  nombre: z.string().min(1).max(100).optional(),
  servicio_id: z.number().int().positive().optional(),
  lenguaje: z.string().optional().nullable(),
  telefono: z.string().optional().nullable(),
  descripcion: z.string().optional().nullable(),
  activo: z.boolean().optional()
});

export const proveedorIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateProveedorInput = z.infer<typeof createProveedorSchema>;
export type UpdateProveedorInput = z.infer<typeof updateProveedorSchema>;
