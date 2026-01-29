import multer from 'multer';
import path from 'path';
import { config } from '../config/environment';
import { Request } from 'express';

// Configuración de almacenamiento
const storage = multer.diskStorage({
  destination: (req, _file, cb) => {
    // Determinar carpeta según el tipo de documento
    const tipoDocumento = req.body.tipo_documento;
    let folder = 'uploads';
    
    if (tipoDocumento === 'FACTURA') {
      folder = path.join(config.upload.dir, 'facturas');
    } else if (tipoDocumento === 'DOCUMENTO_BANCO') {
      folder = path.join(config.upload.dir, 'documentos_banco');
    }
    
    cb(null, folder);
  },
  filename: (_req, file, cb) => {
    // Generar nombre único: timestamp-originalname
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const name = path.basename(file.originalname, ext);
    cb(null, `${name}-${uniqueSuffix}${ext}`);
  }
});

// Filtro de archivos
const fileFilter = (
  _req: Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback
) => {
  // Solo permitir PDFs
  if (config.upload.allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Solo se permiten archivos PDF'));
  }
};

// Configuración de multer
export const uploadConfig = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: config.upload.maxSize // 10MB por defecto
  }
});

// Middleware para subir un solo archivo
export const uploadSingle = uploadConfig.single('file');

// Middleware para subir múltiples archivos
export const uploadMultiple = uploadConfig.array('files', 5);
