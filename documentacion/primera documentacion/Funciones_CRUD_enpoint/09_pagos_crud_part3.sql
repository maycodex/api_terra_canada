-- ============================================================================
-- FUNCIONES CRUD - TABLA: pagos (CORE) - PARTE 3: PUT y DELETE
-- ============================================================================

-- ========================================
-- PUT: Actualizar un pago existente
-- ========================================
CREATE OR REPLACE FUNCTION pagos_put(
    p_id BIGINT,
    p_monto DECIMAL DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
    p_fecha_esperada_debito DATE DEFAULT NULL,
    p_pagado BOOLEAN DEFAULT NULL,
    p_verificado BOOLEAN DEFAULT NULL,
    p_gmail_enviado BOOLEAN DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_verificado_actual BOOLEAN;
    v_gmail_enviado_actual BOOLEAN;
    v_monto_actual DECIMAL;
    v_tipo_medio tipo_medio_pago;
    v_tarjeta_id BIGINT;
BEGIN
    -- Verificar si existe el pago
    SELECT verificado, gmail_enviado, monto, tipo_medio_pago, tarjeta_id
    INTO v_verificado_actual, v_gmail_enviado_actual, v_monto_actual, v_tipo_medio, v_tarjeta_id
    FROM pagos
    WHERE id = p_id;
    
    IF v_verificado_actual IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Pago no encontrado',
            'data', null
        );
    END IF;
    
    -- === VALIDACIONES DE REGLAS DE NEGOCIO ===
    
    -- No se puede editar un pago verificado
    IF v_verificado_actual = TRUE AND p_id IS NOT NULL THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede editar un pago que ya está verificado',
            'data', null
        );
    END IF;
    
    -- No se puede cambiar el monto si es con tarjeta (ya se descontó)
    IF p_monto IS NOT NULL AND p_monto != v_monto_actual AND v_tipo_medio = 'TARJETA' THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede cambiar el monto de un pago con tarjeta (ya se descontó el saldo)',
            'data', null
        );
    END IF;
    
    -- Si se cambia verificado a TRUE, debe tener pagado = TRUE
    IF p_verificado = TRUE THEN
        UPDATE pagos SET pagado = TRUE WHERE id = p_id AND pagado = FALSE;
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE pagos
    SET 
        monto = COALESCE(p_monto, monto),
        descripcion = COALESCE(p_descripcion, descripcion),
        fecha_esperada_debito = COALESCE(p_fecha_esperada_debito, fecha_esperada_debito),
        pagado = COALESCE(p_pagado, pagado),
        verificado = COALESCE(p_verificado, verificado),
        gmail_enviado = COALESCE(p_gmail_enviado, gmail_enviado),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el pago actualizado
    RETURN pagos_get(p_id);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar pago: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un pago
-- ========================================
CREATE OR REPLACE FUNCTION pagos_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_codigo VARCHAR;
    v_gmail_enviado BOOLEAN;
    v_monto DECIMAL;
    v_tipo_medio tipo_medio_pago;
    v_tarjeta_id BIGINT;
BEGIN
    -- Verificar si existe el pago y obtener datos
    SELECT codigo_reserva, gmail_enviado, monto, tipo_medio_pago, tarjeta_id
    INTO v_codigo, v_gmail_enviado, v_monto, v_tipo_medio, v_tarjeta_id
    FROM pagos
    WHERE id = p_id;
    
    IF v_codigo IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Pago no encontrado',
            'data', null
        );
    END IF;
    
    -- No se puede eliminar si gmail_enviado = TRUE
    IF v_gmail_enviado = TRUE THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar un pago que ya fue notificado por correo',
            'data', null
        );
    END IF;
    
    -- Si es pago con tarjeta, DEVOLVER el monto al saldo
    IF v_tipo_medio = 'TARJETA' AND v_tarjeta_id IS NOT NULL THEN
        UPDATE tarjetas_credito
        SET saldo_disponible = saldo_disponible + v_monto
        WHERE id = v_tarjeta_id;
    END IF;
    
    -- Eliminar relaciones con clientes
    DELETE FROM pago_cliente WHERE pago_id = p_id;
    
    -- Eliminar el pago
    DELETE FROM pagos WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Pago eliminado exitosamente',
        'data', json_build_object(
            'codigo_reserva', v_codigo,
            'monto_devuelto', CASE WHEN v_tipo_medio = 'TARJETA' THEN v_monto ELSE 0 END
        )
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar pago: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los pagos
SELECT pagos_get();

-- GET: Obtener un pago específico
SELECT pagos_get(1);

-- PUT: Actualizar un pago (solo campos permitidos)
SELECT pagos_put(
    1,                          -- id
    NULL,                       -- monto (NULL = no cambia)
    'Descripción actualizada',  -- descripcion
    '2026-03-01',               -- fecha_esperada_debito
    TRUE,                       -- pagado
    NULL,                       -- verificado
    NULL,                       -- gmail_enviado
    NULL                        -- activo
);

-- PUT: Marcar un pago como pagado
SELECT pagos_put(
    1,                          -- id
    NULL, NULL, NULL,
    TRUE,                       -- pagado
    NULL, NULL, NULL
);

-- PUT: Marcar un pago como verificado (automáticamente marca pagado también)
SELECT pagos_put(
    1,                          -- id
    NULL, NULL, NULL, NULL,
    TRUE,                       -- verificado
    NULL, NULL
);

-- DELETE: Eliminar un pago
SELECT pagos_delete(1);
*/
