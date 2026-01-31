-- ============================================================================
-- FUNCIONES CRUD - TABLA: envios_correos
-- ============================================================================

-- ========================================
-- GET: Obtener todos los correos o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION envios_correos_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los correos
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correos obtenidos exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', e.id,
                    'proveedor', json_build_object(
                        'id', p.id,
                        'nombre', p.nombre,
                        'lenguaje', p.lenguaje
                    ),
                    'estado', e.estado,
                    'cantidad_pagos', e.cantidad_pagos,
                    'monto_total', e.monto_total,
                    'correo_destino', e.correo_destino,
                    'asunto', e.asunto,
                    'usuario_envio', CASE 
                        WHEN u.id IS NOT NULL THEN
                            json_build_object(
                                'id', u.id,
                                'nombre_completo', u.nombre_completo
                            )
                        ELSE NULL
                    END,
                    'fecha_creacion', e.fecha_creacion,
                    'fecha_envio', e.fecha_envio
                )
            ), '[]'::json)
        ) INTO v_result
        FROM envios_correos e
        JOIN proveedores p ON e.proveedor_id = p.id
        LEFT JOIN usuarios u ON e.usuario_envio_id = u.id
        ORDER BY e.fecha_creacion DESC;
    ELSE
        -- Obtener un correo específico con los pagos incluidos
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correo obtenido exitosamente',
            'data', json_build_object(
                'id', e.id,
                'proveedor', json_build_object(
                    'id', p.id,
                    'nombre', p.nombre,
                    'lenguaje', p.lenguaje,
                    'correos_disponibles', (
                        SELECT COALESCE(json_agg(
                            json_build_object(
                                'id', pc.id,
                                'correo', pc.correo,
                                'principal', pc.principal
                            )
                        ), '[]'::json)
                        FROM proveedor_correos pc
                        WHERE pc.proveedor_id = p.id AND pc.activo = TRUE
                    )
                ),
                'estado', e.estado,
                'cantidad_pagos', e.cantidad_pagos,
                'monto_total', e.monto_total,
                'correo_destino', e.correo_destino,
                'asunto', e.asunto,
                'cuerpo', e.cuerpo,
                'pagos_incluidos', (
                    SELECT COALESCE(json_agg(
                        json_build_object(
                            'id', pa.id,
                            'codigo_reserva', pa.codigo_reserva,
                            'monto', pa.monto,
                            'moneda', pa.moneda,
                            'descripcion', pa.descripcion
                        )
                    ), '[]'::json)
                    FROM correo_pago cp
                    JOIN pagos pa ON cp.pago_id = pa.id
                    WHERE cp.correo_id = e.id
                ),
                'usuario_envio', CASE 
                    WHEN u.id IS NOT NULL THEN
                        json_build_object(
                            'id', u.id,
                            'nombre_completo', u.nombre_completo
                        )
                    ELSE NULL
                END,
                'fecha_creacion', e.fecha_creacion,
                'fecha_envio', e.fecha_envio
            )
        ) INTO v_result
        FROM envios_correos e
        JOIN proveedores p ON e.proveedor_id = p.id
        LEFT JOIN usuarios u ON e.usuario_envio_id = u.id
        WHERE e.id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Correo no encontrado',
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
            'message', 'Error al obtener correos: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo correo (borrador)
-- ========================================
CREATE OR REPLACE FUNCTION envios_correos_post(
    p_proveedor_id BIGINT,
    p_usuario_envio_id BIGINT,
    p_asunto VARCHAR,
    p_cuerpo TEXT,
    p_pagos_ids BIGINT[]
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
    v_pago_id BIGINT;
    v_cantidad INT;
    v_monto_total DECIMAL;
BEGIN
    -- Validaciones
    IF p_asunto IS NULL OR TRIM(p_asunto) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El asunto es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_cuerpo IS NULL OR TRIM(p_cuerpo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El cuerpo del correo es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_pagos_ids IS NULL OR array_length(p_pagos_ids, 1) = 0 THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'Debe incluir al menos un pago en el correo',
            'data', null
        );
    END IF;
    
    -- Verificar que el proveedor existe
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id = p_proveedor_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El proveedor no existe',
            'data', null
        );
    END IF;
    
    -- Calcular cantidad y monto total
    SELECT COUNT(*), COALESCE(SUM(monto), 0)
    INTO v_cantidad, v_monto_total
    FROM pagos
    WHERE id = ANY(p_pagos_ids);
    
    -- Insertar nuevo correo como BORRADOR
    INSERT INTO envios_correos (
        proveedor_id, usuario_envio_id, estado, cantidad_pagos, 
        monto_total, asunto, cuerpo
    )
    VALUES (
        p_proveedor_id, p_usuario_envio_id, 'BORRADOR', v_cantidad,
        v_monto_total, p_asunto, p_cuerpo
    )
    RETURNING id INTO v_id;
    
    -- Vincular los pagos al correo
    FOREACH v_pago_id IN ARRAY p_pagos_ids
    LOOP
        -- Verificar que el pago existe y está pagado
        IF NOT EXISTS (SELECT 1 FROM pagos WHERE id = v_pago_id AND pagado = TRUE AND gmail_enviado = FALSE) THEN
            RAISE EXCEPTION 'El pago con ID % no existe, no está pagado, o ya fue enviado por correo', v_pago_id;
        END IF;
        
        INSERT INTO correo_pago (correo_id, pago_id)
        VALUES (v_id, v_pago_id);
    END LOOP;
    
    -- Obtener el correo creado
    RETURN envios_correos_get(v_id);
    
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
-- PUT: Actualizar un correo (enviar o editar)
-- ========================================
CREATE OR REPLACE FUNCTION envios_correos_put(
    p_id BIGINT,
    p_correo_destino VARCHAR DEFAULT NULL,
    p_asunto VARCHAR DEFAULT NULL,
    p_cuerpo TEXT DEFAULT NULL,
    p_enviar BOOLEAN DEFAULT FALSE
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_estado estado_correo;
    v_pagos_ids BIGINT[];
BEGIN
    -- Verificar si existe el correo
    SELECT estado INTO v_estado FROM envios_correos WHERE id = p_id;
    
    IF v_estado IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Correo no encontrado',
            'data', null
        );
    END IF;
    
    -- No se puede editar un correo ya enviado
    IF v_estado = 'ENVIADO' THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede editar un correo que ya fue enviado',
            'data', null
        );
    END IF;
    
    -- Si se va a enviar, validar correo destino
    IF p_enviar = TRUE THEN
        IF p_correo_destino IS NULL THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'Debe especificar el correo de destino para enviar',
                'data', null
            );
        END IF;
        
        -- Obtener los IDs de los pagos vinculados
        SELECT array_agg(pago_id) INTO v_pagos_ids
        FROM correo_pago
        WHERE correo_id = p_id;
        
        -- Marcar pagos como gmail_enviado = TRUE
        UPDATE pagos
        SET gmail_enviado = TRUE
        WHERE id = ANY(v_pagos_ids);
        
        -- Cambiar estado a ENVIADO y registrar fecha de envío
        UPDATE envios_correos
        SET 
            estado = 'ENVIADO',
            fecha_envio = NOW(),
            correo_destino = p_correo_destino,
            asunto = COALESCE(p_asunto, asunto),
            cuerpo = COALESCE(p_cuerpo, cuerpo)
        WHERE id = p_id;
    ELSE
        -- Solo actualizar contenido (mantener como BORRADOR)
        UPDATE envios_correos
        SET 
            correo_destino = COALESCE(p_correo_destino, correo_destino),
            asunto = COALESCE(p_asunto, asunto),
            cuerpo = COALESCE(p_cuerpo, cuerpo)
        WHERE id = p_id;
    END IF;
    
    -- Obtener el correo actualizado
    RETURN envios_correos_get(p_id);
    
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
-- DELETE: Eliminar un correo (solo BORRADORES)
-- ========================================
CREATE OR REPLACE FUNCTION envios_correos_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_estado estado_correo;
BEGIN
    -- Verificar si existe el correo
    SELECT estado INTO v_estado FROM envios_correos WHERE id = p_id;
    
    IF v_estado IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Correo no encontrado',
            'data', null
        );
    END IF;
    
    -- Solo se pueden eliminar borradores
    IF v_estado = 'ENVIADO' THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar un correo que ya fue enviado',
            'data', null
        );
    END IF;
    
    -- Eliminar vinculaciones con pagos
    DELETE FROM correo_pago WHERE correo_id = p_id;
    
    -- Eliminar el correo
    DELETE FROM envios_correos WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Correo eliminado exitosamente',
        'data', null
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
SELECT envios_correos_get();

-- GET: Obtener un correo específico
SELECT envios_correos_get(1);

-- POST: Crear un nuevo correo (borrador)
SELECT envios_correos_post(
    1,  -- proveedor_id
    1,  -- usuario_envio_id
    'Notificación de Pagos - Enero 2026',
    'Estimado proveedor, adjunto encontrará el detalle de los pagos realizados...',
    ARRAY[1,2,3]::BIGINT[]  -- pagos_ids
);

-- PUT: Editar el contenido de un borrador
SELECT envios_correos_put(
    1,  -- id
    'contacto@proveedor.com',  -- correo_destino
    'Notificación de Pagos Actualizados - Enero 2026',  -- asunto
    'Contenido actualizado del correo...',  -- cuerpo
    FALSE  -- NO enviar, solo editar
);

-- PUT: Enviar el correo
SELECT envios_correos_put(
    1,  -- id
    'contacto@proveedor.com',  -- correo_destino
    NULL,  -- asunto (mantiene el actual)
    NULL,  -- cuerpo (mantiene el actual)
    TRUE  -- SÍ enviar
);

-- DELETE: Eliminar un borrador
SELECT envios_correos_delete(1);
*/
