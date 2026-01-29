-- ============================================================================
-- FUNCIONES CRUD - TABLA: proveedores
-- ============================================================================

-- ========================================
-- GET: Obtener todos los proveedores o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION proveedores_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los proveedores
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Proveedores obtenidos exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', p.id,
                    'nombre', p.nombre,
                    'servicio', json_build_object(
                        'id', s.id,
                        'nombre', s.nombre
                    ),
                    'lenguaje', p.lenguaje,
                    'telefono', p.telefono,
                    'descripcion', p.descripcion,
                    'activo', p.activo,
                    'correos', (
                        SELECT COALESCE(json_agg(
                            json_build_object(
                                'id', pc.id,
                                'correo', pc.correo,
                                'principal', pc.principal,
                                'activo', pc.activo
                            )
                        ), '[]'::json)
                        FROM proveedor_correos pc
                        WHERE pc.proveedor_id = p.id AND pc.activo = TRUE
                    ),
                    'fecha_creacion', p.fecha_creacion,
                    'fecha_actualizacion', p.fecha_actualizacion
                )
            ), '[]'::json)
        ) INTO v_result
        FROM proveedores p
        JOIN servicios s ON p.servicio_id = s.id
        ORDER BY p.nombre;
    ELSE
        -- Obtener un proveedor específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Proveedor obtenido exitosamente',
            'data', json_build_object(
                'id', p.id,
                'nombre', p.nombre,
                'servicio', json_build_object(
                    'id', s.id,
                    'nombre', s.nombre
                ),
                'lenguaje', p.lenguaje,
                'telefono', p.telefono,
                'descripcion', p.descripcion,
                'activo', p.activo,
                'correos', (
                    SELECT COALESCE(json_agg(
                        json_build_object(
                            'id', pc.id,
                            'correo', pc.correo,
                            'principal', pc.principal,
                            'activo', pc.activo
                        )
                    ), '[]'::json)
                    FROM proveedor_correos pc
                    WHERE pc.proveedor_id = p.id AND pc.activo = TRUE
                ),
                'fecha_creacion', p.fecha_creacion,
                'fecha_actualizacion', p.fecha_actualizacion
            )
        ) INTO v_result
        FROM proveedores p
        JOIN servicios s ON p.servicio_id = s.id
        WHERE p.id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Proveedor no encontrado',
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
            'message', 'Error al obtener proveedores: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedores_post(
    p_nombre VARCHAR,
    p_servicio_id INT,
    p_lenguaje VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
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
    
    -- Verificar si el servicio existe
    IF NOT EXISTS (SELECT 1 FROM servicios WHERE id = p_servicio_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El servicio especificado no existe',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo proveedor
    INSERT INTO proveedores (
        nombre, servicio_id, lenguaje, telefono, descripcion, activo
    )
    VALUES (
        p_nombre, p_servicio_id, p_lenguaje, p_telefono, p_descripcion, p_activo
    )
    RETURNING id INTO v_id;
    
    -- Obtener el proveedor creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Proveedor creado exitosamente',
        'data', json_build_object(
            'id', p.id,
            'nombre', p.nombre,
            'servicio', json_build_object(
                'id', s.id,
                'nombre', s.nombre
            ),
            'lenguaje', p.lenguaje,
            'telefono', p.telefono,
            'descripcion', p.descripcion,
            'activo', p.activo,
            'fecha_creacion', p.fecha_creacion
        )
    ) INTO v_result
    FROM proveedores p
    JOIN servicios s ON p.servicio_id = s.id
    WHERE p.id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear proveedor: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un proveedor existente
-- ========================================
CREATE OR REPLACE FUNCTION proveedores_put(
    p_id BIGINT,
    p_nombre VARCHAR DEFAULT NULL,
    p_servicio_id INT DEFAULT NULL,
    p_lenguaje VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el proveedor
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Proveedor no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si el servicio existe (si se proporciona)
    IF p_servicio_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM servicios WHERE id = p_servicio_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El servicio especificado no existe',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE proveedores
    SET 
        nombre = COALESCE(p_nombre, nombre),
        servicio_id = COALESCE(p_servicio_id, servicio_id),
        lenguaje = COALESCE(p_lenguaje, lenguaje),
        telefono = COALESCE(p_telefono, telefono),
        descripcion = COALESCE(p_descripcion, descripcion),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el proveedor actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Proveedor actualizado exitosamente',
        'data', json_build_object(
            'id', p.id,
            'nombre', p.nombre,
            'servicio', json_build_object(
                'id', s.id,
                'nombre', s.nombre
            ),
            'lenguaje', p.lenguaje,
            'telefono', p.telefono,
            'descripcion', p.descripcion,
            'activo', p.activo,
            'fecha_creacion', p.fecha_creacion,
            'fecha_actualizacion', p.fecha_actualizacion
        )
    ) INTO v_result
    FROM proveedores p
    JOIN servicios s ON p.servicio_id = s.id
    WHERE p.id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar proveedor: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedores_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el proveedor
    SELECT nombre INTO v_nombre FROM proveedores WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Proveedor no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pagos WHERE proveedor_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el proveedor porque tiene pagos asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar el proveedor (también eliminará sus correos por CASCADE)
    DELETE FROM proveedores WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Proveedor eliminado exitosamente',
        'data', json_build_object('nombre', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar proveedor: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los proveedores
SELECT proveedores_get();

-- GET: Obtener un proveedor específico
SELECT proveedores_get(1);

-- POST: Crear un nuevo proveedor
SELECT proveedores_post(
    'Tour Guide Services', 
    8, 
    'English', 
    '+1234567890', 
    'Proveedor de servicios de guías turísticos',
    true
);

-- PUT: Actualizar un proveedor
SELECT proveedores_put(
    1, 
    'Premium Tour Guide Services', 
    NULL, 
    'English/French', 
    NULL, 
    'Proveedor premium de servicios de guías',
    NULL
);

-- DELETE: Eliminar un proveedor
SELECT proveedores_delete(1);
*/
