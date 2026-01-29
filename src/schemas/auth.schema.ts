import { z } from 'zod';

/**
 * Schema para login
 */
export const loginSchema = z.object({
  username: z.string()
    .min(1, 'El nombre de usuario es requerido'),
  password: z.string()
    .min(1, 'La contraseña es requerida')
});

/**
 * Schema para cambio de contraseña
 */
export const changePasswordSchema = z.object({
  password_actual: z.string()
    .min(1, 'La contraseña actual es requerida'),
  password_nueva: z.string()
    .min(6, 'La contraseña nueva debe tener al menos 6 caracteres')
});

export type LoginInput = z.infer<typeof loginSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
