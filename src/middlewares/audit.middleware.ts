import { Request, Response, NextFunction } from 'express';
import prisma from '../config/database';
import { TipoEvento } from '../types/enums';
import logger from '../config/logger';

/**
 * Middleware de auditoría
 * Registra todas las acciones importantes en la tabla de eventos
 */
export const auditMiddleware = (tipoEvento: TipoEvento, entidadTipo: string) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    // Guardar el método original de res.json para interceptarlo
    const originalJson = res.json.bind(res);
    
    // Sobrescribir res.json para capturar la respuesta
    res.json = function(data: any) {
      // Solo auditar si la operación fue exitosa (código 2xx)
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Ejecutar auditoría de forma asíncrona sin bloquear la respuesta
        setImmediate(async () => {
          try {
            // Extraer ID de la entidad si está disponible
            let entidadId: number | null = null;
            if (data?.data?.id) {
              entidadId = Number(data.data.id);
            } else if (req.params.id) {
              entidadId = Number(req.params.id);
            }
            
            // Crear descripción del evento
            const descripcion = `${req.method} ${req.path} - ${data?.message || 'Operación completada'}`;
            
            // Registrar evento en la base de datos
            await prisma.eventos.create({
              data: {
                usuario_id: req.user?.userId || null,
                tipo_evento: tipoEvento,
                entidad_tipo: entidadTipo,
                entidad_id: entidadId,
                descripcion,
                ip_origen: req.ip || req.socket.remoteAddress || null,
                user_agent: req.get('user-agent') || null
              }
            });
            
            logger.info(`Evento auditado: ${tipoEvento} - ${entidadTipo} - ${descripcion}`);
          } catch (error) {
            // Solo logear el error, no afectar la respuesta al usuario
            logger.error('Error al auditar evento:', error);
          }
        });
      }
      
      // Enviar la respuesta original
      return originalJson(data);
    };
    
    next();
  };
};
