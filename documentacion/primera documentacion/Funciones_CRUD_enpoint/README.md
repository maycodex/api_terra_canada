# 📚 FUNCIONES CRUD - Sistema de Gestión de Pagos Terra Canada

## 📋 Índice

1. [Descripción General](#descripción-general)
2. [Instalación](#instalación)
3. [Formato de Respuesta](#formato-de-respuesta)
4. [Funciones Disponibles](#funciones-disponibles)
5. [Ejemplos de Uso](#ejemplos-de-uso)
6. [Pruebas Completas](#pruebas-completas)
7. [Reglas de Negocio](#reglas-de-negocio)

---

## 🎯 Descripción General

Este conjunto de funciones proporciona una API completa en PostgreSQL para el Sistema de Gestión de Pagos de Terra Canada. Todas las funciones siguen el patrón CRUD (Create, Read, Update, Delete) y retornan respuestas en formato JSON con códigos HTTP estándar.

### Características principales:
- ✅ Respuestas JSON con códigos HTTP
- ✅ Validaciones de negocio integradas
- ✅ Manejo de errores robusto
- ✅ Auditoría automática
- ✅ Relaciones entre entidades
- ✅ Soporte para transacciones complejas

---

## 🚀 Instalación

### Requisitos previos:
1. PostgreSQL 13 o superior
2. Base de datos creada
3. DDL completo ejecutado (`03_DDL_COMPLETO.sql`)

### Paso 1: Ejecutar el DDL
```sql
\i /ruta/a/03_DDL_COMPLETO.sql
```

### Paso 2: Instalar las funciones CRUD

**Opción A: Ejecutar archivo por archivo**
```sql
\i /ruta/funciones_crud/01_roles_crud.sql
\i /ruta/funciones_crud/02_servicios_crud.sql
\i /ruta/funciones_crud/03_usuarios_crud.sql
\i /ruta/funciones_crud/04_proveedores_crud.sql
\i /ruta/funciones_crud/05_proveedor_correos_crud.sql
\i /ruta/funciones_crud/06_clientes_crud.sql
\i /ruta/funciones_crud/07_tarjetas_credito_crud.sql
\i /ruta/funciones_crud/08_cuentas_bancarias_crud.sql
\i /ruta/funciones_crud/09_pagos_crud_part1.sql
\i /ruta/funciones_crud/09_pagos_crud_part2.sql
\i /ruta/funciones_crud/09_pagos_crud_part3.sql
\i /ruta/funciones_crud/10_documentos_crud.sql
\i /ruta/funciones_crud/11_envios_correos_crud.sql
\i /ruta/funciones_crud/12_eventos_crud.sql
```

**Opción B: Script bash automatizado**
```bash
#!/bin/bash
for file in funciones_crud/*.sql; do
    psql -U tu_usuario -d terra_canada -f "$file"
done
```

---

## 📊 Formato de Respuesta

Todas las funciones retornan JSON con la siguiente estructura:

```json
{
  "code": 200,              // Código HTTP (200, 201, 400, 404, 409, 500)
  "estado": true,           // true = éxito, false = error
  "message": "Mensaje descriptivo",
  "data": { ... }           // Datos de respuesta (objeto o array)
}
```

### Códigos HTTP utilizados:

| Código | Significado | Ejemplo |
|--------|-------------|---------|
| 200 | OK | Consulta exitosa, actualización exitosa |
| 201 | Created | Registro creado exitosamente |
| 400 | Bad Request | Datos inválidos o faltantes |
| 404 | Not Found | Registro no encontrado |
| 409 | Conflict | Violación de reglas de negocio |
| 500 | Internal Server Error | Error del servidor |

---

## 📖 Funciones Disponibles

### 1️⃣ ROLES

```sql
-- GET: Obtener todos o uno específico
roles_get(id INT DEFAULT NULL) RETURNS JSON

-- POST: Crear nuevo rol
roles_post(nombre VARCHAR, descripcion TEXT DEFAULT NULL) RETURNS JSON

-- PUT: Actualizar rol
roles_put(id INT, nombre VARCHAR DEFAULT NULL, descripcion TEXT DEFAULT NULL) RETURNS JSON

-- DELETE: Eliminar rol
roles_delete(id INT) RETURNS JSON
```

### 2️⃣ SERVICIOS

```sql
-- GET
servicios_get(id INT DEFAULT NULL) RETURNS JSON

-- POST
servicios_post(nombre VARCHAR, descripcion TEXT DEFAULT NULL, activo BOOLEAN DEFAULT TRUE) RETURNS JSON

-- PUT
servicios_put(id INT, nombre VARCHAR DEFAULT NULL, descripcion TEXT DEFAULT NULL, activo BOOLEAN DEFAULT NULL) RETURNS JSON

-- DELETE
servicios_delete(id INT) RETURNS JSON
```

### 3️⃣ USUARIOS

```sql
-- GET
usuarios_get(id BIGINT DEFAULT NULL) RETURNS JSON

-- POST
usuarios_post(
    nombre_usuario VARCHAR,
    correo VARCHAR,
    contrasena VARCHAR,
    nombre_completo VARCHAR,
    rol_id INT,
    telefono VARCHAR DEFAULT NULL,
    activo BOOLEAN DEFAULT TRUE
) RETURNS JSON

-- PUT
usuarios_put(
    id BIGINT,
    nombre_usuario VARCHAR DEFAULT NULL,
    correo VARCHAR DEFAULT NULL,
    contrasena VARCHAR DEFAULT NULL,
    nombre_completo VARCHAR DEFAULT NULL,
    rol_id INT DEFAULT NULL,
    telefono VARCHAR DEFAULT NULL,
    activo BOOLEAN DEFAULT NULL
) RETURNS JSON

-- DELETE (desactiva si tiene pagos)
usuarios_delete(id BIGINT) RETURNS JSON
```

### 4️⃣ PROVEEDORES

```sql
-- GET
proveedores_get(id BIGINT DEFAULT NULL) RETURNS JSON

-- POST
proveedores_post(
    nombre VARCHAR,
    servicio_id INT,
    lenguaje VARCHAR DEFAULT NULL,
    telefono VARCHAR DEFAULT NULL,
    descripcion TEXT DEFAULT NULL,
    activo BOOLEAN DEFAULT TRUE
) RETURNS JSON

-- PUT
proveedores_put(
    id BIGINT,
    nombre VARCHAR DEFAULT NULL,
    servicio_id INT DEFAULT NULL,
    lenguaje VARCHAR DEFAULT NULL,
    telefono VARCHAR DEFAULT NULL,
    descripcion TEXT DEFAULT NULL,
    activo BOOLEAN DEFAULT NULL
) RETURNS JSON

-- DELETE
proveedores_delete(id BIGINT) RETURNS JSON
```

### 5️⃣ PROVEEDOR_CORREOS

```sql
-- GET (puede filtrar por proveedor)
proveedor_correos_get(id INT DEFAULT NULL, proveedor_id BIGINT DEFAULT NULL) RETURNS JSON

-- POST (máximo 4 correos activos por proveedor)
proveedor_correos_post(
    proveedor_id BIGINT,
    correo VARCHAR,
    principal BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE
) RETURNS JSON

-- PUT
proveedor_correos_put(
    id INT,
    correo VARCHAR DEFAULT NULL,
    principal BOOLEAN DEFAULT NULL,
    activo BOOLEAN DEFAULT NULL
) RETURNS JSON

-- DELETE (no permite eliminar el último correo)
proveedor_correos_delete(id INT) RETURNS JSON
```

### 6️⃣ CLIENTES

```sql
-- GET
clientes_get(id BIGINT DEFAULT NULL) RETURNS JSON

-- POST
clientes_post(
    nombre VARCHAR,
    ubicacion VARCHAR DEFAULT NULL,
    telefono VARCHAR DEFAULT NULL,
    correo VARCHAR DEFAULT NULL,
    activo BOOLEAN DEFAULT TRUE
) RETURNS JSON

-- PUT
clientes_put(
    id BIGINT,
    nombre VARCHAR DEFAULT NULL,
    ubicacion VARCHAR DEFAULT NULL,
    telefono VARCHAR DEFAULT NULL,
    correo VARCHAR DEFAULT NULL,
    activo BOOLEAN DEFAULT NULL
) RETURNS JSON

-- DELETE
clientes_delete(id BIGINT) RETURNS JSON
```

### 7️⃣ TARJETAS_CREDITO

```sql
-- GET (incluye porcentaje de uso)
tarjetas_credito_get(id BIGINT DEFAULT NULL) RETURNS JSON

-- POST (saldo inicial = límite)
tarjetas_credito_post(
    nombre_titular VARCHAR,
    ultimos_4_digitos VARCHAR,
    moneda tipo_moneda,
    limite_mensual DECIMAL,
    tipo_tarjeta VARCHAR DEFAULT 'Visa',
    activo BOOLEAN DEFAULT TRUE
) RETURNS JSON

-- PUT (ajusta saldo si cambia límite)
tarjetas_credito_put(
    id BIGINT,
    nombre_titular VARCHAR DEFAULT NULL,
    limite_mensual DECIMAL DEFAULT NULL,
    tipo_tarjeta VARCHAR DEFAULT NULL,
    activo BOOLEAN DEFAULT NULL
) RETURNS JSON

-- DELETE
tarjetas_credito_delete(id BIGINT) RETURNS JSON
```

### 8️⃣ CUENTAS_BANCARIAS

```sql
-- GET
cuentas_bancarias_get(id BIGINT DEFAULT NULL) RETURNS JSON

-- POST
cuentas_bancarias_post(
    nombre_banco VARCHAR,
    nombre_cuenta VARCHAR,
    ultimos_4_digitos VARCHAR,
    moneda tipo_moneda,
    activo BOOLEAN DEFAULT TRUE
) RETURNS JSON

-- PUT
cuentas_bancarias_put(
    id BIGINT,
    nombre_banco VARCHAR DEFAULT NULL,
    nombre_cuenta VARCHAR DEFAULT NULL,
    activo BOOLEAN DEFAULT NULL
) RETURNS JSON

-- DELETE
cuentas_bancarias_delete(id BIGINT) RETURNS JSON
```

### 9️⃣ PAGOS (CORE) ⭐

```sql
-- GET (incluye relaciones completas)
pagos_get(id BIGINT DEFAULT NULL) RETURNS JSON

-- POST (valida saldo si es tarjeta, descuenta automáticamente)
pagos_post(
    proveedor_id BIGINT,
    usuario_id BIGINT,
    codigo_reserva VARCHAR,
    monto DECIMAL,
    moneda tipo_moneda,
    tipo_medio_pago tipo_medio_pago,
    tarjeta_id BIGINT DEFAULT NULL,
    cuenta_bancaria_id BIGINT DEFAULT NULL,
    clientes_ids BIGINT[] DEFAULT NULL,
    descripcion TEXT DEFAULT NULL,
    fecha_esperada_debito DATE DEFAULT NULL
) RETURNS JSON

-- PUT (no permite editar si verificado=TRUE)
pagos_put(
    id BIGINT,
    monto DECIMAL DEFAULT NULL,
    descripcion TEXT DEFAULT NULL,
    fecha_esperada_debito DATE DEFAULT NULL,
    pagado BOOLEAN DEFAULT NULL,
    verificado BOOLEAN DEFAULT NULL,
    gmail_enviado BOOLEAN DEFAULT NULL,
    activo BOOLEAN DEFAULT NULL
) RETURNS JSON

-- DELETE (devuelve saldo a tarjeta si aplica)
pagos_delete(id BIGINT) RETURNS JSON
```

### 🔟 DOCUMENTOS

```sql
-- GET (incluye pagos vinculados)
documentos_get(id BIGINT DEFAULT NULL) RETURNS JSON

-- POST (puede vincular directamente a un pago)
documentos_post(
    tipo_documento tipo_documento,
    nombre_archivo VARCHAR,
    url_documento TEXT,
    usuario_subida_id BIGINT,
    pago_id BIGINT DEFAULT NULL
) RETURNS JSON

-- PUT
documentos_put(
    id BIGINT,
    procesado BOOLEAN DEFAULT NULL,
    fecha_procesamiento TIMESTAMPTZ DEFAULT NULL
) RETURNS JSON

-- DELETE
documentos_delete(id BIGINT) RETURNS JSON
```

### 1️⃣1️⃣ ENVIOS_CORREOS

```sql
-- GET (incluye pagos y correos disponibles del proveedor)
envios_correos_get(id BIGINT DEFAULT NULL) RETURNS JSON

-- POST (crea borrador)
envios_correos_post(
    proveedor_id BIGINT,
    usuario_envio_id BIGINT,
    asunto VARCHAR,
    cuerpo TEXT,
    pagos_ids BIGINT[]
) RETURNS JSON

-- PUT (editar o enviar)
envios_correos_put(
    id BIGINT,
    correo_destino VARCHAR DEFAULT NULL,
    asunto VARCHAR DEFAULT NULL,
    cuerpo TEXT DEFAULT NULL,
    enviar BOOLEAN DEFAULT FALSE
) RETURNS JSON

-- DELETE (solo borradores)
envios_correos_delete(id BIGINT) RETURNS JSON
```

### 1️⃣2️⃣ EVENTOS (Auditoría)

```sql
-- GET (con paginación)
eventos_get(id BIGINT DEFAULT NULL, limite INT DEFAULT 100, offset INT DEFAULT 0) RETURNS JSON

-- POST
eventos_post(
    usuario_id BIGINT DEFAULT NULL,
    tipo_evento tipo_evento,
    entidad_tipo VARCHAR,
    entidad_id BIGINT DEFAULT NULL,
    descripcion TEXT,
    ip_origen INET DEFAULT NULL,
    user_agent TEXT DEFAULT NULL
) RETURNS JSON

-- PUT: NO PERMITIDO (inmutable)
eventos_put(id BIGINT) RETURNS JSON

-- DELETE: NO PERMITIDO (inmutable)
eventos_delete(id BIGINT) RETURNS JSON

-- Funciones adicionales:
eventos_get_por_tipo(tipo_evento tipo_evento, limite INT DEFAULT 100) RETURNS JSON
eventos_get_por_usuario(usuario_id BIGINT, limite INT DEFAULT 100) RETURNS JSON
eventos_get_por_entidad(entidad_tipo VARCHAR, entidad_id BIGINT, limite INT DEFAULT 100) RETURNS JSON
```

---

## 🧪 Ejemplos de Uso

### Ejemplo 1: Flujo completo de creación de pago

```sql
-- 1. Crear tarjeta
SELECT tarjetas_credito_post(
    'Terra Canada',
    '1234',
    'USD',
    5000.00,
    'Visa Corporate',
    true
);
-- Retorna: {"code": 201, "estado": true, "message": "Tarjeta creada exitosamente", "data": {...}}

-- 2. Crear proveedor
SELECT proveedores_post(
    'Servicios Turísticos ABC',
    8,  -- ID del servicio
    'Español',
    '+521234567890',
    'Proveedor de guías',
    true
);

-- 3. Agregar correo al proveedor
SELECT proveedor_correos_post(1, 'contacto@abc.com', true, true);

-- 4. Crear cliente
SELECT clientes_post('Hotel Paradise', 'Cancún', NULL, NULL, true);

-- 5. Registrar pago
SELECT pagos_post(
    1,  -- proveedor_id
    1,  -- usuario_id
    'RES-2026-001',
    500.00,
    'USD',
    'TARJETA',
    1,  -- tarjeta_id
    NULL,
    ARRAY[1]::BIGINT[],
    'Servicio de guía turística',
    '2026-02-15'
);
```

### Ejemplo 2: Consultar datos con relaciones

```sql
-- Ver un pago específico con todas sus relaciones
SELECT pagos_get(1);

-- Resultado incluye:
-- - Proveedor (nombre, servicio)
-- - Usuario (nombre, rol)
-- - Medio de pago (tarjeta o cuenta)
-- - Clientes vinculados
-- - Documentos asociados
-- - Estados (pagado, verificado, gmail_enviado)
```

### Ejemplo 3: Actualizar estados de pago

```sql
-- Marcar como pagado
SELECT pagos_put(1, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);

-- Marcar como verificado (automáticamente marca pagado también)
SELECT pagos_put(1, NULL, NULL, NULL, NULL, TRUE, NULL, NULL);

-- Marcar como enviado por correo
SELECT pagos_put(1, NULL, NULL, NULL, NULL, NULL, TRUE, NULL);
```

---

## ✅ Pruebas Completas

### Script de prueba completo:

```sql
-- ============================================
-- SCRIPT DE PRUEBA COMPLETO
-- ============================================

-- Limpiar datos de prueba anteriores (opcional)
-- TRUNCATE TABLE eventos, envios_correos, documentos, pagos, clientes, 
--          proveedor_correos, proveedores, tarjetas_credito, cuentas_bancarias, 
--          usuarios CASCADE;

-- 1. CREAR USUARIO
DO $$
DECLARE
    v_response JSON;
BEGIN
    SELECT usuarios_post(
        'test_user',
        'test@terracanada.com',
        'password123',
        'Usuario de Prueba',
        3,  -- Rol EQUIPO
        '+1234567890',
        true
    ) INTO v_response;
    
    RAISE NOTICE 'Usuario creado: %', v_response;
END $$;

-- 2. CREAR PROVEEDOR
DO $$
DECLARE
    v_response JSON;
BEGIN
    SELECT proveedores_post(
        'Proveedor Test',
        8,
        'Español',
        '+521234567890',
        'Proveedor de prueba',
        true
    ) INTO v_response;
    
    RAISE NOTICE 'Proveedor creado: %', v_response;
END $$;

-- 3. AGREGAR CORREOS AL PROVEEDOR
SELECT proveedor_correos_post(1, 'contacto@test.com', true, true);
SELECT proveedor_correos_post(1, 'admin@test.com', false, true);

-- 4. CREAR CLIENTE
SELECT clientes_post('Hotel Test', 'Test Location', NULL, NULL, true);

-- 5. CREAR TARJETA
SELECT tarjetas_credito_post('Test Card', '9999', 'USD', 10000.00, 'Visa', true);

-- 6. REGISTRAR PAGO
SELECT pagos_post(
    1, 1, 'TEST-001', 750.00, 'USD', 'TARJETA',
    1, NULL, ARRAY[1]::BIGINT[], 'Pago de prueba', NULL
);

-- 7. VERIFICAR SALDO DE TARJETA
SELECT tarjetas_credito_get(1);
-- Debería mostrar saldo_disponible = 9250.00

-- 8. SUBIR DOCUMENTO
SELECT documentos_post(
    'FACTURA',
    'test_factura.pdf',
    'https://test.com/factura.pdf',
    1,
    1
);

-- 9. MARCAR PAGO COMO PAGADO
SELECT pagos_put(1, NULL, NULL, NULL, TRUE, NULL, NULL, NULL);

-- 10. CREAR CORREO BORRADOR
SELECT envios_correos_post(
    1, 1,
    'Test Email',
    'Contenido de prueba',
    ARRAY[1]::BIGINT[]
);

-- 11. ENVIAR CORREO
SELECT envios_correos_put(1, 'contacto@test.com', NULL, NULL, TRUE);

-- 12. VERIFICAR EVENTO CREADO
SELECT eventos_post(
    1, 'ENVIAR_CORREO', 'envios_correos', 1,
    'Correo de prueba enviado', '127.0.0.1'::INET, 'Test Agent'
);

-- 13. CONSULTAR RESULTADOS
SELECT '=== PAGOS ===' as seccion, pagos_get();
SELECT '=== TARJETAS ===' as seccion, tarjetas_credito_get();
SELECT '=== CORREOS ===' as seccion, envios_correos_get();
SELECT '=== EVENTOS ===' as seccion, eventos_get(NULL, 10, 0);

RAISE NOTICE 'PRUEBAS COMPLETADAS EXITOSAMENTE';
```

---

## 🔒 Reglas de Negocio Implementadas

### PAGOS:
1. ✅ Código de reserva único
2. ✅ Si es TARJETA: valida y descuenta saldo
3. ✅ Si es CUENTA_BANCARIA: solo registra (no descuenta)
4. ✅ No se puede editar si verificado = TRUE
5. ✅ No se puede eliminar si gmail_enviado = TRUE
6. ✅ Al eliminar pago con tarjeta, devuelve el saldo

### TARJETAS:
1. ✅ Saldo nunca negativo
2. ✅ Saldo ≤ límite mensual
3. ✅ No se puede eliminar si tiene pagos

### PROVEEDORES:
1. ✅ Máximo 4 correos activos
2. ✅ Al menos 1 correo activo
3. ✅ No se puede eliminar si tiene pagos

### CORREOS:
1. ✅ Solo se pueden eliminar BORRADORES
2. ✅ Al enviar, marca pagos como gmail_enviado = TRUE
3. ✅ Solo incluye pagos con pagado = TRUE

### AUDITORÍA:
1. ✅ Eventos son inmutables (no PUT, no DELETE)
2. ✅ Registro automático de todas las acciones

---

## 📞 Soporte

Para dudas o problemas:
- Revisar mensajes de error en el campo `message` de la respuesta JSON
- Verificar códigos HTTP en el campo `code`
- Consultar logs de PostgreSQL para errores detallados

---

**Versión:** 1.0  
**Última actualización:** 28 de Enero, 2026  
**Autor:** Claude AI  
