-- ============================================================================
-- FUNCIONES CRUD - TABLA: documentos
-- ============================================================================

-- ========================================
-- GET: Obtener todos los documentos o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION documentos_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los documentos
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Documentos obtenidos exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', d.id,
                    'tipo_documento', d.tipo_documento,
                    'nombre_archivo', d.nombre_archivo,
                    'url_documento', d.url_documento,
                    'usuario_subida', json_build_object(
                        'id', u.id,
                        'nombre_completo', u.nombre_completo
                    ),
                    'procesado', d.procesado,
                    'pagos_vinculados', (
                        SELECT COUNT(*)
                        FROM documento_pago dp
                        WHERE dp.documento_id = d.id
                    ),
                    'fecha_subida', d.fecha_subida,
                    'fecha_procesamiento', d.fecha_procesamiento
                )
            ), '[]'::json)
        ) INTO v_result
        FROM documentos d
        LEFT JOIN usuarios u ON d.usuario_subida_id = u.id
        ORDER BY d.fecha_subida DESC;
    ELSE
        -- Obtener un documento específico con sus pagos vinculados
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Documento obtenido exitosamente',
            'data', json_build_object(
                'id', d.id,
                'tipo_documento', d.tipo_documento,
                'nombre_archivo', d.nombre_archivo,
                'url_documento', d.url_documento,
                'usuario_subida', json_build_object(
                    'id', u.id,
                    'nombre_completo', u.nombre_completo
                ),
                'procesado', d.procesado,
                'pagos_vinculados', (
                    SELECT COALESCE(json_agg(
                        json_build_object(
                            'id', p.id,
                            'codigo_reserva', p.codigo_reserva,
                            'monto', p.monto,
                            'pagado', p.pagado,
                            'verificado', p.verificado
                        )
                    ), '[]'::json)
                    FROM documento_pago dp
                    JOIN pagos p ON dp.pago_id = p.id
                    WHERE dp.documento_id = d.id
                ),
                'fecha_subida', d.fecha_subida,
                'fecha_procesamiento', d.fecha_procesamiento
            )
        ) INTO v_result
        FROM documentos d
        LEFT JOIN usuarios u ON d.usuario_subida_id = u.id
        WHERE d.id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Documento no encontrado',
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
            'message', 'Error al obtener documentos: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo documento
-- ========================================
CREATE OR REPLACE FUNCTION documentos_post(
    p_tipo_documento tipo_documento,
    p_nombre_archivo VARCHAR,
    p_url_documento TEXT,
    p_usuario_subida_id BIGINT,
    p_pago_id BIGINT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre_archivo IS NULL OR TRIM(p_nombre_archivo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre del archivo es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_url_documento IS NULL OR TRIM(p_url_documento) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'La URL del documento es obligatoria',
            'data', null
        );
    END IF;
    
    -- Verificar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = p_usuario_subida_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El usuario especificado no existe',
            'data', null
        );
    END IF;
    
    -- Si se proporciona pago_id, verificar que existe
    IF p_pago_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pagos WHERE id = p_pago_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El pago especificado no existe',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo documento
    INSERT INTO documentos (
        tipo_documento, nombre_archivo, url_documento, usuario_subida_id
    )
    VALUES (
        p_tipo_documento, p_nombre_archivo, p_url_documento, p_usuario_subida_id
    )
    RETURNING id INTO v_id;
    
    -- Si se proporcionó pago_id, vincular automáticamente
    IF p_pago_id IS NOT NULL THEN
        INSERT INTO documento_pago (documento_id, pago_id)
        VALUES (v_id, p_pago_id);
    END IF;
    
    -- Obtener el documento creado
    RETURN documentos_get(v_id);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear documento: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un documento existente
-- ========================================
CREATE OR REPLACE FUNCTION documentos_put(
    p_id BIGINT,
    p_procesado BOOLEAN DEFAULT NULL,
    p_fecha_procesamiento TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el documento
    IF NOT EXISTS (SELECT 1 FROM documentos WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Documento no encontrado',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE documentos
    SET 
        procesado = COALESCE(p_procesado, procesado),
        fecha_procesamiento = COALESCE(p_fecha_procesamiento, fecha_procesamiento)
    WHERE id = p_id;
    
    -- Obtener el documento actualizado
    RETURN documentos_get(p_id);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar documento: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un documento
-- ========================================
CREATE OR REPLACE FUNCTION documentos_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
    v_tiene_verificados BOOLEAN;
BEGIN
    -- Verificar si existe el documento
    SELECT nombre_archivo INTO v_nombre FROM documentos WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Documento no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos verificados vinculados
    SELECT EXISTS (
        SELECT 1
        FROM documento_pago dp
        JOIN pagos p ON dp.pago_id = p.id
        WHERE dp.documento_id = p_id AND p.verificado = TRUE
    ) INTO v_tiene_verificados;
    
    IF v_tiene_verificados THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el documento porque tiene pagos verificados vinculados',
            'data', null
        );
    END IF;
    
    -- Eliminar vinculaciones con pagos
    DELETE FROM documento_pago WHERE documento_id = p_id;
    
    -- Eliminar el documento
    DELETE FROM documentos WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Documento eliminado exitosamente',
        'data', json_build_object('nombre_archivo', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar documento: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los documentos
SELECT documentos_get();

-- GET: Obtener un documento específico
SELECT documentos_get(1);

-- POST: Crear un nuevo documento (FACTURA vinculada a un pago)
SELECT documentos_post(
    'FACTURA',
    'factura_RES-2026-001.pdf',
    'https://storage.terracanada.com/facturas/2026/01/factura_RES-2026-001.pdf',
    1,
    1  -- pago_id (opcional, para vincular directamente)
);

-- POST: Crear un nuevo documento (DOCUMENTO_BANCO sin vinculación inicial)
SELECT documentos_post(
    'DOCUMENTO_BANCO',
    'extracto_enero_2026.pdf',
    'https://storage.terracanada.com/extractos/2026/01/extracto_enero_2026.pdf',
    1,
    NULL  -- No se vincula inicialmente, lo hará N8N después
);

-- PUT: Marcar documento como procesado
SELECT documentos_put(
    1,
    TRUE,  -- procesado
    NOW()  -- fecha_procesamiento
);

-- DELETE: Eliminar un documento
SELECT documentos_delete(1);
*/
