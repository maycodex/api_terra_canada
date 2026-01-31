-- ============================================================================
-- ARCHIVO MAESTRO - TODAS LAS FUNCIONES CRUD
-- Sistema de Gestión de Pagos Terra Canada
-- ============================================================================
-- 
-- Este archivo contiene TODAS las funciones CRUD para el sistema.
-- Ejecutar después del DDL completo (03_DDL_COMPLETO.sql)
--
-- TABLAS INCLUIDAS:
-- 1. roles
-- 2. servicios
-- 3. usuarios
-- 4. proveedores
-- 5. proveedor_correos
-- 6. clientes
-- 7. tarjetas_credito
-- 8. cuentas_bancarias
-- 9. pagos (CORE)
-- 10. documentos
-- 11. envios_correos
-- 12. eventos (auditoría)
--
-- FORMATO DE RESPUESTA (todas las funciones):
-- {
--   "code": 200,           -- Código HTTP
--   "estado": true,        -- true = éxito, false = error
--   "message": "...",      -- Mensaje descriptivo
--   "data": {...}          -- Datos de respuesta
-- }
--
-- ============================================================================

-- Para instalar todas las funciones, ejecutar en orden:
-- \i /ruta/funciones_crud/01_roles_crud.sql
-- \i /ruta/funciones_crud/02_servicios_crud.sql
-- \i /ruta/funciones_crud/03_usuarios_crud.sql
-- \i /ruta/funciones_crud/04_proveedores_crud.sql
-- \i /ruta/funciones_crud/05_proveedor_correos_crud.sql
-- \i /ruta/funciones_crud/06_clientes_crud.sql
-- \i /ruta/funciones_crud/07_tarjetas_credito_crud.sql
-- \i /ruta/funciones_crud/08_cuentas_bancarias_crud.sql
-- \i /ruta/funciones_crud/09_pagos_crud_part1.sql
-- \i /ruta/funciones_crud/09_pagos_crud_part2.sql
-- \i /ruta/funciones_crud/09_pagos_crud_part3.sql
-- \i /ruta/funciones_crud/10_documentos_crud.sql
-- \i /ruta/funciones_crud/11_envios_correos_crud.sql
-- \i /ruta/funciones_crud/12_eventos_crud.sql

-- ============================================================================
-- RESUMEN DE FUNCIONES DISPONIBLES
-- ============================================================================

/*
ROLES:
- roles_get(id)
- roles_post(nombre, descripcion)
- roles_put(id, nombre, descripcion)
- roles_delete(id)

SERVICIOS:
- servicios_get(id)
- servicios_post(nombre, descripcion, activo)
- servicios_put(id, nombre, descripcion, activo)
- servicios_delete(id)

USUARIOS:
- usuarios_get(id)
- usuarios_post(nombre_usuario, correo, contrasena, nombre_completo, rol_id, telefono, activo)
- usuarios_put(id, nombre_usuario, correo, contrasena, nombre_completo, rol_id, telefono, activo)
- usuarios_delete(id)

PROVEEDORES:
- proveedores_get(id)
- proveedores_post(nombre, servicio_id, lenguaje, telefono, descripcion, activo)
- proveedores_put(id, nombre, servicio_id, lenguaje, telefono, descripcion, activo)
- proveedores_delete(id)

PROVEEDOR_CORREOS:
- proveedor_correos_get(id, proveedor_id)
- proveedor_correos_post(proveedor_id, correo, principal, activo)
- proveedor_correos_put(id, correo, principal, activo)
- proveedor_correos_delete(id)

CLIENTES:
- clientes_get(id)
- clientes_post(nombre, ubicacion, telefono, correo, activo)
- clientes_put(id, nombre, ubicacion, telefono, correo, activo)
- clientes_delete(id)

TARJETAS_CREDITO:
- tarjetas_credito_get(id)
- tarjetas_credito_post(nombre_titular, ultimos_4_digitos, moneda, limite_mensual, tipo_tarjeta, activo)
- tarjetas_credito_put(id, nombre_titular, limite_mensual, tipo_tarjeta, activo)
- tarjetas_credito_delete(id)

CUENTAS_BANCARIAS:
- cuentas_bancarias_get(id)
- cuentas_bancarias_post(nombre_banco, nombre_cuenta, ultimos_4_digitos, moneda, activo)
- cuentas_bancarias_put(id, nombre_banco, nombre_cuenta, activo)
- cuentas_bancarias_delete(id)

PAGOS (CORE):
- pagos_get(id)
- pagos_post(proveedor_id, usuario_id, codigo_reserva, monto, moneda, tipo_medio_pago, 
             tarjeta_id, cuenta_bancaria_id, clientes_ids, descripcion, fecha_esperada_debito)
- pagos_put(id, monto, descripcion, fecha_esperada_debito, pagado, verificado, gmail_enviado, activo)
- pagos_delete(id)

DOCUMENTOS:
- documentos_get(id)
- documentos_post(tipo_documento, nombre_archivo, url_documento, usuario_subida_id, pago_id)
- documentos_put(id, procesado, fecha_procesamiento)
- documentos_delete(id)

ENVIOS_CORREOS:
- envios_correos_get(id)
- envios_correos_post(proveedor_id, usuario_envio_id, asunto, cuerpo, pagos_ids)
- envios_correos_put(id, correo_destino, asunto, cuerpo, enviar)
- envios_correos_delete(id)

EVENTOS (AUDITORÍA):
- eventos_get(id, limite, offset)
- eventos_post(usuario_id, tipo_evento, entidad_tipo, entidad_id, descripcion, ip_origen, user_agent)
- eventos_put(id) -- NO PERMITIDO
- eventos_delete(id) -- NO PERMITIDO
- eventos_get_por_tipo(tipo_evento, limite)
- eventos_get_por_usuario(usuario_id, limite)
- eventos_get_por_entidad(entidad_tipo, entidad_id, limite)
*/

-- ============================================================================
-- EJEMPLOS DE USO COMPLETO
-- ============================================================================

/*
-- ========== FLUJO COMPLETO DE NEGOCIO ==========

-- 1. CREAR UN USUARIO
SELECT usuarios_post(
    'operador1', 
    'operador1@terracanada.com', 
    'password123', 
    'Juan Operador', 
    3,  -- Rol EQUIPO
    '+1234567890', 
    true
);

-- 2. CREAR UN PROVEEDOR
SELECT proveedores_post(
    'Servicios Turísticos XYZ', 
    8,  -- Servicio: Opérations clients
    'Español', 
    '+521234567890', 
    'Proveedor de servicios de guías',
    true
);

-- 3. AGREGAR CORREOS AL PROVEEDOR
SELECT proveedor_correos_post(1, 'contacto@serviciosxyz.com', true, true);
SELECT proveedor_correos_post(1, 'admin@serviciosxyz.com', false, true);

-- 4. CREAR UN CLIENTE
SELECT clientes_post(
    'Hotel Caribe', 
    'Cancún, México', 
    '+521234567890', 
    'info@hotelcaribe.com',
    true
);

-- 5. CREAR UNA TARJETA DE CRÉDITO
SELECT tarjetas_credito_post(
    'Terra Canada', 
    '1234', 
    'USD', 
    10000.00, 
    'Visa Corporate',
    true
);

-- 6. REGISTRAR UN PAGO CON TARJETA
SELECT pagos_post(
    1,  -- proveedor_id
    1,  -- usuario_id
    'RES-2026-001',
    750.00,
    'USD',
    'TARJETA',
    1,  -- tarjeta_id
    NULL,
    ARRAY[1]::BIGINT[],  -- clientes_ids
    'Servicio de guía turístico - Tour Chichén Itzá',
    '2026-02-15'
);

-- 7. SUBIR UNA FACTURA
SELECT documentos_post(
    'FACTURA',
    'factura_RES-2026-001.pdf',
    'https://storage.terracanada.com/facturas/2026/01/factura_RES-2026-001.pdf',
    1,  -- usuario_subida_id
    1   -- pago_id (vincular directamente)
);

-- 8. MARCAR PAGO COMO PAGADO (simulando procesamiento de N8N)
SELECT pagos_put(1, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);

-- 9. CREAR BORRADOR DE CORREO
SELECT envios_correos_post(
    1,  -- proveedor_id
    1,  -- usuario_envio_id
    'Notificación de Pago - Terra Canada',
    'Estimado proveedor, le informamos que hemos procesado el pago...',
    ARRAY[1]::BIGINT[]  -- pagos_ids
);

-- 10. ENVIAR EL CORREO
SELECT envios_correos_put(
    1,
    'contacto@serviciosxyz.com',
    NULL,
    NULL,
    TRUE  -- enviar = true
);

-- 11. REGISTRAR EVENTO DE AUDITORÍA
SELECT eventos_post(
    1,
    'ENVIAR_CORREO',
    'envios_correos',
    1,
    'Correo enviado a proveedor Servicios Turísticos XYZ',
    '192.168.1.100'::INET,
    'Mozilla/5.0...'
);

-- ========== CONSULTAS DE REPORTE ==========

-- Ver todos los pagos
SELECT pagos_get();

-- Ver pagos pendientes de enviar correo
SELECT * FROM jsonb_array_elements(
    (SELECT data FROM pagos_get())::jsonb
) WHERE (value->>'pagado')::boolean = true 
  AND (value->>'gmail_enviado')::boolean = false;

-- Ver tarjetas y su uso
SELECT tarjetas_credito_get();

-- Ver correos enviados
SELECT * FROM jsonb_array_elements(
    (SELECT data FROM envios_correos_get())::jsonb
) WHERE value->>'estado' = 'ENVIADO';

-- Ver eventos de auditoría
SELECT eventos_get(NULL, 100, 0);
*/

-- ============================================================================
-- FIN DEL ARCHIVO MAESTRO
-- ============================================================================
