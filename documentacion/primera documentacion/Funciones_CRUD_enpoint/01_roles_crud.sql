-- ============================================================================
-- FUNCIONES CRUD - TABLA: roles
-- ============================================================================

-- ========================================
-- GET: Obtener todos los roles o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION roles_get(p_id INT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los roles
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Roles obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', id,
                        'nombre', nombre,
                        'descripcion', descripcion,
                        'fecha_creacion', fecha_creacion
                    )
                    ORDER BY id
                ) FROM roles),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
        -- Obtener un rol específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Rol obtenido exitosamente',
            'data', json_build_object(
                'id', id,
                'nombre', nombre,
                'descripcion', descripcion,
                'fecha_creacion', fecha_creacion
            )
        ) INTO v_result
        FROM roles
        WHERE id = p_id;
        
        IF NOT FOUND THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Rol no encontrado',
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
            'message', 'Error al obtener roles: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo rol
-- ========================================
CREATE OR REPLACE FUNCTION roles_post(
    p_nombre VARCHAR,
    p_descripcion TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_id INT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre es obligatorio',
            'data', null
        );
    END IF;
    
    -- Verificar si ya existe
    IF EXISTS (SELECT 1 FROM roles WHERE nombre = p_nombre) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un rol con ese nombre',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo rol
    INSERT INTO roles (nombre, descripcion)
    VALUES (p_nombre, p_descripcion)
    RETURNING id INTO v_id;
    
    -- Obtener el rol creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Rol creado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'descripcion', descripcion,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM roles
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear rol: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un rol existente
-- ========================================
CREATE OR REPLACE FUNCTION roles_put(
    p_id INT,
    p_nombre VARCHAR DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el rol
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Rol no encontrado',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE roles
    SET 
        nombre = COALESCE(p_nombre, nombre),
        descripcion = COALESCE(p_descripcion, descripcion)
    WHERE id = p_id;
    
    -- Obtener el rol actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Rol actualizado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'descripcion', descripcion,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM roles
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar rol: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un rol
-- ========================================
CREATE OR REPLACE FUNCTION roles_delete(p_id INT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el rol
    SELECT nombre INTO v_nombre FROM roles WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Rol no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si hay usuarios con este rol
    IF EXISTS (SELECT 1 FROM usuarios WHERE rol_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el rol porque tiene usuarios asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar el rol
    DELETE FROM roles WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Rol eliminado exitosamente',
        'data', json_build_object('nombre', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar rol: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los roles
SELECT roles_get();

-- GET: Obtener un rol específico
SELECT roles_get(1);

-- POST: Crear un nuevo rol
SELECT roles_post('CONTADOR', 'Rol para personal de contabilidad');

-- PUT: Actualizar un rol
SELECT roles_put(4, 'CONTADOR_SENIOR', 'Rol para contador senior');

-- DELETE: Eliminar un rol
SELECT roles_delete(4);
*/
