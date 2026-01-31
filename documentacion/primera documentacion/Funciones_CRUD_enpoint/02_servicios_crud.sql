-- ============================================================================
-- FUNCIONES CRUD - TABLA: servicios
-- ============================================================================

-- ========================================
-- GET: Obtener todos los servicios o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION servicios_get(p_id INT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los servicios
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Servicios obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', id,
                        'nombre', nombre,
                        'descripcion', descripcion,
                        'activo', activo,
                        'fecha_creacion', fecha_creacion
                    )
                    ORDER BY nombre
                ) FROM servicios),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
        -- Obtener un servicio específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Servicio obtenido exitosamente',
            'data', json_build_object(
                'id', id,
                'nombre', nombre,
                'descripcion', descripcion,
                'activo', activo,
                'fecha_creacion', fecha_creacion
            )
        ) INTO v_result
        FROM servicios
        WHERE id = p_id;
        
        IF NOT FOUND THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Servicio no encontrado',
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
            'message', 'Error al obtener servicios: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo servicio
-- ========================================
CREATE OR REPLACE FUNCTION servicios_post(
    p_nombre VARCHAR,
    p_descripcion TEXT DEFAULT NULL,
    p_activo BOOLEAN DEFAULT TRUE
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
    IF EXISTS (SELECT 1 FROM servicios WHERE nombre = p_nombre) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un servicio con ese nombre',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo servicio
    INSERT INTO servicios (nombre, descripcion, activo)
    VALUES (p_nombre, p_descripcion, p_activo)
    RETURNING id INTO v_id;
    
    -- Obtener el servicio creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Servicio creado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'descripcion', descripcion,
            'activo', activo,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM servicios
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear servicio: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un servicio existente
-- ========================================
CREATE OR REPLACE FUNCTION servicios_put(
    p_id INT,
    p_nombre VARCHAR DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el servicio
    IF NOT EXISTS (SELECT 1 FROM servicios WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Servicio no encontrado',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE servicios
    SET 
        nombre = COALESCE(p_nombre, nombre),
        descripcion = COALESCE(p_descripcion, descripcion),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el servicio actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Servicio actualizado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'descripcion', descripcion,
            'activo', activo,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM servicios
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar servicio: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un servicio
-- ========================================
CREATE OR REPLACE FUNCTION servicios_delete(p_id INT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el servicio
    SELECT nombre INTO v_nombre FROM servicios WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Servicio no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si hay proveedores con este servicio
    IF EXISTS (SELECT 1 FROM proveedores WHERE servicio_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el servicio porque tiene proveedores asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar el servicio
    DELETE FROM servicios WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Servicio eliminado exitosamente',
        'data', json_build_object('nombre', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar servicio: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los servicios
SELECT servicios_get();

-- GET: Obtener un servicio específico
SELECT servicios_get(1);

-- POST: Crear un nuevo servicio
SELECT servicios_post('Transporte', 'Servicios de transporte turístico', true);

-- PUT: Actualizar un servicio
SELECT servicios_put(11, 'Transporte Premium', 'Servicios de transporte turístico premium', true);

-- DELETE: Eliminar un servicio
SELECT servicios_delete(11);
*/
