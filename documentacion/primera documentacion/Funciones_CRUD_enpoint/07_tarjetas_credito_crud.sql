-- ============================================================================
-- FUNCIONES CRUD - TABLA: tarjetas_credito
-- ============================================================================

-- ========================================
-- GET: Obtener todas las tarjetas o una específica
-- ========================================
CREATE OR REPLACE FUNCTION tarjetas_credito_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todas las tarjetas
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Tarjetas obtenidas exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', id,
                    'nombre_titular', nombre_titular,
                    'ultimos_4_digitos', ultimos_4_digitos,
                    'moneda', moneda,
                    'limite_mensual', limite_mensual,
                    'saldo_disponible', saldo_disponible,
                    'tipo_tarjeta', tipo_tarjeta,
                    'activo', activo,
                    'porcentaje_uso', ROUND((limite_mensual - saldo_disponible) * 100.0 / limite_mensual, 2),
                    'fecha_creacion', fecha_creacion,
                    'fecha_actualizacion', fecha_actualizacion
                )
            ), '[]'::json)
        ) INTO v_result
        FROM tarjetas_credito
        ORDER BY activo DESC, nombre_titular;
    ELSE
        -- Obtener una tarjeta específica
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Tarjeta obtenida exitosamente',
            'data', json_build_object(
                'id', id,
                'nombre_titular', nombre_titular,
                'ultimos_4_digitos', ultimos_4_digitos,
                'moneda', moneda,
                'limite_mensual', limite_mensual,
                'saldo_disponible', saldo_disponible,
                'tipo_tarjeta', tipo_tarjeta,
                'activo', activo,
                'porcentaje_uso', ROUND((limite_mensual - saldo_disponible) * 100.0 / limite_mensual, 2),
                'fecha_creacion', fecha_creacion,
                'fecha_actualizacion', fecha_actualizacion
            )
        ) INTO v_result
        FROM tarjetas_credito
        WHERE id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Tarjeta no encontrada',
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
            'message', 'Error al obtener tarjetas: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear una nueva tarjeta
-- ========================================
CREATE OR REPLACE FUNCTION tarjetas_credito_post(
    p_nombre_titular VARCHAR,
    p_ultimos_4_digitos VARCHAR,
    p_moneda tipo_moneda,
    p_limite_mensual DECIMAL,
    p_tipo_tarjeta VARCHAR DEFAULT 'Visa',
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre_titular IS NULL OR TRIM(p_nombre_titular) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre del titular es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_ultimos_4_digitos IS NULL OR p_ultimos_4_digitos !~ '^\d{4}$' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'Los últimos 4 dígitos deben ser exactamente 4 números',
            'data', null
        );
    END IF;
    
    IF p_limite_mensual IS NULL OR p_limite_mensual <= 0 THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El límite mensual debe ser mayor a 0',
            'data', null
        );
    END IF;
    
    -- Insertar nueva tarjeta (saldo inicial = límite)
    INSERT INTO tarjetas_credito (
        nombre_titular, ultimos_4_digitos, moneda, limite_mensual, 
        saldo_disponible, tipo_tarjeta, activo
    )
    VALUES (
        p_nombre_titular, p_ultimos_4_digitos, p_moneda, p_limite_mensual,
        p_limite_mensual, p_tipo_tarjeta, p_activo
    )
    RETURNING id INTO v_id;
    
    -- Obtener la tarjeta creada
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Tarjeta creada exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre_titular', nombre_titular,
            'ultimos_4_digitos', ultimos_4_digitos,
            'moneda', moneda,
            'limite_mensual', limite_mensual,
            'saldo_disponible', saldo_disponible,
            'tipo_tarjeta', tipo_tarjeta,
            'activo', activo,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM tarjetas_credito
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear tarjeta: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar una tarjeta existente
-- ========================================
CREATE OR REPLACE FUNCTION tarjetas_credito_put(
    p_id BIGINT,
    p_nombre_titular VARCHAR DEFAULT NULL,
    p_limite_mensual DECIMAL DEFAULT NULL,
    p_tipo_tarjeta VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_limite_actual DECIMAL;
    v_saldo_actual DECIMAL;
BEGIN
    -- Verificar si existe la tarjeta
    SELECT limite_mensual, saldo_disponible 
    INTO v_limite_actual, v_saldo_actual
    FROM tarjetas_credito 
    WHERE id = p_id;
    
    IF v_limite_actual IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Tarjeta no encontrada',
            'data', null
        );
    END IF;
    
    -- Si se cambia el límite mensual, ajustar el saldo proporcionalmente
    IF p_limite_mensual IS NOT NULL AND p_limite_mensual != v_limite_actual THEN
        IF p_limite_mensual <= 0 THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'El límite mensual debe ser mayor a 0',
                'data', null
            );
        END IF;
        
        -- Ajustar saldo manteniendo la proporción de uso
        UPDATE tarjetas_credito
        SET 
            limite_mensual = p_limite_mensual,
            saldo_disponible = p_limite_mensual - (v_limite_actual - v_saldo_actual),
            nombre_titular = COALESCE(p_nombre_titular, nombre_titular),
            tipo_tarjeta = COALESCE(p_tipo_tarjeta, tipo_tarjeta),
            activo = COALESCE(p_activo, activo)
        WHERE id = p_id;
    ELSE
        -- Actualizar campos no nulos sin tocar el saldo
        UPDATE tarjetas_credito
        SET 
            nombre_titular = COALESCE(p_nombre_titular, nombre_titular),
            tipo_tarjeta = COALESCE(p_tipo_tarjeta, tipo_tarjeta),
            activo = COALESCE(p_activo, activo)
        WHERE id = p_id;
    END IF;
    
    -- Obtener la tarjeta actualizada
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Tarjeta actualizada exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre_titular', nombre_titular,
            'ultimos_4_digitos', ultimos_4_digitos,
            'moneda', moneda,
            'limite_mensual', limite_mensual,
            'saldo_disponible', saldo_disponible,
            'tipo_tarjeta', tipo_tarjeta,
            'activo', activo,
            'porcentaje_uso', ROUND((limite_mensual - saldo_disponible) * 100.0 / limite_mensual, 2),
            'fecha_creacion', fecha_creacion,
            'fecha_actualizacion', fecha_actualizacion
        )
    ) INTO v_result
    FROM tarjetas_credito
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar tarjeta: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar una tarjeta
-- ========================================
CREATE OR REPLACE FUNCTION tarjetas_credito_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
    v_digitos VARCHAR;
BEGIN
    -- Verificar si existe la tarjeta
    SELECT nombre_titular, ultimos_4_digitos 
    INTO v_nombre, v_digitos
    FROM tarjetas_credito 
    WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Tarjeta no encontrada',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pagos WHERE tarjeta_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar la tarjeta porque tiene pagos asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar la tarjeta
    DELETE FROM tarjetas_credito WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Tarjeta eliminada exitosamente',
        'data', json_build_object(
            'nombre_titular', v_nombre,
            'ultimos_4_digitos', v_digitos
        )
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar tarjeta: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todas las tarjetas
SELECT tarjetas_credito_get();

-- GET: Obtener una tarjeta específica
SELECT tarjetas_credito_get(1);

-- POST: Crear una nueva tarjeta
SELECT tarjetas_credito_post(
    'Juan Pérez', 
    '1234', 
    'USD', 
    5000.00, 
    'Visa',
    true
);

-- PUT: Actualizar una tarjeta
SELECT tarjetas_credito_put(
    1, 
    'Juan Carlos Pérez', 
    6000.00, 
    'Visa Platinum',
    NULL
);

-- DELETE: Eliminar una tarjeta
SELECT tarjetas_credito_delete(1);
*/
