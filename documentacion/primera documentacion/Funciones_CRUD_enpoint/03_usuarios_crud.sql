-- ============================================================================
-- FUNCIONES CRUD - TABLA: usuarios
-- ============================================================================

-- ========================================
-- GET: Obtener todos los usuarios o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION usuarios_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los usuarios
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuarios obtenidos exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', u.id,
                    'nombre_usuario', u.nombre_usuario,
                    'correo', u.correo,
                    'nombre_completo', u.nombre_completo,
                    'rol', json_build_object(
                        'id', r.id,
                        'nombre', r.nombre
                    ),
                    'telefono', u.telefono,
                    'activo', u.activo,
                    'fecha_creacion', u.fecha_creacion,
                    'fecha_actualizacion', u.fecha_actualizacion
                )
            ), '[]'::json)
        ) INTO v_result
        FROM usuarios u
        JOIN roles r ON u.rol_id = r.id
        ORDER BY u.id;
    ELSE
        -- Obtener un usuario específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuario obtenido exitosamente',
            'data', json_build_object(
                'id', u.id,
                'nombre_usuario', u.nombre_usuario,
                'correo', u.correo,
                'nombre_completo', u.nombre_completo,
                'rol', json_build_object(
                    'id', r.id,
                    'nombre', r.nombre
                ),
                'telefono', u.telefono,
                'activo', u.activo,
                'fecha_creacion', u.fecha_creacion,
                'fecha_actualizacion', u.fecha_actualizacion
            )
        ) INTO v_result
        FROM usuarios u
        JOIN roles r ON u.rol_id = r.id
        WHERE u.id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Usuario no encontrado',
                'data', null
            );
        END IF;
    END IF;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al obtener usuarios: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo usuario
-- ========================================
CREATE OR REPLACE FUNCTION usuarios_post(
    p_nombre_usuario VARCHAR,
    p_correo VARCHAR,
    p_contrasena VARCHAR,
    p_nombre_completo VARCHAR,
    p_rol_id INT,
    p_telefono VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
    v_hash VARCHAR;
BEGIN
    -- Validaciones
    IF p_nombre_usuario IS NULL OR TRIM(p_nombre_usuario) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre de usuario es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_correo IS NULL OR TRIM(p_correo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El correo es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_contrasena IS NULL OR LENGTH(p_contrasena) < 6 THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'La contraseña debe tener al menos 6 caracteres',
            'data', null
        );
    END IF;
    
    IF p_nombre_completo IS NULL OR TRIM(p_nombre_completo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre completo es obligatorio',
            'data', null
        );
    END IF;
    
    -- Verificar si el rol existe
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id = p_rol_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El rol especificado no existe',
            'data', null
        );
    END IF;
    
    -- Verificar si ya existe el nombre de usuario
    IF EXISTS (SELECT 1 FROM usuarios WHERE nombre_usuario = p_nombre_usuario) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un usuario con ese nombre de usuario',
            'data', null
        );
    END IF;
    
    -- Verificar si ya existe el correo
    IF EXISTS (SELECT 1 FROM usuarios WHERE correo = p_correo) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un usuario con ese correo',
            'data', null
        );
    END IF;
    
    -- Hashear la contraseña
    v_hash := crypt(p_contrasena, gen_salt('bf'));
    
    -- Insertar nuevo usuario
    INSERT INTO usuarios (
        nombre_usuario, correo, contrasena_hash, nombre_completo, 
        rol_id, telefono, activo
    )
    VALUES (
        p_nombre_usuario, p_correo, v_hash, p_nombre_completo,
        p_rol_id, p_telefono, p_activo
    )
    RETURNING id INTO v_id;
    
    -- Obtener el usuario creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Usuario creado exitosamente',
        'data', json_build_object(
            'id', u.id,
            'nombre_usuario', u.nombre_usuario,
            'correo', u.correo,
            'nombre_completo', u.nombre_completo,
            'rol', json_build_object(
                'id', r.id,
                'nombre', r.nombre
            ),
            'telefono', u.telefono,
            'activo', u.activo,
            'fecha_creacion', u.fecha_creacion
        )
    ) INTO v_result
    FROM usuarios u
    JOIN roles r ON u.rol_id = r.id
    WHERE u.id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear usuario: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un usuario existente
-- ========================================
CREATE OR REPLACE FUNCTION usuarios_put(
    p_id BIGINT,
    p_nombre_usuario VARCHAR DEFAULT NULL,
    p_correo VARCHAR DEFAULT NULL,
    p_contrasena VARCHAR DEFAULT NULL,
    p_nombre_completo VARCHAR DEFAULT NULL,
    p_rol_id INT DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_hash VARCHAR;
BEGIN
    -- Verificar si existe el usuario
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Usuario no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si el rol existe (si se proporciona)
    IF p_rol_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM roles WHERE id = p_rol_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El rol especificado no existe',
            'data', null
        );
    END IF;
    
    -- Hashear la contraseña si se proporciona
    IF p_contrasena IS NOT NULL THEN
        IF LENGTH(p_contrasena) < 6 THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'La contraseña debe tener al menos 6 caracteres',
                'data', null
            );
        END IF;
        v_hash := crypt(p_contrasena, gen_salt('bf'));
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE usuarios
    SET 
        nombre_usuario = COALESCE(p_nombre_usuario, nombre_usuario),
        correo = COALESCE(p_correo, correo),
        contrasena_hash = COALESCE(v_hash, contrasena_hash),
        nombre_completo = COALESCE(p_nombre_completo, nombre_completo),
        rol_id = COALESCE(p_rol_id, rol_id),
        telefono = COALESCE(p_telefono, telefono),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el usuario actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Usuario actualizado exitosamente',
        'data', json_build_object(
            'id', u.id,
            'nombre_usuario', u.nombre_usuario,
            'correo', u.correo,
            'nombre_completo', u.nombre_completo,
            'rol', json_build_object(
                'id', r.id,
                'nombre', r.nombre
            ),
            'telefono', u.telefono,
            'activo', u.activo,
            'fecha_creacion', u.fecha_creacion,
            'fecha_actualizacion', u.fecha_actualizacion
        )
    ) INTO v_result
    FROM usuarios u
    JOIN roles r ON u.rol_id = r.id
    WHERE u.id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar usuario: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar (desactivar) un usuario
-- ========================================
CREATE OR REPLACE FUNCTION usuarios_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el usuario
    SELECT nombre_completo INTO v_nombre FROM usuarios WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Usuario no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pagos WHERE usuario_id = p_id) THEN
        -- Desactivar en lugar de eliminar
        UPDATE usuarios SET activo = FALSE WHERE id = p_id;
        
        RETURN json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuario desactivado exitosamente (tiene pagos asociados)',
            'data', json_build_object('nombre', v_nombre, 'desactivado', true)
        );
    ELSE
        -- Eliminar el usuario
        DELETE FROM usuarios WHERE id = p_id;
        
        RETURN json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuario eliminado exitosamente',
            'data', json_build_object('nombre', v_nombre, 'eliminado', true)
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar usuario: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los usuarios
SELECT usuarios_get();

-- GET: Obtener un usuario específico
SELECT usuarios_get(1);

-- POST: Crear un nuevo usuario
SELECT usuarios_post(
    'jperez', 
    'jperez@terracanada.com', 
    'password123', 
    'Juan Pérez', 
    1, 
    '+1234567890', 
    true
);

-- PUT: Actualizar un usuario
SELECT usuarios_put(
    1, 
    NULL, 
    'juan.perez@terracanada.com', 
    NULL, 
    'Juan Carlos Pérez', 
    NULL, 
    NULL, 
    NULL
);

-- DELETE: Eliminar/Desactivar un usuario
SELECT usuarios_delete(1);
*/
