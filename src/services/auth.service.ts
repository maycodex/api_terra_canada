import { query } from '../config/database';
import { comparePassword } from '../utils/bcrypt.util';
import { generateToken, JWTPayload } from '../utils/jwt.util';
import logger from '../config/logger';

export interface LoginResult {
  token: string;
  user: {
    id: number;
    nombre_usuario: string;
    nombre_completo: string;
    correo: string;
    rol: {
      id: number;
      nombre: string;
      descripcion: string | null;
    };
  };
}

export class AuthService {
  async login(username: string, password: string): Promise<LoginResult | null> {
    try {
      // Buscar usuario por nombre de usuario o correo (con función de BD)
      const result = await query(
        `SELECT u.*, r.nombre as rol_nombre, r.descripcion as rol_descripcion
         FROM usuarios u
         INNER JOIN roles r ON u.rol_id = r.id
         WHERE (u.nombre_usuario = $1 OR u.correo = $1) AND u.activo = true
         LIMIT 1`,
        [username]
      );

      if (result.rows.length === 0) {
        logger.warn(`Intento de login fallido: usuario no encontrado - ${username}`);
        return null;
      }

      const usuario = result.rows[0];

      // Verificar contraseña
      const isPasswordValid = await comparePassword(password, usuario.contrasena_hash);
      
      if (!isPasswordValid) {
        logger.warn(`Intento de login fallido: contraseña incorrecta - ${username}`);
        return null;
      }

      // Generar token JWT
      const payload: JWTPayload = {
        userId: usuario.id,
        username: usuario.nombre_usuario,
        roleId: usuario.rol_id,
        roleName: usuario.rol_nombre
      };

      const token = generateToken(payload);

      logger.info(`Login exitoso: ${usuario.nombre_usuario} (${usuario.rol_nombre})`);

      return {
        token,
        user: {
          id: usuario.id,
          nombre_usuario: usuario.nombre_usuario,
          nombre_completo: usuario.nombre_completo,
          correo: usuario.correo,
          rol: {
            id: usuario.rol_id,
            nombre: usuario.rol_nombre,
            descripcion: usuario.rol_descripcion
          }
        }
      };
    } catch (error) {
      logger.error('Error en login:', error);
      throw error;
    }
  }

  async getMe(userId: number) {
    try {
      const result = await query(
        `SELECT u.*, r.nombre as rol_nombre, r.descripcion as rol_descripcion
         FROM usuarios u
         INNER JOIN roles r ON u.rol_id = r.id
         WHERE u.id = $1
         LIMIT 1`,
        [userId]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const usuario = result.rows[0];

      return {
        id: usuario.id,
        nombre_usuario: usuario.nombre_usuario,
        nombre_completo: usuario.nombre_completo,
        correo: usuario.correo,
        telefono: usuario.telefono,
        activo: usuario.activo,
        rol: {
          id: usuario.rol_id,
          nombre: usuario.rol_nombre,
          descripcion: usuario.rol_descripcion
        },
        fecha_creacion: usuario.fecha_creacion,
        fecha_actualizacion: usuario.fecha_actualizacion
      };
    } catch (error) {
      logger.error('Error al obtener usuario:', error);
      throw error;
    }
  }
}

export const authService = new AuthService();
