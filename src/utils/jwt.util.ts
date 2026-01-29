import jwt from 'jsonwebtoken';
import { config } from '../config/environment';

export interface JWTPayload {
  userId: number;
  username: string;
  roleId: number;
  roleName: string;
}

/**
 * Generar un token JWT
 */
export const generateToken = (payload: JWTPayload): string => {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn
  } as jwt.SignOptions);
};

/**
 * Generar un token de refresh
 */
export const generateRefreshToken = (payload: JWTPayload): string => {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.refreshExpiresIn
  } as jwt.SignOptions);
};

/**
 * Verificar y decodificar un token JWT
 */
export const verifyToken = (token: string): JWTPayload => {
  try {
    const decoded = jwt.verify(token, config.jwt.secret) as JWTPayload;
    return decoded;
  } catch (error) {
    throw new Error('Token inválido o expirado');
  }
};

/**
 * Decodificar un token sin verificar (útil para inspección)
 */
export const decodeToken = (token: string): JWTPayload | null => {
  try {
    return jwt.decode(token) as JWTPayload;
  } catch (error) {
    return null;
  }
};
