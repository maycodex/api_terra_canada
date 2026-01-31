# 🗺️ DIAGRAMA ENTIDAD-RELACIÓN - TERRA CANADA

**Versión:** 3.0 Final  
**Fecha:** 28 de Enero, 2026  
**IDs:** Autoincrementables (BIGSERIAL)

---

## 📊 DIAGRAMA COMPLETO (Mermaid)

```mermaid
erDiagram
    %% ========================================
    %% CATÁLOGOS
    %% ========================================

    roles ||--o{ usuarios : tiene
    servicios ||--o{ proveedores : ofrece

    roles {
        int id PK
        string nombre
        string descripcion
        timestamp fecha_creacion
    }

    servicios {
        int id PK
        string nombre
        string descripcion
        boolean activo
        timestamp fecha_creacion
    }

    %% ========================================
    %% USUARIOS
    %% ========================================

    usuarios {
        bigint id PK
        string nombre_usuario
        string correo
        string contrasena_hash
        string nombre_completo
        int rol_id FK
        string telefono
        boolean activo
        timestamp fecha_creacion
        timestamp fecha_actualizacion
    }

    usuarios ||--o{ pagos : registra
    usuarios ||--o{ documentos : sube
    usuarios ||--o{ envios_correos : envia
    usuarios ||--o{ eventos : genera

    %% ========================================
    %% PROVEEDORES
    %% ========================================

    proveedores {
        bigint id PK
        string nombre
        int servicio_id FK
        string lenguaje
        string telefono
        string descripcion
        boolean activo
        timestamp fecha_creacion
        timestamp fecha_actualizacion
    }

    proveedores ||--o{ proveedor_correos : tiene
    proveedores ||--o{ pagos : recibe
    proveedores ||--o{ envios_correos : recibe_notif

    proveedor_correos {
        int id PK
        bigint proveedor_id FK
        string correo
        boolean principal
        boolean activo
        timestamp fecha_creacion
    }

    %% ========================================
    %% CLIENTES
    %% ========================================

    clientes {
        bigint id PK
        string nombre
        string ubicacion
        string telefono
        string correo
        boolean activo
        timestamp fecha_creacion
        timestamp fecha_actualizacion
    }

    clientes ||--o{ pago_cliente : usa_servicios

    %% ========================================
    %% MEDIOS DE PAGO
    %% ========================================

    tarjetas_credito {
        bigint id PK
        string nombre_titular
        string ultimos_4_digitos
        enum moneda
        decimal limite_mensual
        decimal saldo_disponible
        string tipo_tarjeta
        boolean activo
        timestamp fecha_creacion
        timestamp fecha_actualizacion
    }

    cuentas_bancarias {
        bigint id PK
        string nombre_banco
        string nombre_cuenta
        string ultimos_4_digitos
        enum moneda
        boolean activo
        timestamp fecha_creacion
        timestamp fecha_actualizacion
    }

    tarjetas_credito ||--o{ pagos : paga_con
    cuentas_bancarias ||--o{ pagos : paga_con

    %% ========================================
    %% PAGOS (CORE)
    %% ========================================

    pagos {
        bigint id PK
        bigint proveedor_id FK
        bigint usuario_id FK
        string codigo_reserva UNIQUE
        decimal monto
        enum moneda
        string descripcion
        date fecha_esperada_debito
        enum tipo_medio_pago
        bigint tarjeta_id FK
        bigint cuenta_bancaria_id FK
        boolean pagado
        boolean verificado
        boolean gmail_enviado
        boolean activo
        timestamp fecha_pago
        timestamp fecha_verificacion
        timestamp fecha_creacion
        timestamp fecha_actualizacion
    }

    pagos ||--o{ pago_cliente : tiene
    pagos ||--o{ documento_pago : tiene_docs
    pagos ||--o{ envio_correo_detalle : notificado_en

    pago_cliente {
        int id PK
        bigint pago_id FK
        bigint cliente_id FK
        timestamp fech_creacion
    }

    %% ========================================
    %% DOCUMENTOS
    %% ========================================

    documentos {
        bigint id PK
        bigint usuario_id FK
        bigint pago_id FK
        string nombre_archivo
        string url_documento
        enum tipo_documento
        timestamp fecha_subida
    }

    documentos ||--o{ documento_pago : vincula

    documento_pago {
        int id PK
        bigint documento_id FK
        bigint pago_id FK
        timestamp fecha_vinculacion
    }

    %% ========================================
    %% CORREOS
    %% ========================================

    envios_correos {
        bigint id PK
        bigint proveedor_id FK
        string correo_seleccionado
        bigint usuario_envio_id FK
        string asunto
        text cuerpo
        enum estado
        int cantidad_pagos
        decimal monto_total
        timestamp fecha_generacion
        timestamp fecha_envio
    }

    envios_correos ||--o{ envio_correo_detalle : contiene

    envio_correo_detalle {
        int id PK
        bigint envio_id FK
        bigint pago_id FK
        timestamp fecha_creacion
    }

    %% ========================================
    %% AUDITORÍA
    %% ========================================

    eventos {
        bigint id PK
        bigint usuario_id FK
        enum tipo_evento
        string entidad_tipo
        bigint entidad_id
        text descripcion
        inet ip_origen
        text user_agent
        timestamp fecha_evento
    }
```

---

## 🔑 LEYENDA DE RELACIONES

### **Cardinalidad:**

- `||--o{` : Uno a Muchos (1:N)
- `}o--o{` : Muchos a Muchos (N:N) a través de tabla intermedia

### **Relaciones Principales:**

#### **1. roles → usuarios (1:N)**

- Un rol tiene muchos usuarios
- Un usuario tiene un rol

#### **2. servicios → proveedores (1:N)**

- Un servicio tiene muchos proveedores
- Un proveedor ofrece un servicio

#### **3. proveedores → proveedor_correos (1:N)**

- Un proveedor tiene hasta 4 correos
- Un correo pertenece a un proveedor

#### **4. pagos → pago_cliente → clientes (N:N)**

- Un pago puede tener múltiples clientes
- Un cliente puede estar en múltiples pagos

#### **5. documentos → documento_pago → pagos (N:N)**

- Un documento puede vincularse a múltiples pagos
- Un pago puede tener múltiples documentos

#### **6. envios_correos → envio_correo_detalle → pagos (N:N)**

- Un correo contiene múltiples pagos
- Un pago puede estar en UN solo correo

---

## 📋 TABLAS POR CATEGORÍA

### **Catálogos (Maestros):**

1. roles
2. servicios

### **Transaccionales:**

3. usuarios
4. proveedores
5. clientes
6. tarjetas_credito
7. cuentas_bancarias
8. **pagos** ← TABLA CORE

### **Intermedias (N:N):**

9. proveedor_correos
10. pago_cliente
11. documento_pago
12. envio_correo_detalle

### **Soporte:**

13. documentos
14. envios_correos

### **Auditoría:**

15. eventos

**Total:** 15 tablas

---

## 🎯 FLUJO DE DATOS

```
┌─────────────┐
│  USUARIO    │
└──────┬──────┘
       │
       │ registra
       ▼
┌─────────────────────┐
│  PAGO              │◄────── vincula ──────┐
│                     │                       │
│  • pagado=false    │     ┌──────────────┐  │
│  • verificado=false│     │ DOCUMENTO    │  │
│  • activo=true     │     │              │  │
└──────┬──────────────┘     │ • FACTURA    │──┘
       │                    │ • DOC_BANCO  │
       │                    └──────────────┘
       │ usa
       ▼
┌──────────────────┐
│  TARJETA/CUENTA  │
└──────────────────┘
       │
       │ descuenta (si tarjeta)
       ▼
┌──────────────────┐
│  SALDO           │
└──────────────────┘
       │
       │ cuando pagado=TRUE
       ▼
┌──────────────────┐
│  CORREO          │
└──────────────────┘
```

---

## 🔗 INTEGRIDAD REFERENCIAL

### **ON DELETE CASCADE:**

- proveedor_correos.proveedor_id
- pago_cliente.pago_id
- documento_pago.documento_id
- documento_pago.pago_id
- envio_correo_detalle.envio_id

### **ON UPDATE CASCADE:**

- Todas las Foreign Keys

---

## 📊 ÍNDICES CRÍTICOS

### **Pagos (tabla más consultada):**

```sql
idx_pagos_proveedor      (proveedor_id)
idx_pagos_pagado         (pagado)
idx_pagos_verificado     (verificado)
idx_pagos_activo         (activo) WHERE activo = TRUE
idx_pagos_correos_pend   (pagado, gmail_enviado, proveedor_id)
```

### **Otros índices importantes:**

```sql
idx_usuarios_correo      (correo)
idx_proveedores_servicio (servicio_id)
idx_documentos_tipo      (tipo_documento)
idx_eventos_fecha        (fecha_evento DESC)
```

---

## 🎨 CONVENCIONES

### **Nombres:**

- Tablas: plural, minúsculas, snake_case (`tarjetas_credito`)
- Columnas: snake_case (`nombre_usuario`)
- FKs: `{tabla}_id` (`proveedor_id`)
- Índices: `idx_{tabla}_{columna}` (`idx_pagos_proveedor`)

### **Tipos:**

- IDs: BIGSERIAL (autoincrementable)
- Money: DECIMAL(12,2)
- Texto corto: VARCHAR(n)
- Texto largo: TEXT
- Flags: BOOLEAN
- Fechas: TIMESTAMPTZ

### **Soft Delete:**

- Campo: `activo BOOLEAN DEFAULT TRUE`
- Nunca hacer DELETE, usar: `UPDATE ... SET activo = FALSE`

---

**Fin del Diagrama**  
**Versión:** 3.0 Final
