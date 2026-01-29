import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { sendError, HTTP_STATUS } from '../utils/response.util';

/**
 * Middleware de validación con Zod
 * Valida el body, query o params de la petición
 */
export const validate = (schema: ZodSchema, source: 'body' | 'query' | 'params' = 'body') => {
  return (req: Request, res: Response, next: NextFunction): Response | void => {
    try {
      // Obtener los datos a validar según la fuente
      const dataToValidate = req[source];
      
      // Validar con Zod
      const validatedData = schema.parse(dataToValidate);
      
      // Reemplazar los datos del request con los validados y transformados
      req[source] = validatedData as any;
      
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        // Formatear errores de Zod
        const errors = error.issues.map((err) => ({
          field: err.path.join('.'),
          message: err.message
        }));
        
        return sendError(
          res,
          HTTP_STATUS.BAD_REQUEST,
          'Error de validación',
          errors
        );
      }
      
      // Error inesperado
      return sendError(
        res,
        HTTP_STATUS.INTERNAL_SERVER_ERROR,
        'Error al validar datos'
      );
    }
  };
};
