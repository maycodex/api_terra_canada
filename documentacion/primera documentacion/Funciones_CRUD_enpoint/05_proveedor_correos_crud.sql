-- ============================================================================
-- FUNCIONES CRUD - TABLA: proveedor_correos
-- ============================================================================

-- ========================================
-- GET: Obtener todos los correos de proveedores o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION proveedor_correos_get(p_id INT DEFAULT NULL, p_proveedor_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NOT NULL THEN
        -- Obtener un correo específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correo obtenido exitosamente',
            'data', json_build_object(
                'id', pc.id,
                'proveedor', json_build_object(
                    'id', p.id,
                    'nombre', p.nombre
                ),
                'correo', pc.correo,
                'principal', pc.principal,
                'activo', pc.activo,
                'fecha_creacion', pc.fecha_creacion
            )
        ) INTO v_result
        FROM proveedor_correos pc
        JOIN proveedores p ON pc.proveedor_id = p.id
        WHERE pc.id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Correo no encontrado',
                'data', null
            );
        END IF;
    ELSIF p_proveedor_id IS NOT NULL THEN
        -- Obtener todos los correos de un proveedor específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correos del proveedor obtenidos exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', pc.id,
                    'correo', pc.correo,
                    'principal', pc.principal,
                    'activo', pc.activo,
                    'fecha_creacion', pc.fecha_creacion
                )
            ), '[]'::json)
        ) INTO v_result
        FROM proveedor_correos pc
        WHERE pc.proveedor_id = p_proveedor_id
        ORDER BY pc.principal DESC, pc.id;
    ELSE
        -- Obtener todos los correos de proveedores
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correos obtenidos exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', pc.id,
                    'proveedor', json_build_object(
                        'id', p.id,
                        'nombre', p.nombre
                    ),
                    'correo', pc.correo,
                    'principal', pc.principal,
                    'activo', pc.activo,
                    'fecha_creacion', pc.fecha_creacion
                )
            ), '[]'::json)
        ) INTO v_result
        FROM proveedor_correos pc
        JOIN proveedores p ON pc.proveedor_id = p.id
        ORDER BY p.nombre, pc.principal DESC;
    END IF;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al obtener correos: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo correo de proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedor_correos_post(
    p_proveedor_id BIGINT,
    p_correo VARCHAR,
    p_principal BOOLEAN DEFAULT FALSE,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id INT;
    v_result JSON;
    v_count INT;
BEGIN
    -- Validaciones
    IF p_correo IS NULL OR TRIM(p_correo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El correo es obligatorio',
            'data', null
        );
    END IF;
    
    -- Verificar si el proveedor existe
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id = p_proveedor_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El proveedor especificado no existe',
            'data', null
        );
    END IF;
    
    -- Verificar límite de 4 correos activos
    SELECT COUNT(*) INTO v_count
    FROM proveedor_correos
    WHERE proveedor_id = p_proveedor_id AND activo = TRUE;
    
    IF v_count >= 4 AND p_activo = TRUE THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'El proveedor ya tiene el máximo de 4 correos activos',
            'data', null
        );
    END IF;
    
    -- Si es principal, quitar el flag de los demás correos
    IF p_principal = TRUE THEN
        UPDATE proveedor_correos
        SET principal = FALSE
        WHERE proveedor_id = p_proveedor_id;
    END IF;
    
    -- Insertar nuevo correo
    INSERT INTO proveedor_correos (proveedor_id, correo, principal, activo)
    VALUES (p_proveedor_id, p_correo, p_principal, p_activo)
    RETURNING id INTO v_id;
    
    -- Obtener el correo creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Correo creado exitosamente',
        'data', json_build_object(
            'id', pc.id,
            'proveedor', json_build_object(
                'id', p.id,
                'nombre', p.nombre
            ),
            'correo', pc.correo,
            'principal', pc.principal,
            'activo', pc.activo,
            'fecha_creacion', pc.fecha_creacion
        )
    ) INTO v_result
    FROM proveedor_correos pc
    JOIN proveedores p ON pc.proveedor_id = p.id
    WHERE pc.id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear correo: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un correo de proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedor_correos_put(
    p_id INT,
    p_correo VARCHAR DEFAULT NULL,
    p_principal BOOLEAN DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_proveedor_id BIGINT;
BEGIN
    -- Verificar si existe el correo
    SELECT proveedor_id INTO v_proveedor_id FROM proveedor_correos WHERE id = p_id;
    
    IF v_proveedor_id IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Correo no encontrado',
            'data', null
        );
    END IF;
    
    -- Si se marca como principal, quitar el flag de los demás
    IF p_principal = TRUE THEN
        UPDATE proveedor_correos
        SET principal = FALSE
        WHERE proveedor_id = v_proveedor_id AND id != p_id;
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE proveedor_correos
    SET 
        correo = COALESCE(p_correo, correo),
        principal = COALESCE(p_principal, principal),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el correo actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Correo actualizado exitosamente',
        'data', json_build_object(
            'id', pc.id,
            'proveedor', json_build_object(
                'id', p.id,
                'nombre', p.nombre
            ),
            'correo', pc.correo,
            'principal', pc.principal,
            'activo', pc.activo,
            'fecha_creacion', pc.fecha_creacion
        )
    ) INTO v_result
    FROM proveedor_correos pc
    JOIN proveedores p ON pc.proveedor_id = p.id
    WHERE pc.id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar correo: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un correo de proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedor_correos_delete(p_id INT)
RETURNS JSON AS $$
DECLARE
    v_correo VARCHAR;
    v_proveedor_id BIGINT;
    v_count INT;
BEGIN
    -- Verificar si existe el correo
    SELECT correo, proveedor_id INTO v_correo, v_proveedor_id 
    FROM proveedor_correos 
    WHERE id = p_id;
    
    IF v_correo IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Correo no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar que no sea el último correo del proveedor
    SELECT COUNT(*) INTO v_count
    FROM proveedor_correos
    WHERE proveedor_id = v_proveedor_id AND activo = TRUE;
    
    IF v_count <= 1 THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el último correo activo del proveedor',
            'data', null
        );
    END IF;
    
    -- Eliminar el correo
    DELETE FROM proveedor_correos WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Correo eliminado exitosamente',
        'data', json_build_object('correo', v_correo)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar correo: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los correos
SELECT proveedor_correos_get();

-- GET: Obtener correos de un proveedor específico
SELECT proveedor_correos_get(NULL, 1);

-- GET: Obtener un correo específico
SELECT proveedor_correos_get(1);

-- POST: Crear un nuevo correo de proveedor
SELECT proveedor_correos_post(
    1, 
    'contacto@proveedor.com', 
    true, 
    true
);

-- PUT: Actualizar un correo
SELECT proveedor_correos_put(
    1, 
    'nuevo@proveedor.com', 
    NULL, 
    NULL
);

-- DELETE: Eliminar un correo
SELECT proveedor_correos_delete(2);
*/
