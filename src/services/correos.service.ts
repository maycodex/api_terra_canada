import { query, getClient } from '../config/database';
import logger from '../config/logger';
import { n8nClient } from '../utils/n8n.util';
import { EstadoCorreo } from '../types/enums';

export class CorreosService {
    /**
     * Obtener correos con filtros opcionales
     */
    async getCorreos(
        id?: number,
        filters?: {
            estado?: string;
            proveedor_id?: number;
            fecha_desde?: string;
            fecha_hasta?: string;
        }
    ) {
        try {
            if (id) {
                // Obtener un correo específico con información completa
                const result = await query(
                    `SELECT ec.*,
                  p.nombre as proveedor_nombre,
                  p.lenguaje as proveedor_lenguaje,
                  u.nombre_usuario as usuario_nombre,
                  u.nombre_completo as usuario_completo,
                  (
                    SELECT json_agg(
                      json_build_object(
                        'pago_id', pg.id,
                        'codigo_reserva', pg.codigo_reserva,
                        'monto', pg.monto,
                        'moneda', pg.moneda,
                        'descripcion', pg.descripcion,
                        'cliente_nombre', c.nombre
                      ) ORDER BY pg.fecha_creacion
                    )
                    FROM envio_correo_detalle ecd
                    JOIN pagos pg ON ecd.pago_id = pg.id
                    LEFT JOIN pago_cliente pc ON pg.id = pc.pago_id
                    LEFT JOIN clientes c ON pc.cliente_id = c.id
                    WHERE ecd.envio_id = ec.id
                  ) as pagos_incluidos
           FROM envios_correos ec
           JOIN proveedores p ON ec.proveedor_id = p.id
           JOIN usuarios u ON ec.usuario_envio_id = u.id
           WHERE ec.id = $1`,
                    [id]
                );

                return result.rows[0] || null;
            }

            // Construir query con filtros
            let sql = `
        SELECT ec.*,
               p.nombre as proveedor_nombre,
               u.nombre_usuario as usuario_nombre,
               (
                 SELECT COUNT(*)::int
                 FROM envio_correo_detalle ecd
                 WHERE ecd.envio_id = ec.id
               ) as cantidad_pagos_real
        FROM envios_correos ec
        JOIN proveedores p ON ec.proveedor_id = p.id
        JOIN usuarios u ON ec.usuario_envio_id = u.id
        WHERE 1=1
      `;

            const params: any[] = [];
            let paramCount = 1;

            if (filters?.estado) {
                sql += ` AND ec.estado = $${paramCount++}`;
                params.push(filters.estado);
            }

            if (filters?.proveedor_id) {
                sql += ` AND ec.proveedor_id = $${paramCount++}`;
                params.push(filters.proveedor_id);
            }

            if (filters?.fecha_desde) {
                sql += ` AND ec.fecha_generacion >= $${paramCount++}`;
                params.push(filters.fecha_desde);
            }

            if (filters?.fecha_hasta) {
                sql += ` AND ec.fecha_generacion <= $${paramCount++}`;
                params.push(filters.fecha_hasta);
            }

            sql += ` ORDER BY ec.fecha_generacion DESC LIMIT 100`;

            const result = await query(sql, params);
            return result.rows;
        } catch (error) {
            logger.error('Error al obtener correos:', error);
            throw error;
        }
    }

    /**
     * Generar correos automáticamente para pagos pendientes
     * Agrupa por proveedor los pagos que tienen pagado=TRUE y gmail_enviado=FALSE
     */
    async generarCorreos(usuarioId: number, proveedorId?: number) {
        const client = await getClient();

        try {
            await client.query('BEGIN');

            // Obtener pagos pendientes de envío, agrupados por proveedor
            let sqlPagos = `
        SELECT 
          p.proveedor_id,
          pr.nombre as proveedor_nombre,
          pr.lenguaje as proveedor_lenguaje,
          COUNT(*)::int as cantidad_pagos,
          SUM(p.monto) as monto_total,
          array_agg(p.id ORDER BY p.fecha_creacion) as pago_ids
        FROM pagos p
        JOIN proveedores pr ON p.proveedor_id = pr.id
        WHERE p.pagado = TRUE 
          AND p.gmail_enviado = FALSE 
          AND p.activo = TRUE
      `;

            const params: any[] = [];
            if (proveedorId) {
                sqlPagos += ` AND p.proveedor_id = $1`;
                params.push(proveedorId);
            }

            sqlPagos += ` GROUP BY p.proveedor_id, pr.nombre, pr.lenguaje`;

            const pagosPendientes = await client.query(sqlPagos, params);

            if (pagosPendientes.rows.length === 0) {
                await client.query('COMMIT');
                return {
                    correosGenerados: 0,
                    mensaje: 'No hay pagos pendientes de envío'
                };
            }

            const correosGenerados = [];

            // Por cada proveedor, generar un correo
            for (const grupo of pagosPendientes.rows) {
                // Obtener el primer correo activo del proveedor (principal o cualquiera)
                const correoProveedor = await client.query(
                    `SELECT correo FROM proveedor_correos 
           WHERE proveedor_id = $1 AND activo = TRUE 
           ORDER BY principal DESC, id ASC 
           LIMIT 1`,
                    [grupo.proveedor_id]
                );

                if (correoProveedor.rows.length === 0) {
                    logger.warn(`Proveedor ${grupo.proveedor_nombre} no tiene correos activos`);
                    continue;
                }

                const correoDestino = correoProveedor.rows[0].correo;

                // Generar contenido del correo
                const asunto = this.generarAsunto(grupo.proveedor_nombre, grupo.cantidad_pagos);
                const cuerpo = await this.generarCuerpo(
                    client,
                    grupo.proveedor_nombre,
                    grupo.proveedor_lenguaje,
                    grupo.pago_ids
                );

                // Insertar correo en estado BORRADOR
                const resultCorreo = await client.query(
                    `INSERT INTO envios_correos (
            proveedor_id,
            correo_seleccionado,
            usuario_envio_id,
            asunto,
            cuerpo,
            estado,
            cantidad_pagos,
            monto_total,
            fecha_generacion
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
          RETURNING *`,
                    [
                        grupo.proveedor_id,
                        correoDestino,
                        usuarioId,
                        asunto,
                        cuerpo,
                        EstadoCorreo.BORRADOR,
                        grupo.cantidad_pagos,
                        grupo.monto_total
                    ]
                );

                const correo = resultCorreo.rows[0];

                // Insertar detalles del correo (pagos incluidos)
                for (const pagoId of grupo.pago_ids) {
                    await client.query(
                        `INSERT INTO envio_correo_detalle (envio_id, pago_id)
             VALUES ($1, $2)`,
                        [correo.id, pagoId]
                    );
                }

                correosGenerados.push(correo);

                logger.info(`Correo generado para proveedor ${grupo.proveedor_nombre}`, {
                    correoId: correo.id,
                    cantidadPagos: grupo.cantidad_pagos,
                    montoTotal: grupo.monto_total
                });
            }

            await client.query('COMMIT');

            return {
                correosGenerados: correosGenerados.length,
                correos: correosGenerados
            };
        } catch (error) {
            await client.query('ROLLBACK');
            logger.error('Error al generar correos:', error);
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Crear un correo manualmente
     */
    async createCorreo(data: {
        proveedor_id: number;
        correo_seleccionado: string;
        usuario_id: number;
        asunto: string;
        cuerpo: string;
        pago_ids: number[];
    }) {
        const client = await getClient();

        try {
            await client.query('BEGIN');

            // Validar proveedor
            const proveedor = await client.query('SELECT id, nombre FROM proveedores WHERE id = $1', [
                data.proveedor_id
            ]);
            if (proveedor.rows.length === 0) {
                throw new Error('Proveedor no encontrado');
            }

            // Validar correo del proveedor
            const correoValido = await client.query(
                'SELECT id FROM proveedor_correos WHERE proveedor_id = $1 AND correo = $2 AND activo = TRUE',
                [data.proveedor_id, data.correo_seleccionado]
            );
            if (correoValido.rows.length === 0) {
                throw new Error('El correo seleccionado no pertenece al proveedor o está inactivo');
            }

            // Validar pagos
            const pagos = await client.query(
                `SELECT id, monto, moneda FROM pagos 
         WHERE id = ANY($1) AND proveedor_id = $2 AND pagado = TRUE AND activo = TRUE`,
                [data.pago_ids, data.proveedor_id]
            );

            if (pagos.rows.length !== data.pago_ids.length) {
                throw new Error('Algunos pagos no existen, no pertenecen al proveedor o no están pagados');
            }

            // Calcular totales
            const montoTotal = pagos.rows.reduce((sum, p) => sum + parseFloat(p.monto), 0);

            // Crear correo
            const result = await client.query(
                `INSERT INTO envios_correos (
          proveedor_id,
          correo_seleccionado,
          usuario_envio_id,
          asunto,
          cuerpo,
          estado,
          cantidad_pagos,
          monto_total,
          fecha_generacion
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
        RETURNING *`,
                [
                    data.proveedor_id,
                    data.correo_seleccionado,
                    data.usuario_id,
                    data.asunto,
                    data.cuerpo,
                    EstadoCorreo.BORRADOR,
                    data.pago_ids.length,
                    montoTotal
                ]
            );

            const correo = result.rows[0];

            // Insertar detalles
            for (const pagoId of data.pago_ids) {
                await client.query(`INSERT INTO envio_correo_detalle (envio_id, pago_id) VALUES ($1, $2)`, [
                    correo.id,
                    pagoId
                ]);
            }

            await client.query('COMMIT');

            logger.info(`Correo creado manualmente: ID ${correo.id}`);
            return await this.getCorreos(correo.id);
        } catch (error) {
            await client.query('ROLLBACK');
            logger.error('Error al crear correo:', error);
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Actualizar un borrador de correo
     */
    async updateCorreo(
        id: number,
        data: {
            correo_seleccionado?: string;
            asunto?: string;
            cuerpo?: string;
        }
    ) {
        const client = await getClient();

        try {
            await client.query('BEGIN');

            // Verificar que existe y es borrador
            const existing = await client.query('SELECT * FROM envios_correos WHERE id = $1', [id]);

            if (existing.rows.length === 0) {
                throw new Error('Correo no encontrado');
            }

            if (existing.rows[0].estado !== EstadoCorreo.BORRADOR) {
                throw new Error('Solo se pueden editar correos en estado BORRADOR');
            }

            // Validar correo si se proporciona
            if (data.correo_seleccionado) {
                const correoValido = await client.query(
                    'SELECT id FROM proveedor_correos WHERE proveedor_id = $1 AND correo = $2 AND activo = TRUE',
                    [existing.rows[0].proveedor_id, data.correo_seleccionado]
                );
                if (correoValido.rows.length === 0) {
                    throw new Error('El correo seleccionado no es válido para este proveedor');
                }
            }

            const updates: string[] = [];
            const values: any[] = [];
            let paramCount = 1;

            if (data.correo_seleccionado !== undefined) {
                updates.push(`correo_seleccionado = $${paramCount++}`);
                values.push(data.correo_seleccionado);
            }
            if (data.asunto !== undefined) {
                updates.push(`asunto = $${paramCount++}`);
                values.push(data.asunto);
            }
            if (data.cuerpo !== undefined) {
                updates.push(`cuerpo = $${paramCount++}`);
                values.push(data.cuerpo);
            }

            if (updates.length === 0) {
                await client.query('COMMIT');
                return existing.rows[0];
            }

            values.push(id);
            await client.query(`UPDATE envios_correos SET ${updates.join(', ')} WHERE id = $${paramCount}`, values);

            await client.query('COMMIT');

            logger.info(`Correo actualizado: ID ${id}`);
            return await this.getCorreos(id);
        } catch (error) {
            await client.query('ROLLBACK');
            logger.error('Error al actualizar correo:', error);
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Enviar un correo (cambiar estado a ENVIADO y enviar via N8N)
     */
    async enviarCorreo(
        id: number,
        edicionUltimoMomento?: {
            asunto?: string;
            cuerpo?: string;
        }
    ) {
        const client = await getClient();

        try {
            await client.query('BEGIN');

            // Obtener correo completo
            const correo = await this.getCorreos(id);

            if (!correo) {
                throw new Error('Correo no encontrado');
            }

            if (correo.estado !== EstadoCorreo.BORRADOR) {
                throw new Error('Solo se pueden enviar correos en estado BORRADOR');
            }

            // Aplicar ediciones de último momento si las hay
            let asuntoFinal = correo.asunto;
            let cuerpoFinal = correo.cuerpo;

            if (edicionUltimoMomento?.asunto) {
                asuntoFinal = edicionUltimoMomento.asunto;
                await client.query('UPDATE envios_correos SET asunto = $1 WHERE id = $2', [asuntoFinal, id]);
            }

            if (edicionUltimoMomento?.cuerpo) {
                cuerpoFinal = edicionUltimoMomento.cuerpo;
                await client.query('UPDATE envios_correos SET cuerpo = $1 WHERE id = $2', [cuerpoFinal, id]);
            }

            // Enviar a N8N con el ID del usuario que envía
            await n8nClient.enviarCorreo({
                destinatario: correo.correo_seleccionado,
                asunto: asuntoFinal,
                cuerpo: cuerpoFinal,
                pagos: correo.pagos_incluidos || [],
                proveedor: {
                    nombre: correo.proveedor_nombre,
                    lenguaje: correo.proveedor_lenguaje
                },
                usuario_id: correo.usuario_envio_id
            });

            // Actualizar estado del correo
            await client.query(
                `UPDATE envios_correos 
         SET estado = $1, fecha_envio = NOW() 
         WHERE id = $2`,
                [EstadoCorreo.ENVIADO, id]
            );

            // Actualizar flag gmail_enviado en todos los pagos incluidos
            await client.query(
                `UPDATE pagos 
         SET gmail_enviado = TRUE 
         WHERE id IN (
           SELECT pago_id FROM envio_correo_detalle WHERE envio_id = $1
         )`,
                [id]
            );

            await client.query('COMMIT');

            logger.info(`Correo enviado exitosamente: ID ${id}`, {
                destinatario: correo.correo_seleccionado,
                cantidadPagos: correo.cantidad_pagos
            });

            return await this.getCorreos(id);
        } catch (error) {
            await client.query('ROLLBACK');
            logger.error('Error al enviar correo:', error);
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Eliminar un borrador de correo
     */
    async deleteCorreo(id: number) {
        const client = await getClient();

        try {
            await client.query('BEGIN');

            const existing = await client.query('SELECT * FROM envios_correos WHERE id = $1', [id]);

            if (existing.rows.length === 0) {
                throw new Error('Correo no encontrado');
            }

            if (existing.rows[0].estado === EstadoCorreo.ENVIADO) {
                throw new Error('No se pueden eliminar correos ya enviados');
            }

            // Eliminar detalles (por CASCADE)
            await client.query('DELETE FROM envio_correo_detalle WHERE envio_id = $1', [id]);

            // Eliminar correo
            await client.query('DELETE FROM envios_correos WHERE id = $1', [id]);

            await client.query('COMMIT');

            logger.info(`Correo eliminado: ID ${id}`);
            return existing.rows[0];
        } catch (error) {
            await client.query('ROLLBACK');
            logger.error('Error al eliminar correo:', error);
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Generar asunto del correo
     */
    private generarAsunto(proveedorNombre: string, cantidadPagos: number): string {
        const fecha = new Date().toLocaleDateString('es-ES', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
        return `Notificación de Pagos - ${proveedorNombre} - ${cantidadPagos} pago(s) - ${fecha}`;
    }

    /**
     * Generar cuerpo del correo
     */
    private async generarCuerpo(
        client: any,
        proveedorNombre: string,
        lenguaje: string,
        pagoIds: number[]
    ): Promise<string> {
        // Obtener detalles de los pagos
        const pagos = await client.query(
            `SELECT p.*, c.nombre as cliente_nombre
       FROM pagos p
       LEFT JOIN pago_cliente pc ON p.id = pc.pago_id
       LEFT JOIN clientes c ON pc.cliente_id = c.id
       WHERE p.id = ANY($1)
       ORDER BY p.fecha_creacion`,
            [pagoIds]
        );

        // Plantilla según idioma
        const saludo = lenguaje === 'Français'
            ? `Cher/Chère ${proveedorNombre},`
            : lenguaje === 'English'
                ? `Dear ${proveedorNombre},`
                : `Estimado/a ${proveedorNombre},`;

        const intro = lenguaje === 'Français'
            ? 'Nous vous informons des paiements suivants effectués:'
            : lenguaje === 'English'
                ? 'We inform you about the following payments made:'
                : 'Le notificamos los siguientes pagos realizados:';

        const despedida = lenguaje === 'Français'
            ? 'Cordialement,\nTerra Canada'
            : lenguaje === 'English'
                ? 'Best regards,\nTerra Canada'
                : 'Atentamente,\nTerra Canada';

        // Construir lista de pagos
        let listaPagos = '\n\n';
        let totalGeneral: { [key: string]: number } = {};

        for (const pago of pagos.rows) {
            listaPagos += `• Cliente: ${pago.cliente_nombre || 'N/A'}\n`;
            listaPagos += `  Código de reserva: ${pago.codigo_reserva}\n`;
            listaPagos += `  Monto: $${parseFloat(pago.monto).toFixed(2)} ${pago.moneda}\n`;
            if (pago.descripcion) {
                listaPagos += `  Descripción: ${pago.descripcion}\n`;
            }
            listaPagos += '\n';

            // Acumular totales por moneda
            if (!totalGeneral[pago.moneda]) {
                totalGeneral[pago.moneda] = 0;
            }
            totalGeneral[pago.moneda] += parseFloat(pago.monto);
        }

        // Agregar totales
        listaPagos += '---\n';
        const labelTotal = lenguaje === 'Français'
            ? 'Total'
            : lenguaje === 'English'
                ? 'Total'
                : 'Total';

        for (const [moneda, total] of Object.entries(totalGeneral)) {
            listaPagos += `${labelTotal}: $${total.toFixed(2)} ${moneda}\n`;
        }

        return `${saludo}\n\n${intro}${listaPagos}\n${despedida}`;
    }
}

export const correosService = new CorreosService();
