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
