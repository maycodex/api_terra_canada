import { Request } from 'express';
import { JWTPayload } from '../utils/jwt.util';

// Extender el tipo Request de Express para incluir el usuario autenticado
declare global {
  namespace Express {
    interface Request {
      user?: JWTPayload;
    }
  }
}

export {};
