import { z } from 'zod';

/**
 * Schema para crear rol
 */
export const createRolSchema = z.object({
  nombre: z.string()
    .min(1, 'El nombre es requerido')
    .max(50, 'El nombre no puede exceder 50 caracteres'),
  descripcion: z.string()
    .optional()
    .nullable()
});

/**
 * Schema para actualizar rol
 */
export const updateRolSchema = z.object({
  nombre: z.string()
    .min(1, 'El nombre es requerido')
    .max(50, 'El nombre no puede exceder 50 caracteres')
    .optional(),
  descripcion: z.string()
    .optional()
    .nullable()
});

/**
 * Schema para parámetro ID
 */
export const rolIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateRolInput = z.infer<typeof createRolSchema>;
export type UpdateRolInput = z.infer<typeof updateRolSchema>;
export type RolIdInput = z.infer<typeof rolIdSchema>;
