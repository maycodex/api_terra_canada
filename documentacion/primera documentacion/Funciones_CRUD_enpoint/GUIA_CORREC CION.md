# 🔧 GUÍA COMPLETA DE CORRECCIÓN - FUNCIONES GET

**Error:** GROUP BY con json_agg  
**Archivos Afectados:** TODOS los \*\_crud.sql  
**Solución:** Mover json_agg a subconsulta

---

## 📝 PATRÓN DE CORRECCIÓN

### **❌ ANTES (INCORRECTO):**

```sql
-- Patrón que CAUSA el error
SELECT json_build_object(
    'code', 200,
    'estado', true,
    'message', 'Datos obtenidos',
    'data', COALESCE(json_agg(
        json_build_object(
            'id', id,
            'campo1', campo1,
            'campo2', campo2
        )
    ), '[]'::json)
) INTO v_result
FROM tabla
ORDER BY id;  -- ❌ ERROR AQUÍ
```

**Problema:** El `ORDER BY` fuera de `json_agg` requiere `GROUP BY`, pero `json_build_object` no puede agruparse.

---

### **✅ DESPUÉS (CORRECTO):**

```sql
-- Patrón CORRECTO
SELECT json_build_object(
    'code', 200,
    'estado', true,
    'message', 'Datos obtenidos',
    'data', COALESCE(
        (SELECT json_agg(           -- ✅ Subconsulta
            json_build_object(
                'id', id,
                'campo1', campo1,
                'campo2', campo2
            )
            ORDER BY id             -- ✅ ORDER BY dentro
        ) FROM tabla),
        '[]'::json
    )
) INTO v_result;                    -- ✅ Sin FROM aquí
```

---

## 🔄 CORRECCIONES POR ARCHIVO

### **✅ 1. roles_crud.sql - CORREGIDO**

**Línea 13-29:**

```sql
-- ANTES
SELECT json_build_object(...,
    'data', COALESCE(json_agg(...), '[]'::json)
) INTO v_result
FROM roles
ORDER BY id;

-- DESPUÉS
SELECT json_build_object(...,
    'data', COALESCE(
        (SELECT json_agg(...) ORDER BY id FROM roles),
        '[]'::json
    )
) INTO v_result;
```

**Cambio adicional línea 46:**

```sql
-- ANTES
IF v_result IS NULL THEN

-- DESPUÉS
IF NOT FOUND THEN
```

---

### **⚠️ 2. servicios_crud.sql - PENDIENTE**

**Línea ~15-30:** Aplicar mismo patrón que roles

```sql
SELECT json_build_object(...,
    'data', COALESCE(
        (SELECT json_agg(...) ORDER BY id FROM servicios),
        '[]'::json
    )
) INTO v_result;
```

---

### **⚠️ 3. usuarios_crud.sql - PENDIENTE**

**Línea ~15-35:** Con JOIN a roles

```sql
SELECT json_build_object(...,
    'data', COALESCE(
        (SELECT json_agg(...)
         ORDER BY u.id
         FROM usuarios u
         JOIN roles r ON u.rol_id = r.id),
        '[]'::json
    )
) INTO v_result;
```

---

### **⚠️ 4. proveedores_crud.sql - PENDIENTE**

**Múltiples lugares:**

1. GET todos (línea ~15-45) con JOIN a servicios
2. GET con correos anidados (línea ~60-90)

```sql
-- GET todos los proveedores
SELECT json_build_object(...,
    'data', COALESCE(
        (SELECT json_agg(...)
         ORDER BY p.nombre
         FROM proveedores p
         JOIN servicios s ON p.servicio_id = s.id),
        '[]'::json
    )
) INTO v_result;

-- GET proveedor con correos anidados
... 'correos', COALESCE(
    (SELECT json_agg(...)
     ORDER BY pc.principal DESC
     FROM proveedor_correos pc
     WHERE pc.proveedor_id = p.id),
    '[]'::json
) ...
```

---

### **⚠️ 5. proveedor_correos_crud.sql - PENDIENTE**

Ya lo explicaste. **2 lugares:**

1. **GET por proveedor** (línea ~46-60):

```sql
SELECT json_build_object(...,
    'data', COALESCE(
        (SELECT json_agg(...)
         ORDER BY pc.principal DESC, pc.id
         FROM proveedor_correos pc
         WHERE pc.proveedor_id = p_proveedor_id),
        '[]'::json
    )
) INTO v_result;
```

2. **GET todos** (línea ~62-82):

```sql
SELECT json_build_object(...,
    'data', COALESCE(
        (SELECT json_agg(...)
         ORDER BY p.nombre, pc.principal DESC
         FROM proveedor_correos pc
         JOIN proveedores p ON pc.proveedor_id = p.id),
        '[]'::json
    )
) INTO v_result;
```

---

### **⚠️ 6. clientes_crud.sql - PENDIENTE**

Similar a roles/servicios.

---

### **⚠️ 7. tarjetas_credito_crud.sql - PENDIENTE**

Similar a roles/servicios.

---

### **⚠️ 8. cuentas_bancarias_crud.sql - PENDIENTE**

Similar a roles/servicios.

---

### **⚠️ 9. pagos_crud_part1.sql - PENDIENTE**

**COMPLEJO:** Múltiples JOINs y subconsultas anidadas.

```sql
SELECT json_build_object(...,
    'data', COALESCE(
        (SELECT json_agg(json_build_object(
            'id', p.id,
            ...
            'clientes', (SELECT json_agg(...) FROM pago_cliente pc ...),
            'documentos', (SELECT json_agg(...) FROM documento_pago dp ...)
        ))
        ORDER BY p.fecha_creacion DESC
        FROM pagos p
        JOIN proveedores pr ON p.proveedor_id = pr.id
        JOIN usuarios u ON p.usuario_id = u.id
        ...),
        '[]'::json
    )
) INTO v_result;
```

---

### **⚠️ 10. documentos_crud.sql - PENDIENTE**

Con JOIN a usuarios y posible pago.

---

### **⚠️ 11. envios_correos_crud.sql - PENDIENTE**

Con subconsultas anidadas para detalles.

---

### **⚠️ 12. eventos_crud.sql - PENDIENTE**

**MÚLTIPLES LUGARES** (4 funciones GET diferentes):

- eventos_get()
- eventos_get_by_usuario()
- eventos_get_by_entidad()
- eventos_get_by_tipo()

---

## 🤖 SCRIPT DE CORRECCIÓN AUTOMÁTICA

```bash
# Para cada archivo
for file in *_crud.sql; do
    # Backup
    cp "$file" "$file.bak"

    # Aplicar corrección
    # (requiere herramienta de refactoring SQL)
done
```

---

## ✅ CHECKLIST DE CORRECCIÓN

- [x] 01_roles_crud.sql
- [ ] 02_servicios_crud.sql
- [ ] 03_usuarios_crud.sql
- [ ] 04_proveedores_crud.sql
- [ ] 05_proveedor_correos_crud.sql
- [ ] 06_clientes_crud.sql
- [ ] 07_tarjetas_credito_crud.sql
- [ ] 08_cuentas_bancarias_crud.sql
- [ ] 09_pagos_crud_part1.sql
- [ ] 09_pagos_crud_part2.sql
- [ ] 09_pagos_crud_part3.sql
- [ ] 10_documentos_crud.sql
- [ ] 11_envios_correos_crud.sql
- [ ] 12_eventos_crud.sql

---

## 📊 RESUMEN

**Total archivos:** 14  
**Corregidos:** 1  
**Pendientes:** 13  
**Instancias de error encontradas:** ~25

---

**Siguiente:** Aplicar corrección automáticamente a todos los archivos.
