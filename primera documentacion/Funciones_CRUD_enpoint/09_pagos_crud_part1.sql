-- ============================================================================
-- FUNCIONES CRUD - TABLA: pagos (CORE)
-- ============================================================================

-- ========================================
-- GET: Obtener todos los pagos o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION pagos_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los pagos
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Pagos obtenidos exitosamente',
            'data', COALESCE(json_agg(
                json_build_object(
                    'id', p.id,
                    'codigo_reserva', p.codigo_reserva,
                    'monto', p.monto,
                    'moneda', p.moneda,
                    'descripcion', p.descripcion,
                    'fecha_esperada_debito', p.fecha_esperada_debito,
                    'proveedor', json_build_object(
                        'id', prov.id,
                        'nombre', prov.nombre,
                        'servicio', s.nombre
                    ),
                    'usuario', json_build_object(
                        'id', u.id,
                        'nombre_completo', u.nombre_completo,
                        'rol', r.nombre
                    ),
                    'medio_pago', CASE 
                        WHEN p.tipo_medio_pago = 'TARJETA' THEN
                            json_build_object(
                                'tipo', 'TARJETA',
                                'id', tc.id,
                                'titular', tc.nombre_titular,
                                'ultimos_digitos', tc.ultimos_4_digitos,
                                'tipo_tarjeta', tc.tipo_tarjeta
                            )
                        WHEN p.tipo_medio_pago = 'CUENTA_BANCARIA' THEN
                            json_build_object(
                                'tipo', 'CUENTA_BANCARIA',
                                'id', cb.id,
                                'banco', cb.nombre_banco,
                                'cuenta', cb.nombre_cuenta,
                                'ultimos_digitos', cb.ultimos_4_digitos
                            )
                        ELSE NULL
                    END,
                    'clientes', (
                        SELECT COALESCE(json_agg(
                            json_build_object(
                                'id', c.id,
                                'nombre', c.nombre
                            )
                        ), '[]'::json)
                        FROM pago_cliente pc
                        JOIN clientes c ON pc.cliente_id = c.id
                        WHERE pc.pago_id = p.id
                    ),
                    'estados', json_build_object(
                        'pagado', p.pagado,
                        'verificado', p.verificado,
                        'gmail_enviado', p.gmail_enviado,
                        'activo', p.activo
                    ),
                    'fecha_pago', p.fecha_pago,
                    'fecha_verificacion', p.fecha_verificacion,
                    'fecha_creacion', p.fecha_creacion,
                    'fecha_actualizacion', p.fecha_actualizacion
                )
            ), '[]'::json)
        ) INTO v_result
        FROM pagos p
        JOIN proveedores prov ON p.proveedor_id = prov.id
        JOIN servicios s ON prov.servicio_id = s.id
        JOIN usuarios u ON p.usuario_id = u.id
        JOIN roles r ON u.rol_id = r.id
        LEFT JOIN tarjetas_credito tc ON p.tarjeta_id = tc.id
        LEFT JOIN cuentas_bancarias cb ON p.cuenta_bancaria_id = cb.id
        ORDER BY p.fecha_creacion DESC;
    ELSE
        -- Obtener un pago específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Pago obtenido exitosamente',
            'data', json_build_object(
                'id', p.id,
                'codigo_reserva', p.codigo_reserva,
                'monto', p.monto,
                'moneda', p.moneda,
                'descripcion', p.descripcion,
                'fecha_esperada_debito', p.fecha_esperada_debito,
                'proveedor', json_build_object(
                    'id', prov.id,
                    'nombre', prov.nombre,
                    'servicio', json_build_object(
                        'id', s.id,
                        'nombre', s.nombre
                    )
                ),
                'usuario', json_build_object(
                    'id', u.id,
                    'nombre_completo', u.nombre_completo,
                    'rol', r.nombre
                ),
                'medio_pago', CASE 
                    WHEN p.tipo_medio_pago = 'TARJETA' THEN
                        json_build_object(
                            'tipo', 'TARJETA',
                            'id', tc.id,
                            'titular', tc.nombre_titular,
                            'ultimos_digitos', tc.ultimos_4_digitos,
                            'tipo_tarjeta', tc.tipo_tarjeta,
                            'moneda', tc.moneda
                        )
                    WHEN p.tipo_medio_pago = 'CUENTA_BANCARIA' THEN
                        json_build_object(
                            'tipo', 'CUENTA_BANCARIA',
                            'id', cb.id,
                            'banco', cb.nombre_banco,
                            'cuenta', cb.nombre_cuenta,
                            'ultimos_digitos', cb.ultimos_4_digitos,
                            'moneda', cb.moneda
                        )
                    ELSE NULL
                END,
                'clientes', (
                    SELECT COALESCE(json_agg(
                        json_build_object(
                            'id', c.id,
                            'nombre', c.nombre,
                            'ubicacion', c.ubicacion
                        )
                    ), '[]'::json)
                    FROM pago_cliente pc
                    JOIN clientes c ON pc.cliente_id = c.id
                    WHERE pc.pago_id = p.id
                ),
                'documentos', (
                    SELECT COALESCE(json_agg(
                        json_build_object(
                            'id', d.id,
                            'tipo_documento', d.tipo_documento,
                            'url_documento', d.url_documento,
                            'fecha_subida', d.fecha_subida
                        )
                    ), '[]'::json)
                    FROM documento_pago dp
                    JOIN documentos d ON dp.documento_id = d.id
                    WHERE dp.pago_id = p.id
                ),
                'estados', json_build_object(
                    'pagado', p.pagado,
                    'verificado', p.verificado,
                    'gmail_enviado', p.gmail_enviado,
                    'activo', p.activo
                ),
                'fecha_pago', p.fecha_pago,
                'fecha_verificacion', p.fecha_verificacion,
                'fecha_creacion', p.fecha_creacion,
                'fecha_actualizacion', p.fecha_actualizacion
            )
        ) INTO v_result
        FROM pagos p
        JOIN proveedores prov ON p.proveedor_id = prov.id
        JOIN servicios s ON prov.servicio_id = s.id
        JOIN usuarios u ON p.usuario_id = u.id
        JOIN roles r ON u.rol_id = r.id
        LEFT JOIN tarjetas_credito tc ON p.tarjeta_id = tc.id
        LEFT JOIN cuentas_bancarias cb ON p.cuenta_bancaria_id = cb.id
        WHERE p.id = p_id;
        
        IF v_result IS NULL THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Pago no encontrado',
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
            'message', 'Error al obtener pagos: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- Continúa en el siguiente archivo...
