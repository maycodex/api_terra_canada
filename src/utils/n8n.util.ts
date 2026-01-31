import axios from 'axios';
import { config } from '../config/environment';
import logger from '../config/logger';

/**
 * Cliente para webhooks de N8N
 * Maneja la comunicación con los workflows de N8N
 */
export class N8NClient {
    private baseUrl: string;
    private authToken: string;

    constructor() {
        this.baseUrl = config.n8n.baseUrl;
        this.authToken = config.n8n.authToken;
    }

    /**
     * Enviar documento a N8N para procesamiento OCR
     * 
     * @param documentoId - ID del documento en la BD
     * @param urlDocumento - URL pública o path del documento
     * @param tipoDocumento - FACTURA o DOCUMENTO_BANCO
     * @param pagoId - ID del pago (opcional, solo para FACTURA)
     * @returns Respuesta de N8N con códigos encontrados
     */
    async procesarDocumento(
        documentoId: number,
        urlDocumento: string,
        tipoDocumento: string,
        pagoId?: number
    ) {
        try {
            const webhookUrl = `${this.baseUrl}${config.n8n.webhookDocumento}`;

            logger.info(`Enviando documento ${documentoId} a N8N para procesamiento`, {
                webhookUrl,
                tipoDocumento,
                pagoId
            });

            const payload = {
                documento_id: documentoId,
                url_documento: urlDocumento,
                tipo_documento: tipoDocumento,
                pago_id: pagoId || null,
                timestamp: new Date().toISOString()
            };

            const response = await axios.post(webhookUrl, payload, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': this.authToken ? `Bearer ${this.authToken}` : undefined
                },
                timeout: 30000 // 30 segundos timeout
            });

            logger.info(`Documento ${documentoId} procesado por N8N exitosamente`, {
                codigosEncontrados: response.data?.codigos_encontrados?.length || 0
            });

            return response.data;
        } catch (error: any) {
            logger.error(`Error al enviar documento ${documentoId} a N8N`, {
                error: error.message,
                response: error.response?.data
            });

            // No lanzar error para no bloquear el registro del documento
            // El procesamiento se puede reintentar manualmente
            return {
                success: false,
                error: error.message,
                codigos_encontrados: []
            };
        }
    }

    /**
   * Procesar FACTURAS enviando PDFs en base64 a N8N
   * Máximo 5 facturas por request
   * 
   * @param usuario - Info del usuario que sube las facturas
   * @param archivos - Array de archivos con nombre, tipo y base64
   * @returns Respuesta de N8N con códigos de pagos encontrados
   */
    async procesarFacturas(usuario: {
        nombre: string;
        id: number;
        tipo: string;
        ip: string;
    }, archivos: Array<{
        nombre: string;
        tipo: string;
        base64: string;
    }>) {
        try {
            const webhookUrl = 'https://n8n.salazargroup.cloud/webhook/recibiendo_pdf';

            if (archivos.length > 5) {
                throw new Error('Máximo 5 facturas permitidas por envío');
            }

            logger.info(`Enviando ${archivos.length} factura(s) a N8N`, {
                usuario: usuario.nombre,
                cantidadArchivos: archivos.length
            });

            const payload = {
                usuario: usuario.nombre,
                id_usuario: usuario.id,
                tipo_usuario: usuario.tipo,
                ip: usuario.ip,
                archivos: archivos
            };

            const response = await axios.post(webhookUrl, payload, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Basic QWRtaW5pc3RyYWRvcjpuOG5jNzc3LTRkNTctYTYwOS02ZWFmMWY5ZTg3ZjZ0ZXJyYWNhbmFkYQ=='
                },
                timeout: 60000 // 60 segundos (procesamiento de múltiples PDFs puede tardar)
            });

            const data = response.data;

            // Validar respuesta
            if (data.code === 200 && data.estado === true) {
                logger.info(`Facturas procesadas exitosamente`, {
                    mensaje: data.mensaje,
                    pagosEncontrados: data.facturas?.length || 0
                });
                return data;
            } else if (data.code === 400 && data.estado === false) {
                logger.error(`Error al procesar facturas`, {
                    mensaje: data.mensaje
                });
                throw new Error(data.mensaje || 'Error al extraer la información');
            } else {
                throw new Error('Respuesta inesperada del servicio de procesamiento');
            }
        } catch (error: any) {
            if (error.response) {
                const errorData = error.response.data;
                const errorMsg = errorData?.mensaje || 'Error en el servicio de procesamiento';
                logger.error(`Error HTTP al procesar facturas`, {
                    status: error.response.status,
                    mensaje: errorMsg
                });
                throw new Error(errorMsg);
            } else if (error.request) {
                logger.error(`Sin respuesta del webhook de facturas`, {
                    error: error.message
                });
                throw new Error('No se pudo conectar con el servicio de procesamiento');
            } else {
                logger.error(`Error al procesar facturas`, {
                    error: error.message
                });
                throw error;
            }
        }
    }

    /**
     * Editar un pago con PDF adjunto
     * Se usa cuando un ADMIN edita estado/verificado de un pago y sube PDF
     * 
     * @param pagoData - Datos del pago con PDF en base64
     * @returns Respuesta de N8N
     */
    async editarPagoConPDF(pagoData: {
        pago_id: number;
        usuario_id: number;
        usuario_nombre: string;
        ip: string;
        estado?: string;
        verificado?: boolean;
        archivo: {
            nombre: string;
            tipo: string;
            base64: string;
        };
        // Datos adicionales del pago
        codigo_reserva?: string;
        monto?: number;
        moneda?: string;
        proveedor_nombre?: string;
    }) {
        try {
            const webhookUrl = 'https://n8n.salazargroup.cloud/webhook/edit_pago';

            logger.info(`Editando pago ${pagoData.pago_id} con PDF adjunto`, {
                usuario: pagoData.usuario_nombre,
                archivo: pagoData.archivo.nombre
            });

            const response = await axios.post(webhookUrl, pagoData, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Basic QWRtaW5pc3RyYWRvcjpuOG5jNzc3LTRkNTctYTYwOS02ZWFmMWY5ZTg3ZjZ0ZXJyYWNhbmFkYQ=='
                },
                timeout: 30000
            });

            const data = response.data;

            // Validar respuesta
            if (data.code === 200 && data.estado === true) {
                logger.info(`Pago ${pagoData.pago_id} editado exitosamente`, {
                    mensaje: data.mensaje
                });
                return data;
            } else if (data.code === 400 && data.estado === false) {
                logger.error(`Error al editar pago ${pagoData.pago_id}`, {
                    mensaje: data.mensaje,
                    error: data.error
                });
                throw new Error(data.mensaje || 'Algo salió mal al editar el pago');
            } else {
                throw new Error('Respuesta inesperada del servicio');
            }
        } catch (error: any) {
            if (error.response) {
                const errorData = error.response.data;
                const errorMsg = errorData?.mensaje || 'Error en el servicio';
                logger.error(`Error HTTP al editar pago`, {
                    status: error.response.status,
                    mensaje: errorMsg,
                    pagoId: pagoData.pago_id
                });
                throw new Error(errorMsg);
            } else if (error.request) {
                logger.error(`Sin respuesta del webhook edit_pago`, {
                    error: error.message
                });
                throw new Error('No se pudo conectar con el servicio');
            } else {
                throw error;
            }
        }
    }

    /**
   * Enviar correo a través de N8N (Gmail)
   * 
   * @param correoData - Datos del correo a enviar (incluye usuario_id del remitente)
   * @returns Respuesta de N8N
   * @throws Error si el webhook responde con estado=false o hay error de red
   */
    async enviarCorreo(correoData: {
        destinatario: string;
        asunto: string;
        cuerpo: string;
        pagos: any[];
        proveedor: any;
        usuario_id: number;
    }) {
        try {
            // URL del webhook de N8N para envío de Gmail
            const webhookUrl = 'https://n8n.salazargroup.cloud/webhook/gmail_g';

            logger.info(`Enviando correo a ${correoData.destinatario} vía N8N`, {
                url: webhookUrl,
                cantidadPagos: correoData.pagos.length,
                usuario_id: correoData.usuario_id
            });

            // Preparar payload según especificación del webhook
            const payload = {
                info_correo: {
                    destinatario: correoData.destinatario,
                    asunto: correoData.asunto,
                    cuerpo: correoData.cuerpo,
                    proveedor: correoData.proveedor,
                    usuario_id: correoData.usuario_id
                },
                info_pagos: correoData.pagos
            };

            const response = await axios.post(webhookUrl, payload, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Basic YWRtaW46Y3JpcF9hZG1pbmQ1Ny1hNjA5LTZlYWYxZjllODdmNg=='
                },
                timeout: 30000 // 30 segundos timeout (envío de correo puede tardar)
            });

            const data = response.data;

            // Validar respuesta del webhook
            if (data.code === 200 && data.estado === true) {
                logger.info(`Correo enviado exitosamente a ${correoData.destinatario}`, {
                    mensaje: data.mensaje
                });
                return data;
            } else if (data.code === 400 && data.estado === false) {
                // Error del webhook con mensaje específico
                const errorMsg = data.mensaje || 'Error al enviar correo';
                logger.error(`Webhook N8N respondió con error`, {
                    code: data.code,
                    mensaje: errorMsg,
                    destinatario: correoData.destinatario
                });
                throw new Error(errorMsg);
            } else {
                // Respuesta inesperada
                logger.error(`Respuesta inesperada del webhook N8N`, {
                    data
                });
                throw new Error('Respuesta inesperada del servicio de correo');
            }
        } catch (error: any) {
            // Si es un error de axios (red, timeout, etc.)
            if (error.response) {
                // El servidor respondió con un código de estado fuera del rango 2xx
                const errorData = error.response.data;
                const errorMsg = errorData?.mensaje || 'Error en el servicio de correo';

                logger.error(`Error HTTP al enviar correo vía N8N`, {
                    status: error.response.status,
                    mensaje: errorMsg,
                    destinatario: correoData.destinatario
                });

                throw new Error(errorMsg);
            } else if (error.request) {
                // La petición se hizo pero no hubo respuesta
                logger.error(`Sin respuesta del webhook N8N`, {
                    error: error.message,
                    destinatario: correoData.destinatario
                });
                throw new Error('No se pudo conectar con el servicio de correo. Verifique su conexión.');
            } else {
                // Error ya lanzado por validación de respuesta o error desconocido
                logger.error(`Error al enviar correo vía N8N`, {
                    error: error.message,
                    destinatario: correoData.destinatario
                });
                throw error;
            }
        }
    }

    /**
     * Notificar cambio en un pago (crear, actualizar, eliminar)
     * Envía todos los datos del pago a Intelexia Labs
     * 
     * @param pagoData - Datos completos del pago
     * @param accion - Tipo de acción realizada (CREAR, ACTUALIZAR, ELIMINAR)
     * @returns Respuesta del webhook
     */
    async notificarCambioPago(pagoData: any, accion: 'CREAR' | 'ACTUALIZAR' | 'ELIMINAR') {
        try {
            const webhookUrl = 'https://intelexia-labs-ob-mediafile.af9gwe.easypanel.host/upload';

            logger.info(`Notificando ${accion} de pago ${pagoData.id} a Intelexia Labs`, {
                url: webhookUrl,
                accion
            });

            // Preparar payload con todos los datos del pago
            const payload = {
                accion: accion,
                timestamp: new Date().toISOString(),
                pago: {
                    // Datos básicos del pago
                    id: pagoData.id,
                    codigo_reserva: pagoData.codigo_reserva,
                    monto: parseFloat(pagoData.monto),
                    moneda: pagoData.moneda,
                    estado: pagoData.estado,
                    verificado: pagoData.verificado,
                    pagado: pagoData.pagado,
                    gmail_enviado: pagoData.gmail_enviado,
                    descripcion: pagoData.descripcion,

                    // IDs de relaciones
                    proveedor_id: pagoData.proveedor_id,
                    usuario_id: pagoData.usuario_id,
                    cliente_asociado_id: pagoData.cliente_asociado_id,
                    tarjeta_id: pagoData.tarjeta_id,
                    cuenta_id: pagoData.cuenta_id,
                    servicio_id: pagoData.servicio_id,
                    documento_id: pagoData.documento_id,

                    // Datos de relaciones (cuando están disponibles)
                    proveedor_nombre: pagoData.proveedor_nombre,
                    usuario_nombre: pagoData.usuario_nombre,
                    cliente_nombre: pagoData.cliente_nombre,
                    tarjeta_titular: pagoData.tarjeta_titular,
                    cuenta_banco: pagoData.cuenta_banco,

                    // Fechas
                    fecha_pago: pagoData.fecha_pago,
                    fecha_creacion: pagoData.fecha_creacion,
                    fecha_actualizacion: pagoData.fecha_actualizacion,

                    // Campos adicionales si existen
                    comision_monto: pagoData.comision_monto ? parseFloat(pagoData.comision_monto) : null,
                    comision_porcentaje: pagoData.comision_porcentaje ? parseFloat(pagoData.comision_porcentaje) : null,
                    tasa_cambio: pagoData.tasa_cambio ? parseFloat(pagoData.tasa_cambio) : null,
                    notas: pagoData.notas
                }
            };

            const response = await axios.post(webhookUrl, payload, {
                headers: {
                    'Content-Type': 'application/json'
                },
                timeout: 10000 // 10 segundos timeout
            });

            // Validar respuesta
            if (response.status === 200) {
                logger.info(`Notificación de pago ${pagoData.id} enviada exitosamente`, {
                    accion,
                    status: response.status
                });
                return {
                    success: true,
                    data: response.data
                };
            } else if (response.status === 400) {
                logger.error(`Error al notificar pago ${pagoData.id}`, {
                    status: response.status,
                    data: response.data
                });
                throw new Error('Error al notificar el cambio del pago');
            } else {
                logger.warn(`Respuesta inesperada al notificar pago ${pagoData.id}`, {
                    status: response.status
                });
                return {
                    success: false,
                    data: response.data
                };
            }
        } catch (error: any) {
            if (error.response) {
                logger.error(`Error HTTP al notificar pago`, {
                    status: error.response.status,
                    data: error.response.data,
                    pagoId: pagoData.id
                });

                // No lanzar error para no bloquear la operación principal
                // Solo registrar el fallo
                return {
                    success: false,
                    error: error.message
                };
            } else if (error.request) {
                logger.error(`Sin respuesta del webhook de notificación`, {
                    error: error.message,
                    pagoId: pagoData.id
                });

                return {
                    success: false,
                    error: 'No se pudo conectar con el servicio de notificación'
                };
            } else {
                logger.error(`Error al notificar cambio de pago`, {
                    error: error.message,
                    pagoId: pagoData.id
                });

                return {
                    success: false,
                    error: error.message
                };
            }
        }
    }

    /**
     * Notificar creación/cambio de pago al webhook principal de N8N
     * URL: https://n8n.salazargroup.cloud/webhook/pago
     * 
     * @param pagoData - Datos completos del pago
     * @param accion - Tipo de acción (CREAR, ACTUALIZAR, ELIMINAR)
     * @returns Respuesta del webhook (200 = OK, 400 = Error)
     */
    async notificarPagoWebhook(pagoData: any, accion: 'CREAR' | 'ACTUALIZAR' | 'ELIMINAR' = 'CREAR') {
        try {
            const webhookUrl = 'https://n8n.salazargroup.cloud/webhook/pago';

            logger.info(`Enviando pago ${pagoData?.id || 'nuevo'} al webhook N8N`, {
                url: webhookUrl,
                accion
            });

            // Preparar payload con todos los datos del pago
            const payload = {
                accion: accion,
                timestamp: new Date().toISOString(),
                pago: pagoData
            };

            const response = await axios.post(webhookUrl, payload, {
                headers: {
                    'Content-Type': 'application/json'
                },
                timeout: 15000 // 15 segundos timeout
            });

            // Validar respuesta
            if (response.status === 200) {
                logger.info(`Pago enviado exitosamente al webhook N8N`, {
                    accion,
                    pagoId: pagoData?.id,
                    status: response.status
                });
                return {
                    success: true,
                    code: 200,
                    data: response.data
                };
            } else {
                logger.error(`Error al enviar pago al webhook N8N`, {
                    status: response.status,
                    data: response.data
                });
                return {
                    success: false,
                    code: response.status,
                    data: response.data
                };
            }
        } catch (error: any) {
            if (error.response) {
                logger.error(`Error HTTP del webhook pago N8N`, {
                    status: error.response.status,
                    data: error.response.data,
                    pagoId: pagoData?.id
                });

                // Retornar el error pero NO bloquear la operación
                return {
                    success: false,
                    code: error.response.status,
                    error: error.response.data?.mensaje || 'Error en webhook N8N'
                };
            } else if (error.request) {
                logger.error(`Sin respuesta del webhook pago N8N`, {
                    error: error.message,
                    pagoId: pagoData?.id
                });

                return {
                    success: false,
                    code: 503,
                    error: 'No se pudo conectar con el webhook N8N'
                };
            } else {
                logger.error(`Error al enviar pago a webhook N8N`, {
                    error: error.message,
                    pagoId: pagoData?.id
                });

                return {
                    success: false,
                    code: 500,
                    error: error.message
                };
            }
        }
    }

    /**
     * Endpoint 1: Enviar documento de pago
     * URL: https://n8n.salazargroup.cloud/webhook/documento_pago
     * 
     * Front envía: { pdf, id_pago, usuario_id }
     * Back envía al webhook: { pdf, id_pago, codigo_reserva, usuario_id }
     * Webhook responde: { codigo, mensaje }
     * 
     * @param data - { pdf, id_pago, codigo_reserva, usuario_id }
     * @returns Respuesta del webhook (se retorna directamente al front)
     */
    async enviarDocumentoPago(data: {
        pdf: string;
        id_pago: number;
        codigo_reserva: string;
        usuario_id: number;
    }) {
        try {
            const webhookUrl = 'https://n8n.salazargroup.cloud/webhook/documento_pago';

            logger.info(`Enviando documento para pago ${data.id_pago} al webhook`, {
                url: webhookUrl,
                codigo_reserva: data.codigo_reserva,
                usuario_id: data.usuario_id
            });

            const payload = {
                pdf: data.pdf,
                id_pago: data.id_pago,
                codigo_reserva: data.codigo_reserva,
                usuario_id: data.usuario_id
            };

            const response = await axios.post(webhookUrl, payload, {
                headers: { 'Content-Type': 'application/json' },
                timeout: 30000
            });

            logger.info(`Documento de pago ${data.id_pago} procesado`, {
                status: response.status,
                data: response.data
            });

            // Retornar exactamente la respuesta del webhook
            return response.data;
        } catch (error: any) {
            logger.error(`Error al enviar documento de pago`, {
                error: error.message,
                id_pago: data.id_pago
            });

            if (error.response) {
                return error.response.data;
            }

            return {
                codigo: 500,
                mensaje: error.message || 'Error al conectar con el webhook'
            };
        }
    }

    /**
     * Endpoint 2: Enviar múltiples facturas (hasta 3)
     * URL: https://n8n.salazargroup.cloud/webhook/docu
     * 
     * Front envía: { modulo: "factura", usuario_id, facturas: [{pdf, proveedor_id}] }
     * Back envía al webhook: { modulo: "factura", usuario_id, facturas: [...] }
     * Webhook responde: { codigo, codigos_reserva: [...] }
     * 
     * @param facturas - Array de {pdf, proveedor_id}
     * @param usuario_id - ID del usuario que envía
     * @returns Respuesta del webhook (se retorna al front)
     */
    async enviarFacturasMultiples(
        facturas: Array<{
            pdf: string;
            proveedor_id: number;
        }>,
        usuario_id: number
    ) {
        try {
            const webhookUrl = 'https://n8n.salazargroup.cloud/webhook/docu';

            if (facturas.length > 3) {
                return {
                    codigo: 400,
                    mensaje: 'Máximo 3 facturas permitidas'
                };
            }

            logger.info(`Enviando ${facturas.length} factura(s) al webhook`, {
                url: webhookUrl,
                cantidadFacturas: facturas.length,
                usuario_id: usuario_id
            });

            const payload = {
                modulo: 'factura',
                usuario_id: usuario_id,
                facturas: facturas.map((f) => ({
                    pdf: f.pdf,
                    proveedor_id: f.proveedor_id
                }))
            };

            const response = await axios.post(webhookUrl, payload, {
                headers: { 'Content-Type': 'application/json' },
                timeout: 60000
            });

            logger.info(`Facturas procesadas exitosamente`, {
                status: response.status,
                data: response.data
            });

            // Retornar exactamente la respuesta del webhook
            return response.data;
        } catch (error: any) {
            logger.error(`Error al enviar facturas`, { error: error.message });

            if (error.response) {
                return error.response.data;
            }

            return {
                codigo: 500,
                mensaje: error.message || 'Error al conectar con el webhook'
            };
        }
    }

    /**
     * Endpoint 3: Enviar extracto de banco (1 PDF)
     * URL: https://n8n.salazargroup.cloud/webhook/docu
     * 
     * Front envía: { pdf, usuario_id }
     * Back envía al webhook: { modulo: "Banco", pdf, usuario_id }
     * Webhook responde: { codigo, codigos_reserva: [...] }
     * 
     * @param pdf - PDF en base64
     * @param usuario_id - ID del usuario que envía
     * @returns Respuesta del webhook (se retorna al front)
     */
    async enviarExtractoBanco(pdf: string, usuario_id: number) {
        try {
            const webhookUrl = 'https://n8n.salazargroup.cloud/webhook/docu';

            logger.info(`Enviando extracto de banco al webhook`, { 
                url: webhookUrl,
                usuario_id: usuario_id
            });

            const payload = {
                modulo: 'Banco',
                pdf: pdf,
                usuario_id: usuario_id
            };

            const response = await axios.post(webhookUrl, payload, {
                headers: { 'Content-Type': 'application/json' },
                timeout: 60000
            });

            logger.info(`Extracto de banco procesado exitosamente`, {
                status: response.status,
                data: response.data
            });

            // Retornar exactamente la respuesta del webhook
            return response.data;
        } catch (error: any) {
            logger.error(`Error al enviar extracto de banco`, { error: error.message });

            if (error.response) {
                return error.response.data;
            }

            return {
                codigo: 500,
                mensaje: error.message || 'Error al conectar con el webhook'
            };
        }
    }

    /**
     * Verificar conectividad con N8N
     */
    async healthCheck(): Promise<boolean> {
        try {
            await axios.get(`${this.baseUrl}/healthz`, { timeout: 5000 });
            return true;
        } catch (error) {
            logger.error('N8N health check failed', error);
            return false;
        }
    }
}

export const n8nClient = new N8NClient();

