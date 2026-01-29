import swaggerJsdoc from 'swagger-jsdoc';
import { config } from './environment';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API Terra Canada - Sistema de Gestión de Pagos',
      version: '1.0.0',
      description: `
API RESTful para gestionar pagos a proveedores de servicios turísticos.

## Características principales:
- Autenticación JWT con control de roles (ADMIN, SUPERVISOR, EQUIPO)
- Gestión de pagos con tarjetas de crédito y cuentas bancarias
- Control automático de saldo de tarjetas
- Procesamiento de documentos (facturas y extractos)
- Integración con N8N para automatización
- Sistema de auditoría completo
- Análisis y reportes de negocio

## Autenticación:
Todos los endpoints requieren autenticación JWT, excepto /auth/login.
Incluir el token en el header: Authorization: Bearer {token}
      `,
      contact: {
        name: 'Terra Canada',
        email: 'tech@terracanada.com'
      },
      license: {
        name: 'Privado',
        url: 'https://terracanada.com'
      }
    },
    servers: [
      {
        url: `http://localhost:${config.port}/api/${config.apiVersion}`,
        description: 'Servidor de desarrollo'
      },
      {
        url: `https://api.terracanada.com/api/${config.apiVersion}`,
        description: 'Servidor de producción'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT Token de autenticación'
        }
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            code: {
              type: 'integer',
              description: 'Código HTTP de error'
            },
            estado: {
              type: 'boolean',
              description: 'Estado de la petición (siempre false en errores)'
            },
            message: {
              type: 'string',
              description: 'Mensaje descriptivo del error'
            },
            data: {
              type: 'object',
              nullable: true,
              description: 'Datos adicionales (null en errores)'
            },
            errors: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  field: { type: 'string' },
                  message: { type: 'string' }
                }
              },
              description: 'Detalles de errores de validación'
            }
          }
        },
        Success: {
          type: 'object',
          properties: {
            code: {
              type: 'integer',
              description: 'Código HTTP de éxito'
            },
            estado: {
              type: 'boolean',
              description: 'Estado de la petición (siempre true en éxito)'
            },
            message: {
              type: 'string',
              description: 'Mensaje descriptivo del éxito'
            },
            data: {
              type: 'object',
              description: 'Datos de la respuesta'
            }
          }
        }
      },
      responses: {
        UnauthorizedError: {
          description: 'Token de autenticación faltante o inválido',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                code: 401,
                estado: false,
                message: 'No autorizado: Token no proporcionado',
                data: null
              }
            }
          }
        },
        ForbiddenError: {
          description: 'Usuario no tiene permisos suficientes',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                code: 403,
                estado: false,
                message: 'Acceso denegado: Se requiere rol ADMIN',
                data: null
              }
            }
          }
        },
        NotFoundError: {
          description: 'Recurso no encontrado',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                code: 404,
                estado: false,
                message: 'Recurso no encontrado',
                data: null
              }
            }
          }
        },
        ValidationError: {
          description: 'Error de validación de datos',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                code: 400,
                estado: false,
                message: 'Error de validación',
                data: null,
                errors: [
                  {
                    field: 'email',
                    message: 'Email inválido'
                  }
                ]
              }
            }
          }
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ],
    tags: [
      {
        name: 'Autenticación',
        description: 'Endpoints de autenticación y autorización'
      },
      {
        name: 'Usuarios',
        description: 'Gestión de usuarios del sistema'
      },
      {
        name: 'Roles',
        description: 'Gestión de roles y permisos'
      },
      {
        name: 'Servicios',
        description: 'Catálogo de servicios turísticos'
      },
      {
        name: 'Proveedores',
        description: 'Gestión de proveedores de servicios'
      },
      {
        name: 'Clientes',
        description: 'Gestión de clientes (hoteles)'
      },
      {
        name: 'Tarjetas',
        description: 'Gestión de tarjetas de crédito'
      },
      {
        name: 'Cuentas Bancarias',
        description: 'Gestión de cuentas bancarias'
      },
      {
        name: 'Pagos',
        description: 'Gestión de pagos (CORE del sistema)'
      },
      {
        name: 'Documentos',
        description: 'Gestión de documentos (facturas y extractos)'
      },
      {
        name: 'Correos',
        description: 'Gestión y envío de correos a proveedores'
      },
      {
        name: 'Análisis',
        description: 'Análisis, reportes y dashboards'
      },
      {
        name: 'Eventos',
        description: 'Auditoría de eventos del sistema'
      },
      {
        name: 'Webhooks',
        description: 'Webhooks para integración con N8N'
      }
    ]
  },
  apis: ['./src/routes/*.ts'], // Path a los archivos con JSDoc
};

const swaggerSpec = swaggerJsdoc(options);

export default swaggerSpec;
