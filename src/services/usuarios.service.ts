import { query } from '../config/database';
import { hashPassword } from '../utils/bcrypt.util';
import logger from '../config/logger';

export class UsuariosService {
  async getUsuarios(id?: number) {
    try {
      if (id) {
        const result = await query(
          `SELECT u.id, u.nombre_usuario, u.nombre_completo, u.correo, u.telefono, 
                  u.rol_id, u.activo, u.fecha_creacion, u.fecha_actualizacion,
                  r.nombre as rol_nombre, r.descripcion as rol_descripcion
           FROM usuarios u
           LEFT JOIN roles r ON u.rol_id = r.id
           WHERE u.id = $1`,
          [id]
        );
        return result.rows[0] || null;
      }

      const result = await query(
        `SELECT u.id, u.nombre_usuario, u.nombre_completo, u.correo, u.telefono,
                u.rol_id, u.activo, u.fecha_creacion,
                r.nombre as rol_nombre
         FROM usuarios u
         LEFT JOIN roles r ON u.rol_id = r.id
         WHERE u.activo = true
         ORDER BY u.nombre_usuario ASC`
      );
      return result.rows;
    } catch (error) {
      logger.error('Error al obtener usuarios:', error);
      throw error;
    }
  }

  async createUsuario(data: {
    nombre_usuario: string;
    nombre_completo: string;
    correo: string;
    telefono?: string | null;
    contrasena: string;
    rol_id: number;
    activo?: boolean;
  }) {
    try {
      // Verificar que el rol existe
      const rol = await query('SELECT id FROM roles WHERE id = $1', [data.rol_id]);
      if (rol.rows.length === 0) throw new Error('Rol no encontrado');

      // Verificar que no exista el usuario o correo
      const existing = await query(
        'SELECT id FROM usuarios WHERE nombre_usuario = $1 OR correo = $2',
        [data.nombre_usuario, data.correo]
      );
      if (existing.rows.length > 0) {
        throw new Error('Ya existe un usuario con ese nombre de usuario o correo');
      }

      // Hash de contraseña
      const contrasena_hash = await hashPassword(data.contrasena);

      const result = await query(
        `INSERT INTO usuarios (nombre_usuario, nombre_completo, correo, telefono, contrasena_hash, rol_id, activo)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, nombre_usuario, nombre_completo, correo, telefono, rol_id, activo`,
        [data.nombre_usuario, data.nombre_completo, data.correo, data.telefono || null,
         contrasena_hash, data.rol_id, data.activo !== false]
      );

      logger.info(`Usuario creado: ${result.rows[0].nombre_usuario}`);
      return await this.getUsuarios(result.rows[0].id);
    } catch (error) {
      logger.error('Error al crear usuario:', error);
      throw error;
    }
  }

  async updateUsuario(id: number, data: {
    nombre_usuario?: string;
    nombre_completo?: string;
    correo?: string;
    telefono?: string | null;
    contrasena?: string;
    rol_id?: number;
    activo?: boolean;
  }) {
    try {
      const existing = await query('SELECT * FROM usuarios WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Usuario no encontrado');

      if (data.rol_id) {
        const rol = await query('SELECT id FROM roles WHERE id = $1', [data.rol_id]);
        if (rol.rows.length === 0) throw new Error('Rol no encontrado');
      }

      // Verificar unicidad de usuario y correo
      if (data.nombre_usuario && data.nombre_usuario !== existing.rows[0].nombre_usuario) {
        const duplicate = await query('SELECT id FROM usuarios WHERE nombre_usuario = $1', [data.nombre_usuario]);
        if (duplicate.rows.length > 0) throw new Error('Ya existe un usuario con ese nombre de usuario');
      }

      if (data.correo && data.correo !== existing.rows[0].correo) {
        const duplicate = await query('SELECT id FROM usuarios WHERE correo = $1', [data.correo]);
        if (duplicate.rows.length > 0) throw new Error('Ya existe un usuario con ese correo');
      }

      const updates: string[] = ['fecha_actualizacion = CURRENT_TIMESTAMP'];
      const values: any[] = [];
      let paramCount = 1;

      if (data.nombre_usuario !== undefined) { updates.push(`nombre_usuario = $${paramCount++}`); values.push(data.nombre_usuario); }
      if (data.nombre_completo !== undefined) { updates.push(`nombre_completo = $${paramCount++}`); values.push(data.nombre_completo); }
      if (data.correo !== undefined) { updates.push(`correo = $${paramCount++}`); values.push(data.correo); }
      if (data.telefono !== undefined) { updates.push(`telefono = $${paramCount++}`); values.push(data.telefono); }
      if (data.rol_id !== undefined) { updates.push(`rol_id = $${paramCount++}`); values.push(data.rol_id); }
      if (data.activo !== undefined) { updates.push(`activo = $${paramCount++}`); values.push(data.activo); }
      
      if (data.contrasena) {
        const contrasena_hash = await hashPassword(data.contrasena);
        updates.push(`contrasena_hash = $${paramCount++}`);
        values.push(contrasena_hash);
      }

      values.push(id);
      await query(`UPDATE usuarios SET ${updates.join(', ')} WHERE id = $${paramCount}`, values);

      logger.info(`Usuario actualizado: ${data.nombre_usuario || existing.rows[0].nombre_usuario}`);
      return await this.getUsuarios(id);
    } catch (error) {
      logger.error('Error al actualizar usuario:', error);
      throw error;
    }
  }

  async deleteUsuario(id: number) {
    try {
      const existing = await query('SELECT * FROM usuarios WHERE id = $1', [id]);
      if (existing.rows.length === 0) throw new Error('Usuario no encontrado');

      // Soft delete
      await query('UPDATE usuarios SET activo = false WHERE id = $1', [id]);
      logger.info(`Usuario desactivado: ${existing.rows[0].nombre_usuario}`);
      return existing.rows[0];
    } catch (error) {
      logger.error('Error al eliminar usuario:', error);
      throw error;
    }
  }
}

export const usuariosService = new UsuariosService();
