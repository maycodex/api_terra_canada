# 🔷 SCHEMA PRISMA - TERRA CANADA

**Versión:** 3.0 Final  
**Fecha:** 28 de Enero, 2026  
**Cambios:** IDs autoincrementables, estados booleanos, 4 correos, lenguaje

---

## 📋 CONFIGURACIÓN

**Archivo:** `prisma/schema.prisma`

**Comandos:**

```bash
npx prisma generate
npx prisma db push
```

---

## 📄 SCHEMA COMPLETO

```prisma
// ==========================
// GENERADOR Y DATASOURCE
// ==========================

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ==========================
// ENUMS
// ==========================

enum TipoMoneda {
  USD
  CAD
}

enum TipoMedioPago {
  TARJETA
  CUENTA_BANCARIA
}

enum TipoDocumento {
  FACTURA           // Cambia pagado = TRUE en 1 pago
  DOCUMENTO_BANCO   // Cambia pagado + verificado = TRUE en N pagos
}

enum EstadoCorreo {
  BORRADOR
  ENVIADO
}

enum TipoEvento {
  INICIO_SESION
  CREAR
  ACTUALIZAR
  ELIMINAR
  VERIFICAR_PAGO
  CARGAR_TARJETA
  ENVIAR_CORREO
  SUBIR_DOCUMENTO
  RESET_MENSUAL
}

// ==========================
// CATÁLOGOS
// ==========================

model Rol {
  id          Int      @id @default(autoincrement())
  nombre      String   @unique @db.VarChar(50)
  descripcion String?

  createdAt   DateTime @default(now()) @map("fecha_creacion")

  usuarios    Usuario[]

  @@map("roles")
}

model Servicio {
  id          Int      @id @default(autoincrement())
  nombre      String   @unique @db.VarChar(50)
  descripcion String?
  activo      Boolean  @default(true)

  createdAt   DateTime @default(now()) @map("fecha_creacion")

  proveedores Proveedor[]

  @@map("servicios")
}

// ==========================
// USUARIOS
// ==========================

model Usuario {
  id                BigInt   @id @default(autoincrement())
  nombreUsuario     String   @unique @map("nombre_usuario") @db.VarChar(50)
  correo            String   @unique @db.VarChar(255)
  contrasenaHash    String   @map("contrasena_hash") @db.VarChar(255)
  nombreCompleto    String   @map("nombre_completo") @db.VarChar(100)
  rolId             Int      @map("rol_id")
  telefono          String?  @db.VarChar(20)
  activo            Boolean  @default(true)

  createdAt         DateTime @default(now()) @map("fecha_creacion")
  updatedAt         DateTime @default(now()) @updatedAt @map("fecha_actualizacion")

  // Relaciones
  rol               Rol      @relation(fields: [rolId], references: [id], onUpdate: Cascade)

  pagos             Pago[]
  documentos        Documento[]
  enviosCorreos     EnvioCorreo[]
  eventos           Evento[]

  @@index([correo])
  @@index([rolId])
  @@index([activo])
  @@map("usuarios")
}

// ==========================
// PROVEEDORES Y CLIENTES
// ==========================

model Proveedor {
  id                BigInt   @id @default(autoincrement())
  nombre            String   @db.VarChar(100)
  servicioId        Int      @map("servicio_id")
  lenguaje          String?  @db.VarChar(50)
  telefono          String?  @db.VarChar(20)
  descripcion       String?
  activo            Boolean  @default(true)

  createdAt         DateTime @default(now()) @map("fecha_creacion")
  updatedAt         DateTime @default(now()) @updatedAt @map("fecha_actualizacion")

  // Relaciones
  servicio          Servicio          @relation(fields: [servicioId], references: [id], onUpdate: Cascade)

  correos           ProveedorCorreo[]
  pagos             Pago[]
  enviosCorreos     EnvioCorreo[]

  @@index([servicioId])
  @@index([activo])
  @@index([nombre])
  @@map("proveedores")
}

model ProveedorCorreo {
  id                Int      @id @default(autoincrement())
  proveedorId       BigInt   @map("proveedor_id")
  correo            String   @db.VarChar(255)
  principal         Boolean  @default(false)
  activo            Boolean  @default(true)

  createdAt         DateTime @default(now()) @map("fecha_creacion")

  // Relaciones
  proveedor         Proveedor @relation(fields: [proveedorId], references: [id], onUpdate: Cascade, onDelete: Cascade)

  @@index([proveedorId])
  @@index([proveedorId, activo])
  @@map("proveedor_correos")
}

model Cliente {
  id                BigInt   @id @default(autoincrement())
  nombre            String   @db.VarChar(100)
  ubicacion         String?  @db.VarChar(255)
  telefono          String?  @db.VarChar(20)
  correo            String?  @db.VarChar(255)
  activo            Boolean  @default(true)

  createdAt         DateTime @default(now()) @map("fecha_creacion")
  updatedAt         DateTime @default(now()) @updatedAt @map("fecha_actualizacion")

  // Relaciones
  pagos             PagoCliente[]

  @@index([nombre])
  @@index([activo])
  @@map("clientes")
}

// ==========================
// MEDIOS DE PAGO
// ==========================

model TarjetaCredito {
  id                BigInt      @id @default(autoincrement())
  nombreTitular     String      @map("nombre_titular") @db.VarChar(100)
  ultimos4Digitos   String      @map("ultimos_4_digitos") @db.VarChar(4)
  moneda            TipoMoneda
  limiteMensual     Decimal     @map("limite_mensual") @db.Decimal(12, 2)
  saldoDisponible   Decimal     @map("saldo_disponible") @db.Decimal(12, 2)
  tipoTarjeta       String?     @default("Visa") @map("tipo_tarjeta") @db.VarChar(50)
  activo            Boolean     @default(true)

  createdAt         DateTime    @default(now()) @map("fecha_creacion")
  updatedAt         DateTime    @default(now()) @updatedAt @map("fecha_actualizacion")

  // Relaciones
  pagos             Pago[]

  @@index([activo])
  @@index([moneda])
  @@map("tarjetas_credito")
}

model CuentaBancaria {
  id                BigInt      @id @default(autoincrement())
  nombreBanco       String      @map("nombre_banco") @db.VarChar(100)
  nombreCuenta      String      @map("nombre_cuenta") @db.VarChar(100)
  ultimos4Digitos   String      @map("ultimos_4_digitos") @db.VarChar(4)
  moneda            TipoMoneda
  activo            Boolean     @default(true)

  createdAt         DateTime    @default(now()) @map("fecha_creacion")
  updatedAt         DateTime    @default(now()) @updatedAt @map("fecha_actualizacion")

  // Relaciones
  pagos             Pago[]

  @@index([activo])
  @@index([moneda])
  @@map("cuentas_bancarias")
}

// ==========================
// PAGOS (CORE)
// ==========================

model Pago {
  id                    BigInt          @id @default(autoincrement())
  proveedorId           BigInt          @map("proveedor_id")
  usuarioId             BigInt          @map("usuario_id")
  codigoReserva         String          @unique @map("codigo_reserva") @db.VarChar(100)
  monto                 Decimal         @db.Decimal(12, 2)
  moneda                TipoMoneda
  descripcion           String?
  fechaEsperadaDebito   DateTime?       @map("fecha_esperada_debito") @db.Date

  // Medio de pago (solo uno puede estar lleno)
  tipoMedioPago         TipoMedioPago   @map("tipo_medio_pago")
  tarjetaId             BigInt?         @map("tarjeta_id")
  cuentaBancariaId      BigInt?         @map("cuenta_bancaria_id")

  // Estados booleanos
  pagado                Boolean         @default(false)
  verificado            Boolean         @default(false)
  gmailEnviado          Boolean         @default(false) @map("gmail_enviado")
  activo                Boolean         @default(true)

  // Fechas de control
  fechaPago             DateTime?       @map("fecha_pago")
  fechaVerificacion     DateTime?       @map("fecha_verificacion")
  createdAt             DateTime        @default(now()) @map("fecha_creacion")
  updatedAt             DateTime        @default(now()) @updatedAt @map("fecha_actualizacion")

  // Relaciones
  proveedor             Proveedor       @relation(fields: [proveedorId], references: [id], onUpdate: Cascade)
  usuario               Usuario         @relation(fields: [usuarioId], references: [id], onUpdate: Cascade)
  tarjeta               TarjetaCredito? @relation(fields: [tarjetaId], references: [id], onUpdate: Cascade)
  cuentaBancaria        CuentaBancaria? @relation(fields: [cuentaBancariaId], references: [id], onUpdate: Cascade)

  clientes              PagoCliente[]
  documentos            DocumentoPago[]
  documentosDirectos    Documento[]     @relation("DocumentoPagoDirecto")
  enviosCorreoDetalle   EnvioCorreoDetalle[]

  @@index([proveedorId])
  @@index([usuarioId])
  @@index([pagado])
  @@index([verificado])
  @@index([gmailEnviado])
  @@index([activo])
  @@index([createdAt(sort: Desc)])
  @@index([codigoReserva])
  @@index([pagado, gmailEnviado, proveedorId])
  @@map("pagos")
}

model PagoCliente {
  id                Int      @id @default(autoincrement())
  pagoId            BigInt   @map("pago_id")
  clienteId         BigInt   @map("cliente_id")

  createdAt         DateTime @default(now()) @map("fecha_creacion")

  // Relaciones
  pago              Pago     @relation(fields: [pagoId], references: [id], onUpdate: Cascade, onDelete: Cascade)
  cliente           Cliente  @relation(fields: [clienteId], references: [id], onUpdate: Cascade)

  @@unique([pagoId, clienteId])
  @@index([pagoId])
  @@index([clienteId])
  @@map("pago_cliente")
}

// ==========================
// DOCUMENTOS
// ==========================

model Documento {
  id                BigInt          @id @default(autoincrement())
  usuarioId         BigInt          @map("usuario_id")
  pagoId            BigInt?         @map("pago_id")
  nombreArchivo     String          @map("nombre_archivo") @db.VarChar(255)
  urlDocumento      String          @map("url_documento")
  tipoDocumento     TipoDocumento   @map("tipo_documento")

  createdAt         DateTime        @default(now()) @map("fecha_subida")

  // Relaciones
  usuario           Usuario         @relation(fields: [usuarioId], references: [id], onUpdate: Cascade)
  pago              Pago?           @relation("DocumentoPagoDirecto", fields: [pagoId], references: [id], onUpdate: Cascade)

  pagos             DocumentoPago[]

  @@index([usuarioId])
  @@index([pagoId])
  @@index([tipoDocumento])
  @@index([createdAt(sort: Desc)])
  @@map("documentos")
}

model DocumentoPago {
  id                Int      @id @default(autoincrement())
  documentoId       BigInt   @map("documento_id")
  pagoId            BigInt   @map("pago_id")

  createdAt         DateTime @default(now()) @map("fecha_vinculacion")

  // Relaciones
  documento         Documento @relation(fields: [documentoId], references: [id], onUpdate: Cascade, onDelete: Cascade)
  pago              Pago      @relation(fields: [pagoId], references: [id], onUpdate: Cascade, onDelete: Cascade)

  @@unique([documentoId, pagoId])
  @@index([documentoId])
  @@index([pagoId])
  @@map("documento_pago")
}

// ==========================
// CORREOS
// ==========================

model EnvioCorreo {
  id                    BigInt              @id @default(autoincrement())
  proveedorId           BigInt              @map("proveedor_id")
  correoSeleccionado    String              @map("correo_seleccionado") @db.VarChar(255)
  usuarioEnvioId        BigInt              @map("usuario_envio_id")
  asunto                String              @db.VarChar(255)
  cuerpo                String
  estado                EstadoCorreo        @default(BORRADOR)
  cantidadPagos         Int                 @map("cantidad_pagos")
  montoTotal            Decimal             @map("monto_total") @db.Decimal(12, 2)

  createdAt             DateTime            @default(now()) @map("fecha_generacion")
  fechaEnvio            DateTime?           @map("fecha_envio")

  // Relaciones
  proveedor             Proveedor           @relation(fields: [proveedorId], references: [id], onUpdate: Cascade)
  usuarioEnvio          Usuario             @relation(fields: [usuarioEnvioId], references: [id], onUpdate: Cascade)

  detalles              EnvioCorreoDetalle[]

  @@index([proveedorId])
  @@index([estado])
  @@index([fechaEnvio(sort: Desc)])
  @@map("envios_correos")
}

model EnvioCorreoDetalle {
  id                Int         @id @default(autoincrement())
  envioId           BigInt      @map("envio_id")
  pagoId            BigInt      @map("pago_id")

  createdAt         DateTime    @default(now()) @map("fecha_creacion")

  // Relaciones
  envio             EnvioCorreo @relation(fields: [envioId], references: [id], onUpdate: Cascade, onDelete: Cascade)
  pago              Pago        @relation(fields: [pagoId], references: [id], onUpdate: Cascade)

  @@unique([envioId, pagoId])
  @@index([envioId])
  @@index([pagoId])
  @@map("envio_correo_detalle")
}

// ==========================
// AUDITORÍA
// ==========================

model Evento {
  id                BigInt       @id @default(autoincrement())
  usuarioId         BigInt?      @map("usuario_id")
  tipoEvento        TipoEvento   @map("tipo_evento")
  entidadTipo       String       @map("entidad_tipo") @db.VarChar(50)
  entidadId         BigInt?      @map("entidad_id")
  descripcion       String
  ipOrigen          String?      @map("ip_origen") @db.Inet
  userAgent         String?      @map("user_agent")

  createdAt         DateTime     @default(now()) @map("fecha_evento")

  // Relaciones
  usuario           Usuario?     @relation(fields: [usuarioId], references: [id], onUpdate: Cascade)

  @@index([usuarioId])
  @@index([createdAt(sort: Desc)])
  @@index([entidadTipo, entidadId])
  @@index([tipoEvento])
  @@map("eventos")
}
```

---

## 📝 EJEMPLOS DE USO

### **1. Crear un pago**

```typescript
const pago = await prisma.pago.create({
  data: {
    proveedorId: 1,
    usuarioId: 1,
    codigoReserva: "ABC123",
    monto: 1000,
    moneda: "USD",
    tipoMedioPago: "TARJETA",
    tarjetaId: 1,
    descripcion: "Servicio Assurance",
    clientes: {
      create: [{ clienteId: 1 }, { clienteId: 2 }],
    },
  },
});
```

### **2. Obtener pagos pendientes de correo**

```typescript
const pagos = await prisma.pago.findMany({
  where: {
    pagado: true,
    gmailEnviado: false,
    activo: true,
  },
  include: {
    proveedor: {
      include: {
        correos: {
          where: { activo: true },
        },
      },
    },
  },
});
```

### **3. Soft delete**

```typescript
await prisma.pago.update({
  where: { id: 5 },
  data: { activo: false },
});
```

---

**Versión:** 3.0  
**IDs:** Autoincrementables  
**Estados:** Booleanos  
**Timezone:** Europe/Paris
