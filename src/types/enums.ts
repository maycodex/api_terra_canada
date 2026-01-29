// Enums del sistema (basados en los tipos ENUM de PostgreSQL)

export enum TipoMoneda {
  USD = 'USD',
  CAD = 'CAD',
  MXN = 'MXN',
  EUR = 'EUR'
}

export enum MedioPago {
  TARJETA_CREDITO = 'TARJETA_CREDITO',
  CUENTA_BANCARIA = 'CUENTA_BANCARIA',
  EFECTIVO = 'EFECTIVO',
  TRANSFERENCIA = 'TRANSFERENCIA'
}

export enum EstadoPago {
  PENDIENTE = 'PENDIENTE',
  COMPLETADO = 'COMPLETADO',
  CANCELADO = 'CANCELADO'
}

export enum TipoMedioPago {
  TARJETA = 'TARJETA',
  CUENTA_BANCARIA = 'CUENTA_BANCARIA'
}

export enum TipoDocumento {
  FACTURA = 'FACTURA',
  DOCUMENTO_BANCO = 'DOCUMENTO_BANCO'
}

export enum EstadoCorreo {
  BORRADOR = 'BORRADOR',
  ENVIADO = 'ENVIADO'
}

export enum TipoEvento {
  INICIO_SESION = 'INICIO_SESION',
  CREAR = 'CREAR',
  ACTUALIZAR = 'ACTUALIZAR',
  ELIMINAR = 'ELIMINAR',
  VERIFICAR_PAGO = 'VERIFICAR_PAGO',
  CARGAR_TARJETA = 'CARGAR_TARJETA',
  ENVIAR_CORREO = 'ENVIAR_CORREO',
  SUBIR_DOCUMENTO = 'SUBIR_DOCUMENTO',
  RESET_MENSUAL = 'RESET_MENSUAL'
}

// Roles del sistema
export enum RolNombre {
  ADMIN = 'ADMIN',
  SUPERVISOR = 'SUPERVISOR',
  EQUIPO = 'EQUIPO'
}

// Constantes de permisos
export const PERMISOS = {
  ADMIN: {
    usuarios: ['create', 'read', 'update', 'delete'],
    pagos: ['create', 'read', 'update', 'delete', 'verify'],
    tarjetas: ['create', 'read', 'update', 'delete', 'use', 'recharge'],
    cuentas: ['create', 'read', 'update', 'delete', 'use'],
    documentos: ['create', 'read', 'delete'],
    correos: ['read', 'send'],
    analisis: ['read'],
    eventos: ['read']
  },
  SUPERVISOR: {
    usuarios: ['read'],
    pagos: ['create', 'read', 'update', 'delete', 'verify'],
    tarjetas: ['create', 'read', 'update', 'delete', 'use', 'recharge'],
    cuentas: ['create', 'read', 'update', 'delete', 'use'],
    documentos: ['create', 'read', 'delete'],
    correos: ['read', 'send'],
    analisis: ['read'],
    eventos: ['read']
  },
  EQUIPO: {
    usuarios: [],
    pagos: ['create', 'read'], // Solo sus propios pagos
    tarjetas: ['read', 'use'], // Solo puede usar tarjetas existentes
    cuentas: [], // NO puede usar cuentas bancarias
    documentos: ['create', 'read'], // Solo sus propios documentos
    correos: [],
    analisis: ['read'], // Solo sus propios datos
    eventos: []
  }
} as const;

