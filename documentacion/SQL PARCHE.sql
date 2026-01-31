
-- ============================================================================
-- SOLUCIÓN: TRIGGER AUTOMÁTICO PARA GENERACIÓN DE CORREOS
-- ============================================================================
-- PROBLEMA: Al cambiar pagado=TRUE, no se generan correos automáticamente
-- SOLUCIÓN: Crear trigger que ejecute generar_correos_pendientes()
-- ============================================================================

-- ========================================
-- PASO 1: MEJORAR LA FUNCIÓN generar_correos_pendientes()
-- ========================================
-- La función actual tiene problemas:
-- 1. No valida si ya existe un borrador para ese proveedor
-- 2. Usa usuario_envio_id = 1 hardcodeado
-- 3. No genera correo_seleccionado ni correos del proveedor

CREATE OR REPLACE FUNCTION generar_correos_pendientes()
RETURNS void AS $$
DECLARE
    v_proveedor RECORD;
    v_correo_principal VARCHAR;
    v_existe_borrador BOOLEAN;
BEGIN
    -- Recorrer pagos pendientes agrupados por proveedor
    FOR v_proveedor IN
        SELECT 
            proveedor_id, 
            COUNT(*) as cantidad, 
            SUM(monto) as total,
            MIN(moneda) as moneda  -- Asumimos misma moneda por proveedor
        FROM pagos
        WHERE pagado = TRUE 
          AND gmail_enviado = FALSE 
          AND activo = TRUE
        GROUP BY proveedor_id
    LOOP
        -- Verificar si ya existe un borrador para este proveedor
        SELECT EXISTS (
            SELECT 1 
            FROM envios_correos 
            WHERE proveedor_id = v_proveedor.proveedor_id 
              AND estado = 'BORRADOR'
        ) INTO v_existe_borrador;
        
        -- Solo crear si NO existe borrador
        IF NOT v_existe_borrador THEN
            -- Obtener correo principal del proveedor
            SELECT correo INTO v_correo_principal
            FROM proveedor_correos
            WHERE proveedor_id = v_proveedor.proveedor_id 
              AND principal = TRUE 
              AND activo = TRUE
            LIMIT 1;
            
            -- Si no hay correo principal, tomar el primero activo
            IF v_correo_principal IS NULL THEN
                SELECT correo INTO v_correo_principal
                FROM proveedor_correos
                WHERE proveedor_id = v_proveedor.proveedor_id 
                  AND activo = TRUE
                ORDER BY id
                LIMIT 1;
            END IF;
            
            -- Crear borrador de correo
            INSERT INTO envios_correos (
                proveedor_id, 
                correo_seleccionado,
                usuario_envio_id,
                estado, 
                cantidad_pagos, 
                monto_total, 
                asunto, 
                cuerpo
            ) VALUES (
                v_proveedor.proveedor_id,
                v_correo_principal,
                1,  -- Usuario sistema (idealmente debería ser el que marcó pagado=TRUE)
                'BORRADOR',
                v_proveedor.cantidad,
                v_proveedor.total,
                'Notificación de Pagos Pendientes',
                format('Estimado proveedor, se han registrado %s pagos por un total de %s %s.',
                    v_proveedor.cantidad, 
                    v_proveedor.total,
                    v_proveedor.moneda
                )
            );
            
            RAISE NOTICE 'Correo borrador creado para proveedor ID: %', v_proveedor.proveedor_id;
        ELSE
            RAISE NOTICE 'Ya existe borrador para proveedor ID: %, omitiendo', v_proveedor.proveedor_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generar_correos_pendientes() IS 
'Genera borradores de correos para proveedores con pagos pendientes. 
Solo crea UN borrador por proveedor si no existe ya.';

-- ========================================
-- PASO 2: CREAR FUNCIÓN TRIGGER
-- ========================================
CREATE OR REPLACE FUNCTION trigger_generar_correo_automatico()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo ejecutar si:
    -- 1. El pago cambió de pagado=FALSE a pagado=TRUE
    -- 2. El pago está activo
    -- 3. El pago NO ha sido enviado por correo aún
    IF NEW.pagado = TRUE 
       AND OLD.pagado = FALSE 
       AND NEW.activo = TRUE 
       AND NEW.gmail_enviado = FALSE THEN
        
        -- Ejecutar función para generar correos pendientes
        PERFORM generar_correos_pendientes();
        
        RAISE NOTICE 'Trigger ejecutado: Generando correos pendientes para pago ID: %', NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION trigger_generar_correo_automatico() IS 
'Trigger que detecta cuando un pago cambia a pagado=TRUE y genera automáticamente 
un borrador de correo para el proveedor.';

-- ========================================
-- PASO 3: CREAR TRIGGER EN LA TABLA pagos
-- ========================================
DROP TRIGGER IF EXISTS trg_pagos_generar_correo ON pagos;

CREATE TRIGGER trg_pagos_generar_correo
AFTER UPDATE ON pagos
FOR EACH ROW 
EXECUTE FUNCTION trigger_generar_correo_automatico();

COMMENT ON TRIGGER trg_pagos_generar_correo ON pagos IS 
'Trigger automático que genera borradores de correo cuando pagado cambia a TRUE';

-- ========================================
-- PASO 4: VINCULAR PAGOS AL CORREO GENERADO
-- ========================================
-- NOTA IMPORTANTE: La función actual NO vincula los pagos al correo
-- Necesitamos mejorarla para que también vincule en envio_correo_detalle

CREATE OR REPLACE FUNCTION generar_correos_pendientes_con_vinculacion()
RETURNS void AS $$
DECLARE
    v_proveedor RECORD;
    v_correo_principal VARCHAR;
    v_existe_borrador BOOLEAN;
    v_correo_id BIGINT;
    v_pago RECORD;
BEGIN
    -- Recorrer pagos pendientes agrupados por proveedor
    FOR v_proveedor IN
        SELECT 
            proveedor_id, 
            COUNT(*) as cantidad, 
            SUM(monto) as total,
            MIN(moneda) as moneda
        FROM pagos
        WHERE pagado = TRUE 
          AND gmail_enviado = FALSE 
          AND activo = TRUE
        GROUP BY proveedor_id
    LOOP
        -- Verificar si ya existe un borrador para este proveedor
        SELECT id INTO v_correo_id
        FROM envios_correos 
        WHERE proveedor_id = v_proveedor.proveedor_id 
          AND estado = 'BORRADOR'
        LIMIT 1;
        
        -- Si NO existe borrador, crear uno nuevo
        IF v_correo_id IS NULL THEN
            -- Obtener correo principal del proveedor
            SELECT correo INTO v_correo_principal
            FROM proveedor_correos
            WHERE proveedor_id = v_proveedor.proveedor_id 
              AND principal = TRUE 
              AND activo = TRUE
            LIMIT 1;
            
            -- Si no hay correo principal, tomar el primero activo
            IF v_correo_principal IS NULL THEN
                SELECT correo INTO v_correo_principal
                FROM proveedor_correos
                WHERE proveedor_id = v_proveedor.proveedor_id 
                  AND activo = TRUE
                ORDER BY id
                LIMIT 1;
            END IF;
            
            -- Crear borrador de correo
            INSERT INTO envios_correos (
                proveedor_id, 
                correo_seleccionado,
                usuario_envio_id,
                estado, 
                cantidad_pagos, 
                monto_total, 
                asunto, 
                cuerpo
            ) VALUES (
                v_proveedor.proveedor_id,
                v_correo_principal,
                1,
                'BORRADOR',
                v_proveedor.cantidad,
                v_proveedor.total,
                'Notificación de Pagos Pendientes',
                format('Estimado proveedor, se han registrado %s pagos por un total de %s %s.',
                    v_proveedor.cantidad, 
                    v_proveedor.total,
                    v_proveedor.moneda
                )
            ) RETURNING id INTO v_correo_id;
            
            RAISE NOTICE 'Correo borrador creado para proveedor ID: %', v_proveedor.proveedor_id;
        END IF;
        
        -- VINCULAR TODOS LOS PAGOS PENDIENTES AL CORREO (nuevo o existente)
        FOR v_pago IN
            SELECT id
            FROM pagos
            WHERE proveedor_id = v_proveedor.proveedor_id
              AND pagado = TRUE 
              AND gmail_enviado = FALSE 
              AND activo = TRUE
        LOOP
            -- Verificar si ya está vinculado
            IF NOT EXISTS (
                SELECT 1 
                FROM envio_correo_detalle 
                WHERE envio_id = v_correo_id 
                  AND pago_id = v_pago.id
            ) THEN
                -- Vincular pago al correo
                INSERT INTO envio_correo_detalle (envio_id, pago_id)
                VALUES (v_correo_id, v_pago.id);
                
                RAISE NOTICE 'Pago ID: % vinculado a correo ID: %', v_pago.id, v_correo_id;
            END IF;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generar_correos_pendientes_con_vinculacion() IS 
'Genera borradores de correos Y vincula automáticamente los pagos en envio_correo_detalle';

-- ========================================
-- PASO 5: ACTUALIZAR TRIGGER PARA USAR NUEVA FUNCIÓN
-- ========================================
CREATE OR REPLACE FUNCTION trigger_generar_correo_automatico()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.pagado = TRUE 
       AND OLD.pagado = FALSE 
       AND NEW.activo = TRUE 
       AND NEW.gmail_enviado = FALSE THEN
        
        -- Usar función mejorada con vinculación
        PERFORM generar_correos_pendientes_con_vinculacion();
        
        RAISE NOTICE 'Trigger ejecutado: Generando correos con vinculación para pago ID: %', NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PASO 6: TESTING
-- ========================================
-- Para probar el trigger:
/*
-- 1. Crear un pago de prueba
SELECT pagos_post(
    1,  -- proveedor_id
    1,  -- usuario_id
    'TEST-AUTO-EMAIL-001',
    100.00,
    'USD',
    'TARJETA',
    1,  -- tarjeta_id
    NULL,
    NULL,
    'Pago de prueba para trigger automático',
    NULL
);

-- 2. Verificar que el pago está con pagado=FALSE
SELECT id, codigo_reserva, pagado, gmail_enviado 
FROM pagos 
WHERE codigo_reserva = 'TEST-AUTO-EMAIL-001';

-- 3. Cambiar pagado a TRUE (esto debe disparar el trigger)
UPDATE pagos 
SET pagado = TRUE 
WHERE codigo_reserva = 'TEST-AUTO-EMAIL-001';

-- 4. Verificar que se creó el correo borrador
SELECT * FROM envios_correos WHERE estado = 'BORRADOR' ORDER BY id DESC LIMIT 1;

-- 5. Verificar que el pago está vinculado al correo
SELECT ec.id as correo_id, ec.proveedor_id, ecd.pago_id, p.codigo_reserva
FROM envios_correos ec
JOIN envio_correo_detalle ecd ON ec.id = ecd.envio_id
JOIN pagos p ON ecd.pago_id = p.id
WHERE ec.estado = 'BORRADOR'
ORDER BY ec.id DESC;
*/

-- ============================================================================
-- FIN DE LA SOLUCIÓN
-- ============================================================================

-- ========================================
-- RESUMEN DE CAMBIOS
-- ========================================
/*
CAMBIOS REALIZADOS:

1. ✅ Mejorada función generar_correos_pendientes() para:
   - No duplicar borradores
   - Seleccionar correo principal del proveedor
   - Generar contenido básico del correo

2. ✅ Creada función trigger_generar_correo_automatico() que:
   - Detecta cambio de pagado=FALSE a pagado=TRUE
   - Ejecuta generación de correos automáticamente

3. ✅ Creado trigger trg_pagos_generar_correo que:
   - Se dispara AFTER UPDATE en tabla pagos
   - Ejecuta la función automáticamente

4. ✅ Creada función generar_correos_pendientes_con_vinculacion() que:
   - Genera borradores
   - Vincula pagos en envio_correo_detalle
   - No duplica vinculaciones

FLUJO FINAL:
1. Usuario actualiza pago: SET pagado = TRUE
2. Trigger detecta el cambio
3. Función genera borrador de correo para el proveedor
4. Función vincula el pago al correo en envio_correo_detalle
5. Usuario ve "Correos pendientes" en el módulo de envíos


*/



-- ============================================================================
-- SOLUCIÓN INMEDIATA: Reemplazar función con versión que usa usuario dinámico
-- ============================================================================
-- EJECUTA ESTE SCRIPT COMPLETO EN TU BASE DE DATOS
-- ============================================================================

-- ========================================
-- PASO 1: Reemplazar la función problemática
-- ========================================

CREATE OR REPLACE FUNCTION generar_correos_pendientes_con_vinculacion()
RETURNS void AS $$
DECLARE
    v_proveedor RECORD;
    v_correo_principal VARCHAR;
    v_correo_id BIGINT;
    v_pago RECORD;
    v_usuario_sistema_id BIGINT;
BEGIN
    -- ============================================
    -- BUSCAR USUARIO ACTIVO AUTOMÁTICAMENTE
    -- ============================================
    SELECT id INTO v_usuario_sistema_id
    FROM usuarios
    WHERE activo = TRUE
    ORDER BY id
    LIMIT 1;
    
    -- Si NO hay usuarios activos, abortar
    IF v_usuario_sistema_id IS NULL THEN
        RAISE EXCEPTION 'No hay usuarios activos en el sistema. Debe crear al menos un usuario.';
    END IF;
    
    RAISE NOTICE '✓ Usando usuario_envio_id: %', v_usuario_sistema_id;
    
    -- ============================================
    -- Generar correos por proveedor
    -- ============================================
    FOR v_proveedor IN
        SELECT 
            proveedor_id, 
            COUNT(*) as cantidad, 
            SUM(monto) as total,
            MIN(moneda) as moneda
        FROM pagos
        WHERE pagado = TRUE 
          AND gmail_enviado = FALSE 
          AND activo = TRUE
        GROUP BY proveedor_id
    LOOP
        -- Verificar si ya existe un borrador para este proveedor
        SELECT id INTO v_correo_id
        FROM envios_correos 
        WHERE proveedor_id = v_proveedor.proveedor_id 
          AND estado = 'BORRADOR'
        LIMIT 1;
        
        -- Si NO existe borrador, crear uno nuevo
        IF v_correo_id IS NULL THEN
            -- Obtener correo del proveedor
            SELECT correo INTO v_correo_principal
            FROM proveedor_correos
            WHERE proveedor_id = v_proveedor.proveedor_id 
              AND activo = TRUE
            ORDER BY principal DESC, id
            LIMIT 1;
            
            -- Si no hay correo, usar placeholder
            IF v_correo_principal IS NULL THEN
                v_correo_principal := 'sin-correo@temporal.com';
                RAISE WARNING 'Proveedor ID % no tiene correos registrados', v_proveedor.proveedor_id;
            END IF;
            
            -- Crear borrador de correo
            INSERT INTO envios_correos (
                proveedor_id, 
                correo_seleccionado,
                usuario_envio_id,        -- ← AHORA USA VARIABLE DINÁMICA
                estado, 
                cantidad_pagos, 
                monto_total, 
                asunto, 
                cuerpo
            ) VALUES (
                v_proveedor.proveedor_id,
                v_correo_principal,
                v_usuario_sistema_id,    -- ← USUARIO DINÁMICO (id=2 en tu caso)
                'BORRADOR',
                v_proveedor.cantidad,
                v_proveedor.total,
                'Notificación de Pagos Pendientes',
                format('Estimado proveedor, se han registrado %s pago(s) por un total de %s %s.',
                    v_proveedor.cantidad, 
                    v_proveedor.total,
                    v_proveedor.moneda
                )
            ) RETURNING id INTO v_correo_id;
            
            RAISE NOTICE '✓ Correo borrador creado para proveedor ID: % (correo_id: %)', 
                v_proveedor.proveedor_id, v_correo_id;
        ELSE
            RAISE NOTICE 'Borrador existente para proveedor ID: % (correo_id: %)', 
                v_proveedor.proveedor_id, v_correo_id;
        END IF;
        
        -- ============================================
        -- Vincular pagos pendientes al correo
        -- ============================================
        FOR v_pago IN
            SELECT id
            FROM pagos
            WHERE proveedor_id = v_proveedor.proveedor_id
              AND pagado = TRUE 
              AND gmail_enviado = FALSE 
              AND activo = TRUE
        LOOP
            -- Verificar si ya está vinculado
            IF NOT EXISTS (
                SELECT 1 
                FROM envio_correo_detalle 
                WHERE envio_id = v_correo_id 
                  AND pago_id = v_pago.id
            ) THEN
                -- Vincular pago al correo
                INSERT INTO envio_correo_detalle (envio_id, pago_id)
                VALUES (v_correo_id, v_pago.id);
                
                RAISE NOTICE '  → Pago ID: % vinculado a correo ID: %', v_pago.id, v_correo_id;
            ELSE
                RAISE NOTICE '  → Pago ID: % ya estaba vinculado', v_pago.id;
            END IF;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '✓ Proceso completado exitosamente';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generar_correos_pendientes_con_vinculacion() IS 
'Genera borradores de correos Y vincula pagos automáticamente.
MEJORA v2: Busca automáticamente el primer usuario activo (no usa hardcoded id=1).';

-- ========================================
-- PASO 2: Verificar que el trigger usa la función correcta
-- ========================================

CREATE OR REPLACE FUNCTION trigger_generar_correo_automatico()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo ejecutar si el pago cambió de FALSE a TRUE
    IF NEW.pagado = TRUE 
       AND OLD.pagado = FALSE 
       AND NEW.activo = TRUE 
       AND NEW.gmail_enviado = FALSE THEN
        
        RAISE NOTICE '🔔 Trigger activado para pago ID: %', NEW.id;
        
        -- Usar función mejorada con usuario dinámico
        PERFORM generar_correos_pendientes_con_vinculacion();
        
        RAISE NOTICE '✓ Correos generados exitosamente';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PASO 3: Recrear el trigger (por si acaso)
-- ========================================

DROP TRIGGER IF EXISTS trg_pagos_generar_correo ON pagos;

CREATE TRIGGER trg_pagos_generar_correo
AFTER UPDATE ON pagos
FOR EACH ROW 
EXECUTE FUNCTION trigger_generar_correo_automatico();

-- ============================================================================
-- VERIFICACIÓN INMEDIATA
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '✓ Funciones actualizadas correctamente';
    RAISE NOTICE '✓ Trigger recreado correctamente';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'Ahora puedes ejecutar:';
    RAISE NOTICE '  SELECT pagos_put(3, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- PRUEBA (Descomenta si quieres probar inmediatamente)
-- ============================================================================

/*
-- Habilitar mensajes de NOTICE para ver el log
SET client_min_messages TO NOTICE;

-- Ver usuarios disponibles
SELECT id, nombre_usuario, activo FROM usuarios;

-- Intentar actualizar el pago
SELECT pagos_put(3, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);

-- Ver correos generados
SELECT 
    id,
    proveedor_id,
    usuario_envio_id,
    cantidad_pagos,
    monto_total,
    estado,
    fecha_generacion
FROM envios_correos 
WHERE estado = 'BORRADOR'
ORDER BY id DESC 
LIMIT 5;

-- Ver vinculaciones
SELECT 
    ec.id as correo_id,
    ec.proveedor_id,
    ecd.pago_id,
    p.codigo_reserva,
    p.monto
FROM envios_correos ec
JOIN envio_correo_detalle ecd ON ec.id = ecd.envio_id
JOIN pagos p ON ecd.pago_id = p.id
WHERE ec.estado = 'BORRADOR'
ORDER BY ec.id DESC;
*/




-- ============================================================================
-- MEJORA: GENERAR CORREOS SEPARADOS POR TIPO DE MEDIO DE PAGO
-- ============================================================================
-- REQUERIMIENTO: Un proveedor puede tener 2 correos borradores:
--   1. Correo con pagos de TARJETA
--   2. Correo con pagos de CUENTA_BANCARIA
-- ============================================================================

-- ========================================
-- PASO 1: AGREGAR CAMPO tipo_medio_pago A envios_correos
-- ========================================

-- Verificar si la columna ya existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'envios_correos' 
        AND column_name = 'tipo_medio_pago'
    ) THEN
        ALTER TABLE envios_correos 
        ADD COLUMN tipo_medio_pago tipo_medio_pago;
        
        RAISE NOTICE '✓ Columna tipo_medio_pago agregada a envios_correos';
    ELSE
        RAISE NOTICE '⚠ Columna tipo_medio_pago ya existe en envios_correos';
    END IF;
END $$;

-- Agregar índice para mejorar búsquedas
CREATE INDEX IF NOT EXISTS idx_envios_correos_tipo_medio 
ON envios_correos(proveedor_id, estado, tipo_medio_pago);

COMMENT ON COLUMN envios_correos.tipo_medio_pago IS 
'Tipo de medio de pago de los pagos incluidos en este correo (TARJETA o CUENTA_BANCARIA)';

-- ========================================
-- PASO 2: FUNCIÓN MEJORADA - Generar correos por tipo de pago
-- ========================================

CREATE OR REPLACE FUNCTION generar_correos_pendientes_con_vinculacion()
RETURNS void AS $$
DECLARE
    v_proveedor_medio RECORD;
    v_correo_principal VARCHAR;
    v_correo_id BIGINT;
    v_pago RECORD;
    v_usuario_sistema_id BIGINT;
    v_asunto TEXT;
    v_cuerpo TEXT;
BEGIN
    -- ============================================
    -- BUSCAR USUARIO ACTIVO AUTOMÁTICAMENTE
    -- ============================================
    SELECT id INTO v_usuario_sistema_id
    FROM usuarios
    WHERE activo = TRUE
    ORDER BY id
    LIMIT 1;
    
    IF v_usuario_sistema_id IS NULL THEN
        RAISE EXCEPTION 'No hay usuarios activos en el sistema. Debe crear al menos un usuario.';
    END IF;
    
    RAISE NOTICE '✓ Usando usuario_envio_id: %', v_usuario_sistema_id;
    
    -- ============================================
    -- Agrupar por PROVEEDOR + TIPO_MEDIO_PAGO
    -- ============================================
    FOR v_proveedor_medio IN
        SELECT 
            proveedor_id,
            tipo_medio_pago,
            COUNT(*) as cantidad, 
            SUM(monto) as total,
            MIN(moneda) as moneda
        FROM pagos
        WHERE pagado = TRUE 
          AND gmail_enviado = FALSE 
          AND activo = TRUE
        GROUP BY proveedor_id, tipo_medio_pago  -- ← CLAVE: Agrupar por tipo de pago
        ORDER BY proveedor_id, tipo_medio_pago
    LOOP
        RAISE NOTICE '';
        RAISE NOTICE '═══════════════════════════════════════════════════════';
        RAISE NOTICE 'Procesando: Proveedor ID=%s, Tipo=%s', 
            v_proveedor_medio.proveedor_id, 
            v_proveedor_medio.tipo_medio_pago;
        RAISE NOTICE '  Cantidad pagos: %s', v_proveedor_medio.cantidad;
        RAISE NOTICE '  Monto total: %s %s', v_proveedor_medio.total, v_proveedor_medio.moneda;
        
        -- ============================================
        -- Verificar si ya existe borrador para este proveedor + tipo
        -- ============================================
        SELECT id INTO v_correo_id
        FROM envios_correos 
        WHERE proveedor_id = v_proveedor_medio.proveedor_id 
          AND tipo_medio_pago = v_proveedor_medio.tipo_medio_pago
          AND estado = 'BORRADOR'
        LIMIT 1;
        
        -- ============================================
        -- Si NO existe borrador, crear uno nuevo
        -- ============================================
        IF v_correo_id IS NULL THEN
            -- Obtener correo del proveedor
            SELECT correo INTO v_correo_principal
            FROM proveedor_correos
            WHERE proveedor_id = v_proveedor_medio.proveedor_id 
              AND activo = TRUE
            ORDER BY principal DESC, id
            LIMIT 1;
            
            IF v_correo_principal IS NULL THEN
                v_correo_principal := 'sin-correo@temporal.com';
                RAISE WARNING 'Proveedor ID % no tiene correos registrados', 
                    v_proveedor_medio.proveedor_id;
            END IF;
            
            -- Generar asunto personalizado según tipo de pago
            IF v_proveedor_medio.tipo_medio_pago = 'TARJETA' THEN
                v_asunto := format('Notificación de Pagos - Tarjeta de Crédito (%s %s)', 
                    v_proveedor_medio.total, 
                    v_proveedor_medio.moneda);
            ELSE
                v_asunto := format('Notificación de Pagos - Transferencia Bancaria (%s %s)', 
                    v_proveedor_medio.total, 
                    v_proveedor_medio.moneda);
            END IF;
            
            -- Generar cuerpo personalizado según tipo de pago
            IF v_proveedor_medio.tipo_medio_pago = 'TARJETA' THEN
                v_cuerpo := format(
                    E'Estimado proveedor,\n\n' ||
                    'Le informamos que se han realizado %s pago(s) con TARJETA DE CRÉDITO ' ||
                    'por un total de %s %s.\n\n' ||
                    'Los detalles de cada pago se encuentran adjuntos en este correo.\n\n' ||
                    'Saludos cordiales,\n' ||
                    'Terra Canada',
                    v_proveedor_medio.cantidad,
                    v_proveedor_medio.total,
                    v_proveedor_medio.moneda
                );
            ELSE
                v_cuerpo := format(
                    E'Estimado proveedor,\n\n' ||
                    'Le informamos que se han realizado %s pago(s) mediante TRANSFERENCIA BANCARIA ' ||
                    'por un total de %s %s.\n\n' ||
                    'Los detalles de cada pago se encuentran adjuntos en este correo.\n\n' ||
                    'Saludos cordiales,\n' ||
                    'Terra Canada',
                    v_proveedor_medio.cantidad,
                    v_proveedor_medio.total,
                    v_proveedor_medio.moneda
                );
            END IF;
            
            -- Crear borrador de correo
            INSERT INTO envios_correos (
                proveedor_id, 
                correo_seleccionado,
                usuario_envio_id,
                tipo_medio_pago,         -- ← NUEVO CAMPO
                estado, 
                cantidad_pagos, 
                monto_total, 
                asunto, 
                cuerpo
            ) VALUES (
                v_proveedor_medio.proveedor_id,
                v_correo_principal,
                v_usuario_sistema_id,
                v_proveedor_medio.tipo_medio_pago,  -- ← ALMACENAR TIPO
                'BORRADOR',
                v_proveedor_medio.cantidad,
                v_proveedor_medio.total,
                v_asunto,
                v_cuerpo
            ) RETURNING id INTO v_correo_id;
            
            RAISE NOTICE '✓ Correo borrador creado (ID: %, Tipo: %)', 
                v_correo_id,
                v_proveedor_medio.tipo_medio_pago;
        ELSE
            RAISE NOTICE '→ Borrador existente (ID: %, Tipo: %)', 
                v_correo_id,
                v_proveedor_medio.tipo_medio_pago;
        END IF;
        
        -- ============================================
        -- Vincular SOLO pagos del mismo tipo de medio
        -- ============================================
        FOR v_pago IN
            SELECT id, codigo_reserva
            FROM pagos
            WHERE proveedor_id = v_proveedor_medio.proveedor_id
              AND tipo_medio_pago = v_proveedor_medio.tipo_medio_pago  -- ← FILTRO CRÍTICO
              AND pagado = TRUE 
              AND gmail_enviado = FALSE 
              AND activo = TRUE
        LOOP
            -- Verificar si ya está vinculado
            IF NOT EXISTS (
                SELECT 1 
                FROM envio_correo_detalle 
                WHERE envio_id = v_correo_id 
                  AND pago_id = v_pago.id
            ) THEN
                INSERT INTO envio_correo_detalle (envio_id, pago_id)
                VALUES (v_correo_id, v_pago.id);
                
                RAISE NOTICE '  → Pago vinculado: ID=%s, Código=%s', 
                    v_pago.id, 
                    v_pago.codigo_reserva;
            END IF;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✓ Proceso completado exitosamente';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generar_correos_pendientes_con_vinculacion() IS 
'Genera borradores de correos separados por TIPO DE MEDIO DE PAGO.
Un proveedor puede tener 2 correos: uno para TARJETA y otro para CUENTA_BANCARIA.';

-- ========================================
-- PASO 3: ACTUALIZAR FUNCIÓN GET de envios_correos
-- ========================================

CREATE OR REPLACE FUNCTION envios_correos_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los correos (con tipo_medio_pago)
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correos obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', e.id,
                        'proveedor', json_build_object(
                            'id', p.id,
                            'nombre', p.nombre,
                            'lenguaje', p.lenguaje
                        ),
                        'tipo_medio_pago', e.tipo_medio_pago,  -- ← NUEVO CAMPO
                        'estado', e.estado,
                        'cantidad_pagos', e.cantidad_pagos,
                        'monto_total', e.monto_total,
                        'correo_seleccionado', e.correo_seleccionado,
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
                    ORDER BY e.fecha_creacion DESC
                ) FROM envios_correos e
                JOIN proveedores p ON e.proveedor_id = p.id
                LEFT JOIN usuarios u ON e.usuario_envio_id = u.id),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
        -- Obtener un correo específico (con tipo_medio_pago y pagos filtrados)
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
                'tipo_medio_pago', e.tipo_medio_pago,  -- ← NUEVO CAMPO
                'estado', e.estado,
                'cantidad_pagos', e.cantidad_pagos,
                'monto_total', e.monto_total,
                'correo_seleccionado', e.correo_seleccionado,
                'asunto', e.asunto,
                'cuerpo', e.cuerpo,
                'pagos_incluidos', (
                    SELECT COALESCE(json_agg(
                        json_build_object(
                            'id', pa.id,
                            'codigo_reserva', pa.codigo_reserva,
                            'monto', pa.monto,
                            'moneda', pa.moneda,
                            'tipo_medio_pago', pa.tipo_medio_pago,  -- ← MOSTRAR TIPO
                            'descripcion', pa.descripcion
                        )
                    ), '[]'::json)
                    FROM envio_correo_detalle ecd
                    JOIN pagos pa ON ecd.pago_id = pa.id
                    WHERE ecd.envio_id = e.id
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
-- PASO 4: ACTUALIZAR FUNCIÓN POST de envios_correos
-- ========================================

CREATE OR REPLACE FUNCTION envios_correos_post(
    p_proveedor_id BIGINT,
    p_usuario_envio_id BIGINT,
    p_tipo_medio_pago tipo_medio_pago,  -- ← NUEVO PARÁMETRO
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
    v_tipo_invalido BOOLEAN := FALSE;
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
    
    -- ============================================
    -- VALIDAR: Todos los pagos deben ser del mismo tipo_medio_pago
    -- ============================================
    SELECT EXISTS (
        SELECT 1 
        FROM pagos 
        WHERE id = ANY(p_pagos_ids) 
        AND tipo_medio_pago != p_tipo_medio_pago
    ) INTO v_tipo_invalido;
    
    IF v_tipo_invalido THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', format('Todos los pagos deben ser del tipo %s', p_tipo_medio_pago),
            'data', null
        );
    END IF;
    
    -- Calcular cantidad y monto total
    SELECT COUNT(*), COALESCE(SUM(monto), 0)
    INTO v_cantidad, v_monto_total
    FROM pagos
    WHERE id = ANY(p_pagos_ids);
    
    -- Insertar nuevo correo con tipo_medio_pago
    INSERT INTO envios_correos (
        proveedor_id, 
        usuario_envio_id, 
        tipo_medio_pago,      -- ← NUEVO CAMPO
        estado, 
        cantidad_pagos, 
        monto_total, 
        asunto, 
        cuerpo
    )
    VALUES (
        p_proveedor_id, 
        p_usuario_envio_id, 
        p_tipo_medio_pago,    -- ← ALMACENAR TIPO
        'BORRADOR', 
        v_cantidad,
        v_monto_total, 
        p_asunto, 
        p_cuerpo
    )
    RETURNING id INTO v_id;
    
    -- Vincular los pagos al correo
    FOREACH v_pago_id IN ARRAY p_pagos_ids
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pagos WHERE id = v_pago_id AND pagado = TRUE AND gmail_enviado = FALSE) THEN
            RAISE EXCEPTION 'El pago con ID % no existe, no está pagado, o ya fue enviado por correo', v_pago_id;
        END IF;
        
        INSERT INTO envio_correo_detalle (envio_id, pago_id)
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

-- ============================================================================
-- PASO 5: EJEMPLOS Y VERIFICACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '✓ MIGRACIÓN COMPLETADA EXITOSAMENTE';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'CAMBIOS REALIZADOS:';
    RAISE NOTICE '  1. ✓ Columna tipo_medio_pago agregada a envios_correos';
    RAISE NOTICE '  2. ✓ Función de generación mejorada (agrupa por tipo)';
    RAISE NOTICE '  3. ✓ Función GET actualizada (muestra tipo)';
    RAISE NOTICE '  4. ✓ Función POST actualizada (valida tipo)';
    RAISE NOTICE '';
    RAISE NOTICE 'COMPORTAMIENTO NUEVO:';
    RAISE NOTICE '  • Un proveedor puede tener 2 correos borradores:';
    RAISE NOTICE '    - Uno con pagos de TARJETA';
    RAISE NOTICE '    - Otro con pagos de CUENTA_BANCARIA';
    RAISE NOTICE '';
    RAISE NOTICE 'PRUEBA:';
    RAISE NOTICE '  SELECT pagos_put(ID, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- CONSULTAS ÚTILES PARA VERIFICAR
-- ============================================================================

/*
-- Ver correos agrupados por proveedor y tipo
SELECT 
    proveedor_id,
    tipo_medio_pago,
    COUNT(*) as num_correos,
    SUM(cantidad_pagos) as total_pagos,
    SUM(monto_total) as total_monto,
    estado
FROM envios_correos
GROUP BY proveedor_id, tipo_medio_pago, estado
ORDER BY proveedor_id, tipo_medio_pago;

-- Ver detalle de correos con tipo de pago
SELECT 
    e.id as correo_id,
    p.nombre as proveedor,
    e.tipo_medio_pago,
    e.cantidad_pagos,
    e.monto_total,
    e.estado
FROM envios_correos e
JOIN proveedores p ON e.proveedor_id = p.id
ORDER BY e.proveedor_id, e.tipo_medio_pago, e.id DESC;

-- Ver pagos en cada correo con su tipo
SELECT 
    ec.id as correo_id,
    ec.tipo_medio_pago as tipo_correo,
    pag.id as pago_id,
    pag.codigo_reserva,
    pag.tipo_medio_pago as tipo_pago,
    pag.monto
FROM envios_correos ec
JOIN envio_correo_detalle ecd ON ec.id = ecd.envio_id
JOIN pagos pag ON ecd.pago_id = pag.id
WHERE ec.estado = 'BORRADOR'
ORDER BY ec.id, pag.id;
*/



-- ============================================================================
-- CORRECCIÓN: Trigger solo debe ejecutarse cuando pagado cambia a TRUE
-- ============================================================================
-- PROBLEMA: El trigger se ejecuta en cualquier UPDATE, incluso al crear pagos
-- SOLUCIÓN: Verificar estrictamente que OLD.pagado = FALSE y NEW.pagado = TRUE
-- ============================================================================

-- ========================================
-- DIAGNÓSTICO: Ver qué está pasando
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '🔍 DIAGNÓSTICO DEL PROBLEMA';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- Ver correos que se generaron incorrectamente
SELECT 
    'Correos generados incorrectamente:' as diagnostico,
    ec.id,
    ec.proveedor_id,
    ec.tipo_medio_pago,
    ec.cantidad_pagos,
    ec.fecha_generacion,
    COUNT(ecd.pago_id) as pagos_vinculados,
    COUNT(CASE WHEN p.pagado = FALSE THEN 1 END) as pagos_no_pagados
FROM envios_correos ec
LEFT JOIN envio_correo_detalle ecd ON ec.id = ecd.envio_id
LEFT JOIN pagos p ON ecd.pago_id = p.id
WHERE ec.estado = 'BORRADOR'
GROUP BY ec.id, ec.proveedor_id, ec.tipo_medio_pago, ec.cantidad_pagos, ec.fecha_generacion
HAVING COUNT(CASE WHEN p.pagado = FALSE THEN 1 END) > 0;

-- ========================================
-- PASO 1: CORREGIR LA FUNCIÓN TRIGGER
-- ========================================

CREATE OR REPLACE FUNCTION trigger_generar_correo_automatico()
RETURNS TRIGGER AS $$
BEGIN
    -- ============================================
    -- VALIDACIÓN ESTRICTA: Solo ejecutar si:
    -- 1. OLD.pagado = FALSE (era FALSE antes)
    -- 2. NEW.pagado = TRUE (cambió a TRUE ahora)
    -- 3. NEW.activo = TRUE (el pago está activo)
    -- 4. NEW.gmail_enviado = FALSE (no ha sido enviado)
    -- ============================================
    
    -- Primero verificar que OLD existe (no es INSERT)
    IF TG_OP = 'INSERT' THEN
        -- En INSERT, OLD no existe, no hacer nada
        RAISE NOTICE '→ INSERT detectado (no generar correo)';
        RETURN NEW;
    END IF;
    
    -- Ahora sí, validar el cambio de estado
    IF OLD.pagado = FALSE 
       AND NEW.pagado = TRUE 
       AND NEW.activo = TRUE 
       AND NEW.gmail_enviado = FALSE THEN
        
        RAISE NOTICE '';
        RAISE NOTICE '🔔 ═══════════════════════════════════════════════════';
        RAISE NOTICE '🔔 TRIGGER ACTIVADO - Pago cambió a PAGADO=TRUE';
        RAISE NOTICE '🔔 ═══════════════════════════════════════════════════';
        RAISE NOTICE '   Pago ID: %', NEW.id;
        RAISE NOTICE '   Código: %', NEW.codigo_reserva;
        RAISE NOTICE '   OLD.pagado: FALSE → NEW.pagado: TRUE';
        RAISE NOTICE '   Proveedor ID: %', NEW.proveedor_id;
        RAISE NOTICE '   Tipo medio: %', NEW.tipo_medio_pago;
        RAISE NOTICE '';
        
        -- Ejecutar función de generación de correos
        PERFORM generar_correos_pendientes_con_vinculacion();
        
        RAISE NOTICE '✓ Correos generados exitosamente';
        RAISE NOTICE '';
    ELSE
        -- Log para debugging (ver por qué NO se ejecutó)
        IF OLD.pagado != NEW.pagado THEN
            RAISE NOTICE '→ Cambio en pagado detectado pero no cumple condiciones:';
            RAISE NOTICE '   Pago ID: %, OLD.pagado: %, NEW.pagado: %', 
                NEW.id, OLD.pagado, NEW.pagado;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION trigger_generar_correo_automatico() IS 
'Trigger que SOLO genera correos cuando pagado cambia de FALSE a TRUE.
VALIDACIÓN ESTRICTA: Verifica que sea UPDATE (no INSERT) y que OLD.pagado = FALSE.';

-- ========================================
-- PASO 2: RECREAR EL TRIGGER
-- ========================================

-- Eliminar trigger existente
DROP TRIGGER IF EXISTS trg_pagos_generar_correo ON pagos;

-- Crear trigger SOLO para UPDATE (no INSERT)
CREATE TRIGGER trg_pagos_generar_correo
AFTER UPDATE ON pagos           -- ← SOLO UPDATE, no INSERT
FOR EACH ROW 
WHEN (OLD.pagado = FALSE AND NEW.pagado = TRUE)  -- ← CONDICIÓN EN EL TRIGGER
EXECUTE FUNCTION trigger_generar_correo_automatico();

COMMENT ON TRIGGER trg_pagos_generar_correo ON pagos IS 
'Trigger que se ejecuta SOLO cuando pagado cambia de FALSE a TRUE en UPDATE.
NO se ejecuta en INSERT.';

-- ========================================
-- PASO 3: LIMPIAR CORREOS GENERADOS INCORRECTAMENTE
-- ========================================

DO $$
DECLARE
    v_correos_borrados INT := 0;
    v_correo RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '🧹 LIMPIEZA DE CORREOS INCORRECTOS';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    
    -- Buscar correos que tengan pagos con pagado=FALSE
    FOR v_correo IN
        SELECT DISTINCT ec.id, ec.proveedor_id, ec.tipo_medio_pago
        FROM envios_correos ec
        JOIN envio_correo_detalle ecd ON ec.id = ecd.envio_id
        JOIN pagos p ON ecd.pago_id = p.id
        WHERE ec.estado = 'BORRADOR'
          AND p.pagado = FALSE  -- ← Pagos que no están pagados
    LOOP
        RAISE NOTICE '  → Eliminando correo ID: % (tiene pagos con pagado=FALSE)', v_correo.id;
        
        -- Eliminar vinculaciones
        DELETE FROM envio_correo_detalle WHERE envio_id = v_correo.id;
        
        -- Eliminar correo
        DELETE FROM envios_correos WHERE id = v_correo.id;
        
        v_correos_borrados := v_correos_borrados + 1;
    END LOOP;
    
    IF v_correos_borrados > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '✓ Se eliminaron % correos generados incorrectamente', v_correos_borrados;
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✓ No se encontraron correos incorrectos';
    END IF;
    
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- ========================================
-- PASO 4: VERIFICAR CONFIGURACIÓN FINAL
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '✓ CORRECCIÓN APLICADA EXITOSAMENTE';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'CAMBIOS REALIZADOS:';
    RAISE NOTICE '  1. ✓ Función trigger corregida con validación estricta';
    RAISE NOTICE '  2. ✓ Trigger recreado con cláusula WHEN';
    RAISE NOTICE '  3. ✓ Correos incorrectos eliminados';
    RAISE NOTICE '';
    RAISE NOTICE 'COMPORTAMIENTO CORRECTO:';
    RAISE NOTICE '  • INSERT de pago → NO genera correo ✓';
    RAISE NOTICE '  • UPDATE sin cambiar pagado → NO genera correo ✓';
    RAISE NOTICE '  • UPDATE pagado FALSE→TRUE → SÍ genera correo ✓';
    RAISE NOTICE '';
    RAISE NOTICE 'PRUEBA:';
    RAISE NOTICE '  1. Crear pago: SELECT pagos_post(...) → No genera correo';
    RAISE NOTICE '  2. Marcar pagado: SELECT pagos_put(ID, ..., TRUE, ...) → SÍ genera correo';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- ========================================
-- PASO 5: CONSULTAS DE VERIFICACIÓN
-- ========================================

-- Ver trigger actual
SELECT 
    'Configuración del trigger:' as info,
    tgname as nombre_trigger,
    tgtype as tipo,
    tgenabled as habilitado,
    pg_get_triggerdef(oid) as definicion
FROM pg_trigger 
WHERE tgname = 'trg_pagos_generar_correo';

-- Ver correos borradores actuales (deberían estar todos con pagado=TRUE)
SELECT 
    'Correos borradores válidos:' as info,
    ec.id,
    ec.proveedor_id,
    ec.tipo_medio_pago,
    ec.cantidad_pagos,
    COUNT(ecd.pago_id) as pagos_vinculados,
    COUNT(CASE WHEN p.pagado = TRUE THEN 1 END) as pagos_pagados,
    COUNT(CASE WHEN p.pagado = FALSE THEN 1 END) as pagos_no_pagados
FROM envios_correos ec
LEFT JOIN envio_correo_detalle ecd ON ec.id = ecd.envio_id
LEFT JOIN pagos p ON ecd.pago_id = p.id
WHERE ec.estado = 'BORRADOR'
GROUP BY ec.id, ec.proveedor_id, ec.tipo_medio_pago, ec.cantidad_pagos
ORDER BY ec.id;

-- ============================================================================
-- CASOS DE PRUEBA
-- ============================================================================

/*
-- PRUEBA 1: Crear un pago (NO debe generar correo)
-- ═══════════════════════════════════════════════════════════════════════════

SELECT pagos_post(
    1,  -- proveedor_id
    2,  -- usuario_id
    'TEST-NO-CORREO-001',
    100.00,
    'USD',
    'TARJETA',
    1,  -- tarjeta_id
    NULL,
    NULL,
    'Pago de prueba - NO debe generar correo al crear',
    NULL
);

-- Verificar: NO debe haber correo nuevo
SELECT COUNT(*) as correos_nuevos 
FROM envios_correos 
WHERE fecha_generacion > NOW() - INTERVAL '1 minute';
-- Debe devolver: 0

-- Ver el pago creado
SELECT id, codigo_reserva, pagado, gmail_enviado 
FROM pagos 
WHERE codigo_reserva = 'TEST-NO-CORREO-001';
-- Debe mostrar: pagado = FALSE


-- PRUEBA 2: Marcar como pagado (SÍ debe generar correo)
-- ═══════════════════════════════════════════════════════════════════════════

-- Obtener el ID del pago
SELECT id FROM pagos WHERE codigo_reserva = 'TEST-NO-CORREO-001';

-- Marcar como pagado (reemplaza X con el ID del pago)
SELECT pagos_put(
    X,      -- id del pago
    NULL,   -- monto
    NULL,   -- descripcion
    NULL,   -- fecha_esperada_debito
    TRUE,   -- pagado = TRUE ← AQUÍ DEBE GENERAR CORREO
    NULL,   -- verificado
    NULL,   -- gmail_enviado
    NULL    -- activo
);

-- Verificar: SÍ debe haber correo nuevo
SELECT 
    ec.id,
    ec.proveedor_id,
    ec.tipo_medio_pago,
    ec.cantidad_pagos,
    ec.fecha_generacion
FROM envios_correos ec
WHERE ec.fecha_generacion > NOW() - INTERVAL '1 minute'
  AND ec.estado = 'BORRADOR';
-- Debe devolver: 1 correo

-- Verificar vinculación
SELECT 
    ecd.envio_id,
    ecd.pago_id,
    p.codigo_reserva,
    p.pagado
FROM envio_correo_detalle ecd
JOIN pagos p ON ecd.pago_id = p.id
WHERE p.codigo_reserva = 'TEST-NO-CORREO-001';
-- Debe mostrar: el pago vinculado al correo


-- PRUEBA 3: UPDATE sin cambiar pagado (NO debe generar correo)
-- ═══════════════════════════════════════════════════════════════════════════

SELECT pagos_put(
    X,      -- id del pago
    NULL,
    'Descripción actualizada',  -- solo cambio descripción
    NULL,
    NULL,   -- pagado sigue TRUE
    NULL,
    NULL,
    NULL
);

-- Verificar: NO debe generar correo adicional
SELECT COUNT(*) as correos_nuevos 
FROM envios_correos 
WHERE fecha_generacion > NOW() - INTERVAL '10 seconds';
-- Debe devolver: 0 (no nuevos)


-- PRUEBA 4: Múltiples pagos del mismo proveedor
-- ═══════════════════════════════════════════════════════════════════════════

-- Crear 3 pagos con tarjeta
SELECT pagos_post(1, 2, 'MULTI-T-001', 100.00, 'USD', 'TARJETA', 1, NULL, NULL, 'Pago 1', NULL);
SELECT pagos_post(1, 2, 'MULTI-T-002', 200.00, 'USD', 'TARJETA', 1, NULL, NULL, 'Pago 2', NULL);
SELECT pagos_post(1, 2, 'MULTI-T-003', 300.00, 'USD', 'TARJETA', 1, NULL, NULL, 'Pago 3', NULL);

-- Crear 2 pagos con cuenta bancaria
SELECT pagos_post(1, 2, 'MULTI-C-001', 500.00, 'USD', 'CUENTA_BANCARIA', NULL, 1, NULL, 'Pago 4', NULL);
SELECT pagos_post(1, 2, 'MULTI-C-002', 600.00, 'USD', 'CUENTA_BANCARIA', NULL, 1, NULL, 'Pago 5', NULL);

-- NO debe haber correos aún
SELECT COUNT(*) FROM envios_correos WHERE fecha_generacion > NOW() - INTERVAL '1 minute';
-- Debe devolver: 0

-- Marcar los 5 como pagados
UPDATE pagos SET pagado = TRUE WHERE codigo_reserva LIKE 'MULTI-%';

-- Verificar: Deben generarse 2 correos (uno TARJETA, uno CUENTA_BANCARIA)
SELECT 
    tipo_medio_pago,
    cantidad_pagos,
    monto_total
FROM envios_correos 
WHERE fecha_generacion > NOW() - INTERVAL '1 minute'
ORDER BY tipo_medio_pago;
-- Debe mostrar:
-- CUENTA_BANCARIA | 2 | 1100.00
-- TARJETA         | 3 | 600.00
*/

-- ============================================================================
-- FIN DEL SCRIPT DE CORRECCIÓN
-- ============================================================================





-- Antes de la prueba
SELECT COUNT(*) FROM envios_correos;  -- Ej: 5 correos

-- Crear pago
SELECT pagos_post(1, 2, 'TEST-001', 100, 'USD', 'TARJETA', 1, NULL, NULL, 'Test', NULL);

-- Después de la prueba
SELECT COUNT(*) FROM envios_correos;  -- Debe seguir: 5 correos (sin cambios)

-- Verificar el pago
SELECT pagado FROM pagos WHERE codigo_reserva = 'TEST-001';
-- Debe mostrar: FALSE



-- Antes
SELECT COUNT(*) FROM envios_correos;  -- Ej: 5 correos

-- Obtener ID
SELECT id FROM pagos WHERE codigo_reserva = 'TEST-001';  -- Ej: 10

-- Marcar como pagado
SELECT pagos_put(7, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);

-- Después
SELECT COUNT(*) FROM envios_correos;  -- Debe ser: 6 correos (nuevo)

-- Verificar vinculación
SELECT COUNT(*) 
FROM envio_correo_detalle ecd
JOIN pagos p ON ecd.pago_id = p.id
WHERE p.codigo_reserva = 'TEST-001';
-- Debe mostrar: 1 (vinculado)