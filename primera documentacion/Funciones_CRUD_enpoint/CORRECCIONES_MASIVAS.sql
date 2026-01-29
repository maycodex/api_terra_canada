-- ============================================================================
-- SCRIPT DE CORRECCIÓN MASIVA - TODAS LAS FUNCIONES GET
-- Ejecutar este script para aplicar todas las correcciones
-- ============================================================================

-- NOTA: Este script contiene SOLO las funciones GET corregidas
-- Las demás funciones (POST, PUT, DELETE) no tienen el error y se mantienen igual

-- ============================================================================
-- ✅ 03_usuarios_crud.sql - usuarios_get() CORREGIDO
-- ============================================================================

CREATE OR REPLACE FUNCTION usuarios_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los usuarios
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuarios obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', u.id,
                        'nombre_usuario', u.nombre_usuario,
                        'correo', u.correo,
                        'nombre_completo', u.nombre_completo,
                        'rol', json_build_object(
                            'id', r.id,
                            'nombre', r.nombre
                        ),
                        'telefono', u.telefono,
                        'activo', u.activo,
                        'fecha_creacion', u.fecha_creacion
                    )
                    ORDER BY u.id
                ) FROM usuarios u
                  JOIN roles r ON u.rol_id = r.id),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuario obtenido exitosamente',
            'data', json_build_object(
                'id', u.id,
                'nombre_usuario', u.nombre_usuario,
                'correo', u.correo,
                'nombre_completo', u.nombre_completo,
                'rol', json_build_object(
                    'id', r.id,
                    'nombre', r.nombre
                ),
                'telefono', u.telefono,
                'activo', u.activo,
                'fecha_creacion', u.fecha_creacion
            )
        ) INTO v_result
        FROM usuarios u
        JOIN roles r ON u.rol_id = r.id
        WHERE u.id = p_id;
        
        IF NOT FOUND THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Usuario no encontrado',
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
            'message', 'Error al obtener usuarios: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ✅ 04_proveedores_crud.sql - proveedores_get() CORREGIDO
-- ============================================================================

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
            'data', COALESCE(
                (SELECT json_agg(
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
                        'correos', COALESCE(
                            (SELECT json_agg(
                                json_build_object(
                                    'id', pc.id,
                                    'correo', pc.correo,
                                    'principal', pc.principal
                                )
                                ORDER BY pc.principal DESC
                            ) FROM proveedor_correos pc
                              WHERE pc.proveedor_id = p.id AND pc.activo = TRUE),
                            '[]'::json
                        ),
                        'fecha_creacion', p.fecha_creacion
                    )
                    ORDER BY p.nombre
                ) FROM proveedores p
                  JOIN servicios s ON p.servicio_id = s.id),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
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
                'correos', COALESCE(
                    (SELECT json_agg(
                        json_build_object(
                            'id', pc.id,
                            'correo', pc.correo,
                            'principal', pc.principal,
                            'activo', pc.activo
                        )
                        ORDER BY pc.principal DESC
                    ) FROM proveedor_correos pc
                      WHERE pc.proveedor_id = p.id),
                    '[]'::json
                ),
                'fecha_creacion', p.fecha_creacion
            )
        ) INTO v_result
        FROM proveedores p
        JOIN servicios s ON p.servicio_id = s.id
        WHERE p.id = p_id;
        
        IF NOT FOUND THEN
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

-- ============================================================================
-- ✅ 05_proveedor_correos_crud.sql - proveedor_correos_get() CORREGIDO
-- ============================================================================

CREATE OR REPLACE FUNCTION proveedor_correos_get(p_id INT DEFAULT NULL, p_proveedor_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NOT NULL THEN
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
        
        IF NOT FOUND THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Correo no encontrado',
                'data', null
            );
        END IF;
        
    ELSIF p_proveedor_id IS NOT NULL THEN
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correos del proveedor obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', pc.id,
                        'correo', pc.correo,
                        'principal', pc.principal,
                        'activo', pc.activo,
                        'fecha_creacion', pc.fecha_creacion
                    )
                    ORDER BY pc.principal DESC, pc.id
                ) FROM proveedor_correos pc
                  WHERE pc.proveedor_id = p_proveedor_id),
                '[]'::json
            )
        ) INTO v_result;
        
    ELSE
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correos obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
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
                    ORDER BY p.nombre, pc.principal DESC
                ) FROM proveedor_correos pc
                  JOIN proveedores p ON pc.proveedor_id = p.id),
                '[]'::json
            )
        ) INTO v_result;
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

-- ============================================================================
-- ✅ 06_clientes_crud.sql - clientes_get() CORREGIDO
-- ============================================================================

CREATE OR REPLACE FUNCTION clientes_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Clientes obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', id,
                        'nombre', nombre,
                        'ubicacion', ubicacion,
                        'telefono', telefono,
                        'correo', correo,
                        'activo', activo,
                        'fecha_creacion', fecha_creacion
                    )
                    ORDER BY nombre
                ) FROM clientes),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
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
                'fecha_creacion', fecha_creacion
            )
        ) INTO v_result
        FROM clientes
        WHERE id = p_id;
        
        IF NOT FOUND THEN
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

-- ============================================================================
-- ✅ 07_tarjetas_credito_crud.sql - tarjetas_credito_get() CORREGIDO
-- ============================================================================

CREATE OR REPLACE FUNCTION tarjetas_credito_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Tarjetas obtenidas exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', id,
                        'nombre_titular', nombre_titular,
                        'ultimos_4_digitos', ultimos_4_digitos,
                        'moneda', moneda,
                        'limite_mensual', limit e_mensual,
                        'saldo_disponible', saldo_disponible,
                        'tipo_tarjeta', tipo_tarjeta,
                        'activo', activo,
                        'fecha_creacion', fecha_creacion
                    )
                    ORDER BY nombre_titular
                ) FROM tarjetas_credito),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
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
                'fecha_creacion', fecha_creacion
            )
        ) INTO v_result
        FROM tarjetas_credito
        WHERE id = p_id;
        
        IF NOT FOUND THEN
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

-- ============================================================================
-- ✅ 08_cuentas_bancarias_crud.sql - cuentas_bancarias_get() CORREGIDO
-- ============================================================================

CREATE OR REPLACE FUNCTION cuentas_bancarias_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Cuentas bancarias obtenidas exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', id,
                        'nombre_banco', nombre_banco,
                        'nombre_cuenta', nombre_cuenta,
                        'ultimos_4_digitos', ultimos_4_digitos,
                        'moneda', moneda,
                        'activo', activo,
                        'fecha_creacion', fecha_creacion
                    )
                    ORDER BY nombre_banco
                ) FROM cuentas_bancarias),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
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
                'fecha_creacion', fecha_creacion
            )
        ) INTO v_result
        FROM cuentas_bancarias
        WHERE id = p_id;
        
        IF NOT FOUND THEN
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

-- ============================================================================
-- NOTA: Los archivos más complejos (pagos, documentos, envios_correos, eventos)
-- requieren análisis individual debido a múltiples JOINs y subconsultas anidadas.
-- Aplica el mismo patrón: mover json_agg a subconsulta.
-- ============================================================================

-- ✅ CORREGIDOS: 01, 02, 03, 04, 05, 06, 07, 08
-- ⏳ PENDIENTES: 09, 10, 11, 12 (requieren revisión manual por complejidad)
