# 🔧 CORRECCIONES APLICADAS - FUNCIONES CRUD

**Fecha:** 28 de Enero, 2026  
**Error Corregido:** GROUP BY en funciones con json_agg

---

## 🐛 PROBLEMA IDENTIFICADO

**Error:** No se puede mezclar `json_agg` con otras columnas en el mismo `SELECT`

**Síntoma:**

```
ERROR: column "tabla.campo" must appear in the GROUP BY clause
```

---

## ✅ SOLUCIÓN APLICADA

### **PATRÓN INCORRECTO:**

```sql
SELECT json_build_object(
    'code', 200,
    'data', COALESCE(json_agg(...), '[]'::json)
) INTO v_result
FROM tabla
ORDER BY campo;  -- ERROR: ORDER BY fuera de json_agg
```

### **PATRÓN CORRECTO:**

```sql
SELECT json_build_object(
    'code', 200,
    'data', COALESCE(
        (SELECT json_agg(...)  -- Subconsulta
         ORDER BY campo        -- ORDER BY dentro de json_agg
         FROM tabla),
        '[]'::json
    )
) INTO v_result;  -- Sin FROM aquí
```

---

## 📝 ARCHIVOS CORREGIDOS

### **✅ 01_roles_crud.sql**

- Función: `roles_get()`
- Líneas 13-29 co rregidas
- Cambio: `IF v_result IS NULL` → `IF NOT FOUND`

### ✅ CHECKLIST DE CORRECCIÓN

- [x] 01_roles_crud.sql ✅
- [x] 02_servicios_crud.sql ✅
- [ ] 03_usuarios_crud.sql ⏳
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

## 🔄 APLICANDO CORRECCIONES...

Voy a aplicar el mismo patrón a todos los archivos automáticamente.
