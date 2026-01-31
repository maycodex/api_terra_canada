# 📊 EJEMPLOS DE RESPUESTAS JSON

Este documento muestra ejemplos reales de las respuestas JSON que retornan las funciones CRUD.

---

## 📥 Ejemplo 1: GET de un Pago (con todas las relaciones)

```sql
SELECT pagos_get(1);
```

**Respuesta:**
```json
{
  "code": 200,
  "estado": true,
  "message": "Pago obtenido exitosamente",
  "data": {
    "id": 1,
    "codigo_reserva": "RES-2026-001",
    "monto": 750.00,
    "moneda": "USD",
    "descripcion": "Servicio de guía turística - Tour Chichén Itzá",
    "fecha_esperada_debito": "2026-02-15",
    "proveedor": {
      "id": 1,
      "nombre": "Servicios Turísticos XYZ",
      "servicio": {
        "id": 8,
        "nombre": "Opérations clients (Services/activités/guides/entrées/transports)"
      }
    },
    "usuario": {
      "id": 1,
      "nombre_completo": "Juan Operador",
      "rol": "EQUIPO"
    },
    "medio_pago": {
      "tipo": "TARJETA",
      "id": 1,
      "titular": "Terra Canada",
      "ultimos_digitos": "1234",
      "tipo_tarjeta": "Visa Corporate",
      "moneda": "USD"
    },
    "clientes": [
      {
        "id": 1,
        "nombre": "Hotel Paradise",
        "ubicacion": "Cancún, México"
      },
      {
        "id": 2,
        "nombre": "Hotel Caribe",
        "ubicacion": "Playa del Carmen"
      }
    ],
    "documentos": [
      {
        "id": 1,
        "tipo_documento": "FACTURA",
        "url_documento": "https://storage.terracanada.com/facturas/2026/01/factura_RES-2026-001.pdf",
        "fecha_subida": "2026-01-28T10:30:00Z"
      }
    ],
    "estados": {
      "pagado": true,
      "verificado": false,
      "gmail_enviado": true,
      "activo": true
    },
    "fecha_pago": "2026-01-28T11:00:00Z",
    "fecha_verificacion": null,
    "fecha_creacion": "2026-01-28T09:00:00Z",
    "fecha_actualizacion": "2026-01-28T14:30:00Z"
  }
}
```

---

## 📥 Ejemplo 2: GET de Tarjeta (con porcentaje de uso)

```sql
SELECT tarjetas_credito_get(1);
```

**Respuesta:**
```json
{
  "code": 200,
  "estado": true,
  "message": "Tarjeta obtenida exitosamente",
  "data": {
    "id": 1,
    "nombre_titular": "Terra Canada",
    "ultimos_4_digitos": "1234",
    "moneda": "USD",
    "limite_mensual": 10000.00,
    "saldo_disponible": 8900.00,
    "tipo_tarjeta": "Visa Corporate",
    "activo": true,
    "porcentaje_uso": 11.00,
    "fecha_creacion": "2026-01-28T08:00:00Z",
    "fecha_actualizacion": "2026-01-28T09:00:00Z"
  }
}
```

---

## 📥 Ejemplo 3: GET de Proveedor (con correos)

```sql
SELECT proveedores_get(1);
```

**Respuesta:**
```json
{
  "code": 200,
  "estado": true,
  "message": "Proveedor obtenido exitosamente",
  "data": {
    "id": 1,
    "nombre": "Servicios Turísticos XYZ",
    "servicio": {
      "id": 8,
      "nombre": "Opérations clients (Services/activités/guides/entrées/transports)"
    },
    "lenguaje": "Español",
    "telefono": "+521234567890",
    "descripcion": "Proveedor de servicios de guías turísticos",
    "activo": true,
    "correos": [
      {
        "id": 1,
        "correo": "contacto@serviciosxyz.com",
        "principal": true,
        "activo": true
      },
      {
        "id": 2,
        "correo": "admin@serviciosxyz.com",
        "principal": false,
        "activo": true
      },
      {
        "id": 3,
        "correo": "ventas@serviciosxyz.com",
        "principal": false,
        "activo": true
      }
    ],
    "fecha_creacion": "2026-01-28T08:00:00Z",
    "fecha_actualizacion": "2026-01-28T08:00:00Z"
  }
}
```

---

## 📥 Ejemplo 4: GET de Correo con Pagos

```sql
SELECT envios_correos_get(1);
```

**Respuesta:**
```json
{
  "code": 200,
  "estado": true,
  "message": "Correo obtenido exitosamente",
  "data": {
    "id": 1,
    "proveedor": {
      "id": 1,
      "nombre": "Servicios Turísticos XYZ",
      "lenguaje": "Español",
      "correos_disponibles": [
        {
          "id": 1,
          "correo": "contacto@serviciosxyz.com",
          "principal": true
        },
        {
          "id": 2,
          "correo": "admin@serviciosxyz.com",
          "principal": false
        },
        {
          "id": 3,
          "correo": "ventas@serviciosxyz.com",
          "principal": false
        }
      ]
    },
    "estado": "ENVIADO",
    "cantidad_pagos": 2,
    "monto_total": 1100.00,
    "correo_destino": "contacto@serviciosxyz.com",
    "asunto": "Notificación de Pagos - Terra Canada",
    "cuerpo": "Estimado proveedor, le informamos que hemos procesado los siguientes pagos...",
    "pagos_incluidos": [
      {
        "id": 1,
        "codigo_reserva": "RES-2026-001",
        "monto": 750.00,
        "moneda": "USD",
        "descripcion": "Servicio de guía turística"
      },
      {
        "id": 3,
        "codigo_reserva": "RES-2026-003",
        "monto": 350.00,
        "moneda": "USD",
        "descripcion": "Excursión"
      }
    ],
    "usuario_envio": {
      "id": 1,
      "nombre_completo": "Juan Operador"
    },
    "fecha_creacion": "2026-01-28T14:00:00Z",
    "fecha_envio": "2026-01-28T14:30:00Z"
  }
}
```

---

## 📥 Ejemplo 5: POST - Crear Pago Exitoso

```sql
SELECT pagos_post(
    1, 1, 'RES-2026-004', 500.00, 'USD', 'TARJETA',
    1, NULL, ARRAY[1]::BIGINT[], 'Pago test', NULL
);
```

**Respuesta:**
```json
{
  "code": 201,
  "estado": true,
  "message": "Pago creado exitosamente",
  "data": {
    "id": 4,
    "codigo_reserva": "RES-2026-004",
    "monto": 500.00,
    "moneda": "USD",
    "descripcion": "Pago test",
    "fecha_esperada_debito": null,
    "proveedor": {
      "id": 1,
      "nombre": "Servicios Turísticos XYZ",
      "servicio": {
        "id": 8,
        "nombre": "Opérations clients (Services/activités/guides/entrées/transports)"
      }
    },
    "usuario": {
      "id": 1,
      "nombre_completo": "Juan Operador",
      "rol": "EQUIPO"
    },
    "medio_pago": {
      "tipo": "TARJETA",
      "id": 1,
      "titular": "Terra Canada",
      "ultimos_digitos": "1234",
      "tipo_tarjeta": "Visa Corporate",
      "moneda": "USD"
    },
    "clientes": [
      {
        "id": 1,
        "nombre": "Hotel Paradise",
        "ubicacion": "Cancún, México"
      }
    ],
    "documentos": [],
    "estados": {
      "pagado": false,
      "verificado": false,
      "gmail_enviado": false,
      "activo": true
    },
    "fecha_pago": null,
    "fecha_verificacion": null,
    "fecha_creacion": "2026-01-28T15:00:00Z",
    "fecha_actualizacion": "2026-01-28T15:00:00Z"
  }
}
```

---

## ❌ Ejemplo 6: Error - Código Duplicado

```sql
SELECT pagos_post(
    1, 1, 'RES-2026-001', 100.00, 'USD', 'TARJETA',
    1, NULL, ARRAY[1]::BIGINT[], 'Test', NULL
);
```

**Respuesta:**
```json
{
  "code": 409,
  "estado": false,
  "message": "Ya existe un pago con ese código de reserva",
  "data": null
}
```

---

## ❌ Ejemplo 7: Error - Saldo Insuficiente

```sql
SELECT pagos_post(
    1, 1, 'RES-2026-999', 50000.00, 'USD', 'TARJETA',
    1, NULL, ARRAY[1]::BIGINT[], 'Test', NULL
);
```

**Respuesta:**
```json
{
  "code": 409,
  "estado": false,
  "message": "Saldo insuficiente en la tarjeta. Disponible: 8400.00",
  "data": {
    "saldo_disponible": 8400.00
  }
}
```

---

## ❌ Ejemplo 8: Error - Pago No Encontrado

```sql
SELECT pagos_get(999);
```

**Respuesta:**
```json
{
  "code": 404,
  "estado": false,
  "message": "Pago no encontrado",
  "data": null
}
```

---

## ❌ Ejemplo 9: Error - No Se Puede Editar Pago Verificado

```sql
SELECT pagos_put(2, 999.99, NULL, NULL, NULL, NULL, NULL, NULL);
```

**Respuesta:**
```json
{
  "code": 409,
  "estado": false,
  "message": "No se puede editar un pago que ya está verificado",
  "data": null
}
```

---

## ❌ Ejemplo 10: Error - Máximo de Correos Alcanzado

```sql
SELECT proveedor_correos_post(1, 'quinto@test.com', false, true);
```

**Respuesta:**
```json
{
  "code": 409,
  "estado": false,
  "message": "El proveedor ya tiene el máximo de 4 correos activos",
  "data": null
}
```

---

## 📥 Ejemplo 11: GET con Lista Vacía

```sql
SELECT documentos_get();
-- Cuando no hay documentos en la base de datos
```

**Respuesta:**
```json
{
  "code": 200,
  "estado": true,
  "message": "Documentos obtenidos exitosamente",
  "data": []
}
```

---

## 📥 Ejemplo 12: GET de Eventos (con paginación)

```sql
SELECT eventos_get(NULL, 5, 0);
```

**Respuesta:**
```json
{
  "code": 200,
  "estado": true,
  "message": "Eventos obtenidos exitosamente",
  "total": 25,
  "limite": 5,
  "offset": 0,
  "data": [
    {
      "id": 25,
      "usuario": {
        "id": 1,
        "nombre_completo": "Juan Operador",
        "rol": "EQUIPO"
      },
      "tipo_evento": "ENVIAR_CORREO",
      "entidad_tipo": "envios_correos",
      "entidad_id": 1,
      "descripcion": "Correo enviado a proveedor Servicios Turísticos XYZ",
      "ip_origen": "192.168.1.100",
      "fecha_evento": "2026-01-28T14:30:00Z"
    },
    {
      "id": 24,
      "usuario": {
        "id": 1,
        "nombre_completo": "Juan Operador",
        "rol": "EQUIPO"
      },
      "tipo_evento": "ACTUALIZAR",
      "entidad_tipo": "pagos",
      "entidad_id": 1,
      "descripcion": "Pago RES-2026-001 marcado como pagado",
      "ip_origen": "192.168.1.100",
      "fecha_evento": "2026-01-28T11:00:00Z"
    },
    {
      "id": 23,
      "usuario": {
        "id": 1,
        "nombre_completo": "Juan Operador",
        "rol": "EQUIPO"
      },
      "tipo_evento": "SUBIR_DOCUMENTO",
      "entidad_tipo": "documentos",
      "entidad_id": 1,
      "descripcion": "Factura factura_RES-2026-001.pdf subida",
      "ip_origen": "192.168.1.100",
      "fecha_evento": "2026-01-28T10:30:00Z"
    },
    {
      "id": 22,
      "usuario": {
        "id": 1,
        "nombre_completo": "Juan Operador",
        "rol": "EQUIPO"
      },
      "tipo_evento": "CREAR",
      "entidad_tipo": "pagos",
      "entidad_id": 1,
      "descripcion": "Pago RES-2026-001 creado por $750.00 USD",
      "ip_origen": "192.168.1.100",
      "fecha_evento": "2026-01-28T09:00:00Z"
    },
    {
      "id": 21,
      "usuario": {
        "id": 1,
        "nombre_completo": "Juan Operador",
        "rol": "EQUIPO"
      },
      "tipo_evento": "INICIO_SESION",
      "entidad_tipo": "usuarios",
      "entidad_id": 1,
      "descripcion": "Usuario admin inició sesión",
      "ip_origen": "192.168.1.100",
      "fecha_evento": "2026-01-28T08:45:00Z"
    }
  ]
}
```

---

## ❌ Ejemplo 13: Auditoría - No Se Puede Modificar

```sql
SELECT eventos_put(1);
```

**Respuesta:**
```json
{
  "code": 405,
  "estado": false,
  "message": "No se pueden modificar eventos de auditoría (inmutables)",
  "data": null
}
```

---

## ❌ Ejemplo 14: Auditoría - No Se Puede Eliminar

```sql
SELECT eventos_delete(1);
```

**Respuesta:**
```json
{
  "code": 405,
  "estado": false,
  "message": "No se pueden eliminar eventos de auditoría (inmutables)",
  "data": null
}
```

---

## 🔄 Ejemplo 15: DELETE Exitoso (Devuelve Saldo)

```sql
SELECT pagos_delete(4);
-- Pago de $500 con tarjeta, no enviado por correo
```

**Respuesta:**
```json
{
  "code": 200,
  "estado": true,
  "message": "Pago eliminado exitosamente",
  "data": {
    "codigo_reserva": "RES-2026-004",
    "monto_devuelto": 500.00
  }
}
```

---

## 📝 Notas Importantes

1. **Todos los campos de fecha/hora** están en formato ISO 8601 con zona horaria (Europe/Paris configurada en el DDL)

2. **Los montos decimales** siempre tienen 2 decimales (.00)

3. **Las relaciones** se incluyen como objetos o arrays anidados para facilitar el uso

4. **Los códigos HTTP** son consistentes:
   - `200`: Éxito en consulta/actualización
   - `201`: Recurso creado
   - `400`: Datos inválidos
   - `404`: No encontrado
   - `405`: Método no permitido
   - `409`: Conflicto (reglas de negocio)
   - `500`: Error del servidor

5. **El campo `data`** puede ser:
   - Un objeto (para un solo registro)
   - Un array (para múltiples registros)
   - `null` (en caso de error o no encontrado)
   - Un array vacío `[]` (cuando no hay resultados pero la consulta fue exitosa)
