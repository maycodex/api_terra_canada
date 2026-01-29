import { Response } from 'express';

export interface ApiResponse<T = any> {
  code: number;
  estado: boolean;
  message: string;
  data: T | null;
  errors?: Array<{
    field: string;
    message: string;
  }>;
}

/**
 * Enviar respuesta de éxito
 */
export const sendSuccess = <T>(
  res: Response,
  code: number,
  message: string,
  data: T | null = null
): Response => {
  const response: ApiResponse<T> = {
    code,
    estado: true,
    message,
    data
  };
  return res.status(code).json(response);
};

/**
 * Enviar respuesta de error
 */
export const sendError = (
  res: Response,
  code: number,
  message: string,
  errors?: Array<{ field: string; message: string }>
): Response => {
  const response: ApiResponse = {
    code,
    estado: false,
    message,
    data: null,
    ...(errors && { errors })
  };
  return res.status(code).json(response);
};

/**
 * Códigos de estado HTTP comunes
 */
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_SERVER_ERROR: 500
} as const;
