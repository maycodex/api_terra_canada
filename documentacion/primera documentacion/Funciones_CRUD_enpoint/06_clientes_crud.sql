-- ============================================================================
-- FUNCIONES CRUD - TABLA: clientes
-- ============================================================================

-- ========================================
-- GET: Obtener todos los clientes o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION clientes_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los clientes
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Clientes obtenidos exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', id,
                    'nombre', nombre,
                    'ubicacion', ubicacion,
                    'telefono', telefono,
                    'correo', correo,
                    'activo', activo,
                    'fecha_creacion', fecha_creacion,
                    'fecha_actualizacion', fecha_actualizacion
                )
            ), '[]'::json)
        ) INTO v_result
        FROM clientes
        ORDER BY nombre;
    ELSE
        -- Obtener un cliente específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Cliente obtenido exitosamente',
            'data', json_build_object(
                'id', id,
                'nombre', nombre,
                'ubicacion', ubicacion,
                'telefono', telefono,
                'correo', correo,
                'activo', activo,
                'fecha_creacion', fecha_creacion,
                'fecha_actualizacion', fecha_actualizacion
            )
        ) INTO v_result
        FROM clientes
        WHERE id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Cliente no encontrado',
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
            'message', 'Error al obtener clientes: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo cliente
-- ========================================
CREATE OR REPLACE FUNCTION clientes_post(
    p_nombre VARCHAR,
    p_ubicacion VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_correo VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
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
    
    -- Insertar nuevo cliente
    INSERT INTO clientes (nombre, ubicacion, telefono, correo, activo)
    VALUES (p_nombre, p_ubicacion, p_telefono, p_correo, p_activo)
    RETURNING id INTO v_id;
    
    -- Obtener el cliente creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Cliente creado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'ubicacion', ubicacion,
            'telefono', telefono,
            'correo', correo,
            'activo', activo,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM clientes
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear cliente: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un cliente existente
-- ========================================
CREATE OR REPLACE FUNCTION clientes_put(
    p_id BIGINT,
    p_nombre VARCHAR DEFAULT NULL,
    p_ubicacion VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_correo VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el cliente
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Cliente no encontrado',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE clientes
    SET 
        nombre = COALESCE(p_nombre, nombre),
        ubicacion = COALESCE(p_ubicacion, ubicacion),
        telefono = COALESCE(p_telefono, telefono),
        correo = COALESCE(p_correo, correo),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el cliente actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Cliente actualizado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'ubicacion', ubicacion,
            'telefono', telefono,
            'correo', correo,
            'activo', activo,
            'fecha_creacion', fecha_creacion,
            'fecha_actualizacion', fecha_actualizacion
        )
    ) INTO v_result
    FROM clientes
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar cliente: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un cliente
-- ========================================
CREATE OR REPLACE FUNCTION clientes_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el cliente
    SELECT nombre INTO v_nombre FROM clientes WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Cliente no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pago_cliente WHERE cliente_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el cliente porque tiene pagos asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar el cliente
    DELETE FROM clientes WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Cliente eliminado exitosamente',
        'data', json_build_object('nombre', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar cliente: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los clientes
SELECT clientes_get();

-- GET: Obtener un cliente específico
SELECT clientes_get(1);

-- POST: Crear un nuevo cliente
SELECT clientes_post(
    'Hotel Paradise', 
    'Cancún, México', 
    '+521234567890', 
    'info@hotelparadise.com',
    true
);

-- PUT: Actualizar un cliente
SELECT clientes_put(
    1, 
    'Hotel Paradise Resort', 
    NULL, 
    '+521234567899', 
    NULL,
    NULL
);

-- DELETE: Eliminar un cliente
SELECT clientes_delete(1);
*/
