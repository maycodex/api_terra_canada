-- ============================================================================
-- FUNCIONES CRUD - TABLA: pagos (CORE) - PARTE 2: POST
-- ============================================================================

-- ========================================
-- POST: Crear un nuevo pago
-- ========================================
CREATE OR REPLACE FUNCTION pagos_post(
    p_proveedor_id BIGINT,
    p_usuario_id BIGINT,
    p_codigo_reserva VARCHAR,
    p_monto DECIMAL,
    p_moneda tipo_moneda,
    p_tipo_medio_pago tipo_medio_pago,
    p_tarjeta_id BIGINT DEFAULT NULL,
    p_cuenta_bancaria_id BIGINT DEFAULT NULL,
    p_clientes_ids BIGINT[] DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
    p_fecha_esperada_debito DATE DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
    v_saldo_disponible DECIMAL;
    v_cliente_id BIGINT;
BEGIN
    -- === VALIDACIONES BÁSICAS ===
    IF p_codigo_reserva IS NULL OR TRIM(p_codigo_reserva) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El código de reserva es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El monto debe ser mayor a 0',
            'data', null
        );
    END IF;
    
    -- Verificar código de reserva único
    IF EXISTS (SELECT 1 FROM pagos WHERE codigo_reserva = p_codigo_reserva) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un pago con ese código de reserva',
            'data', null
        );
    END IF;
    
    -- Verificar que el proveedor existe
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id = p_proveedor_id AND activo = TRUE) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El proveedor no existe o está inactivo',
            'data', null
        );
    END IF;
    
    -- Verificar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = p_usuario_id AND activo = TRUE) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El usuario no existe o está inactivo',
            'data', null
        );
    END IF;
    
    -- === VALIDACIÓN DE MEDIO DE PAGO ===
    IF p_tipo_medio_pago = 'TARJETA' THEN
        -- Debe tener tarjeta_id y NO cuenta_bancaria_id
        IF p_tarjeta_id IS NULL THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'Debe especificar una tarjeta de crédito',
                'data', null
            );
        END IF;
        
        IF p_cuenta_bancaria_id IS NOT NULL THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'No puede especificar cuenta bancaria cuando el medio de pago es tarjeta',
                'data', null
            );
        END IF;
        
        -- Verificar que la tarjeta existe y está activa
        SELECT saldo_disponible INTO v_saldo_disponible
        FROM tarjetas_credito
        WHERE id = p_tarjeta_id AND activo = TRUE;
        
        IF v_saldo_disponible IS NULL THEN
            RETURN json_build_object(
                'code', 404,
                'estado', false,
                'message', 'La tarjeta no existe o está inactiva',
                'data', null
            );
        END IF;
        
        -- Verificar saldo suficiente
        IF v_saldo_disponible < p_monto THEN
            RETURN json_build_object(
                'code', 409,
                'estado', false,
                'message', 'Saldo insuficiente en la tarjeta. Disponible: ' || v_saldo_disponible,
                'data', json_build_object('saldo_disponible', v_saldo_disponible)
            );
        END IF;
        
        -- DESCONTAR EL SALDO DE LA TARJETA
        UPDATE tarjetas_credito
        SET saldo_disponible = saldo_disponible - p_monto
        WHERE id = p_tarjeta_id;
        
    ELSIF p_tipo_medio_pago = 'CUENTA_BANCARIA' THEN
        -- Debe tener cuenta_bancaria_id y NO tarjeta_id
        IF p_cuenta_bancaria_id IS NULL THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'Debe especificar una cuenta bancaria',
                'data', null
            );
        END IF;
        
        IF p_tarjeta_id IS NOT NULL THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'No puede especificar tarjeta cuando el medio de pago es cuenta bancaria',
                'data', null
            );
        END IF;
        
        -- Verificar que la cuenta existe y está activa
        IF NOT EXISTS (SELECT 1 FROM cuentas_bancarias WHERE id = p_cuenta_bancaria_id AND activo = TRUE) THEN
            RETURN json_build_object(
                'code', 404,
                'estado', false,
                'message', 'La cuenta bancaria no existe o está inactiva',
                'data', null
            );
        END IF;
        
        -- NOTA: Las cuentas bancarias NO descuentan saldo, solo registran
    END IF;
    
    -- === INSERTAR EL PAGO ===
    INSERT INTO pagos (
        proveedor_id, usuario_id, codigo_reserva, monto, moneda,
        tipo_medio_pago, tarjeta_id, cuenta_bancaria_id,
        descripcion, fecha_esperada_debito
    )
    VALUES (
        p_proveedor_id, p_usuario_id, p_codigo_reserva, p_monto, p_moneda,
        p_tipo_medio_pago, p_tarjeta_id, p_cuenta_bancaria_id,
        p_descripcion, p_fecha_esperada_debito
    )
    RETURNING id INTO v_id;
    
    -- === VINCULAR CLIENTES ===
    IF p_clientes_ids IS NOT NULL AND array_length(p_clientes_ids, 1) > 0 THEN
        FOREACH v_cliente_id IN ARRAY p_clientes_ids
        LOOP
            -- Verificar que el cliente existe
            IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = v_cliente_id AND activo = TRUE) THEN
                -- Revertir todo si algún cliente no existe
                RAISE EXCEPTION 'El cliente con ID % no existe o está inactivo', v_cliente_id;
            END IF;
            
            INSERT INTO pago_cliente (pago_id, cliente_id)
            VALUES (v_id, v_cliente_id);
        END LOOP;
    END IF;
    
    -- === OBTENER EL PAGO CREADO ===
    RETURN pagos_get(v_id);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear pago: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- POST: Crear un nuevo pago con TARJETA
SELECT pagos_post(
    1,                          -- proveedor_id
    1,                          -- usuario_id
    'RES-2026-001',             -- codigo_reserva
    500.00,                     -- monto
    'USD',                      -- moneda
    'TARJETA',                  -- tipo_medio_pago
    1,                          -- tarjeta_id
    NULL,                       -- cuenta_bancaria_id
    ARRAY[1,2]::BIGINT[],       -- clientes_ids
    'Pago de servicio de guía turística',  -- descripcion
    '2026-02-15'                -- fecha_esperada_debito
);

-- POST: Crear un nuevo pago con CUENTA BANCARIA
SELECT pagos_post(
    1,                          -- proveedor_id
    1,                          -- usuario_id
    'RES-2026-002',             -- codigo_reserva
    1200.00,                    -- monto
    'CAD',                      -- moneda
    'CUENTA_BANCARIA',          -- tipo_medio_pago
    NULL,                       -- tarjeta_id
    1,                          -- cuenta_bancaria_id
    ARRAY[1]::BIGINT[],         -- clientes_ids
    'Pago de servicio hotelero',  -- descripcion
    NULL                        -- fecha_esperada_debito
);
*/
