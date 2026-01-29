import { z } from 'zod';

export const createUsuarioSchema = z.object({
  nombre_usuario: z.string().min(3).max(50),
  nombre_completo: z.string().min(1).max(100),
  correo: z.string().email(),
  telefono: z.string().optional().nullable(),
  contrasena: z.string().min(6),
  rol_id: z.number().int().positive(),
  activo: z.boolean().default(true).optional()
});

export const updateUsuarioSchema = z.object({
  nombre_usuario: z.string().min(3).max(50).optional(),
  nombre_completo: z.string().min(1).max(100).optional(),
  correo: z.string().email().optional(),
  telefono: z.string().optional().nullable(),
  contrasena: z.string().min(6).optional(),
  rol_id: z.number().int().positive().optional(),
  activo: z.boolean().optional()
});

export const usuarioIdSchema = z.object({
  id: z.string().transform((val) => parseInt(val, 10))
});

export type CreateUsuarioInput = z.infer<typeof createUsuarioSchema>;
export type UpdateUsuarioInput = z.infer<typeof updateUsuarioSchema>;
