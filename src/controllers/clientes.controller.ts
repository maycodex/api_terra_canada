import { Request, Response } from 'express';
import { clientesService } from '../services/clientes.service';
import { sendSuccess, sendError, HTTP_STATUS } from '../utils/response.util';
import logger from '../config/logger';

export class ClientesController {
  async getClientes(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const clienteId = id ? parseInt(id) : undefined;
      const clientes = await clientesService.getClientes(clienteId);

      if (clienteId && !clientes) {
        return sendError(res, HTTP_STATUS.NOT_FOUND, 'Cliente no encontrado');
      }

      return sendSuccess(res, HTTP_STATUS.OK, clienteId ? 'Cliente obtenido' : 'Clientes obtenidos', clientes);
    } catch (error) {
      logger.error('Error en getClientes:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al obtener clientes');
    }
  }

  async createCliente(req: Request, res: Response): Promise<Response> {
    try {
      const cliente = await clientesService.createCliente(req.body);
      return sendSuccess(res, HTTP_STATUS.CREATED, 'Cliente creado', cliente);
    } catch (error) {
      logger.error('Error en createCliente:', error);
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al crear cliente');
    }
  }

  async updateCliente(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      const cliente = await clientesService.updateCliente(id, req.body);
      return sendSuccess(res, HTTP_STATUS.OK, 'Cliente actualizado', cliente);
    } catch (error: any) {
      logger.error('Error en updateCliente:', error);
      if (error.message === 'Cliente no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al actualizar cliente');
    }
  }

  async deleteCliente(req: Request, res: Response): Promise<Response> {
    try {
      const id = parseInt(req.params.id);
      await clientesService.deleteCliente(id);
      return sendSuccess(res, HTTP_STATUS.OK, 'Cliente desactivado', null);
    } catch (error: any) {
      logger.error('Error en deleteCliente:', error);
      if (error.message === 'Cliente no encontrado') {
        return sendError(res, HTTP_STATUS.NOT_FOUND, error.message);
      }
      return sendError(res, HTTP_STATUS.INTERNAL_SERVER_ERROR, 'Error al eliminar cliente');
    }
  }
}

export const clientesController = new ClientesController();
