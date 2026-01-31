# 📊 ESTRUCTURA DE BASE DE DATOS - TERRA CANADA

**Versión:** 3.0 Final  
**Fecha:** 28 de Enero, 2026  
**Database:** PostgreSQL  
**Timezone:** Europe/Paris

---

## 📋 TABLA DE CONTENIDOS

1. [Información General](#información-general)
2. [Extensiones y Configuración](#extensiones-y-configuración)
3. [Tipos ENUM](#tipos-enum)
4. [Tablas del Sistema](#tablas-del-sistema)
5. [Índices y Optimizaciones](#índices-y-optimizaciones)
6. [Funciones y Triggers](#funciones-y-triggers)
7. [Queries Comunes](#queries-comunes)

---

## 🎯 INFORMACIÓN GENERAL

### **Base de Datos:**

- **Motor:** PostgreSQL 14+
- **Charset:** UTF8
- **Collation:** es_ES.UTF-8 / fr_FR.UTF-8
- **Timezone:** Europe/Paris

### **Convenciones:**

- Nombres de tablas: plural, minúsculas, snake_case
- Nombres de columnas: snake_case
- IDs: BIGSERIAL (autoincrementables)
- Timestamps: TIMESTAMPTZ (con zona horaria)
- Soft delete: campo `activo` BOOLEAN

---

## 🔧 EXTENSIONES Y CONFIGURACIÓN

```sql
-- Extensión para encriptación
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Configuración de zona horaria
SET timezone = 'Europe/Paris';
```

**NOTA:** NO se usa uuid-ossp, se usan IDs autoincrementables simples.

---

## 🏷️ TIPOS ENUM

### **tipo_moneda**

```sql
CREATE TYPE tipo_moneda AS ENUM ('USD', 'CAD');
```

**Uso:** Monedas soportadas en pagos y medios de pago

### **tipo_medio_pago**

```sql
CREATE TYPE tipo_medio_pago AS ENUM ('TARJETA', 'CUENTA_BANCARIA');
```

**Uso:** Tipo de medio de pago (lógica diferente en cada uno)

### **tipo_documento**

```sql
CREATE TYPE tipo_documento AS ENUM ('FACTURA', 'DOCUMENTO_BANCO');
```

**Uso:**

- FACTURA: cambia pagado = TRUE en 1 pago
- DOCUMENTO_BANCO: cambia pagado + verificado = TRUE en N pagos

### **estado_correo**

```sql
CREATE TYPE estado_correo AS ENUM ('BORRADOR', 'ENVIADO');
```

**Uso:** Estado del correo en el workflow

### **tipo_evento**

```sql
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
```

**Uso:** Tipos de eventos en la tabla de auditoría

---

## 📁 TABLAS DEL SISTEMA

### **1. ROLES**

**Propósito:** Catálogo de roles del sistema

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PK, NOT NULL | ID autoincrementable |
| nombre | VARCHAR(50) | NOT NULL, UNIQUE | ADMIN, SUPERVISOR, EQUIPO |
| descripcion | TEXT | NULL | Descripción del rol |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |

**Valores iniciales:**

- ADMIN: Control total del sistema
- SUPERVISOR: Casi control total excepto gestión de usuarios
- EQUIPO: Operaciones básicas con tarjetas, puede enviar correos

---

### **2. SERVICIOS**

**Propósito:** Catálogo de servicios ofrecidos

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PK, NOT NULL | ID autoincrementable |
| nombre | VARCHAR(50) | NOT NULL, UNIQUE | Nombre del servicio |
| descripcion | TEXT | NULL | Descripción |
| activo | BOOLEAN | DEFAULT TRUE | Si está activo |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |

**Servicios predefinidos:**

1. Assurance
2. Comptable
3. Cadeaux et invitations
4. Bureau / équipement / internet, téléphonie
5. Voyage de reco
6. Frais coworking/cafés
7. Hotels
8. Opérations clients (Services/activités/guides/entrées/transports)
9. Promotion de l'agence
10. Salaires

**Índices:**

- None (tabla pequeña)

---

### **3. USUARIOS**

**Propósito:** Usuarios del sistema con autenticación

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| nombre_usuario | VARCHAR(50) | NOT NULL, UNIQUE | Username para login |
| correo | VARCHAR(255) | NOT NULL, UNIQUE | Email del usuario |
| contrasena_hash | VARCHAR(255) | NOT NULL | Contraseña encriptada |
| nombre_completo | VARCHAR(100) | NOT NULL | Nombre completo |
| rol_id | INT | FK, NOT NULL | Rol del usuario |
| telefono | VARCHAR(20) | NULL | Teléfono |
| activo | BOOLEAN | DEFAULT TRUE | Si está activo |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |
| fecha_actualizacion | TIMESTAMPTZ | DEFAULT NOW() | Última actualización |

**Relaciones:**

- `rol_id` → `roles.id` (N:1)

**Índices:**

- `idx_usuarios_correo` en `correo`
- `idx_usuarios_rol` en `rol_id`
- `idx_usuarios_activo` en `activo` WHERE activo = TRUE

**Reglas de Negocio:**

- Solo ADMIN puede crear usuarios
- Contraseña debe estar hasheada con bcrypt o similar
- Email debe ser válido (constraint)
- Username único en el sistema

---

### **4. PROVEEDORES**

**Propósito:** Proveedores de servicios

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| nombre | VARCHAR(100) | NOT NULL | Nombre del proveedor |
| servicio_id | INT | FK, NOT NULL | Servicio que ofrece |
| lenguaje | VARCHAR(50) | NULL | Idioma (Español, English, Français) |
| telefono | VARCHAR(20) | NULL | Teléfono |
| descripcion | TEXT | NULL | Descripción |
| activo | BOOLEAN | DEFAULT TRUE | Si está activo |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |
| fecha_actualizacion | TIMESTAMPTZ | DEFAULT NOW() | Última actualización |

**Relaciones:**

- `servicio_id` → `servicios.id` (N:1)
- Tiene hasta 4 correos en `proveedor_correos`

**Índices:**

- `idx_proveedores_servicio` en `servicio_id`
- `idx_proveedores_activo` en `activo` WHERE activo = TRUE
- `idx_proveedores_nombre` en `nombre`

**Campo lenguaje:**

- Dato de referencia para que el usuario redacte correos
- No tiene lógica automática
- Ejemplos: "Español", "English", "Français", "Deutsch"

---

### **5. PROVEEDOR_CORREOS**

**Propósito:** Hasta 4 correos por proveedor

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PK, NOT NULL | ID autoincrementable |
| proveedor_id | BIGINT | FK, NOT NULL | Proveedor |
| correo | VARCHAR(255) | NOT NULL | Email |
| principal | BOOLEAN | DEFAULT FALSE | Si es principal |
| activo | BOOLEAN | DEFAULT TRUE | Si está activo |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |

**Relaciones:**

- `proveedor_id` → `proveedores.id` (N:1) ON DELETE CASCADE

**Índices:**

- `idx_proveedor_correos_proveedor` en `proveedor_id`
- `idx_proveedor_correos_activo` en `(proveedor_id, activo)` WHERE activo = TRUE

**Reglas de Negocio:**

- Máximo 4 correos activos por proveedor (trigger)
- Email debe ser válido (constraint)

---

### **6. CLIENTES**

**Propósito:** Hoteles y empresas clientes

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| nombre | VARCHAR(100) | NOT NULL | Nombre del cliente |
| ubicacion | VARCHAR(255) | NULL | Ubicación |
| telefono | VARCHAR(20) | NULL | Teléfono |
| correo | VARCHAR(255) | NULL | Email |
| activo | BOOLEAN | DEFAULT TRUE | Si está activo |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |
| fecha_actualizacion | TIMESTAMPTZ | DEFAULT NOW() | Última actualización |

**Índices:**

- `idx_clientes_nombre` en `nombre`
- `idx_clientes_activo` en `activo` WHERE activo = TRUE

---

### **7. TARJETAS_CREDITO**

**Propósito:** Tarjetas con control de saldo

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| nombre_titular | VARCHAR(100) | NOT NULL | Titular |
| ultimos_4_digitos | VARCHAR(4) | NOT NULL | Últimos 4 dígitos |
| moneda | tipo_moneda | NOT NULL | USD o CAD |
| limite_mensual | DECIMAL(12,2) | NOT NULL | Límite mensual |
| saldo_disponible | DECIMAL(12,2) | NOT NULL | Saldo actual |
| tipo_tarjeta | VARCHAR(50) | DEFAULT 'Visa' | Tipo (Visa, MC, etc) |
| activo | BOOLEAN | DEFAULT TRUE | Si está activa |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |
| fecha_actualizacion | TIMESTAMPTZ | DEFAULT NOW() | Última actualización |

**Índices:**

- `idx_tarjetas_activo` en `activo` WHERE activo = TRUE
- `idx_tarjetas_moneda` en `moneda`

**Reglas de Negocio:**

- Límite mensual > 0
- Saldo disponible >= 0
- Saldo disponible <= límite_mensual
- Se resetea el día 1 de cada mes

---

### **8. CUENTAS_BANCARIAS**

**Propósito:** Cuentas bancarias sin control de saldo

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| nombre_banco | VARCHAR(100) | NOT NULL | Nombre del banco |
| nombre_cuenta | VARCHAR(100) | NOT NULL | Nombre de la cuenta |
| ultimos_4_digitos | VARCHAR(4) | NOT NULL | Últimos 4 dígitos |
| moneda | tipo_moneda | NOT NULL | USD o CAD |
| activo | BOOLEAN | DEFAULT TRUE | Si está activa |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |
| fecha_actualizacion | TIMESTAMPTZ | DEFAULT NOW() | Última actualización |

**Índices:**

- `idx_cuentas_activo` en `activo` WHERE activo = TRUE
- `idx_cuentas_moneda` en `moneda`

**Reglas de Negocio:**

- Solo etiquetas, NO controlan saldo
- Solo Admin y Supervisor pueden usarlas

---

### **9. PAGOS** (TABLA CORE)

**Propósito:** Tabla principal del sistema

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| proveedor_id | BIGINT | FK, NOT NULL | Proveedor |
| usuario_id | BIGINT | FK, NOT NULL | Usuario que registró |
| codigo_reserva | VARCHAR(100) | NOT NULL, UNIQUE | Código único |
| monto | DECIMAL(12,2) | NOT NULL | Monto del pago |
| moneda | tipo_moneda | NOT NULL | USD o CAD |
| descripcion | TEXT | NULL | Descripción |
| fecha_esperada_debito | DATE | NULL | Fecha esperada de débito |
| tipo_medio_pago | tipo_medio_pago | NOT NULL | TARJETA o CUENTA_BANCARIA |
| tarjeta_id | BIGINT | FK, NULL | Tarjeta usada |
| cuenta_bancaria_id | BIGINT | FK, NULL | Cuenta usada |
| **pagado** | **BOOLEAN** | **DEFAULT FALSE** | **Si fue confirmado** |
| **verificado** | **BOOLEAN** | **DEFAULT FALSE** | **Si fue verificado** |
| gmail_enviado | BOOLEAN | DEFAULT FALSE | Si se envió correo |
| **activo** | **BOOLEAN** | **DEFAULT TRUE** | **Soft delete** |
| fecha_pago | TIMESTAMPTZ | NULL | Cuándo se marcó como pagado |
| fecha_verificacion | TIMESTAMPTZ | NULL | Cuándo se verificó |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |
| fecha_actualizacion | TIMESTAMPTZ | DEFAULT NOW() | Última actualización |

**Relaciones:**

- `proveedor_id` → `proveedores.id` (N:1)
- `usuario_id` → `usuarios.id` (N:1)
- `tarjeta_id` → `tarjetas_credito.id` (N:1)
- `cuenta_bancaria_id` → `cuentas_bancarias.id` (N:1)

**Índices:**

- `idx_pagos_proveedor` en `proveedor_id`
- `idx_pagos_usuario` en `usuario_id`
- `idx_pagos_pagado` en `pagado`
- `idx_pagos_verificado` en `verificado`
- `idx_pagos_gmail_enviado` en `gmail_enviado`
- `idx_pagos_activo` en `activo` WHERE activo = TRUE
- `idx_pagos_codigo` en `codigo_reserva`
- `idx_pagos_correos_pendientes` en `(pagado, gmail_enviado, proveedor_id)` WHERE pagado = TRUE AND gmail_enviado = FALSE AND activo = TRUE

**Estados del Pago:**

```
REGISTRO → PAGADO → VERIFICADO
   ↓          ↓          ↓
[Usuario] [N8N/Admin] [N8N/Admin]

pagado=false → pagado=true → verificado=true
```

**Escenarios:**

1. **Solo FACTURA:**
   - pagado = TRUE
   - verificado = FALSE
2. **FACTURA + DOCUMENTO_BANCO:**
   - pagado = TRUE
   - verificado = TRUE
3. **Solo DOCUMENTO_BANCO:**
   - pagado = TRUE
   - verificado = TRUE

**Reglas de Negocio:**

- Solo un medio de pago (tarjeta O cuenta, no ambos)
- Si tarjeta: descuenta saldo automáticamente
- Si cuenta: solo registra, no descuenta
- No editar si verificado = TRUE
- Soft delete: activo = FALSE
- Un pago puede tener múltiples clientes (pago_cliente)
- Código de reserva único en todo el sistema

---

### **10. PAGO_CLIENTE**

**Propósito:** Relación N:N entre pagos y clientes

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PK, NOT NULL | ID autoincrementable |
| pago_id | BIGINT | FK, NOT NULL | Pago |
| cliente_id | BIGINT | FK, NOT NULL | Cliente |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |

**Relaciones:**

- `pago_id` → `pagos.id` (N:1) ON DELETE CASCADE
- `cliente_id` → `clientes.id` (N:1)

**Índices:**

- `idx_pago_cliente_pago` en `pago_id`
- `idx_pago_cliente_cliente` en `cliente_id`
- `uq_pago_cliente` UNIQUE en `(pago_id, cliente_id)`

---

### **11. DOCUMENTOS**

**Propósito:** Documentos de respaldo

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| usuario_id | BIGINT | FK, NOT NULL | Usuario que subió |
| pago_id | BIGINT | FK, NULL | Pago específico (FACTURA) |
| nombre_archivo | VARCHAR(255) | NOT NULL | Nombre del archivo |
| url_documento | TEXT | NOT NULL | URL del archivo |
| tipo_documento | tipo_documento | NOT NULL | FACTURA o DOCUMENTO_BANCO |
| fecha_subida | TIMESTAMPTZ | DEFAULT NOW() | Fecha de subida |

**Relaciones:**

- `usuario_id` → `usuarios.id` (N:1)
- `pago_id` → `pagos.id` (N:1) _opcional_

**Índices:**

- `idx_documentos_usuario` en `usuario_id`
- `idx_documentos_pago` en `pago_id`
- `idx_documentos_tipo` en `tipo_documento`
- `idx_documentos_fecha` en `fecha_subida DESC`

**Tipos de Documentos:**

**FACTURA:**

- Se puede vincular directamente a un pago (`pago_id` NOT NULL)
- N8N cambia: `pagado = TRUE`
- Procesa 1 pago a la vez

**DOCUMENTO_BANCO:**

- NO se vincula inicialmente (`pago_id = NULL`)
- N8N cambia: `pagado = TRUE` + `verificado = TRUE`
- Procesa múltiples pagos a la vez

---

### **12. DOCUMENTO_PAGO**

**Propósito:** Relación N:N entre documentos y pagos

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PK, NOT NULL | ID autoincrementable |
| documento_id | BIGINT | FK, NOT NULL | Documento |
| pago_id | BIGINT | FK, NOT NULL | Pago |
| fecha_vinculacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de vinculación |

**Relaciones:**

- `documento_id` → `documentos.id` (N:1) ON DELETE CASCADE
- `pago_id` → `pagos.id` (N:1) ON DELETE CASCADE

**Índices:**

- `idx_documento_pago_documento` en `documento_id`
- `idx_documento_pago_pago` en `pago_id`
- `uq_documento_pago` UNIQUE en `(documento_id, pago_id)`

---

### **13. ENVIOS_CORREOS**

**Propósito:** Correos generados y enviados

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| proveedor_id | BIGINT | FK, NOT NULL | Proveedor |
| correo_seleccionado | VARCHAR(255) | NOT NULL | Uno de los 4 correos |
| usuario_envio_id | BIGINT | FK, NOT NULL | Usuario que envía |
| asunto | VARCHAR(255) | NOT NULL | Asunto del correo |
| cuerpo | TEXT | NOT NULL | Contenido |
| estado | estado_correo | DEFAULT 'BORRADOR' | Estado |
| cantidad_pagos | INT | NOT NULL | Cantidad de pagos |
| monto_total | DECIMAL(12,2) | NOT NULL | Monto total |
| fecha_generacion | TIMESTAMPTZ | DEFAULT NOW() | Cuándo se generó |
| fecha_envio | TIMESTAMPTZ | NULL | Cuándo se envió |

**Relaciones:**

- `proveedor_id` → `proveedores.id` (N:1)
- `usuario_envio_id` → `usuarios.id` (N:1)

**Índices:**

- `idx_envios_proveedor` en `proveedor_id`
- `idx_envios_estado` en `estado`
- `idx_envios_fecha` en `fecha_envio DESC`

**Reglas de Negocio:**

- Se genera automáticamente cuando pagado = TRUE y gmail_enviado = FALSE
- Usuario selecciona 1 de los 4 correos del proveedor
- Se envía vía webhook N8N
- Admin, Supervisor y EQUIPO pueden enviar

---

### **14. ENVIO_CORREO_DETALLE**

**Propósito:** Detalle de pagos en cada correo

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PK, NOT NULL | ID autoincrementable |
| envio_id | BIGINT | FK, NOT NULL | Envío |
| pago_id | BIGINT | FK, NOT NULL | Pago |
| fecha_creacion | TIMESTAMPTZ | DEFAULT NOW() | Fecha de creación |

**Relaciones:**

- `envio_id` → `envios_correos.id` (N:1) ON DELETE CASCADE
- `pago_id` → `pagos.id` (N:1)

**Índices:**

- `idx_envio_detalle_envio` en `envio_id`
- `idx_envio_detalle_pago` en `pago_id`
- `uq_envio_pago` UNIQUE en `(envio_id, pago_id)`

---

### **15. EVENTOS**

**Propósito:** Auditoría completa

**Campos:**
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | BIGSERIAL | PK, NOT NULL | ID autoincrementable |
| usuario_id | BIGINT | FK, NULL | Usuario (null si sistema) |
| tipo_evento | tipo_evento | NOT NULL | Tipo de evento |
| entidad_tipo | VARCHAR(50) | NOT NULL | Tabla afectada |
| entidad_id | BIGINT | NULL | ID del registro |
| descripcion | TEXT | NOT NULL | Descripción |
| ip_origen | INET | NULL | IP del usuario |
| user_agent | TEXT | NULL | Navegador |
| fecha_evento | TIMESTAMPTZ | DEFAULT NOW() | Fecha del evento |

**Relaciones:**

- `usuario_id` → `usuarios.id` (N:1)

**Índices:**

- `idx_eventos_usuario` en `usuario_id`
- `idx_eventos_fecha` en `fecha_evento DESC`
- `idx_eventos_entidad` en `(entidad_tipo, entidad_id)`
- `idx_eventos_tipo` en `tipo_evento`

**Reglas de Negocio:**

- NUNCA se eliminan eventos
- Solo lectura para la mayoría de usuarios
- Solo Admin ve todos los eventos
- Recomendado: particionamiento por mes

---

## 🚀 FUNCIONES DE NEGOCIO

### **1. procesar_factura()**

Procesa un documento tipo FACTURA

```sql
SELECT * FROM procesar_factura(
  p_documento_id := 1,
  p_codigo_reserva := 'ABC123',
  p_pago_id := NULL  -- Opcional
);
```

**Retorna:** `(pago_id, codigo_reserva, pagado)`

---

### **2. verificar_pagos_por_documento()**

Procesa un documento tipo DOCUMENTO_BANCO

```sql
SELECT * FROM verificar_pagos_por_documento(
  p_documento_id := 1,
  p_codigos_encontrados := ARRAY['ABC123', 'DEF456', 'GHI789']
);
```

**Retorna:** `(pago_id, codigo_reserva, pagado, verificado)`

---

### **3. reset_mensual_tarjetas()**

Resetea el saldo de todas las tarjetas el día 1 del mes

```sql
SELECT * FROM reset_mensual_tarjetas();
```

**Retorna:** Cantidad de tarjetas reseteadas

---

## 📊 QUERIES COMUNES

### **Pagos pendientes de correo:**

```sql
SELECT * FROM pagos
WHERE pagado = TRUE
  AND gmail_enviado = FALSE
  AND activo = TRUE;
```

### **Pagos por verificar:**

```sql
SELECT * FROM pagos
WHERE pagado = TRUE
  AND verificado = FALSE
  AND activo = TRUE;
```

### **Listar solo activos:**

```sql
SELECT * FROM pagos WHERE activo = TRUE;
SELECT * FROM proveedores WHERE activo = TRUE;
SELECT * FROM tarjetas_credito WHERE activo = TRUE;
```

---

**Fin del Documento**  
**Versión:** 3.0 Final
