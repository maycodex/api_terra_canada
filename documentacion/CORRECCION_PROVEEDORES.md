# 🤝 CORRECCIÓN - ENDPOINT PROVEEDORES

## Fecha: 2026-01-30

---

## ❌ Problema Reportado

### Request INCORRECTO enviado:

```json
{
  "nombre": "Air Canada",
  "lenguaje": "English",
  "correo1": "billing@aircanada.com",
  "correo2": "user@example.com",
  "correo3": "user@example.com",
  "correo4": "user@example.com"
}
```

### Error recibido:

```json
{
  "code": 400,
  "estado": false,
  "message": "Error de validación",
  "data": null,
  "errors": [
    {
      "field": "servicio_id",
      "message": "Invalid input: expected number, received undefined"
    }
  ]
}
```

---

## ✅ Solución

### Schema Correcto del Endpoint

El endpoint `POST /proveedores` requiere los siguientes campos:

```typescript
{
  nombre: string (obligatorio),
  servicio_id: number (obligatorio),
  lenguaje?: string | null (opcional),
  telefono?: string | null (opcional),
  descripcion?: string | null (opcional),
  correos?: Array<{ correo: string, principal: boolean }> (opcional),
  activo?: boolean (opcional, default: true)
}
```

---

## 📝 Request Body CORRECTO

### Ejemplo 1: Proveedor con correos

```json
{
  "nombre": "Air Canada",
  "servicio_id": 1,
  "lenguaje": "English",
  "telefono": "+1-800-123-4567",
  "descripcion": "Proveedor principal de servicios aéreos",
  "correos": [
    {
      "correo": "billing@aircanada.com",
      "principal": true
    },
    {
      "correo": "support@aircanada.com",
      "principal": false
    },
    {
      "correo": "sales@aircanada.com",
      "principal": false
    },
    {
      "correo": "info@aircanada.com",
      "principal": false
    }
  ],
  "activo": true
}
```

### Ejemplo 2: Proveedor sin correos

```json
{
  "nombre": "Air Canada",
  "servicio_id": 1,
  "lenguaje": "English"
}
```

---

## 🔍 Explicación Detallada

### 1. `servicio_id` es OBLIGATORIO

Cada proveedor DEBE estar asociado a un servicio existente en la base de datos.

**Pasos para obtener servicios disponibles:**

```bash
GET /api/v1/servicios
```

**Respuesta:**

```json
{
  "success": true,
  "message": "Servicios obtenidos",
  "data": [
    {
      "id": 1,
      "nombre": "Vuelos",
      "descripcion": "Servicios de vuelos internacionales",
      "activo": true
    },
    {
      "id": 2,
      "nombre": "Hoteles",
      "descripcion": "Reservas de hoteles",
      "activo": true
    }
  ]
}
```

### 2. Correos como Array de Objetos

❌ **INCORRECTO:**

```json
{
  "correo1": "email1@example.com",
  "correo2": "email2@example.com",
  "correo3": "email3@example.com",
  "correo4": "email4@example.com"
}
```

✅ **CORRECTO:**

```json
{
  "correos": [
    {
      "correo": "email1@example.com",
      "principal": true
    },
    {
      "correo": "email2@example.com",
      "principal": false
    }
  ]
}
```

### 3. Límite de correos

- Máximo 4 correos permitidos por proveedor
- Solo puede haber un correo marcado como `principal: true`

---

## 🧪 Ejemplo de Prueba Completo

### Paso 1: Obtener servicios disponibles

```bash
curl -X GET http://localhost:3000/api/v1/servicios \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Paso 2: Crear proveedor con el servicio_id correcto

```bash
curl -X POST http://localhost:3000/api/v1/proveedores \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Air Canada",
    "servicio_id": 1,
    "lenguaje": "English",
    "telefono": "+1-800-247-2262",
    "descripcion": "Aerolínea principal de Canadá",
    "correos": [
      {
        "correo": "billing@aircanada.com",
        "principal": true
      },
      {
        "correo": "support@aircanada.com",
        "principal": false
      }
    ],
    "activo": true
  }'
```

### Respuesta esperada (201 Created)

```json
{
  "success": true,
  "message": "Proveedor creado",
  "data": {
    "id": 5,
    "nombre": "Air Canada",
    "servicio_id": 1,
    "servicio_nombre": "Vuelos",
    "lenguaje": "English",
    "telefono": "+1-800-247-2262",
    "descripcion": "Aerolínea principal de Canadá",
    "activo": true,
    "correos": [
      {
        "id": 1,
        "correo": "billing@aircanada.com",
        "principal": true,
        "activo": true
      },
      {
        "id": 2,
        "correo": "support@aircanada.com",
        "principal": false,
        "activo": true
      }
    ],
    "fecha_creacion": "2026-01-30T17:52:00Z"
  }
}
```

---

## ⚠️ Posibles Errores

### Error 1: servicio_id no proporcionado

```json
{
  "code": 400,
  "message": "Error de validación",
  "errors": [
    {
      "field": "servicio_id",
      "message": "Invalid input: expected number, received undefined"
    }
  ]
}
```

**Solución:** Agregar el campo `servicio_id` con un ID válido de servicio.

### Error 2: servicio_id no existe

```json
{
  "success": false,
  "message": "Servicio no encontrado"
}
```

**Solución:** Verificar que el servicio exista usando `GET /servicios` y usar un ID válido.

### Error 3: Más de 4 correos

Si intentas agregar más de 4 correos posteriormente:

```json
{
  "success": false,
  "message": "Máximo 4 correos permitidos por proveedor"
}
```

### Error 4: Formato de correo inválido

```json
{
  "code": 400,
  "message": "Error de validación",
  "errors": [
    {
      "field": "correos[0].correo",
      "message": "Invalid email format"
    }
  ]
}
```

---

## 📋 Checklist para Crear un Proveedor

- [ ] Obtener lista de servicios disponibles
- [ ] Seleccionar el `servicio_id` correcto
- [ ] Formatear correos como array de objetos
- [ ] Marcar un correo como principal
- [ ] No exceder 4 correos
- [ ] Verificar que los correos tengan formato válido
- [ ] Incluir todos los campos obligatorios

---

## 🔗 Endpoints Relacionados

### Agregar correo adicional después de crear el proveedor

```bash
POST /api/v1/proveedores/:id/correos

{
  "correo": "nuevo@proveedor.com",
  "principal": false
}
```

### Actualizar proveedor

```bash
PUT /api/v1/proveedores/:id

{
  "nombre": "Air Canada - Updated",
  "lenguaje": "Spanish",
  "telefono": "+1-800-999-9999"
}
```

Nota: Los correos se actualizan mediante el endpoint específico `/correos`, no en el PUT del proveedor.
