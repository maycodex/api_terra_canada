# 📋 CHECKLIST RÁPIDO: Endpoints Faltantes en Postman

**Fecha:** 30 de Enero de 2026

---

## 🔴 CRÍTICO - Agregar Inmediatamente

### Módulo: PAGOS

- [ ] **PATCH** `/pagos/:id/desactivar` - Desactivar pago
- [ ] **PATCH** `/pagos/:id/activar` - Activar pago
- [ ] **POST** `/pagos/documento-estado` - Enviar documento de estado (N8N) + `usuario_id`
- [ ] **POST** `/pagos/subir-facturas` - Subir facturas (N8N) + `usuario_id`
- [ ] **POST** `/pagos/subir-extracto-banco` - Subir extracto bancario (N8N) + `usuario_id`

### Módulo: DOCUMENTOS

- [ ] **PUT** `/documentos/:id` - Actualizar documento
- [ ] **Corregir POST** `/documentos` - Cambiar de `formdata` a `JSON`:
  ```json
  {
    "tipo_documento": "FACTURA",
    "nombre_archivo": "factura.pdf",
    "url_documento": "https://...",
    "usuario_id": 2,
    "pago_id": 10
  }
  ```

---

## 🟡 IMPORTANTE - Agregar Pronto

### Módulo: ROLES

- [ ] **POST** `/roles` - Crear rol
- [ ] **PUT** `/roles/:id` - Actualizar rol
- [ ] **DELETE** `/roles/:id` - Eliminar rol

### Módulo: CORREOS

- [ ] **GET** `/correos/pendientes` - Obtener correos pendientes

---

## 🟢 MENOR - Correcciones

### Módulo: AUTH

- [ ] **Cambiar** GET `/auth/profile` → `/auth/me`

### Módulo: FACTURAS

- [ ] **Mover** POST `/facturas/procesar` → `/pagos/subir-facturas` (ya está en CRÍTICO)

---

## 📊 RESUMEN

| Prioridad     | Cantidad       | Estado            |
| ------------- | -------------- | ----------------- |
| 🔴 Crítico    | 7 endpoints    | ⚠️ Pendiente      |
| 🟡 Importante | 4 endpoints    | ⚠️ Pendiente      |
| 🟢 Menor      | 2 correcciones | ⚠️ Pendiente      |
| **TOTAL**     | **13 cambios** | **0% completado** |

---

## ✅ ENDPOINTS YA COMPLETOS (No requieren cambios)

- ✅ Usuarios (5/5)
- ✅ Proveedores (6/6)
- ✅ Servicios (5/5)
- ✅ Clientes (5/5)
- ✅ Tarjetas (6/6)
- ✅ Cuentas (5/5)
- ✅ Correos (7/8) - Solo falta `/pendientes`

---

**Ver detalles completos en:** `POSTMAN_VS_SWAGGER_CHECKLIST.md`
