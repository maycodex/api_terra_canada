-- ============================================================================
-- DDL COMPLETO - SISTEMA DE GESTIÓN DE PAGOS TERRA CANADA
-- VERSION 2.0 - CON IDs AUTOINCREMENTABLES (SIN UUIDs)
-- Fecha: 28 de Enero, 2026
-- ============================================================================

-- ==========================
-- EXTENSIONES REQUERIDAS
-- ==========================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- Para encriptación de contraseñas

-- ==========================
-- CONFIGURACIÓN DE ZONA HORARIA
-- ==========================

SET timezone = 'Europe/Paris';  -- Hora de Francia

-- ==========================
-- TIPOS ENUM
-- ==========================

-- NOTA: ¿Por qué ENUM y no tablas?
-- Los ENUMs son valores FIJOS con lógica de negocio en el código.
-- Si los valores pueden crecer o necesitan metadata, usar tablas.

-- Roles: USA TABLA (roles) porque puede tener metadata y permisos
-- Servicios: USA TABLA (servicios) porque puede crecer dinámicamente

-- Monedas soportadas (ENUM: solo 2 valores fijos)
CREATE TYPE tipo_moneda AS ENUM (
  'USD',
  'CAD'
);

-- Tipos de medios de pago (ENUM: lógica de negocio diferente)
CREATE TYPE tipo_medio_pago AS ENUM (
  'TARJETA',            -- Descuenta saldo automáticamente
  'CUENTA_BANCARIA'     -- Solo registra, no descuenta
);

-- Tipos de documentos (ENUM: lógica MUY diferente)
CREATE TYPE tipo_documento AS ENUM (
  'FACTURA',          -- Cambia pagado = TRUE en 1 pago
  'DOCUMENTO_BANCO'   -- Cambia pagado + verificado = TRUE en N pagos
);

-- Estados de correo (ENUM: workflow simple de 2 estados)
CREATE TYPE estado_correo AS ENUM (
  'BORRADOR',
  'ENVIADO'
);

-- Tipos de eventos de auditoría (ENUM: lista fija del sistema)
CREATE TYPE tipo_evento AS ENUM (
  'INICIO_SESION',
  'CREAR',
  'ACTUALIZAR',
  'ELIMINAR',
  'VERIFICAR_PAGO',
  'CARGAR_TARJETA',
  'ENVIAR_CORREO',
  'SUBIR_DOCUMENTO',
  'RESET_MENSUAL'
);

-- ==========================
-- TABLAS CATÁLOGO
-- ==========================

CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE roles IS 'Catálogo de roles del sistema';

CREATE TABLE servicios (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE servicios IS 'Catálogo de servicios ofrecidos';

-- ==========================
-- TABLA: usuarios
-- ==========================

CREATE TABLE usuarios (
  id BIGSERIAL PRIMARY KEY,
  nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
  correo VARCHAR(255) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL,
  nombre_completo VARCHAR(100) NOT NULL,
  rol_id INT NOT NULL REFERENCES roles(id) ON UPDATE CASCADE,
  telefono VARCHAR(20),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_email_valido CHECK (correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_usuarios_correo ON usuarios(correo);
CREATE INDEX idx_usuarios_rol ON usuarios(rol_id);
CREATE INDEX idx_usuarios_activo ON usuarios(activo) WHERE activo = TRUE;

COMMENT ON TABLE usuarios IS 'Usuarios del sistema con autenticación y roles';

-- ==========================
-- TABLA: proveedores
-- ==========================

CREATE TABLE proveedores (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  servicio_id INT NOT NULL REFERENCES servicios(id) ON UPDATE CASCADE,
  lenguaje VARCHAR(50),  -- Idioma del proveedor (Español, English, Français)
  telefono VARCHAR(20),
  descripcion TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_proveedores_servicio ON proveedores(servicio_id);
CREATE INDEX idx_proveedores_activo ON proveedores(activo) WHERE activo = TRUE;
CREATE INDEX idx_proveedores_nombre ON proveedores(nombre);

COMMENT ON TABLE proveedores IS 'Proveedores de servicios turísticos';
COMMENT ON COLUMN proveedores.lenguaje IS 'Idioma del proveedor, dato de referencia para redactar correos';

-- ==========================
-- TABLA: proveedor_correos
-- ==========================

CREATE TABLE proveedor_correos (
  id SERIAL PRIMARY KEY,
  proveedor_id BIGINT NOT NULL REFERENCES proveedores(id) ON UPDATE CASCADE ON DELETE CASCADE,
  correo VARCHAR(255) NOT NULL,
  principal BOOLEAN NOT NULL DEFAULT FALSE,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_email_valido CHECK (correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_proveedor_correos_proveedor ON proveedor_correos(proveedor_id);
CREATE INDEX idx_proveedor_correos_activo ON proveedor_correos(proveedor_id, activo) WHERE activo = TRUE;

COMMENT ON TABLE proveedor_correos IS 'Hasta 4 correos por proveedor';

-- ==========================
-- TABLA: clientes
-- ==========================

CREATE TABLE clientes (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  ubicacion VARCHAR(255),
  telefono VARCHAR(20),
  correo VARCHAR(255),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_email_valido CHECK (correo IS NULL OR correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_clientes_nombre ON clientes(nombre);
CREATE INDEX idx_clientes_activo ON clientes(activo) WHERE activo = TRUE;

COMMENT ON TABLE clientes IS 'Hoteles y empresas clientes';

-- ==========================
-- TABLA: tarjetas_credito
-- ==========================

CREATE TABLE tarjetas_credito (
  id BIGSERIAL PRIMARY KEY,
  nombre_titular VARCHAR(100) NOT NULL,
  ultimos_4_digitos VARCHAR(4) NOT NULL,
  moneda tipo_moneda NOT NULL,
  limite_mensual DECIMAL(12,2) NOT NULL,
  saldo_disponible DECIMAL(12,2) NOT NULL,
  tipo_tarjeta VARCHAR(50) DEFAULT 'Visa',
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_limite_positivo CHECK (limite_mensual > 0),
  CONSTRAINT chk_saldo_no_negativo CHECK (saldo_disponible >= 0),
  CONSTRAINT chk_saldo_no_excede_limite CHECK (saldo_disponible <= limite_mensual),
  CONSTRAINT chk_ultimos_4_digitos CHECK (ultimos_4_digitos ~ '^\d{4}$')
);

CREATE INDEX idx_tarjetas_activo ON tarjetas_credito(activo) WHERE activo = TRUE;
CREATE INDEX idx_tarjetas_moneda ON tarjetas_credito(moneda);

COMMENT ON TABLE tarjetas_credito IS 'Tarjetas de crédito con control de saldo';

-- ==========================
-- TABLA: cuentas_bancarias
-- ==========================

CREATE TABLE cuentas_bancarias (
  id BIGSERIAL PRIMARY KEY,
  nombre_banco VARCHAR(100) NOT NULL,
  nombre_cuenta VARCHAR(100) NOT NULL,
  ultimos_4_digitos VARCHAR(4) NOT NULL,
  moneda tipo_moneda NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chk_ultimos_4_digitos CHECK (ultimos_4_digitos ~ '^\d{4}$')
);

CREATE INDEX idx_cuentas_activo ON cuentas_bancarias(activo) WHERE activo = TRUE;
CREATE INDEX idx_cuentas_moneda ON cuentas_bancarias(moneda);

COMMENT ON TABLE cuentas_bancarias IS 'Cuentas bancarias sin control de saldo';

-- ==========================
-- TABLA: pagos (CORE)
-- ==========================

CREATE TABLE pagos (
  id BIGSERIAL PRIMARY KEY,
  proveedor_id BIGINT NOT NULL REFERENCES proveedores(id) ON UPDATE CASCADE,
  usuario_id BIGINT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE,
  codigo_reserva VARCHAR(100) NOT NULL UNIQUE,
  monto DECIMAL(12,2) NOT NULL,
  moneda tipo_moneda NOT NULL,
  descripcion TEXT,
  fecha_esperada_debito DATE,
  
  -- Medio de pago
  tipo_medio_pago tipo_medio_pago NOT NULL,
  tarjeta_id BIGINT REFERENCES tarjetas_credito(id) ON UPDATE CASCADE,
  cuenta_bancaria_id BIGINT REFERENCES cuentas_bancarias(id) ON UPDATE CASCADE,
  
  -- Estados booleanos
  pagado BOOLEAN NOT NULL DEFAULT FALSE,
  verificado BOOLEAN NOT NULL DEFAULT FALSE,
  gmail_enviado BOOLEAN NOT NULL DEFAULT FALSE,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Fechas de control
  fecha_pago TIMESTAMPTZ,
  fecha_verificacion TIMESTAMPTZ,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT chk_monto_positivo CHECK (monto > 0),
  CONSTRAINT chk_medio_pago_exclusivo CHECK (
    (tipo_medio_pago = 'TARJETA' AND tarjeta_id IS NOT NULL AND cuenta_bancaria_id IS NULL) OR
    (tipo_medio_pago = 'CUENTA_BANCARIA' AND cuenta_bancaria_id IS NOT NULL AND tarjeta_id IS NULL)
  ),
  CONSTRAINT chk_fecha_pago_coherente CHECK (
    (pagado = TRUE AND fecha_pago IS NOT NULL) OR
    (pagado = FALSE AND fecha_pago IS NULL)
  ),
  CONSTRAINT chk_fecha_verificacion_coherente CHECK (
    (verificado = TRUE AND fecha_verificacion IS NOT NULL) OR
    (verificado = FALSE AND fecha_verificacion IS NULL)
  )
);

CREATE INDEX idx_pagos_proveedor ON pagos(proveedor_id);
CREATE INDEX idx_pagos_usuario ON pagos(usuario_id);
CREATE INDEX idx_pagos_pagado ON pagos(pagado);
CREATE INDEX idx_pagos_verificado ON pagos(verificado);
CREATE INDEX idx_pagos_gmail_enviado ON pagos(gmail_enviado);
CREATE INDEX idx_pagos_activo ON pagos(activo) WHERE activo = TRUE;
CREATE INDEX idx_pagos_fecha_creacion ON pagos(fecha_creacion DESC);
CREATE INDEX idx_pagos_codigo ON pagos(codigo_reserva);
CREATE INDEX idx_pagos_correos_pendientes 
ON pagos(pagado, gmail_enviado, proveedor_id) 
WHERE pagado = TRUE AND gmail_enviado = FALSE AND activo = TRUE;

COMMENT ON TABLE pagos IS 'Tabla principal de pagos';
COMMENT ON COLUMN pagos.pagado IS 'TRUE si el pago fue confirmado';
COMMENT ON COLUMN pagos.verificado IS 'TRUE si fue verificado en extracto bancario';
COMMENT ON COLUMN pagos.activo IS 'FALSE para soft delete';

-- ==========================
-- TABLA: pago_cliente
-- ==========================

CREATE TABLE pago_cliente (
  id SERIAL PRIMARY KEY,
  pago_id BIGINT NOT NULL REFERENCES pagos(id) ON UPDATE CASCADE ON DELETE CASCADE,
  cliente_id BIGINT NOT NULL REFERENCES clientes(id) ON UPDATE CASCADE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT uq_pago_cliente UNIQUE(pago_id, cliente_id)
);

CREATE INDEX idx_pago_cliente_pago ON pago_cliente(pago_id);
CREATE INDEX idx_pago_cliente_cliente ON pago_cliente(cliente_id);

COMMENT ON TABLE pago_cliente IS 'Relación N:N entre pagos y clientes';

-- ==========================
-- TABLA: documentos
-- ==========================

CREATE TABLE documentos (
  id BIGSERIAL PRIMARY KEY,
  usuario_id BIGINT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE,
  pago_id BIGINT REFERENCES pagos(id) ON UPDATE CASCADE,
  nombre_archivo VARCHAR(255) NOT NULL,
  url_documento TEXT NOT NULL,
  tipo_documento tipo_documento NOT NULL,
  fecha_subida TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documentos_usuario ON documentos(usuario_id);
CREATE INDEX idx_documentos_pago ON documentos(pago_id);
CREATE INDEX idx_documentos_tipo ON documentos(tipo_documento);
CREATE INDEX idx_documentos_fecha ON documentos(fecha_subida DESC);

COMMENT ON TABLE documentos IS 'Documentos de respaldo';
COMMENT ON COLUMN documentos.pago_id IS 'Vinculación directa para FACTURA';

-- ==========================
-- TABLA: documento_pago
-- ==========================

CREATE TABLE documento_pago (
  id SERIAL PRIMARY KEY,
  documento_id BIGINT NOT NULL REFERENCES documentos(id) ON UPDATE CASCADE ON DELETE CASCADE,
  pago_id BIGINT NOT NULL REFERENCES pagos(id) ON UPDATE CASCADE ON DELETE CASCADE,
  fecha_vinculacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT uq_documento_pago UNIQUE(documento_id, pago_id)
);

CREATE INDEX idx_documento_pago_documento ON documento_pago(documento_id);
CREATE INDEX idx_documento_pago_pago ON documento_pago(pago_id);

COMMENT ON TABLE documento_pago IS 'Relación N:N entre documentos y pagos';

-- ==========================
-- TABLA: envios_correos
-- ==========================

CREATE TABLE envios_correos (
  id BIGSERIAL PRIMARY KEY,
  proveedor_id BIGINT NOT NULL REFERENCES proveedores(id) ON UPDATE CASCADE,
  correo_seleccionado VARCHAR(255) NOT NULL,
  usuario_envio_id BIGINT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE,
  asunto VARCHAR(255) NOT NULL,
  cuerpo TEXT NOT NULL,
  estado estado_correo NOT NULL DEFAULT 'BORRADOR',
  cantidad_pagos INT NOT NULL,
  monto_total DECIMAL(12,2) NOT NULL,
  fecha_generacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_envio TIMESTAMPTZ,
  
  CONSTRAINT chk_cantidad_pagos_positiva CHECK (cantidad_pagos > 0),
  CONSTRAINT chk_monto_total_positivo CHECK (monto_total > 0),
  CONSTRAINT chk_fecha_envio_coherente CHECK (
    (estado = 'ENVIADO' AND fecha_envio IS NOT NULL) OR
    (estado = 'BORRADOR' AND fecha_envio IS NULL)
  )
);

CREATE INDEX idx_envios_proveedor ON envios_correos(proveedor_id);
CREATE INDEX idx_envios_estado ON envios_correos(estado);
CREATE INDEX idx_envios_fecha ON envios_correos(fecha_envio DESC);

COMMENT ON TABLE envios_correos IS 'Correos a proveedores';

-- ==========================
-- TABLA: envio_correo_detalle
-- ==========================

CREATE TABLE envio_correo_detalle (
  id SERIAL PRIMARY KEY,
  envio_id BIGINT NOT NULL REFERENCES envios_correos(id) ON UPDATE CASCADE ON DELETE CASCADE,
  pago_id BIGINT NOT NULL REFERENCES pagos(id) ON UPDATE CASCADE,
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT uq_envio_pago UNIQUE(envio_id, pago_id)
);

CREATE INDEX idx_envio_detalle_envio ON envio_correo_detalle(envio_id);
CREATE INDEX idx_envio_detalle_pago ON envio_correo_detalle(pago_id);

COMMENT ON TABLE envio_correo_detalle IS 'Detalle de pagos en cada correo';

-- ==========================
-- TABLA: eventos (AUDITORÍA)
-- ==========================

CREATE TABLE eventos (
  id BIGSERIAL PRIMARY KEY,
  usuario_id BIGINT REFERENCES usuarios(id) ON UPDATE CASCADE,
  tipo_evento tipo_evento NOT NULL,
  entidad_tipo VARCHAR(50) NOT NULL,
  entidad_id BIGINT,
  descripcion TEXT NOT NULL,
  ip_origen INET,
  user_agent TEXT,
  fecha_evento TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_eventos_usuario ON eventos(usuario_id);
CREATE INDEX idx_eventos_fecha ON eventos(fecha_evento DESC);
CREATE INDEX idx_eventos_entidad ON eventos(entidad_tipo, entidad_id);
CREATE INDEX idx_eventos_tipo ON eventos(tipo_evento);

COMMENT ON TABLE eventos IS 'Auditoría de acciones del sistema';

-- ==========================
-- TRIGGERS
-- ==========================

CREATE OR REPLACE FUNCTION trigger_actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.fecha_actualizacion = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuarios_timestamp
BEFORE UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_timestamp();

CREATE TRIGGER trg_proveedores_timestamp
BEFORE UPDATE ON proveedores
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_timestamp();

CREATE TRIGGER trg_clientes_timestamp
BEFORE UPDATE ON clientes
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_timestamp();

CREATE TRIGGER trg_tarjetas_timestamp
BEFORE UPDATE ON tarjetas_credito
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_timestamp();

CREATE TRIGGER trg_cuentas_timestamp
BEFORE UPDATE ON cuentas_bancarias
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_timestamp();

CREATE TRIGGER trg_pagos_timestamp
BEFORE UPDATE ON pagos
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_timestamp();

CREATE OR REPLACE FUNCTION trigger_actualizar_fecha_pago()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.pagado = TRUE AND OLD.pagado = FALSE THEN
    NEW.fecha_pago = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pagos_fecha_pago
BEFORE UPDATE ON pagos
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_fecha_pago();

CREATE OR REPLACE FUNCTION trigger_actualizar_fecha_verificacion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.verificado = TRUE AND OLD.verificado = FALSE THEN
    NEW.fecha_verificacion = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pagos_fecha_verificacion
BEFORE UPDATE ON pagos
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_fecha_verificacion();

CREATE OR REPLACE FUNCTION trigger_validar_max_4_correos()
RETURNS TRIGGER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM proveedor_correos
  WHERE proveedor_id = NEW.proveedor_id AND activo = TRUE;
  
  IF v_count > 4 THEN
    RAISE EXCEPTION 'Un proveedor solo puede tener máximo 4 correos activos';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_max_4_correos
AFTER INSERT OR UPDATE ON proveedor_correos
FOR EACH ROW EXECUTE FUNCTION trigger_validar_max_4_correos();

-- ==========================
-- FUNCIONES DE NEGOCIO
-- ==========================

CREATE OR REPLACE FUNCTION reset_mensual_tarjetas()
RETURNS TABLE(tarjetas_reseteadas INT) AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE tarjetas_credito
  SET saldo_disponible = limite_mensual,
      fecha_actualizacion = NOW()
  WHERE activo = TRUE;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  INSERT INTO eventos (tipo_evento, entidad_tipo, descripcion)
  VALUES ('RESET_MENSUAL', 'tarjetas_credito', 'Reset mensual: ' || v_count || ' tarjetas');
  
  RETURN QUERY SELECT v_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION procesar_factura(
  p_documento_id BIGINT,
  p_codigo_reserva VARCHAR,
  p_pago_id BIGINT DEFAULT NULL
)
RETURNS TABLE(
  pago_id BIGINT,
  codigo_reserva VARCHAR,
  pagado BOOLEAN
) AS $$
DECLARE
  v_pago_id BIGINT;
BEGIN
  IF p_pago_id IS NOT NULL THEN
    v_pago_id := p_pago_id;
  ELSE
    SELECT id INTO v_pago_id
    FROM pagos
    WHERE codigo_reserva = p_codigo_reserva
    AND pagado = FALSE
    AND activo = TRUE;
    
    IF NOT FOUND THEN
      RAISE EXCEPTION 'No se encontró pago activo con código: %', p_codigo_reserva;
    END IF;
  END IF;
  
  UPDATE pagos
  SET 
    pagado = TRUE,
    fecha_pago = NOW()
  WHERE id = v_pago_id;
  
  INSERT INTO documento_pago (documento_id, pago_id)
  VALUES (p_documento_id, v_pago_id)
  ON CONFLICT DO NOTHING;
  
  RETURN QUERY
  SELECT p.id, p.codigo_reserva, p.pagado
  FROM pagos p
  WHERE p.id = v_pago_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION verificar_pagos_por_documento(
  p_documento_id BIGINT,
  p_codigos_encontrados TEXT[]
)
RETURNS TABLE(
  pago_id BIGINT,
  codigo_reserva VARCHAR,
  pagado BOOLEAN,
  verificado BOOLEAN
) AS $$
DECLARE
  v_codigo TEXT;
BEGIN
  FOREACH v_codigo IN ARRAY p_codigos_encontrados
  LOOP
    UPDATE pagos
    SET 
      pagado = TRUE,
      verificado = TRUE,
      fecha_pago = COALESCE(fecha_pago, NOW()),
      fecha_verificacion = NOW()
    WHERE 
      codigo_reserva = v_codigo
      AND activo = TRUE;
    
    INSERT INTO documento_pago (documento_id, pago_id)
    SELECT p_documento_id, id
    FROM pagos
    WHERE codigo_reserva = v_codigo
    ON CONFLICT DO NOTHING;
  END LOOP;
  
  RETURN QUERY
  SELECT p.id, p.codigo_reserva, p.pagado, p.verificado
  FROM pagos p
  JOIN documento_pago dp ON p.id = dp.pago_id
  WHERE dp.documento_id = p_documento_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generar_correos_pendientes()
RETURNS void AS $$
DECLARE
  v_proveedor RECORD;
BEGIN
  FOR v_proveedor IN
    SELECT proveedor_id, COUNT(*) as cantidad, SUM(monto) as total
    FROM pagos
    WHERE pagado = TRUE AND gmail_enviado = FALSE AND activo = TRUE
    GROUP BY proveedor_id
  LOOP
    INSERT INTO envios_correos (
      proveedor_id, estado, cantidad_pagos, monto_total, asunto, cuerpo, usuario_envio_id
    ) VALUES (
      v_proveedor.proveedor_id,
      'BORRADOR',
      v_proveedor.cantidad,
      v_proveedor.total,
      'Notificación de Pagos',
      'Generado automáticamente',
      1  -- ID del usuario sistema
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ==========================
-- DATOS INICIALES (SEEDS)
-- ==========================

INSERT INTO roles (nombre, descripcion) VALUES
('ADMIN', 'Control total del sistema'),
('SUPERVISOR', 'Casi control total excepto gestión de usuarios'),
('EQUIPO', 'Operaciones básicas con tarjetas, puede enviar correos');

-- Servicios reales de Terra Canada (en francés)
INSERT INTO servicios (nombre, descripcion) VALUES
('Assurance', 'Seguros'),
('Comptable', 'Servicios contables'),
('Cadeaux et invitations', 'Regalos e invitaciones'),
('Bureau / équipement / internet, téléphonie', 'Oficina, equipamiento, internet y telefonía'),
('Voyage de reco', 'Viajes de reconocimiento'),
('Frais coworking/cafés', 'Gastos de coworking y cafés'),
('Hotels', 'Hoteles'),
('Opérations clients (Services/activités/guides/entrées/transports)', 'Operaciones clientes: servicios, actividades, guías, entradas, transportes'),
('Promotion de l''agence', 'Promoción de la agencia'),
('Salaires', 'Salarios');

-- ============================================================================
-- FIN DEL DDL
-- ============================================================================

-- ============================================================================
-- FUNCIONES CRUD - TABLA: roles
-- ============================================================================

-- ========================================
-- GET: Obtener todos los roles o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION roles_get(p_id INT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los roles
        -- 1. Primero, se crea una subconsulta para agregar los datos de los roles.
        --    Esto resuelve el error del GROUP BY.
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Roles obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(
                    json_build_object(
                        'id', r.id,
                        'nombre', r.nombre,
                        'descripcion', r.descripcion,
                        'fecha_creacion', r.fecha_creacion
                    )
                    -- Puedes ordenar aquí dentro del json_agg para un resultado predecible
                    ORDER BY r.id 
                ) FROM roles r),
                '[]'::json
            )
        ) INTO v_result;

    ELSE
        -- Obtener un rol específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Rol obtenido exitosamente',
            'data', json_build_object(
                'id', id,
                'nombre', nombre,
                'descripcion', descripcion,
                'fecha_creacion', fecha_creacion
            )
        ) INTO v_result
        FROM roles
        WHERE id = p_id;
        
        -- Es más idiomático y seguro usar IF NOT FOUND
        IF NOT FOUND THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Rol no encontrado',
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
            'message', 'Error al obtener roles: ' || SQLERRM,
            'data', null
        );
END;
 $$ LANGUAGE plpgsql;

SELECT roles_get();
-- ========================================
-- POST: Crear un nuevo rol
-- ========================================
CREATE OR REPLACE FUNCTION roles_post(
    p_nombre VARCHAR,
    p_descripcion TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_id INT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre es obligatorio',
            'data', null
        );
    END IF;
    
    -- Verificar si ya existe
    IF EXISTS (SELECT 1 FROM roles WHERE nombre = p_nombre) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un rol con ese nombre',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo rol
    INSERT INTO roles (nombre, descripcion)
    VALUES (p_nombre, p_descripcion)
    RETURNING id INTO v_id;
    
    -- Obtener el rol creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Rol creado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'descripcion', descripcion,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM roles
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear rol: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un rol existente
-- ========================================
CREATE OR REPLACE FUNCTION roles_put(
    p_id INT,
    p_nombre VARCHAR DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el rol
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Rol no encontrado',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE roles
    SET 
        nombre = COALESCE(p_nombre, nombre),
        descripcion = COALESCE(p_descripcion, descripcion)
    WHERE id = p_id;
    
    -- Obtener el rol actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Rol actualizado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'descripcion', descripcion,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM roles
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar rol: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un rol
-- ========================================
CREATE OR REPLACE FUNCTION roles_delete(p_id INT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el rol
    SELECT nombre INTO v_nombre FROM roles WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Rol no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si hay usuarios con este rol
    IF EXISTS (SELECT 1 FROM usuarios WHERE rol_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el rol porque tiene usuarios asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar el rol
    DELETE FROM roles WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Rol eliminado exitosamente',
        'data', json_build_object('nombre', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar rol: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los roles
SELECT roles_get();

-- GET: Obtener un rol específico
SELECT roles_get(1);

-- POST: Crear un nuevo rol
SELECT roles_post('CONTADOR', 'Rol para personal de contabilidad');

-- PUT: Actualizar un rol
SELECT roles_put(4, 'CONTADOR_SENIOR', 'Rol para contador senior');

-- DELETE: Eliminar un rol
SELECT roles_delete(4);
*/



-- ============================================================================
-- FUNCIONES CRUD - TABLA: servicios
-- ============================================================================

-- ========================================
-- GET: Obtener todos los servicios o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION servicios_get(p_id INT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los servicios
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Servicios obtenidos exitosamente',
            'data', COALESCE(
                -- 1. La subconsulta se encarga únicamente de crear el array JSON.
                --    Esto resuelve el conflicto del GROUP BY.
                (SELECT json_agg(
                    json_build_object(
                        'id', s.id,
                        'nombre', s.nombre,
                        'descripcion', s.descripcion,
                        'activo', s.activo,
                        'fecha_creacion', s.fecha_creacion
                    )
                    -- 2. El ORDER BY se mueve aquí dentro del json_agg para ordenar los elementos del array.
                    ORDER BY s.nombre 
                ) FROM servicios s),
                '[]'::json
            )
        ) INTO v_result;

    ELSE
        -- Obtener un servicio específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Servicio obtenido exitosamente',
            'data', json_build_object(
                'id', id,
                'nombre', nombre,
                'descripcion', descripcion,
                'activo', activo,
                'fecha_creacion', fecha_creacion
            )
        ) INTO v_result
        FROM servicios
        WHERE id = p_id;
        
        -- 3. Usamos la comprobación más robusta y recomendada: IF NOT FOUND.
        IF NOT FOUND THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Servicio no encontrado',
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
            'message', 'Error al obtener servicios: ' || SQLERRM,
            'data', null
        );
END;
 $$ LANGUAGE plpgsql;

SELECT servicios_get();
-- ========================================
-- POST: Crear un nuevo servicio
-- ========================================
CREATE OR REPLACE FUNCTION servicios_post(
    p_nombre VARCHAR,
    p_descripcion TEXT DEFAULT NULL,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id INT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre es obligatorio',
            'data', null
        );
    END IF;
    
    -- Verificar si ya existe
    IF EXISTS (SELECT 1 FROM servicios WHERE nombre = p_nombre) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un servicio con ese nombre',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo servicio
    INSERT INTO servicios (nombre, descripcion, activo)
    VALUES (p_nombre, p_descripcion, p_activo)
    RETURNING id INTO v_id;
    
    -- Obtener el servicio creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Servicio creado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'descripcion', descripcion,
            'activo', activo,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM servicios
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear servicio: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un servicio existente
-- ========================================
CREATE OR REPLACE FUNCTION servicios_put(
    p_id INT,
    p_nombre VARCHAR DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el servicio
    IF NOT EXISTS (SELECT 1 FROM servicios WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Servicio no encontrado',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE servicios
    SET 
        nombre = COALESCE(p_nombre, nombre),
        descripcion = COALESCE(p_descripcion, descripcion),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el servicio actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Servicio actualizado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'descripcion', descripcion,
            'activo', activo,
            'fecha_creacion', fecha_creacion
        )
    ) INTO v_result
    FROM servicios
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar servicio: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un servicio
-- ========================================
CREATE OR REPLACE FUNCTION servicios_delete(p_id INT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el servicio
    SELECT nombre INTO v_nombre FROM servicios WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Servicio no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si hay proveedores con este servicio
    IF EXISTS (SELECT 1 FROM proveedores WHERE servicio_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el servicio porque tiene proveedores asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar el servicio
    DELETE FROM servicios WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Servicio eliminado exitosamente',
        'data', json_build_object('nombre', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar servicio: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los servicios
SELECT servicios_get();

-- GET: Obtener un servicio específico
SELECT servicios_get(1);

-- POST: Crear un nuevo servicio
SELECT servicios_post('Transporte', 'Servicios de transporte turístico', true);

-- PUT: Actualizar un servicio
SELECT servicios_put(1, 'Transporte Premium', 'Servicios de transporte turístico premium', true);

-- DELETE: Eliminar un servicio
SELECT servicios_delete(1);
*/





-- ============================================================================
-- FUNCIONES CRUD - TABLA: usuarios
-- ============================================================================

-- ========================================
-- GET: Obtener todos los usuarios o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION usuarios_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los usuarios
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuarios obtenidos exitosamente',
            'data', COALESCE(
                -- 1. La subconsulta se encarga únicamente de crear el array JSON de usuarios.
                --    Esto resuelve el conflicto del GROUP BY, incluso con el JOIN.
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
                        'fecha_creacion', u.fecha_creacion,
                        'fecha_actualizacion', u.fecha_actualizacion
                    )
                    -- 2. El ORDER BY se mueve aquí dentro del json_agg para ordenar los elementos del array.
                    ORDER BY u.id 
                ) FROM usuarios u
                JOIN roles r ON u.rol_id = r.id),
                '[]'::json
            )
        ) INTO v_result;

    ELSE
        -- Obtener un usuario específico
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
                'fecha_creacion', u.fecha_creacion,
                'fecha_actualizacion', u.fecha_actualizacion
            )
        ) INTO v_result
        FROM usuarios u
        JOIN roles r ON u.rol_id = r.id
        WHERE u.id = p_id;
        
        -- 3. Usamos la comprobación más robusta y recomendada: IF NOT FOUND.
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
-- ========================================
-- POST: Crear un nuevo usuario
-- ========================================
CREATE OR REPLACE FUNCTION usuarios_post(
    p_nombre_usuario VARCHAR,
    p_correo VARCHAR,
    p_contrasena VARCHAR,
    p_nombre_completo VARCHAR,
    p_rol_id INT,
    p_telefono VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
    v_hash VARCHAR;
BEGIN
    -- Validaciones
    IF p_nombre_usuario IS NULL OR TRIM(p_nombre_usuario) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre de usuario es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_correo IS NULL OR TRIM(p_correo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El correo es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_contrasena IS NULL OR LENGTH(p_contrasena) < 6 THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'La contraseña debe tener al menos 6 caracteres',
            'data', null
        );
    END IF;
    
    IF p_nombre_completo IS NULL OR TRIM(p_nombre_completo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre completo es obligatorio',
            'data', null
        );
    END IF;
    
    -- Verificar si el rol existe
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id = p_rol_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El rol especificado no existe',
            'data', null
        );
    END IF;
    
    -- Verificar si ya existe el nombre de usuario
    IF EXISTS (SELECT 1 FROM usuarios WHERE nombre_usuario = p_nombre_usuario) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un usuario con ese nombre de usuario',
            'data', null
        );
    END IF;
    
    -- Verificar si ya existe el correo
    IF EXISTS (SELECT 1 FROM usuarios WHERE correo = p_correo) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'Ya existe un usuario con ese correo',
            'data', null
        );
    END IF;
    
    -- Hashear la contraseña
    v_hash := crypt(p_contrasena, gen_salt('bf'));
    
    -- Insertar nuevo usuario
    INSERT INTO usuarios (
        nombre_usuario, correo, contrasena_hash, nombre_completo, 
        rol_id, telefono, activo
    )
    VALUES (
        p_nombre_usuario, p_correo, v_hash, p_nombre_completo,
        p_rol_id, p_telefono, p_activo
    )
    RETURNING id INTO v_id;
    
    -- Obtener el usuario creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Usuario creado exitosamente',
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
    WHERE u.id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear usuario: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un usuario existente
-- ========================================
CREATE OR REPLACE FUNCTION usuarios_put(
    p_id BIGINT,
    p_nombre_usuario VARCHAR DEFAULT NULL,
    p_correo VARCHAR DEFAULT NULL,
    p_contrasena VARCHAR DEFAULT NULL,
    p_nombre_completo VARCHAR DEFAULT NULL,
    p_rol_id INT DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_hash VARCHAR;
BEGIN
    -- Verificar si existe el usuario
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Usuario no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si el rol existe (si se proporciona)
    IF p_rol_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM roles WHERE id = p_rol_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El rol especificado no existe',
            'data', null
        );
    END IF;
    
    -- Hashear la contraseña si se proporciona
    IF p_contrasena IS NOT NULL THEN
        IF LENGTH(p_contrasena) < 6 THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'La contraseña debe tener al menos 6 caracteres',
                'data', null
            );
        END IF;
        v_hash := crypt(p_contrasena, gen_salt('bf'));
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE usuarios
    SET 
        nombre_usuario = COALESCE(p_nombre_usuario, nombre_usuario),
        correo = COALESCE(p_correo, correo),
        contrasena_hash = COALESCE(v_hash, contrasena_hash),
        nombre_completo = COALESCE(p_nombre_completo, nombre_completo),
        rol_id = COALESCE(p_rol_id, rol_id),
        telefono = COALESCE(p_telefono, telefono),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el usuario actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Usuario actualizado exitosamente',
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
            'fecha_creacion', u.fecha_creacion,
            'fecha_actualizacion', u.fecha_actualizacion
        )
    ) INTO v_result
    FROM usuarios u
    JOIN roles r ON u.rol_id = r.id
    WHERE u.id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar usuario: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar (desactivar) un usuario
-- ========================================
CREATE OR REPLACE FUNCTION usuarios_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el usuario
    SELECT nombre_completo INTO v_nombre FROM usuarios WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Usuario no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pagos WHERE usuario_id = p_id) THEN
        -- Desactivar en lugar de eliminar
        UPDATE usuarios SET activo = FALSE WHERE id = p_id;
        
        RETURN json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuario desactivado exitosamente (tiene pagos asociados)',
            'data', json_build_object('nombre', v_nombre, 'desactivado', true)
        );
    ELSE
        -- Eliminar el usuario
        DELETE FROM usuarios WHERE id = p_id;
        
        RETURN json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Usuario eliminado exitosamente',
            'data', json_build_object('nombre', v_nombre, 'eliminado', true)
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar usuario: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los usuarios
SELECT usuarios_get();

-- GET: Obtener un usuario específico
SELECT usuarios_get(1);

-- POST: Crear un nuevo usuario
SELECT usuarios_post(
    'jperez', 
    'jperez@terracanada.com', 
    'password123', 
    'Juan Pérez', 
    1, 
    '+1234567890', 
    true
);

-- PUT: Actualizar un usuario
SELECT usuarios_put(
    1, 
    NULL, 
    'juan.perez@terracanada.com', 
    NULL, 
    'Juan Carlos Pérez', 
    NULL, 
    NULL, 
    NULL
);

-- DELETE: Eliminar/Desactivar un usuario
SELECT usuarios_delete(1);
*/


-- ============================================================================
-- FUNCIONES CRUD - TABLA: proveedores
-- ============================================================================

-- ========================================
-- GET: Obtener todos los proveedores o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION proveedores_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los proveedores
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Proveedores obtenidos exitosamente',
            'data', COALESCE(
                -- 1. La subconsulta se encarga de toda la lógica de agregación.
                --    Esto incluye el JOIN y la subconsulta correlacionada para los correos.
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
                        'correos', (
                            -- Esta subconsulta correlacionada funciona sin cambios
                            -- dentro de la estructura de la subconsulta principal.
                            SELECT COALESCE(json_agg(
                                json_build_object(
                                    'id', pc.id,
                                    'correo', pc.correo,
                                    'principal', pc.principal,
                                    'activo', pc.activo
                                )
                            ), '[]'::json)
                            FROM proveedor_correos pc
                            WHERE pc.proveedor_id = p.id AND pc.activo = TRUE
                        ),
                        'fecha_creacion', p.fecha_creacion,
                        'fecha_actualizacion', p.fecha_actualizacion
                    )
                    -- 2. El ORDER BY se mueve aquí para ordenar los proveedores
                    --    dentro del array JSON.
                    ORDER BY p.nombre 
                ) FROM proveedores p
                JOIN servicios s ON p.servicio_id = s.id),
                '[]'::json
            )
        ) INTO v_result;

    ELSE
        -- Obtener un proveedor específico
        -- Esta parte no tiene agregación, por lo que no necesita cambios estructurales.
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
                'correos', (
                    SELECT COALESCE(json_agg(
                        json_build_object(
                            'id', pc.id,
                            'correo', pc.correo,
                            'principal', pc.principal,
                            'activo', pc.activo
                        )
                    ), '[]'::json)
                    FROM proveedor_correos pc
                    WHERE pc.proveedor_id = p.id AND pc.activo = TRUE
                ),
                'fecha_creacion', p.fecha_creacion,
                'fecha_actualizacion', p.fecha_actualizacion
            )
        ) INTO v_result
        FROM proveedores p
        JOIN servicios s ON p.servicio_id = s.id
        WHERE p.id = p_id;
        
        -- 3. Mejoramos la comprobación de existencia con IF NOT FOUND.
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

-- ========================================
-- POST: Crear un nuevo proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedores_post(
    p_nombre VARCHAR,
    p_servicio_id INT,
    p_lenguaje VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre es obligatorio',
            'data', null
        );
    END IF;
    
    -- Verificar si el servicio existe
    IF NOT EXISTS (SELECT 1 FROM servicios WHERE id = p_servicio_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El servicio especificado no existe',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo proveedor
    INSERT INTO proveedores (
        nombre, servicio_id, lenguaje, telefono, descripcion, activo
    )
    VALUES (
        p_nombre, p_servicio_id, p_lenguaje, p_telefono, p_descripcion, p_activo
    )
    RETURNING id INTO v_id;
    
    -- Obtener el proveedor creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Proveedor creado exitosamente',
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
            'fecha_creacion', p.fecha_creacion
        )
    ) INTO v_result
    FROM proveedores p
    JOIN servicios s ON p.servicio_id = s.id
    WHERE p.id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear proveedor: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un proveedor existente
-- ========================================
CREATE OR REPLACE FUNCTION proveedores_put(
    p_id BIGINT,
    p_nombre VARCHAR DEFAULT NULL,
    p_servicio_id INT DEFAULT NULL,
    p_lenguaje VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el proveedor
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Proveedor no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si el servicio existe (si se proporciona)
    IF p_servicio_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM servicios WHERE id = p_servicio_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El servicio especificado no existe',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE proveedores
    SET 
        nombre = COALESCE(p_nombre, nombre),
        servicio_id = COALESCE(p_servicio_id, servicio_id),
        lenguaje = COALESCE(p_lenguaje, lenguaje),
        telefono = COALESCE(p_telefono, telefono),
        descripcion = COALESCE(p_descripcion, descripcion),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el proveedor actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Proveedor actualizado exitosamente',
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
            'fecha_creacion', p.fecha_creacion,
            'fecha_actualizacion', p.fecha_actualizacion
        )
    ) INTO v_result
    FROM proveedores p
    JOIN servicios s ON p.servicio_id = s.id
    WHERE p.id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar proveedor: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedores_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el proveedor
    SELECT nombre INTO v_nombre FROM proveedores WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Proveedor no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pagos WHERE proveedor_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el proveedor porque tiene pagos asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar el proveedor (también eliminará sus correos por CASCADE)
    DELETE FROM proveedores WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Proveedor eliminado exitosamente',
        'data', json_build_object('nombre', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar proveedor: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los proveedores
SELECT proveedores_get();

-- GET: Obtener un proveedor específico
SELECT proveedores_get(1);

-- POST: Crear un nuevo proveedor
SELECT proveedores_post(
    'Tour Guide Sessss', 
    2, 
    'English', 
    '+1234567890', 
    'Proveedor de servicios de guías turísticos',
    true
);

-- PUT: Actualizar un proveedor
SELECT proveedores_put(
    1, 
    'Premium Tour Guide Services', 
    NULL, 
    'English/French', 
    NULL, 
    'Proveedor premium de servicios de guías',
    NULL
);

-- DELETE: Eliminar un proveedor
SELECT proveedores_delete(1);
*/



-- ============================================================================
-- FUNCIONES CRUD - TABLA: proveedor_correos
-- ============================================================================

-- ========================================
-- GET: Obtener todos los correos de proveedores o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION proveedor_correos_get(p_id INT DEFAULT NULL, p_proveedor_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NOT NULL THEN
        -- Obtener un correo específico (sin cambios estructurales, solo mejoramos la comprobación)
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
        
        -- Usamos la comprobación recomendada
        IF NOT FOUND THEN
            v_result := json_build_object(
                'code', 404,
                'estado', false,
                'message', 'Correo no encontrado',
                'data', null
            );
        END IF;

    ELSIF p_proveedor_id IS NOT NULL THEN
        -- Obtener todos los correos de un proveedor específico
        -- APLICAMOS LA SOLUCIÓN: Subconsulta para json_agg
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
                    -- El ORDER BY va aquí dentro
                    ORDER BY pc.principal DESC, pc.id
                ) FROM proveedor_correos pc
                WHERE pc.proveedor_id = p_proveedor_id),
                '[]'::json
            )
        ) INTO v_result;

    ELSE
        -- Obtener todos los correos de proveedores
        -- APLICAMOS LA SOLUCIÓN: Subconsulta para json_agg con JOIN
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
                    -- El ORDER BY va aquí dentro
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

-- ========================================
-- POST: Crear un nuevo correo de proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedor_correos_post(
    p_proveedor_id BIGINT,
    p_correo VARCHAR,
    p_principal BOOLEAN DEFAULT FALSE,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id INT;
    v_result JSON;
    v_count INT;
BEGIN
    -- Validaciones
    IF p_correo IS NULL OR TRIM(p_correo) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El correo es obligatorio',
            'data', null
        );
    END IF;
    
    -- Verificar si el proveedor existe
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id = p_proveedor_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El proveedor especificado no existe',
            'data', null
        );
    END IF;
    
    -- Verificar límite de 4 correos activos
    SELECT COUNT(*) INTO v_count
    FROM proveedor_correos
    WHERE proveedor_id = p_proveedor_id AND activo = TRUE;
    
    IF v_count >= 4 AND p_activo = TRUE THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'El proveedor ya tiene el máximo de 4 correos activos',
            'data', null
        );
    END IF;
    
    -- Si es principal, quitar el flag de los demás correos
    IF p_principal = TRUE THEN
        UPDATE proveedor_correos
        SET principal = FALSE
        WHERE proveedor_id = p_proveedor_id;
    END IF;
    
    -- Insertar nuevo correo
    INSERT INTO proveedor_correos (proveedor_id, correo, principal, activo)
    VALUES (p_proveedor_id, p_correo, p_principal, p_activo)
    RETURNING id INTO v_id;
    
    -- Obtener el correo creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Correo creado exitosamente',
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
    WHERE pc.id = v_id;
    
    RETURN v_result;
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
-- PUT: Actualizar un correo de proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedor_correos_put(
    p_id INT,
    p_correo VARCHAR DEFAULT NULL,
    p_principal BOOLEAN DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_proveedor_id BIGINT;
BEGIN
    -- Verificar si existe el correo
    SELECT proveedor_id INTO v_proveedor_id FROM proveedor_correos WHERE id = p_id;
    
    IF v_proveedor_id IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Correo no encontrado',
            'data', null
        );
    END IF;
    
    -- Si se marca como principal, quitar el flag de los demás
    IF p_principal = TRUE THEN
        UPDATE proveedor_correos
        SET principal = FALSE
        WHERE proveedor_id = v_proveedor_id AND id != p_id;
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE proveedor_correos
    SET 
        correo = COALESCE(p_correo, correo),
        principal = COALESCE(p_principal, principal),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el correo actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Correo actualizado exitosamente',
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
    
    RETURN v_result;
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
-- DELETE: Eliminar un correo de proveedor
-- ========================================
CREATE OR REPLACE FUNCTION proveedor_correos_delete(p_id INT)
RETURNS JSON AS $$
DECLARE
    v_correo VARCHAR;
    v_proveedor_id BIGINT;
    v_count INT;
BEGIN
    -- Verificar si existe el correo
    SELECT correo, proveedor_id INTO v_correo, v_proveedor_id 
    FROM proveedor_correos 
    WHERE id = p_id;
    
    IF v_correo IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Correo no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar que no sea el último correo del proveedor
    SELECT COUNT(*) INTO v_count
    FROM proveedor_correos
    WHERE proveedor_id = v_proveedor_id AND activo = TRUE;
    
    IF v_count <= 1 THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el último correo activo del proveedor',
            'data', null
        );
    END IF;
    
    -- Eliminar el correo
    DELETE FROM proveedor_correos WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Correo eliminado exitosamente',
        'data', json_build_object('correo', v_correo)
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
SELECT proveedor_correos_get();

-- GET: Obtener correos de un proveedor específico
SELECT proveedor_correos_get(NULL, 1);

-- GET: Obtener un correo específico
SELECT proveedor_correos_get(1);

-- POST: Crear un nuevo correo de proveedor
SELECT proveedor_correos_post(
    1, 
    'contacto@proveedor.com', 
    true, 
    true
);

-- PUT: Actualizar un correo
SELECT proveedor_correos_put(
    1, 
    'nuevo@proveedor.com', 
    NULL, 
    NULL
);

-- DELETE: Eliminar un correo
SELECT proveedor_correos_delete(2);
*/


-- ============================================================================
-- FUNCIONES CRUD - TABLA: clientes
-- ============================================================================

-- ========================================
-- GET: Obtener todos los clientes o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION clientes_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los clientes
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Clientes obtenidos exitosamente',
            'data', COALESCE(
                -- 1. La subconsulta se encarga únicamente de crear el array JSON.
                --    Esto resuelve el conflicto del GROUP BY.
                (SELECT json_agg(
                    json_build_object(
                        'id', c.id,
                        'nombre', c.nombre,
                        'ubicacion', c.ubicacion,
                        'telefono', c.telefono,
                        'correo', c.correo,
                        'activo', c.activo,
                        'fecha_creacion', c.fecha_creacion,
                        'fecha_actualizacion', c.fecha_actualizacion
                    )
                    -- 2. El ORDER BY se mueve aquí dentro del json_agg para ordenar los elementos del array.
                    ORDER BY c.nombre 
                ) FROM clientes c),
                '[]'::json
            )
        ) INTO v_result;

    ELSE
        -- Obtener un cliente específico
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Cliente obtenido exitosamente',
            'data', json_build_object(
                'id', c.id,
                'nombre', c.nombre,
                'ubicacion', c.ubicacion,
                'telefono', c.telefono,
                'correo', c.correo,
                'activo', c.activo,
                'fecha_creacion', c.fecha_creacion,
                'fecha_actualizacion', c.fecha_actualizacion
            )
        ) INTO v_result
        FROM clientes c
        WHERE c.id = p_id;
        
        -- 3. Usamos la comprobación más robusta y recomendada: IF NOT FOUND.
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
-- ========================================
-- POST: Crear un nuevo cliente
-- ========================================
CREATE OR REPLACE FUNCTION clientes_post(
    p_nombre VARCHAR,
    p_ubicacion VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_correo VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre es obligatorio',
            'data', null
        );
    END IF;
    
    -- Insertar nuevo cliente
    INSERT INTO clientes (nombre, ubicacion, telefono, correo, activo)
    VALUES (p_nombre, p_ubicacion, p_telefono, p_correo, p_activo)
    RETURNING id INTO v_id;
    
    -- Obtener el cliente creado
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Cliente creado exitosamente',
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
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear cliente: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar un cliente existente
-- ========================================
CREATE OR REPLACE FUNCTION clientes_put(
    p_id BIGINT,
    p_nombre VARCHAR DEFAULT NULL,
    p_ubicacion VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_correo VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe el cliente
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Cliente no encontrado',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE clientes
    SET 
        nombre = COALESCE(p_nombre, nombre),
        ubicacion = COALESCE(p_ubicacion, ubicacion),
        telefono = COALESCE(p_telefono, telefono),
        correo = COALESCE(p_correo, correo),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener el cliente actualizado
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Cliente actualizado exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre', nombre,
            'ubicacion', ubicacion,
            'telefono', telefono,
            'correo', correo,
            'activo', activo,
            'fecha_creacion', fecha_creacion,
            'fecha_actualizacion', fecha_actualizacion
        )
    ) INTO v_result
    FROM clientes
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar cliente: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar un cliente
-- ========================================
CREATE OR REPLACE FUNCTION clientes_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    -- Verificar si existe el cliente
    SELECT nombre INTO v_nombre FROM clientes WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Cliente no encontrado',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pago_cliente WHERE cliente_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar el cliente porque tiene pagos asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar el cliente
    DELETE FROM clientes WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Cliente eliminado exitosamente',
        'data', json_build_object('nombre', v_nombre)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar cliente: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todos los clientes
SELECT clientes_get();

-- GET: Obtener un cliente específico
SELECT clientes_get(1);

-- POST: Crear un nuevo cliente
SELECT clientes_post(
    'Hotel Paradise', 
    'Cancún, México', 
    '+521234567890', 
    'info@hotelparadise.com',
    true
);

-- PUT: Actualizar un cliente
SELECT clientes_put(
    1, 
    'Hotel Paradise Resort', 
    NULL, 
    '+521234567899', 
    NULL,
    NULL
);

-- DELETE: Eliminar un cliente
SELECT clientes_delete(1);
*/

-- ============================================================================
-- FUNCIONES CRUD - TABLA: tarjetas_credito
-- ============================================================================

-- ========================================
-- GET: Obtener todas las tarjetas o una específica
-- ========================================
CREATE OR REPLACE FUNCTION tarjetas_credito_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todas las tarjetas
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Tarjetas obtenidas exitosamente',
            'data', COALESCE(
                -- 1. La subconsulta se encarga únicamente de crear el array JSON.
                --    Esto resuelve el conflicto del GROUP BY.
                (SELECT json_agg(
                    json_build_object(
                        'id', tc.id,
                        'nombre_titular', tc.nombre_titular,
                        'ultimos_4_digitos', tc.ultimos_4_digitos,
                        'moneda', tc.moneda,
                        'limite_mensual', tc.limite_mensual,
                        'saldo_disponible', tc.saldo_disponible,
                        'tipo_tarjeta', tc.tipo_tarjeta,
                        'activo', tc.activo,
                        -- 2. El campo calculado funciona sin problemas aquí.
                        'porcentaje_uso', ROUND((tc.limite_mensual - tc.saldo_disponible) * 100.0 / tc.limite_mensual, 2),
                        'fecha_creacion', tc.fecha_creacion,
                        'fecha_actualizacion', tc.fecha_actualizacion
                    )
                    -- 3. El ORDER BY se mueve aquí dentro del json_agg.
                    ORDER BY tc.activo DESC, tc.nombre_titular
                ) FROM tarjetas_credito tc),
                '[]'::json
            )
        ) INTO v_result;

    ELSE
        -- Obtener una tarjeta específica
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Tarjeta obtenida exitosamente',
            'data', json_build_object(
                'id', tc.id,
                'nombre_titular', tc.nombre_titular,
                'ultimos_4_digitos', tc.ultimos_4_digitos,
                'moneda', tc.moneda,
                'limite_mensual', tc.limite_mensual,
                'saldo_disponible', tc.saldo_disponible,
                'tipo_tarjeta', tc.tipo_tarjeta,
                'activo', tc.activo,
                'porcentaje_uso', ROUND((tc.limite_mensual - tc.saldo_disponible) * 100.0 / tc.limite_mensual, 2),
                'fecha_creacion', tc.fecha_creacion,
                'fecha_actualizacion', tc.fecha_actualizacion
            )
        ) INTO v_result
        FROM tarjetas_credito tc
        WHERE tc.id = p_id;
        
        -- 4. Usamos la comprobación más robusta y recomendada: IF NOT FOUND.
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
-- ========================================
-- POST: Crear una nueva tarjeta
-- ========================================
CREATE OR REPLACE FUNCTION tarjetas_credito_post(
    p_nombre_titular VARCHAR,
    p_ultimos_4_digitos VARCHAR,
    p_moneda tipo_moneda,
    p_limite_mensual DECIMAL,
    p_tipo_tarjeta VARCHAR DEFAULT 'Visa',
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre_titular IS NULL OR TRIM(p_nombre_titular) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre del titular es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_ultimos_4_digitos IS NULL OR p_ultimos_4_digitos !~ '^\d{4}$' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'Los últimos 4 dígitos deben ser exactamente 4 números',
            'data', null
        );
    END IF;
    
    IF p_limite_mensual IS NULL OR p_limite_mensual <= 0 THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El límite mensual debe ser mayor a 0',
            'data', null
        );
    END IF;
    
    -- Insertar nueva tarjeta (saldo inicial = límite)
    INSERT INTO tarjetas_credito (
        nombre_titular, ultimos_4_digitos, moneda, limite_mensual, 
        saldo_disponible, tipo_tarjeta, activo
    )
    VALUES (
        p_nombre_titular, p_ultimos_4_digitos, p_moneda, p_limite_mensual,
        p_limite_mensual, p_tipo_tarjeta, p_activo
    )
    RETURNING id INTO v_id;
    
    -- Obtener la tarjeta creada
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Tarjeta creada exitosamente',
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
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear tarjeta: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar una tarjeta existente
-- ========================================
CREATE OR REPLACE FUNCTION tarjetas_credito_put(
    p_id BIGINT,
    p_nombre_titular VARCHAR DEFAULT NULL,
    p_limite_mensual DECIMAL DEFAULT NULL,
    p_tipo_tarjeta VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_limite_actual DECIMAL;
    v_saldo_actual DECIMAL;
BEGIN
    -- Verificar si existe la tarjeta
    SELECT limite_mensual, saldo_disponible 
    INTO v_limite_actual, v_saldo_actual
    FROM tarjetas_credito 
    WHERE id = p_id;
    
    IF v_limite_actual IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Tarjeta no encontrada',
            'data', null
        );
    END IF;
    
    -- Si se cambia el límite mensual, ajustar el saldo proporcionalmente
    IF p_limite_mensual IS NOT NULL AND p_limite_mensual != v_limite_actual THEN
        IF p_limite_mensual <= 0 THEN
            RETURN json_build_object(
                'code', 400,
                'estado', false,
                'message', 'El límite mensual debe ser mayor a 0',
                'data', null
            );
        END IF;
        
        -- Ajustar saldo manteniendo la proporción de uso
        UPDATE tarjetas_credito
        SET 
            limite_mensual = p_limite_mensual,
            saldo_disponible = p_limite_mensual - (v_limite_actual - v_saldo_actual),
            nombre_titular = COALESCE(p_nombre_titular, nombre_titular),
            tipo_tarjeta = COALESCE(p_tipo_tarjeta, tipo_tarjeta),
            activo = COALESCE(p_activo, activo)
        WHERE id = p_id;
    ELSE
        -- Actualizar campos no nulos sin tocar el saldo
        UPDATE tarjetas_credito
        SET 
            nombre_titular = COALESCE(p_nombre_titular, nombre_titular),
            tipo_tarjeta = COALESCE(p_tipo_tarjeta, tipo_tarjeta),
            activo = COALESCE(p_activo, activo)
        WHERE id = p_id;
    END IF;
    
    -- Obtener la tarjeta actualizada
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Tarjeta actualizada exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre_titular', nombre_titular,
            'ultimos_4_digitos', ultimos_4_digitos,
            'moneda', moneda,
            'limite_mensual', limite_mensual,
            'saldo_disponible', saldo_disponible,
            'tipo_tarjeta', tipo_tarjeta,
            'activo', activo,
            'porcentaje_uso', ROUND((limite_mensual - saldo_disponible) * 100.0 / limite_mensual, 2),
            'fecha_creacion', fecha_creacion,
            'fecha_actualizacion', fecha_actualizacion
        )
    ) INTO v_result
    FROM tarjetas_credito
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar tarjeta: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar una tarjeta
-- ========================================
CREATE OR REPLACE FUNCTION tarjetas_credito_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
    v_digitos VARCHAR;
BEGIN
    -- Verificar si existe la tarjeta
    SELECT nombre_titular, ultimos_4_digitos 
    INTO v_nombre, v_digitos
    FROM tarjetas_credito 
    WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Tarjeta no encontrada',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pagos WHERE tarjeta_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar la tarjeta porque tiene pagos asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar la tarjeta
    DELETE FROM tarjetas_credito WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Tarjeta eliminada exitosamente',
        'data', json_build_object(
            'nombre_titular', v_nombre,
            'ultimos_4_digitos', v_digitos
        )
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar tarjeta: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todas las tarjetas
SELECT tarjetas_credito_get();

-- GET: Obtener una tarjeta específica
SELECT tarjetas_credito_get(1);

-- POST: Crear una nueva tarjeta
SELECT tarjetas_credito_post(
    'Juan Pérez', 
    '1234', 
    'USD', 
    5000.00, 
    'Visa',
    true
);

-- PUT: Actualizar una tarjeta
SELECT tarjetas_credito_put(
    1, 
    'Juan Carlos Pérez', 
    6000.00, 
    'Visa Platinum',
    NULL
);

-- DELETE: Eliminar una tarjeta
SELECT tarjetas_credito_delete(1);
*/

-- ============================================================================
-- FUNCIONES CRUD - TABLA: cuentas_bancarias
-- ============================================================================

-- ========================================
-- GET: Obtener todas las cuentas o una específica
-- ========================================
CREATE OR REPLACE FUNCTION cuentas_bancarias_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todas las cuentas
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Cuentas bancarias obtenidas exitosamente',
            'data', COALESCE(
                -- 1. La subconsulta se encarga únicamente de crear el array JSON.
                --    Esto resuelve el conflicto del GROUP BY.
                (SELECT json_agg(
                    json_build_object(
                        'id', cb.id,
                        'nombre_banco', cb.nombre_banco,
                        'nombre_cuenta', cb.nombre_cuenta,
                        'ultimos_4_digitos', cb.ultimos_4_digitos,
                        'moneda', cb.moneda,
                        'activo', cb.activo,
                        'fecha_creacion', cb.fecha_creacion,
                        'fecha_actualizacion', cb.fecha_actualizacion
                    )
                    -- 2. El ORDER BY se mueve aquí dentro del json_agg para ordenar los elementos del array.
                    ORDER BY cb.activo DESC, cb.nombre_banco
                ) FROM cuentas_bancarias cb),
                '[]'::json
            )
        ) INTO v_result;

    ELSE
        -- Obtener una cuenta específica
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Cuenta bancaria obtenida exitosamente',
            'data', json_build_object(
                'id', cb.id,
                'nombre_banco', cb.nombre_banco,
                'nombre_cuenta', cb.nombre_cuenta,
                'ultimos_4_digitos', cb.ultimos_4_digitos,
                'moneda', cb.moneda,
                'activo', cb.activo,
                'fecha_creacion', cb.fecha_creacion,
                'fecha_actualizacion', cb.fecha_actualizacion
            )
        ) INTO v_result
        FROM cuentas_bancarias cb
        WHERE cb.id = p_id;
        
        -- 3. Usamos la comprobación más robusta y recomendada: IF NOT FOUND.
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
-- ========================================
-- POST: Crear una nueva cuenta bancaria
-- ========================================
CREATE OR REPLACE FUNCTION cuentas_bancarias_post(
    p_nombre_banco VARCHAR,
    p_nombre_cuenta VARCHAR,
    p_ultimos_4_digitos VARCHAR,
    p_moneda tipo_moneda,
    p_activo BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    v_id BIGINT;
    v_result JSON;
BEGIN
    -- Validaciones
    IF p_nombre_banco IS NULL OR TRIM(p_nombre_banco) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre del banco es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_nombre_cuenta IS NULL OR TRIM(p_nombre_cuenta) = '' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'El nombre de la cuenta es obligatorio',
            'data', null
        );
    END IF;
    
    IF p_ultimos_4_digitos IS NULL OR p_ultimos_4_digitos !~ '^\d{4}$' THEN
        RETURN json_build_object(
            'code', 400,
            'estado', false,
            'message', 'Los últimos 4 dígitos deben ser exactamente 4 números',
            'data', null
        );
    END IF;
    
    -- Insertar nueva cuenta bancaria
    INSERT INTO cuentas_bancarias (
        nombre_banco, nombre_cuenta, ultimos_4_digitos, moneda, activo
    )
    VALUES (
        p_nombre_banco, p_nombre_cuenta, p_ultimos_4_digitos, p_moneda, p_activo
    )
    RETURNING id INTO v_id;
    
    -- Obtener la cuenta creada
    SELECT json_build_object(
        'code', 201,
        'estado', true,
        'message', 'Cuenta bancaria creada exitosamente',
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
    WHERE id = v_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al crear cuenta bancaria: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PUT: Actualizar una cuenta bancaria existente
-- ========================================
CREATE OR REPLACE FUNCTION cuentas_bancarias_put(
    p_id BIGINT,
    p_nombre_banco VARCHAR DEFAULT NULL,
    p_nombre_cuenta VARCHAR DEFAULT NULL,
    p_activo BOOLEAN DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar si existe la cuenta
    IF NOT EXISTS (SELECT 1 FROM cuentas_bancarias WHERE id = p_id) THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Cuenta bancaria no encontrada',
            'data', null
        );
    END IF;
    
    -- Actualizar campos no nulos
    UPDATE cuentas_bancarias
    SET 
        nombre_banco = COALESCE(p_nombre_banco, nombre_banco),
        nombre_cuenta = COALESCE(p_nombre_cuenta, nombre_cuenta),
        activo = COALESCE(p_activo, activo)
    WHERE id = p_id;
    
    -- Obtener la cuenta actualizada
    SELECT json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Cuenta bancaria actualizada exitosamente',
        'data', json_build_object(
            'id', id,
            'nombre_banco', nombre_banco,
            'nombre_cuenta', nombre_cuenta,
            'ultimos_4_digitos', ultimos_4_digitos,
            'moneda', moneda,
            'activo', activo,
            'fecha_creacion', fecha_creacion,
            'fecha_actualizacion', fecha_actualizacion
        )
    ) INTO v_result
    FROM cuentas_bancarias
    WHERE id = p_id;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al actualizar cuenta bancaria: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- DELETE: Eliminar una cuenta bancaria
-- ========================================
CREATE OR REPLACE FUNCTION cuentas_bancarias_delete(p_id BIGINT)
RETURNS JSON AS $$
DECLARE
    v_nombre VARCHAR;
    v_banco VARCHAR;
BEGIN
    -- Verificar si existe la cuenta
    SELECT nombre_cuenta, nombre_banco 
    INTO v_nombre, v_banco
    FROM cuentas_bancarias 
    WHERE id = p_id;
    
    IF v_nombre IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'Cuenta bancaria no encontrada',
            'data', null
        );
    END IF;
    
    -- Verificar si tiene pagos asociados
    IF EXISTS (SELECT 1 FROM pagos WHERE cuenta_bancaria_id = p_id) THEN
        RETURN json_build_object(
            'code', 409,
            'estado', false,
            'message', 'No se puede eliminar la cuenta porque tiene pagos asociados',
            'data', null
        );
    END IF;
    
    -- Eliminar la cuenta
    DELETE FROM cuentas_bancarias WHERE id = p_id;
    
    RETURN json_build_object(
        'code', 200,
        'estado', true,
        'message', 'Cuenta bancaria eliminada exitosamente',
        'data', json_build_object(
            'nombre_cuenta', v_nombre,
            'nombre_banco', v_banco
        )
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'code', 500,
            'estado', false,
            'message', 'Error al eliminar cuenta bancaria: ' || SQLERRM,
            'data', null
        );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

/*
-- GET: Obtener todas las cuentas bancarias
SELECT cuentas_bancarias_get();

-- GET: Obtener una cuenta específica
SELECT cuentas_bancarias_get(1);

-- POST: Crear una nueva cuenta bancaria
SELECT cuentas_bancarias_post(
    'Banco Nacional', 
    'Cuenta Corriente Empresarial', 
    '5678', 
    'CAD',
    true
);

-- PUT: Actualizar una cuenta bancaria
SELECT cuentas_bancarias_put(
    1, 
    'Banco Nacional de Canadá', 
    'Cuenta Empresarial Premium',
    NULL
);

-- DELETE: Eliminar una cuenta bancaria
SELECT cuentas_bancarias_delete(1);
*/



-- ============================================================================
-- FUNCIONES CRUD - TABLA: pagos (CORE)
-- ============================================================================

-- ========================================
-- GET: Obtener todos los pagos o uno específico
-- ========================================
CREATE OR REPLACE FUNCTION pagos_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los pagos
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Pagos obtenidos exitosamente',
            'data', COALESCE(
                -- 1. La subconsulta se encarga de toda la lógica compleja de agregación.
                (SELECT json_agg(
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
                            'servicio', json_build_object( -- Mejora: consistencia
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
                                    'moneda', tc.moneda -- Mejora: consistencia
                                )
                            WHEN p.tipo_medio_pago = 'CUENTA_BANCARIA' THEN
                                json_build_object(
                                    'tipo', 'CUENTA_BANCARIA',
                                    'id', cb.id,
                                    'banco', cb.nombre_banco,
                                    'cuenta', cb.nombre_cuenta,
                                    'ultimos_digitos', cb.ultimos_4_digitos,
                                    'moneda', cb.moneda -- Mejora: consistencia
                                )
                            ELSE NULL
                        END,
                        'clientes', (
                            SELECT COALESCE(json_agg(
                                json_build_object(
                                    'id', c.id,
                                    'nombre', c.nombre,
                                    'ubicacion', c.ubicacion -- Mejora: consistencia
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
                    -- 2. El ORDER BY se mueve aquí.
                    ORDER BY p.fecha_creacion DESC
                ) FROM pagos p
                JOIN proveedores prov ON p.proveedor_id = prov.id
                JOIN servicios s ON prov.servicio_id = s.id
                JOIN usuarios u ON p.usuario_id = u.id
                JOIN roles r ON u.rol_id = r.id
                LEFT JOIN tarjetas_credito tc ON p.tarjeta_id = tc.id
                LEFT JOIN cuentas_bancarias cb ON p.cuenta_bancaria_id = cb.id),
                '[]'::json
            )
        ) INTO v_result;

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
        
        -- 3. Mejora: Usamos la comprobación más robusta.
        IF NOT FOUND THEN
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
    2,                          -- proveedor_id
    2,                          -- usuario_id
    'RES-2026-004',             -- codigo_reserva
    500.00,                     -- monto
    'USD',                      -- moneda
    'TARJETA',                  -- tipo_medio_pago
    1,                          -- tarjeta_id
    NULL,                       -- cuenta_bancaria_id
    ARRAY[1]::BIGINT[],       -- clientes_ids
    'Pago de servicio de guía turística',  -- descripcion
    '2026-02-15'                -- fecha_esperada_debito
);

-- POST: Crear un nuevo pago con CUENTA BANCARIA
SELECT pagos_post(
    2,                          -- proveedor_id
    2,                          -- usuario_id
    'RES-2026-005',             -- codigo_reserva
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
SELECT pagos_get(2);

-- PUT: Actualizar un pago (solo campos permitidos)
SELECT pagos_put(
    2,                          -- id
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
    6,                          -- id
    NULL, NULL, NULL,
    TRUE,                       -- pagado
    NULL, NULL, NULL
);
SELECT pagos_put(3, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);



-- PUT: Marcar un pago como verificado (automáticamente marca pagado también)
SELECT pagos_put(
    2,                          -- id
    NULL, NULL, NULL, NULL,
    TRUE,                       -- verificado
    NULL, NULL
);

-- DELETE: Eliminar un pago
SELECT pagos_delete(1);
*/

-- ============================================================================
-- FUNCIONES CRUD - TABLA: documentos
-- ============================================================================
-- ============================================================================
-- FUNCIONES CRUD - TABLA: envios_correos
-- ============================================================================

-- ========================================
-- GET: Obtener todos los correos o uno específico
-- ========================================
-- ========================================
-- GET: Obtener todos los correos o uno específico (MEJORADO)
-- ========================================
-- ========================================
-- GET: Obtener todos los correos o uno específico (CORREGIDO)
-- ========================================
CREATE OR REPLACE FUNCTION envios_correos_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ 
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los correos (vista de lista)
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correos obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(correo_data) FROM (
                    SELECT json_build_object(
                        'id', e.id,
                        'proveedor', json_build_object(
                            'id', p.id,
                            'nombre', p.nombre,
                            'lenguaje', p.lenguaje,
                            'servicio', s.nombre
                        ),
                        'estado', e.estado,
                        'cantidad_pagos', e.cantidad_pagos,
                        'monto_total', e.monto_total,
                        'monedas', (
                            SELECT array_agg(DISTINCT pa.moneda ORDER BY pa.moneda)
                            FROM envio_correo_detalle ecd
                            JOIN pagos pa ON ecd.pago_id = pa.id
                            WHERE ecd.envio_id = e.id
                        ),
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
                        'fecha_generacion', e.fecha_generacion,
                        'fecha_envio', e.fecha_envio,
                        'resumen_medios_pago', (
                            SELECT json_agg(
                                json_build_object(
                                    'tipo', pa.tipo_medio_pago,
                                    'cantidad', COUNT(*),
                                    'monto_total', SUM(pa.monto)
                                )
                            )
                            FROM envio_correo_detalle ecd
                            JOIN pagos pa ON ecd.pago_id = pa.id
                            WHERE ecd.envio_id = e.id
                            GROUP BY pa.tipo_medio_pago
                        )
                    ) AS correo_data
                    FROM envios_correos e
                    JOIN proveedores p ON e.proveedor_id = p.id
                    JOIN servicios s ON p.servicio_id = s.id
                    LEFT JOIN usuarios u ON e.usuario_envio_id = u.id
                ) AS correos_lista),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
        -- Obtener un correo específico con todos los datos completos de los pagos
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
                    'telefono', p.telefono,
                    'descripcion', p.descripcion,
                    'servicio', json_build_object(
                        'id', s.id,
                        'nombre', s.nombre,
                        'descripcion', s.descripcion
                    ),
                    'correos_disponibles', (
                        SELECT COALESCE(json_agg(pc_data), '[]'::json) FROM (
                            SELECT json_build_object(
                                'id', pc.id,
                                'correo', pc.correo,
                                'principal', pc.principal,
                                'activo', pc.activo
                            ) AS pc_data
                            FROM proveedor_correos pc
                            WHERE pc.proveedor_id = p.id AND pc.activo = TRUE
                            ORDER BY pc.principal DESC, pc.id
                        ) AS pc_table
                    )
                ),
                'estado', e.estado,
                'cantidad_pagos', e.cantidad_pagos,
                'monto_total', e.monto_total,
                'correo_seleccionado', e.correo_seleccionado,
                'asunto', e.asunto,
                'cuerpo', e.cuerpo,
                'pagos_incluidos', pagos_detalle.pagos_json,
                'resumen_correo', json_build_object(
                    'monto_por_moneda', (
                        SELECT json_agg(
                            json_build_object(
                                'moneda', moneda,
                                'cantidad', COUNT(*),
                                'monto_total', SUM(monto)
                            ) ORDER BY moneda
                        )
                        FROM (
                            SELECT pa.moneda, pa.monto
                            FROM envio_correo_detalle ecd
                            JOIN pagos pa ON ecd.pago_id = pa.id
                            WHERE ecd.envio_id = e.id
                        ) AS resumen_moneda
                        GROUP BY moneda
                    ),
                    'monto_por_medio_pago', (
                        SELECT json_agg(
                            json_build_object(
                                'tipo', tipo_medio_pago,
                                'cantidad', COUNT(*),
                                'monto_total', SUM(monto)
                            )
                        )
                        FROM (
                            SELECT pa.tipo_medio_pago, pa.monto
                            FROM envio_correo_detalle ecd
                            JOIN pagos pa ON ecd.pago_id = pa.id
                            WHERE ecd.envio_id = e.id
                        ) AS resumen_medio
                        GROUP BY tipo_medio_pago
                    ),
                    'pagos_por_cliente', (
                        SELECT json_agg(
                            json_build_object(
                                'cliente', json_build_object(
                                    'id', c.id,
                                    'nombre', c.nombre,
                                    'ubicacion', c.ubicacion
                                ),
                                'cantidad_pagos', COUNT(*),
                                'monto_total', SUM(pa.monto)
                            )
                        )
                        FROM envio_correo_detalle ecd
                        JOIN pagos pa ON ecd.pago_id = pa.id
                        JOIN pago_cliente pc ON pa.id = pc.pago_id
                        JOIN clientes c ON pc.cliente_id = c.id
                        WHERE ecd.envio_id = e.id
                        GROUP BY c.id, c.nombre, c.ubicacion
                    )
                ),
                'usuario_envio', CASE 
                    WHEN u.id IS NOT NULL THEN
                        json_build_object(
                            'id', u.id,
                            'nombre_completo', u.nombre_completo,
                            'rol', r.nombre
                        )
                    ELSE NULL
                END,
                'fecha_generacion', e.fecha_generacion,
                'fecha_envio', e.fecha_envio
            )
        ) INTO v_result
        FROM envios_correos e
        JOIN proveedores p ON e.proveedor_id = p.id
        JOIN servicios s ON p.servicio_id = s.id
        LEFT JOIN usuarios u ON e.usuario_envio_id = u.id
        LEFT JOIN roles r ON u.rol_id = r.id
        LEFT JOIN LATERAL (
            SELECT COALESCE(json_agg(pago_data), '[]'::json) AS pagos_json FROM (
                SELECT json_build_object(
                    'id', pa.id,
                    'codigo_reserva', pa.codigo_reserva,
                    'monto', pa.monto,
                    'moneda', pa.moneda,
                    'descripcion', pa.descripcion,
                    'fecha_esperada_debito', pa.fecha_esperada_debito,
                    'proveedor', json_build_object(
                        'id', prov.id,
                        'nombre', prov.nombre,
                        'servicio', json_build_object(
                            'id', s.id,
                            'nombre', s.nombre
                        )
                    ),
                    'usuario', json_build_object(
                        'id', us.id,
                        'nombre_completo', us.nombre_completo,
                        'rol', ro.nombre,
                        'correo', us.correo
                    ),
                    'medio_pago', CASE 
                        WHEN pa.tipo_medio_pago = 'TARJETA' THEN
                            json_build_object(
                                'tipo', 'TARJETA',
                                'id', tc.id,
                                'titular', tc.nombre_titular,
                                'ultimos_digitos', tc.ultimos_4_digitos,
                                'tipo_tarjeta', tc.tipo_tarjeta,
                                'moneda', tc.moneda,
                                'limite_mensual', tc.limite_mensual,
                                'saldo_disponible', tc.saldo_disponible,
                                'porcentaje_uso', ROUND((tc.limite_mensual - tc.saldo_disponible) * 100.0 / tc.limite_mensual, 2)
                            )
                        WHEN pa.tipo_medio_pago = 'CUENTA_BANCARIA' THEN
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
                        SELECT COALESCE(json_agg(cliente_data), '[]'::json) FROM (
                            SELECT json_build_object(
                                'id', c.id,
                                'nombre', c.nombre,
                                'ubicacion', c.ubicacion,
                                'telefono', c.telefono,
                                'correo', c.correo
                            ) AS cliente_data
                            FROM pago_cliente pc
                            JOIN clientes c ON pc.cliente_id = c.id
                            WHERE pc.pago_id = pa.id
                        ) AS clientes_table
                    ),
                    'documentos', (
                        SELECT COALESCE(json_agg(doc_data), '[]'::json) FROM (
                            SELECT json_build_object(
                                'id', d.id,
                                'tipo_documento', d.tipo_documento,
                                'nombre_archivo', d.nombre_archivo,
                                'url_documento', d.url_documento,
                                'fecha_subida', d.fecha_subida,
                                'usuario_subida', us_sub.nombre_completo
                            ) AS doc_data
                            FROM documento_pago dp
                            JOIN documentos d ON dp.documento_id = d.id
                            LEFT JOIN usuarios us_sub ON d.usuario_id = us_sub.id
                            WHERE dp.pago_id = pa.id
                        ) AS docs_table
                    ),
                    'estados', json_build_object(
                        'pagado', pa.pagado,
                        'verificado', pa.verificado,
                        'gmail_enviado', pa.gmail_enviado,
                        'activo', pa.activo
                    ),
                    'fechas_importantes', json_build_object(
                        'fecha_pago', pa.fecha_pago,
                        'fecha_verificacion', pa.fecha_verificacion,
                        'fecha_creacion', pa.fecha_creacion,
                        'fecha_actualizacion', pa.fecha_actualizacion
                    ),
                    'auditoria', (
                        SELECT COALESCE(json_agg(aud_data), '[]'::json) FROM (
                            SELECT json_build_object(
                                'id', ev.id,
                                'tipo_evento', ev.tipo_evento,
                                'descripcion', ev.descripcion,
                                'usuario', json_build_object(
                                    'id', u_aud.id,
                                    'nombre', u_aud.nombre_completo
                                ),
                                'fecha_evento', ev.fecha_evento,
                                'ip_origen', ev.ip_origen
                            ) AS aud_data
                            FROM eventos ev
                            LEFT JOIN usuarios u_aud ON ev.usuario_id = u_aud.id
                            WHERE ev.entidad_tipo = 'pagos' AND ev.entidad_id = pa.id
                            ORDER BY ev.fecha_evento DESC
                            LIMIT 5
                        ) AS aud_table
                    )
                ) AS pago_data
                FROM envio_correo_detalle ecd
                JOIN pagos pa ON ecd.pago_id = pa.id
                JOIN proveedores prov ON pa.proveedor_id = prov.id
                JOIN servicios s ON prov.servicio_id = s.id
                JOIN usuarios us ON pa.usuario_id = us.id
                JOIN roles ro ON us.rol_id = ro.id
                LEFT JOIN tarjetas_credito tc ON pa.tarjeta_id = tc.id
                LEFT JOIN cuentas_bancarias cb ON pa.cuenta_bancaria_id = cb.id
                WHERE ecd.envio_id = e.id
            ) AS pagos_table
        ) AS pagos_detalle ON true
        WHERE e.id = p_id;
        
        IF NOT FOUND THEN
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
SELECT envios_correos_get(8);

-- POST: Crear un nuevo correo (borrador)
SELECT envios_correos_post(
    1,  -- proveedor_id
    2,  -- usuario_envio_id
    'Notificación de Pagos - Enero 2026',
    'Estimado proveedor, adjunto encontrará el detalle de los pagos realizados...',
    ARRAY[8]::BIGINT[]  -- pagos_ids
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
    8,  -- id
    'contacto@proveedor.com',  -- correo_destino
    NULL,  -- asunto (mantiene el actual)
    NULL,  -- cuerpo (mantiene el actual)
    TRUE  -- SÍ enviar
);

-- DELETE: Eliminar un borrador
SELECT envios_correos_delete(1);
*/
-- ========================================
-- GET: Obtener todos los correos o uno específico (CON PAGOS EN LISTA)
-- ========================================


-- ========================================
-- GET: Obtener todos los correos o uno específico (CORREGIDO)
-- ========================================
CREATE OR REPLACE FUNCTION envios_correos_get(p_id BIGINT DEFAULT NULL)
RETURNS JSON AS $$ 
DECLARE
    v_result JSON;
BEGIN
    IF p_id IS NULL THEN
        -- Obtener todos los correos (vista de lista) CON DATOS DE PAGOS
        SELECT json_build_object(
            'code', 200,
            'estado', true,
            'message', 'Correos obtenidos exitosamente',
            'data', COALESCE(
                (SELECT json_agg(data_row)
                FROM (
                    SELECT 
                        json_build_object(
                            'id', e.id,
                            'proveedor', json_build_object(
                                'id', p.id,
                                'nombre', p.nombre,
                                'lenguaje', p.lenguaje,
                                'servicio', s.nombre
                            ),
                            'estado', e.estado,
                            'cantidad_pagos', e.cantidad_pagos,
                            'monto_total', e.monto_total,
                            'monedas', (
                                SELECT array_agg(DISTINCT pa.moneda ORDER BY pa.moneda)
                                FROM envio_correo_detalle ecd
                                JOIN pagos pa ON ecd.pago_id = pa.id
                                WHERE ecd.envio_id = e.id
                            ),
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
                            'fecha_generacion', e.fecha_generacion,
                            'fecha_envio', e.fecha_envio,
                            'resumen_medios_pago', (
                                SELECT json_agg(
                                    json_build_object(
                                        'tipo', tipo_medio_pago,
                                        'cantidad', cantidad,
                                        'monto_total', monto_total
                                    )
                                )
                                FROM (
                                    SELECT 
                                        pa.tipo_medio_pago,
                                        COUNT(*) as cantidad,
                                        SUM(pa.monto) as monto_total
                                    FROM envio_correo_detalle ecd
                                    JOIN pagos pa ON ecd.pago_id = pa.id
                                    WHERE ecd.envio_id = e.id
                                    GROUP BY pa.tipo_medio_pago
                                ) AS resumen_medio
                            ),
                            'pagos_incluidos', COALESCE(
                                (SELECT json_agg(
                                    json_build_object(
                                        'id', pa.id,
                                        'codigo_reserva', pa.codigo_reserva,
                                        'monto', pa.monto,
                                        'moneda', pa.moneda,
                                        'descripcion', pa.descripcion,
                                        'fecha_esperada_debito', pa.fecha_esperada_debito,
                                        'medio_pago', CASE 
                                            WHEN pa.tipo_medio_pago = 'TARJETA' THEN
                                                json_build_object(
                                                    'tipo', 'TARJETA',
                                                    'id', tc.id,
                                                    'titular', tc.nombre_titular,
                                                    'ultimos_digitos', tc.ultimos_4_digitos,
                                                    'moneda', tc.moneda
                                                )
                                            WHEN pa.tipo_medio_pago = 'CUENTA_BANCARIA' THEN
                                                json_build_object(
                                                    'tipo', 'CUENTA_BANCARIA',
                                                    'id', cb.id,
                                                    'banco', cb.nombre_banco,
                                                    'ultimos_digitos', cb.ultimos_4_digitos,
                                                    'moneda', cb.moneda
                                                )
                                            ELSE NULL
                                        END,
                                        'clientes', COALESCE(
                                            (SELECT json_agg(
                                                json_build_object(
                                                    'id', c.id,
                                                    'nombre', c.nombre
                                                )
                                            ) FROM pago_cliente pc
                                            JOIN clientes c ON pc.cliente_id = c.id
                                            WHERE pc.pago_id = pa.id),
                                            '[]'::json
                                        ),
                                        'estados', json_build_object(
                                            'pagado', pa.pagado,
                                            'verificado', pa.verificado,
                                            'gmail_enviado', pa.gmail_enviado
                                        ),
                                        'fecha_pago', pa.fecha_pago,
                                        'fecha_creacion', pa.fecha_creacion
                                    )
                                ) FROM envio_correo_detalle ecd
                                JOIN pagos pa ON ecd.pago_id = pa.id
                                LEFT JOIN tarjetas_credito tc ON pa.tarjeta_id = tc.id
                                LEFT JOIN cuentas_bancarias cb ON pa.cuenta_bancaria_id = cb.id
                                WHERE ecd.envio_id = e.id),
                                '[]'::json
                            )
                        ) AS data_row
                    FROM envios_correos e
                    JOIN proveedores p ON e.proveedor_id = p.id
                    JOIN servicios s ON p.servicio_id = s.id
                    LEFT JOIN usuarios u ON e.usuario_envio_id = u.id
                    ORDER BY e.fecha_generacion DESC
                ) AS ordered_correos),
                '[]'::json
            )
        ) INTO v_result;
    ELSE
        -- Obtener un correo específico con todos los datos completos
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
                    'telefono', p.telefono,
                    'descripcion', p.descripcion,
                    'servicio', json_build_object(
                        'id', s.id,
                        'nombre', s.nombre,
                        'descripcion', s.descripcion
                    ),
                    'correos_disponibles', COALESCE(
                        (SELECT json_agg(
                            json_build_object(
                                'id', pc.id,
                                'correo', pc.correo,
                                'principal', pc.principal,
                                'activo', pc.activo
                            )
                        ) FROM proveedor_correos pc
                        WHERE pc.proveedor_id = p.id AND pc.activo = TRUE),
                        '[]'::json
                    )
                ),
                'estado', e.estado,
                'cantidad_pagos', e.cantidad_pagos,
                'monto_total', e.monto_total,
                'correo_seleccionado', e.correo_seleccionado,
                'asunto', e.asunto,
                'cuerpo', e.cuerpo,
                'pagos_incluidos', COALESCE(
                    (SELECT json_agg(
                        json_build_object(
                            'id', pa.id,
                            'codigo_reserva', pa.codigo_reserva,
                            'monto', pa.monto,
                            'moneda', pa.moneda,
                            'descripcion', pa.descripcion,
                            'fecha_esperada_debito', pa.fecha_esperada_debito,
                            'proveedor', json_build_object(
                                'id', prov.id,
                                'nombre', prov.nombre,
                                'servicio', json_build_object(
                                    'id', s.id,
                                    'nombre', s.nombre
                                )
                            ),
                            'usuario', json_build_object(
                                'id', us.id,
                                'nombre_completo', us.nombre_completo,
                                'rol', ro.nombre,
                                'correo', us.correo
                            ),
                            'medio_pago', CASE 
                                WHEN pa.tipo_medio_pago = 'TARJETA' THEN
                                    json_build_object(
                                        'tipo', 'TARJETA',
                                        'id', tc.id,
                                        'titular', tc.nombre_titular,
                                        'ultimos_digitos', tc.ultimos_4_digitos,
                                        'tipo_tarjeta', tc.tipo_tarjeta,
                                        'moneda', tc.moneda,
                                        'limite_mensual', tc.limite_mensual,
                                        'saldo_disponible', tc.saldo_disponible,
                                        'porcentaje_uso', ROUND((tc.limite_mensual - tc.saldo_disponible) * 100.0 / tc.limite_mensual, 2)
                                    )
                                WHEN pa.tipo_medio_pago = 'CUENTA_BANCARIA' THEN
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
                            'clientes', COALESCE(
                                (SELECT json_agg(
                                    json_build_object(
                                        'id', c.id,
                                        'nombre', c.nombre,
                                        'ubicacion', c.ubicacion,
                                        'telefono', c.telefono,
                                        'correo', c.correo
                                    )
                                ) FROM pago_cliente pc
                                JOIN clientes c ON pc.cliente_id = c.id
                                WHERE pc.pago_id = pa.id),
                                '[]'::json
                            ),
                            'documentos', COALESCE(
                                (SELECT json_agg(
                                    json_build_object(
                                        'id', d.id,
                                        'tipo_documento', d.tipo_documento,
                                        'nombre_archivo', d.nombre_archivo,
                                        'url_documento', d.url_documento,
                                        'fecha_subida', d.fecha_subida,
                                        'usuario_subida', us_sub.nombre_completo
                                    )
                                ) FROM documento_pago dp
                                JOIN documentos d ON dp.documento_id = d.id
                                LEFT JOIN usuarios us_sub ON d.usuario_id = us_sub.id
                                WHERE dp.pago_id = pa.id),
                                '[]'::json
                            ),
                            'estados', json_build_object(
                                'pagado', pa.pagado,
                                'verificado', pa.verificado,
                                'gmail_enviado', pa.gmail_enviado,
                                'activo', pa.activo
                            ),
                            'fechas_importantes', json_build_object(
                                'fecha_pago', pa.fecha_pago,
                                'fecha_verificacion', pa.fecha_verificacion,
                                'fecha_creacion', pa.fecha_creacion,
                                'fecha_actualizacion', pa.fecha_actualizacion
                            ),
                            'auditoria', COALESCE(
                                (SELECT json_agg(
                                    json_build_object(
                                        'id', ev.id,
                                        'tipo_evento', ev.tipo_evento,
                                        'descripcion', ev.descripcion,
                                        'usuario', json_build_object(
                                            'id', u_aud.id,
                                            'nombre', u_aud.nombre_completo
                                        ),
                                        'fecha_evento', ev.fecha_evento,
                                        'ip_origen', ev.ip_origen
                                    )
                                ) FROM eventos ev
                                LEFT JOIN usuarios u_aud ON ev.usuario_id = u_aud.id
                                WHERE ev.entidad_tipo = 'pagos' AND ev.entidad_id = pa.id
                                LIMIT 5),
                                '[]'::json
                            )
                        )
                    ) FROM envio_correo_detalle ecd
                    JOIN pagos pa ON ecd.pago_id = pa.id
                    JOIN proveedores prov ON pa.proveedor_id = prov.id
                    JOIN servicios s ON prov.servicio_id = s.id
                    JOIN usuarios us ON pa.usuario_id = us.id
                    JOIN roles ro ON us.rol_id = ro.id
                    LEFT JOIN tarjetas_credito tc ON pa.tarjeta_id = tc.id
                    LEFT JOIN cuentas_bancarias cb ON pa.cuenta_bancaria_id = cb.id
                    WHERE ecd.envio_id = e.id),
                    '[]'::json
                ),
                'resumen_correo', json_build_object(
                    'monto_por_moneda', (
                        SELECT json_agg(
                            json_build_object(
                                'moneda', moneda,
                                'cantidad', cantidad,
                                'monto_total', monto_total
                            )
                        )
                        FROM (
                            SELECT 
                                pa.moneda, 
                                COUNT(*) as cantidad,
                                SUM(pa.monto) as monto_total
                            FROM envio_correo_detalle ecd
                            JOIN pagos pa ON ecd.pago_id = pa.id
                            WHERE ecd.envio_id = e.id
                            GROUP BY pa.moneda
                        ) AS resumen_moneda
                    ),
                    'monto_por_medio_pago', (
                        SELECT json_agg(
                            json_build_object(
                                'tipo', tipo_medio_pago,
                                'cantidad', cantidad,
                                'monto_total', monto_total
                            )
                        )
                        FROM (
                            SELECT 
                                pa.tipo_medio_pago,
                                COUNT(*) as cantidad,
                                SUM(pa.monto) as monto_total
                            FROM envio_correo_detalle ecd
                            JOIN pagos pa ON ecd.pago_id = pa.id
                            WHERE ecd.envio_id = e.id
                            GROUP BY pa.tipo_medio_pago
                        ) AS resumen_medio
                    ),
                    -- CORRECCIÓN: Referenciar columnas del resultado de la subconsulta
                    'pagos_por_cliente', (
                        SELECT json_agg(
                            json_build_object(
                                'cliente', json_build_object(
                                    'id', id,               -- CORREGIDO: antes era c.id
                                    'nombre', nombre,       -- CORREGIDO: antes era c.nombre
                                    'ubicacion', ubicacion  -- CORREGIDO: antes era c.ubicacion
                                ),
                                'cantidad_pagos', cantidad,
                                'monto_total', monto_total
                            )
                        )
                        FROM (
                            SELECT 
                                c.id, c.nombre, c.ubicacion,
                                COUNT(*) as cantidad,
                                SUM(pa.monto) as monto_total
                            FROM envio_correo_detalle ecd
                            JOIN pagos pa ON ecd.pago_id = pa.id
                            JOIN pago_cliente pc ON pa.id = pc.pago_id
                            JOIN clientes c ON pc.cliente_id = c.id
                            WHERE ecd.envio_id = e.id
                            GROUP BY c.id, c.nombre, c.ubicacion
                        ) AS resumen_cliente
                    )
                ),
                'usuario_envio', CASE 
                    WHEN u.id IS NOT NULL THEN
                        json_build_object(
                            'id', u.id,
                            'nombre_completo', u.nombre_completo,
                            'rol', r.nombre
                        )
                    ELSE NULL
                END,
                'fecha_generacion', e.fecha_generacion,
                'fecha_envio', e.fecha_envio
            )
        ) INTO v_result
        FROM envios_correos e
        JOIN proveedores p ON e.proveedor_id = p.id
        JOIN servicios s ON p.servicio_id = s.id
        LEFT JOIN usuarios u ON e.usuario_envio_id = u.id
        LEFT JOIN roles r ON u.rol_id = r.id
        WHERE e.id = p_id;
        
        IF NOT FOUND THEN
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
CREATE OR REPLACE FUNCTION envios_correos_post(
    p_proveedor_id BIGINT,
    p_usuario_envio_id BIGINT,
    p_asunto VARCHAR,
    p_cuerpo TEXT,
    p_pagos_ids BIGINT[]
)
RETURNS JSON AS $$ DECLARE
    v_id BIGINT;
    v_result JSON;
    v_pago_id BIGINT;
    v_cantidad INT;
    v_monto_total DECIMAL;
    v_correo_seleccionado VARCHAR;
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
    
    -- OBTENER EL CORREO DEL PROVEEDOR
    SELECT correo INTO v_correo_seleccionado
    FROM proveedor_correos
    WHERE proveedor_id = p_proveedor_id 
      AND principal = TRUE 
      AND activo = TRUE
    LIMIT 1;
    
    IF v_correo_seleccionado IS NULL THEN
        SELECT correo INTO v_correo_seleccionado
        FROM proveedor_correos
        WHERE proveedor_id = p_proveedor_id 
          AND activo = TRUE
        ORDER BY id
        LIMIT 1;
    END IF;
    
    IF v_correo_seleccionado IS NULL THEN
        RETURN json_build_object(
            'code', 404,
            'estado', false,
            'message', 'El proveedor no tiene correos registrados',
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
        proveedor_id, 
        correo_seleccionado,
        usuario_envio_id, 
        estado, 
        cantidad_pagos, 
        monto_total, 
        asunto, 
        cuerpo
    )
    VALUES (
        p_proveedor_id, 
        v_correo_seleccionado,
        p_usuario_envio_id, 
        'BORRADOR', 
        v_cantidad,
        v_monto_total, 
        p_asunto, 
        p_cuerpo
    )
    RETURNING id INTO v_id;
    
    -- Vincular los pagos al correo (¡LÍNEA CORREGIDA!)
    FOREACH v_pago_id IN ARRAY p_pagos_ids
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pagos WHERE id = v_pago_id AND pagado = TRUE AND gmail_enviado = FALSE) THEN
            RAISE EXCEPTION 'El pago con ID % no existe, no está pagado, o ya fue enviado por correo', v_pago_id;
        END IF;
        
        -- CORRECCIÓN AQUÍ:
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


SELECT envios_correos_post(
    1,  -- p_proveedor_id (Tours Montreal)
    2,  -- p_usuario_envio_id (Ana García)
    'Notificación de Pagos - Enero 2026', -- p_asunto
    'Estimado equipo de Tours Montreal,

Adjunto encontrará el detalle del pago correspondiente a la reserva #TOUR-456.

El pago ha sido procesado y debería reflejarse en su cuenta en los próximos 2-3 días hábiles.

Gracias por su excelente servicio.

Saludos cordiales,
Terra Canada', -- p_cuerpo
    ARRAY[2]::BIGINT[]  -- p_pagos_ids (un array con el ID del pago)
);









CREATE OR REPLACE FUNCTION envios_correos_put(
    p_id BIGINT,
    p_correo_destino VARCHAR DEFAULT NULL,
    p_asunto VARCHAR DEFAULT NULL,
    p_cuerpo TEXT DEFAULT NULL,
    p_enviar BOOLEAN DEFAULT FALSE
)
RETURNS JSON AS $$ DECLARE
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
        
        -- OBTENER LOS IDs DE LOS PAGOS VINCULADOS (TABLA CORREGIDA)
        SELECT array_agg(pago_id) INTO v_pagos_ids
        FROM envio_correo_detalle  -- <-- CORRECCIÓN AQUÍ
        WHERE envio_id = p_id;
        
        -- Marcar pagos como gmail_enviado = TRUE
        UPDATE pagos
        SET gmail_enviado = TRUE
        WHERE id = ANY(v_pagos_ids);
        
        -- Cambiar estado a ENVIADO y registrar fecha de envío
        UPDATE envios_correos
        SET 
            estado = 'ENVIADO',
            fecha_envio = NOW(),
            correo_seleccionado = p_correo_destino, -- Se actualiza el correo destino final
            asunto = COALESCE(p_asunto, asunto),
            cuerpo = COALESCE(p_cuerpo, cuerpo)
        WHERE id = p_id;
    ELSE
        -- Solo actualizar contenido (mantener como BORRADOR)
        UPDATE envios_correos
        SET 
            correo_seleccionado = COALESCE(p_correo_destino, correo_seleccionado),
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
aaaaaa
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
