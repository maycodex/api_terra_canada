-- ============================================================================
-- FUNCIONES CRUD - TABLA: cuentas_bancarias
-- ============================================================================

-- ========================================
-- GET: Obtener todas las cuentas o una específica
-- ========================================
CREATE OR REPLACE FUNCTION cuentas_bancarias_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todas las cuentas
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Cuentas bancarias obtenidas exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', id,
                    'nombre_banco', nombre_banco,
                    'nombre_cuenta', nombre_cuenta,
                    'ultimos_4_digitos', ultimos_4_digitos,
                    'moneda', moneda,
                    'activo', activo,
                    'fecha_creacion', fecha_creacion,
                    'fecha_actualizacion', fecha_actualizacion
                )
            ), '[]'::json)
        ) INTO v_result
        FROM cuentas_bancarias
        ORDER BY activo DESC, nombre_banco;
    ELSE
        -- Obtener una cuenta específica
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Cuenta bancaria obtenida exitosamente',
            'data', json_build_object(
                'id', id,
                'nombre_banco', nombre_banco,
                'nombre_cuenta', nombre_cuenta,
                'ultimos_4_digitos', ultimos_4_digitos,
                'moneda', moneda,
                'activo', activo,
                'fecha_creacion', fecha_creacion,
                'fecha_actualizacion', fecha_actualizacion
            )
        ) INTO v_result
        FROM cuentas_bancarias
        WHERE id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Cuenta bancaria no encontrada',
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
            'message', 'Error al obtener cuentas bancarias: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear una nueva cuenta bancaria
-- ========================================
CREATE OR REPLACE FUNCTION cuentas_bancarias_post(
    p_nombre_banco VARCHAR,
    p_nombre_cuenta VARCHAR,
    p_ultimos_4_digitos VARCHAR,
    p_moneda tipo_moneda,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre_banco IS NULL OR TRIM(p_nombre_banco) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre del banco es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_nombre_cuenta IS NULL OR TRIM(p_nombre_cuenta) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre de la cuenta es obligatorio',
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
    
    -- Insertar nueva cuenta bancaria
    INSERT INTO cuentas_bancarias (
        nombre_banco, nombre_cuenta, ultimos_4_digitos, moneda, activo
    )
    VALUES (
        p_nombre_banco, p_nombre_cuenta, p_ultimos_4_digitos, p_moneda, p_activo
    )
    RETURNING id INTO v_id;
    
    -- Obtener la cuenta creada
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Cuenta bancaria creada exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre_banco', nombre_banco,
            'nombre_cuenta', nombre_cuenta,
            'ultimos_4_digitos', ultimos_4_digitos,
            'moneda', moneda,
            'activo', activo,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM cuentas_bancarias
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear cuenta bancaria: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar una cuenta bancaria existente
-- ========================================
CREATE OR REPLACE FUNCTION cuentas_bancarias_put(
    p_id BIGINT,
    p_nombre_banco VARCHAR DEFAULT NULL,
    p_nombre_cuenta VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe la cuenta
    IF NOT EXISTS (SELECT 1 FROM cuentas_bancarias WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Cuenta bancaria no encontrada',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE cuentas_bancarias
    SET 
        nombre_banco = COALESCE(p_nombre_banco, nombre_banco),
        nombre_cuenta = COALESCE(p_nombre_cuenta, nombre_cuenta),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener la cuenta actualizada
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Cuenta bancaria actualizada exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre_banco', nombre_banco,
            'nombre_cuenta', nombre_cuenta,
            'ultimos_4_digitos', ultimos_4_digitos,
            'moneda', moneda,
            'activo', activo,
            'fecha_creacion', fecha_creacion,
            'fecha_actualizacion', fecha_actualizacion
        )
    ) INTO v_result
    FROM cuentas_bancarias
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar cuenta bancaria: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar una cuenta bancaria
-- ========================================
CREATE OR REPLACE FUNCTION cuentas_bancarias_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
    v_banco VARCHAR;
BEGIN
    -- Verificar si existe la cuenta
    SELECT nombre_cuenta, nombre_banco 
    INTO v_nombre, v_banco
    FROM cuentas_bancarias 
    WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Cuenta bancaria no encontrada',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pagos WHERE cuenta_bancaria_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar la cuenta porque tiene pagos asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar la cuenta
    DELETE FROM cuentas_bancarias WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Cuenta bancaria eliminada exitosamente',
        'data', json_build_object(
            'nombre_cuenta', v_nombre,
            'nombre_banco', v_banco
        )
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar cuenta bancaria: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todas las cuentas bancarias
SELECT cuentas_bancarias_get();

-- GET: Obtener una cuenta específica
SELECT cuentas_bancarias_get(1);

-- POST: Crear una nueva cuenta bancaria
SELECT cuentas_bancarias_post(
    'Banco Nacional', 
    'Cuenta Corriente Empresarial', 
    '5678', 
    'CAD',
    true
);

-- PUT: Actualizar una cuenta bancaria
SELECT cuentas_bancarias_put(
    1, 
    'Banco Nacional de Canadá', 
    'Cuenta Empresarial Premium',
    NULL
);

-- DELETE: Eliminar una cuenta bancaria
SELECT cuentas_bancarias_delete(1);
*/
