-- ============================================================================
-- FUNCIONES CRUD - TABLA: eventos (AUDITORÍA)
-- ============================================================================

-- ========================================
-- GET: Obtener todos los eventos o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION eventos_get(
    p_id BIGINT DEFAULT NULL,
    p_limite INT DEFAULT 100,
    p_offset INT DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_total BIGINT;
BEGIN
    IF p_id IS NULL THEN
        -- Contar total de eventos
        SELECT COUNT(*) INTO v_total FROM eventos;
        
        -- Obtener eventos con paginación
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Eventos obtenidos exitosamente',
            'total', v_total,
            'limite', p_limite,
            'offset', p_offset,
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', e.id,
                    'usuario', CASE 
                        WHEN u.id IS NOT NULL THEN
                            json_build_object(
                                'id', u.id,
                                'nombre_completo', u.nombre_completo,
                                'rol', r.nombre
                            )
                        ELSE NULL
                    END,
                    'tipo_evento', e.tipo_evento,
                    'entidad_tipo', e.entidad_tipo,
                    'entidad_id', e.entidad_id,
                    'descripcion', e.descripcion,
                    'ip_origen', e.ip_origen,
                    'fecha_evento', e.fecha_evento
                )
            ), '[]'::json)
        ) INTO v_result
        FROM eventos e
        LEFT JOIN usuarios u ON e.usuario_id = u.id
        LEFT JOIN roles r ON u.rol_id = r.id
        ORDER BY e.fecha_evento DESC
        LIMIT p_limite
        OFFSET p_offset;
    ELSE
        -- Obtener un evento específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Evento obtenido exitosamente',
            'data', json_build_object(
                'id', e.id,
                'usuario', CASE 
                    WHEN u.id IS NOT NULL THEN
                        json_build_object(
                            'id', u.id,
                            'nombre_completo', u.nombre_completo,
                            'rol', r.nombre
                        )
                    ELSE NULL
                END,
                'tipo_evento', e.tipo_evento,
                'entidad_tipo', e.entidad_tipo,
                'entidad_id', e.entidad_id,
                'descripcion', e.descripcion,
                'ip_origen', e.ip_origen,
                'user_agent', e.user_agent,
                'fecha_evento', e.fecha_evento
            )
        ) INTO v_result
        FROM eventos e
        LEFT JOIN usuarios u ON e.usuario_id = u.id
        LEFT JOIN roles r ON u.rol_id = r.id
        WHERE e.id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Evento no encontrado',
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
            'message', 'Error al obtener eventos: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- POST: Crear un nuevo evento de auditoría
-- ========================================
CREATE OR REPLACE FUNCTION eventos_post(
    p_usuario_id BIGINT DEFAULT NULL,
    p_tipo_evento tipo_evento,
    p_entidad_tipo VARCHAR,
    p_entidad_id BIGINT DEFAULT NULL,
    p_descripcion TEXT,
    p_ip_origen INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_tipo_evento IS NULL THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El tipo de evento es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_entidad_tipo IS NULL OR TRIM(p_entidad_tipo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El tipo de entidad es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_descripcion IS NULL OR TRIM(p_descripcion) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'La descripción es obligatoria',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo evento
    INSERT INTO eventos (
        usuario_id, tipo_evento, entidad_tipo, entidad_id,
        descripcion, ip_origen, user_agent
    )
    VALUES (
        p_usuario_id, p_tipo_evento, p_entidad_tipo, p_entidad_id,
        p_descripcion, p_ip_origen, p_user_agent
    )
    RETURNING id INTO v_id;
    
    -- Obtener el evento creado
    RETURN eventos_get(v_id);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear evento: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: No permitido (auditoría es inmutable)
-- ========================================
CREATE OR REPLACE FUNCTION eventos_put(p_id BIGINT)
RETURNS JSON AS $$
BEGIN
    RETURN json_build_object(
        'code', 405,
        'estado', false,
        'message', 'No se pueden modificar eventos de auditoría (inmutables)',
        'data', null
    );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: No permitido (auditoría es inmutable)
-- ========================================
CREATE OR REPLACE FUNCTION eventos_delete(p_id BIGINT)
RETURNS JSON AS $$
BEGIN
    RETURN json_build_object(
        'code', 405,
        'estado', false,
        'message', 'No se pueden eliminar eventos de auditoría (inmutables)',
        'data', null
    );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- FUNCIONES ADICIONALES PARA CONSULTAS ESPECÍFICAS
-- ========================================

-- Obtener eventos por tipo
CREATE OR REPLACE FUNCTION eventos_get_por_tipo(
    p_tipo_evento tipo_evento,
    p_limite INT DEFAULT 100
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Eventos obtenidos exitosamente',
        'data', COALESCE(json_agg(
            json_build_object(
                'id', e.id,
                'usuario', CASE 
                    WHEN u.id IS NOT NULL THEN
                        json_build_object(
                            'id', u.id,
                            'nombre_completo', u.nombre_completo
                        )
                    ELSE NULL
                END,
                'entidad_tipo', e.entidad_tipo,
                'entidad_id', e.entidad_id,
                'descripcion', e.descripcion,
                'fecha_evento', e.fecha_evento
            )
        ), '[]'::json)
    ) INTO v_result
    FROM eventos e
    LEFT JOIN usuarios u ON e.usuario_id = u.id
    WHERE e.tipo_evento = p_tipo_evento
    ORDER BY e.fecha_evento DESC
    LIMIT p_limite;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Obtener eventos por usuario
CREATE OR REPLACE FUNCTION eventos_get_por_usuario(
    p_usuario_id BIGINT,
    p_limite INT DEFAULT 100
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Eventos del usuario obtenidos exitosamente',
        'data', COALESCE(json_agg(
            json_build_object(
                'id', e.id,
                'tipo_evento', e.tipo_evento,
                'entidad_tipo', e.entidad_tipo,
                'entidad_id', e.entidad_id,
                'descripcion', e.descripcion,
                'fecha_evento', e.fecha_evento
            )
        ), '[]'::json)
    ) INTO v_result
    FROM eventos e
    WHERE e.usuario_id = p_usuario_id
    ORDER BY e.fecha_evento DESC
    LIMIT p_limite;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Obtener eventos por entidad
CREATE OR REPLACE FUNCTION eventos_get_por_entidad(
    p_entidad_tipo VARCHAR,
    p_entidad_id BIGINT,
    p_limite INT DEFAULT 100
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Eventos de la entidad obtenidos exitosamente',
        'data', COALESCE(json_agg(
            json_build_object(
                'id', e.id,
                'usuario', CASE 
                    WHEN u.id IS NOT NULL THEN
                        json_build_object(
                            'id', u.id,
                            'nombre_completo', u.nombre_completo
                        )
                    ELSE NULL
                END,
                'tipo_evento', e.tipo_evento,
                'descripcion', e.descripcion,
                'fecha_evento', e.fecha_evento
            )
        ), '[]'::json)
    ) INTO v_result
    FROM eventos e
    LEFT JOIN usuarios u ON e.usuario_id = u.id
    WHERE e.entidad_tipo = p_entidad_tipo AND e.entidad_id = p_entidad_id
    ORDER BY e.fecha_evento DESC
    LIMIT p_limite;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener eventos con paginación
SELECT eventos_get(NULL, 50, 0);  -- Primeros 50 eventos
SELECT eventos_get(NULL, 50, 50); -- Siguientes 50 eventos

-- GET: Obtener un evento específico
SELECT eventos_get(1);

-- POST: Crear un nuevo evento de auditoría
SELECT eventos_post(
    1,                    -- usuario_id
    'CREAR',              -- tipo_evento
    'pagos',              -- entidad_tipo
    123,                  -- entidad_id
    'Pago creado con código RES-2026-001 por $500 USD',  -- descripcion
    '192.168.1.100'::INET, -- ip_origen
    'Mozilla/5.0...'      -- user_agent
);

-- POST: Crear evento de inicio de sesión
SELECT eventos_post(
    1,
    'INICIO_SESION',
    'usuarios',
    1,
    'Usuario admin inició sesión',
    '192.168.1.100'::INET,
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64)...'
);

-- Consultas específicas
SELECT eventos_get_por_tipo('CREAR', 50);
SELECT eventos_get_por_usuario(1, 100);
SELECT eventos_get_por_entidad('pagos', 123, 50);

-- PUT y DELETE no están permitidos (retornan error 405)
SELECT eventos_put(1);
SELECT eventos_delete(1);
*/
