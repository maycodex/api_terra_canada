-- ============================================================================
-- SCRIPT DE PRUEBA COMPLETO - Sistema Terra Canada
-- ============================================================================
-- Este script ejecuta pruebas de todas las funciones CRUD
-- Ejecutar después de instalar todas las funciones
-- ============================================================================

\timing on
\echo '============================================'
\echo 'INICIANDO PRUEBAS DEL SISTEMA'
\echo '============================================'

-- ============================================
-- LIMPIEZA DE DATOS DE PRUEBA (OPCIONAL)
-- ============================================
\echo ''
\echo '=== LIMPIANDO DATOS ANTERIORES ==='

DO $$
BEGIN
    -- Desactivar temporalmente triggers para limpieza
    DELETE FROM correo_pago;
    DELETE FROM pago_cliente;
    DELETE FROM documento_pago;
    DELETE FROM eventos;
    DELETE FROM envios_correos;
    DELETE FROM documentos;
    DELETE FROM pagos;
    DELETE FROM proveedor_correos;
    DELETE FROM proveedores;
    DELETE FROM clientes;
    DELETE FROM tarjetas_credito;
    DELETE FROM cuentas_bancarias;
    DELETE FROM usuarios WHERE id > 3;  -- Mantener usuarios iniciales
    
    RAISE NOTICE 'Datos de prueba anteriores eliminados';
END $$;

-- ============================================
-- PRUEBA 1: USUARIOS
-- ============================================
\echo ''
\echo '=== PRUEBA 1: USUARIOS ==='

-- Crear usuario
SELECT '1.1 - Crear usuario de prueba' as test;
SELECT usuarios_post(
    'test_operador',
    'operador@test.com',
    'password123',
    'Operador de Prueba',
    3,  -- Rol EQUIPO
    '+1234567890',
    true
);

-- Obtener usuario
SELECT '1.2 - Obtener usuario creado' as test;
SELECT usuarios_get(4);

-- Actualizar usuario
SELECT '1.3 - Actualizar usuario' as test;
SELECT usuarios_put(
    4,
    NULL,
    'operador.actualizado@test.com',
    NULL,
    NULL,
    NULL,
    '+9876543210',
    NULL
);

-- Listar todos los usuarios
SELECT '1.4 - Listar todos los usuarios' as test;
SELECT usuarios_get();

-- ============================================
-- PRUEBA 2: PROVEEDORES Y CORREOS
-- ============================================
\echo ''
\echo '=== PRUEBA 2: PROVEEDORES ==='

-- Crear proveedor
SELECT '2.1 - Crear proveedor' as test;
SELECT proveedores_post(
    'Servicios Turísticos Test',
    8,  -- Opérations clients
    'Español',
    '+521234567890',
    'Proveedor de prueba para testing',
    true
);

-- Agregar correos al proveedor
SELECT '2.2 - Agregar correo principal' as test;
SELECT proveedor_correos_post(1, 'contacto@test.com', true, true);

SELECT '2.3 - Agregar correo secundario' as test;
SELECT proveedor_correos_post(1, 'admin@test.com', false, true);

SELECT '2.4 - Agregar tercer correo' as test;
SELECT proveedor_correos_post(1, 'ventas@test.com', false, true);

-- Ver proveedor con correos
SELECT '2.5 - Ver proveedor completo' as test;
SELECT proveedores_get(1);

-- ============================================
-- PRUEBA 3: CLIENTES
-- ============================================
\echo ''
\echo '=== PRUEBA 3: CLIENTES ==='

SELECT '3.1 - Crear cliente 1' as test;
SELECT clientes_post('Hotel Paradise Test', 'Cancún, México', '+521111111111', 'info@paradise.com', true);

SELECT '3.2 - Crear cliente 2' as test;
SELECT clientes_post('Hotel Caribe Test', 'Playa del Carmen', '+522222222222', 'info@caribe.com', true);

SELECT '3.3 - Listar clientes' as test;
SELECT clientes_get();

-- ============================================
-- PRUEBA 4: TARJETAS DE CRÉDITO
-- ============================================
\echo ''
\echo '=== PRUEBA 4: TARJETAS DE CRÉDITO ==='

SELECT '4.1 - Crear tarjeta USD' as test;
SELECT tarjetas_credito_post(
    'Terra Canada - Visa Corporate',
    '1234',
    'USD',
    10000.00,
    'Visa Corporate',
    true
);

SELECT '4.2 - Crear tarjeta CAD' as test;
SELECT tarjetas_credito_post(
    'Terra Canada - Mastercard',
    '5678',
    'CAD',
    15000.00,
    'Mastercard Business',
    true
);

SELECT '4.3 - Ver tarjetas creadas' as test;
SELECT tarjetas_credito_get();

-- ============================================
-- PRUEBA 5: CUENTAS BANCARIAS
-- ============================================
\echo ''
\echo '=== PRUEBA 5: CUENTAS BANCARIAS ==='

SELECT '5.1 - Crear cuenta bancaria' as test;
SELECT cuentas_bancarias_post(
    'Banco Nacional de Canadá',
    'Cuenta Empresarial',
    '9999',
    'CAD',
    true
);

SELECT '5.2 - Ver cuentas' as test;
SELECT cuentas_bancarias_get();

-- ============================================
-- PRUEBA 6: PAGOS CON TARJETA
-- ============================================
\echo ''
\echo '=== PRUEBA 6: PAGOS ==='

-- Pago 1: Con tarjeta USD
SELECT '6.1 - Crear pago con tarjeta USD' as test;
SELECT pagos_post(
    1,  -- proveedor_id
    4,  -- usuario_id (test_operador)
    'TEST-RES-001',
    750.00,
    'USD',
    'TARJETA',
    1,  -- tarjeta USD
    NULL,
    ARRAY[1,2]::BIGINT[],  -- ambos clientes
    'Pago de prueba - Servicio de guía turística',
    '2026-02-15'
);

-- Verificar saldo de tarjeta después del pago
SELECT '6.2 - Verificar saldo de tarjeta después del pago' as test;
SELECT tarjetas_credito_get(1);

-- Pago 2: Con cuenta bancaria
SELECT '6.3 - Crear pago con cuenta bancaria' as test;
SELECT pagos_post(
    1,  -- proveedor_id
    4,  -- usuario_id
    'TEST-RES-002',
    1200.00,
    'CAD',
    'CUENTA_BANCARIA',
    NULL,
    1,  -- cuenta bancaria
    ARRAY[1]::BIGINT[],
    'Pago de prueba - Servicio hotelero',
    NULL
);

-- Pago 3: Otro con tarjeta USD
SELECT '6.4 - Crear tercer pago' as test;
SELECT pagos_post(
    1,
    4,
    'TEST-RES-003',
    350.00,
    'USD',
    'TARJETA',
    1,
    NULL,
    ARRAY[2]::BIGINT[],
    'Pago de prueba - Excursión',
    '2026-02-20'
);

-- Ver todos los pagos
SELECT '6.5 - Ver todos los pagos' as test;
SELECT pagos_get();

-- Ver un pago específico
SELECT '6.6 - Ver pago específico con detalles' as test;
SELECT pagos_get(1);

-- ============================================
-- PRUEBA 7: DOCUMENTOS
-- ============================================
\echo ''
\echo '=== PRUEBA 7: DOCUMENTOS ==='

-- Subir factura vinculada a pago
SELECT '7.1 - Subir factura (vinculada a pago 1)' as test;
SELECT documentos_post(
    'FACTURA',
    'factura_TEST-RES-001.pdf',
    'https://storage.test.com/facturas/TEST-RES-001.pdf',
    4,  -- usuario_subida
    1   -- pago_id
);

-- Subir extracto bancario (sin vincular)
SELECT '7.2 - Subir documento banco (sin vincular)' as test;
SELECT documentos_post(
    'DOCUMENTO_BANCO',
    'extracto_enero_2026.pdf',
    'https://storage.test.com/extractos/enero_2026.pdf',
    4,
    NULL  -- sin vincular inicialmente
);

-- Marcar documento como procesado
SELECT '7.3 - Marcar documento como procesado' as test;
SELECT documentos_put(1, TRUE, NOW());

-- Ver documentos
SELECT '7.4 - Ver todos los documentos' as test;
SELECT documentos_get();

-- ============================================
-- PRUEBA 8: ACTUALIZACIÓN DE ESTADOS DE PAGO
-- ============================================
\echo ''
\echo '=== PRUEBA 8: ACTUALIZACIÓN DE ESTADOS ==='

-- Marcar pago 1 como pagado
SELECT '8.1 - Marcar pago 1 como pagado' as test;
SELECT pagos_put(1, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);

-- Marcar pago 2 como pagado y verificado
SELECT '8.2 - Marcar pago 2 como pagado y verificado' as test;
SELECT pagos_put(2, NULL, NULL, NULL, TRUE, TRUE, NULL, NULL);

-- Marcar pago 3 como pagado
SELECT '8.3 - Marcar pago 3 como pagado' as test;
SELECT pagos_put(3, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);

-- Ver estados actualizados
SELECT '8.4 - Ver pagos con estados actualizados' as test;
SELECT pagos_get();

-- ============================================
-- PRUEBA 9: ENVÍOS DE CORREOS
-- ============================================
\echo ''
\echo '=== PRUEBA 9: ENVÍOS DE CORREOS ==='

-- Crear borrador de correo con los pagos pagados
SELECT '9.1 - Crear borrador de correo' as test;
SELECT envios_correos_post(
    1,  -- proveedor
    4,  -- usuario
    'Notificación de Pagos - Test',
    'Estimado proveedor, le informamos que hemos procesado los siguientes pagos...',
    ARRAY[1,3]::BIGINT[]  -- pagos 1 y 3 (pagado=true, gmail_enviado=false)
);

-- Ver el correo creado
SELECT '9.2 - Ver correo borrador' as test;
SELECT envios_correos_get(1);

-- Editar el correo
SELECT '9.3 - Editar contenido del correo' as test;
SELECT envios_correos_put(
    1,
    'contacto@test.com',
    'Notificación de Pagos - Terra Canada Test',
    'Contenido actualizado del correo con más detalles...',
    FALSE  -- no enviar todavía
);

-- Enviar el correo
SELECT '9.4 - Enviar el correo' as test;
SELECT envios_correos_put(
    1,
    'contacto@test.com',
    NULL,
    NULL,
    TRUE  -- enviar
);

-- Verificar que los pagos se marcaron como gmail_enviado
SELECT '9.5 - Verificar pagos marcados como enviados' as test;
SELECT pagos_get();

-- ============================================
-- PRUEBA 10: EVENTOS DE AUDITORÍA
-- ============================================
\echo ''
\echo '=== PRUEBA 10: EVENTOS DE AUDITORÍA ==='

-- Crear eventos manualmente
SELECT '10.1 - Crear evento de inicio de sesión' as test;
SELECT eventos_post(
    4,
    'INICIO_SESION',
    'usuarios',
    4,
    'Usuario test_operador inició sesión',
    '192.168.1.100'::INET,
    'Mozilla/5.0 (Test) AppleWebKit/537.36'
);

SELECT '10.2 - Crear evento de creación' as test;
SELECT eventos_post(
    4,
    'CREAR',
    'pagos',
    1,
    'Pago TEST-RES-001 creado por $750 USD',
    '192.168.1.100'::INET,
    'Mozilla/5.0 (Test) AppleWebKit/537.36'
);

-- Ver eventos
SELECT '10.3 - Ver últimos 10 eventos' as test;
SELECT eventos_get(NULL, 10, 0);

-- Ver eventos por tipo
SELECT '10.4 - Ver eventos de tipo CREAR' as test;
SELECT eventos_get_por_tipo('CREAR', 10);

-- Ver eventos por usuario
SELECT '10.5 - Ver eventos del usuario test_operador' as test;
SELECT eventos_get_por_usuario(4, 10);

-- ============================================
-- PRUEBA 11: VALIDACIONES Y ERRORES
-- ============================================
\echo ''
\echo '=== PRUEBA 11: VALIDACIONES ==='

-- Intentar crear pago con código duplicado (debe fallar)
SELECT '11.1 - Intentar código de reserva duplicado (debe fallar)' as test;
SELECT pagos_post(
    1, 4, 'TEST-RES-001', 100.00, 'USD', 'TARJETA',
    1, NULL, ARRAY[1]::BIGINT[], 'Debe fallar', NULL
);

-- Intentar crear pago con saldo insuficiente (debe fallar)
SELECT '11.2 - Intentar pago con saldo insuficiente (debe fallar)' as test;
SELECT pagos_post(
    1, 4, 'TEST-RES-999', 50000.00, 'USD', 'TARJETA',
    1, NULL, ARRAY[1]::BIGINT[], 'Debe fallar por saldo', NULL
);

-- Intentar editar pago verificado (debe fallar)
SELECT '11.3 - Intentar editar pago verificado (debe fallar)' as test;
SELECT pagos_put(2, 999.99, NULL, NULL, NULL, NULL, NULL, NULL);

-- Intentar eliminar pago enviado por correo (debe fallar)
SELECT '11.4 - Intentar eliminar pago enviado (debe fallar)' as test;
SELECT pagos_delete(1);

-- Intentar agregar 5to correo a proveedor (debe fallar)
SELECT '11.5 - Intentar agregar 5to correo (debe fallar)' as test;
SELECT proveedor_correos_post(1, 'quinto@test.com', false, true);

-- ============================================
-- PRUEBA 12: ELIMINACIONES EXITOSAS
-- ============================================
\echo ''
\echo '=== PRUEBA 12: ELIMINACIONES ==='

-- Eliminar un pago que SÍ se puede eliminar (no enviado)
SELECT '12.1 - Crear pago temporal' as test;
SELECT pagos_post(
    1, 4, 'TEST-TEMP-001', 100.00, 'USD', 'TARJETA',
    1, NULL, ARRAY[1]::BIGINT[], 'Pago temporal', NULL
);

SELECT '12.2 - Verificar saldo antes de eliminar' as test;
SELECT tarjetas_credito_get(1);

SELECT '12.3 - Eliminar pago temporal (devuelve saldo)' as test;
SELECT pagos_delete((SELECT MAX(id) FROM pagos));

SELECT '12.4 - Verificar saldo después de eliminar' as test;
SELECT tarjetas_credito_get(1);

-- ============================================
-- RESUMEN FINAL
-- ============================================
\echo ''
\echo '============================================'
\echo 'RESUMEN DE PRUEBAS'
\echo '============================================'

SELECT '=== TOTAL DE REGISTROS CREADOS ===' as resumen;
SELECT 'Usuarios' as tabla, COUNT(*) as total FROM usuarios
UNION ALL
SELECT 'Proveedores', COUNT(*) FROM proveedores
UNION ALL
SELECT 'Correos Proveedor', COUNT(*) FROM proveedor_correos
UNION ALL
SELECT 'Clientes', COUNT(*) FROM clientes
UNION ALL
SELECT 'Tarjetas', COUNT(*) FROM tarjetas_credito
UNION ALL
SELECT 'Cuentas Bancarias', COUNT(*) FROM cuentas_bancarias
UNION ALL
SELECT 'Pagos', COUNT(*) FROM pagos
UNION ALL
SELECT 'Documentos', COUNT(*) FROM documentos
UNION ALL
SELECT 'Correos Enviados', COUNT(*) FROM envios_correos
UNION ALL
SELECT 'Eventos Auditoría', COUNT(*) FROM eventos;

\echo ''
\echo '============================================'
\echo 'PRUEBAS COMPLETADAS EXITOSAMENTE'
\echo '============================================'

\timing off
