const path = require('path');
const fs = require('fs');
const { dbGet, dbAll, dbRun } = require('../database');

// Directorio para almacenar imágenes de fotos subidas
const uploadsDir = path.resolve(__dirname, '../../uploads/photos');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

/**
 * Mapeo de residuos reciclables reconocidos y sus puntos ecológicos
 */
const WASTE_CATEGORIES = {
  'plastico': { name: 'Botella de plástico PET', points: 50 },
  'vidrio': { name: 'Botella o envase de vidrio', points: 60 },
  'aluminio': { name: 'Lata de aluminio', points: 70 },
  'carton': { name: 'Caja o envase de cartón', points: 40 },
  'papel': { name: 'Papel reciclable', points: 30 },
  'organico': { name: 'Residuo orgánico compostable', points: 35 },
  'general': { name: 'Residuo reciclable clasificado', points: 50 }
};

/**
 * Tarea 1000: Backend: endpoint para subir y guardar la foto (asociada al usuario)
 * POST /api/photos/upload
 * 
 * Soporta payload JSON con Base64 (ideal para Flutter móvil y web)
 * Headers opcionales o requeridos: Authorization: Bearer <jwt>
 * Body: {
 *   imageBase64: "data:image/jpeg;base64,...",
 *   tipoResiduo: "plastico" | "vidrio" | etc.,
 *   nombrePersonalizado: "Mi residuo",
 *   usuarioId: 1 (opcional si viene en token)
 * }
 */
async function uploadPhoto(req, res) {
  try {
    const { imageBase64, tipoResiduo, nombrePersonalizado, usuarioId } = req.body;

    // 1. Determinar el usuario propietario de la foto
    const finalUserId = req.user?.id || usuarioId;
    if (!finalUserId) {
      return res.status(401).json({
        success: false,
        message: 'No se pudo identificar al usuario. Inicia sesión o proporciona usuarioId.'
      });
    }

    // 2. Verificar que el usuario exista en la base de datos
    const usuarioExiste = await dbGet('SELECT id, nombre_completo FROM Usuario WHERE id = ?', [finalUserId]);
    if (!usuarioExiste) {
      return res.status(404).json({
        success: false,
        message: 'El usuario especificado no existe en la base de datos.'
      });
    }

    // 3. Validar presencia de la imagen
    if (!imageBase64 || typeof imageBase64 !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'La imagen en formato Base64 es obligatoria.'
      });
    }

    // 4. Procesar el Base64 y extraer extensión
    let extension = 'jpg';
    let base64Data = imageBase64;

    const matches = imageBase64.match(/^data:image\/([a-zA-Z0-9+]+);base64,(.+)$/);
    if (matches) {
      extension = matches[1] === 'jpeg' ? 'jpg' : matches[1];
      base64Data = matches[2];
    }

    // Decodificar a buffer binario
    const imageBuffer = Buffer.from(base64Data, 'base64');
    if (imageBuffer.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Los datos de la imagen son inválidos o están vacíos.'
      });
    }

    // 5. Generar nombre de archivo único con timestamp
    const timestamp = Date.now();
    const randomSuffix = Math.floor(Math.random() * 10000);
    const fileName = `foto_user_${finalUserId}_${timestamp}_${randomSuffix}.${extension}`;
    const filePath = path.join(uploadsDir, fileName);

    // Guardar archivo en disco
    await fs.promises.writeFile(filePath, imageBuffer);

    // 6. Determinar puntos y categoría
    const keyCat = (tipoResiduo || 'plastico').toLowerCase();
    const categoryInfo = WASTE_CATEGORIES[keyCat] || WASTE_CATEGORIES['general'];
    const puntosOtorgados = categoryInfo.points;
    const nombreTipoResiduo = categoryInfo.name;

    // 7. Generar URL pública o relativa para la app móvil
    const urlFoto = `/uploads/photos/${fileName}`;

    // 8. Tarea 970: Insertar en la tabla 'Fotos' de la base de datos
    const insertResult = await dbRun(
      `INSERT INTO Fotos (
        usuario_id, 
        nombre_archivo, 
        ruta_archivo, 
        url_foto, 
        tipo_residuo, 
        tamano_bytes, 
        puntos_otorgados
      ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        finalUserId,
        nombrePersonalizado || fileName,
        filePath,
        urlFoto,
        nombreTipoResiduo,
        imageBuffer.length,
        puntosOtorgados
      ]
    );

    const fotoId = insertResult.lastID;

    // Consultar registro recién creado
    const fotoGuardada = await dbGet('SELECT * FROM Fotos WHERE id = ?', [fotoId]);

    return res.status(201).json({
      success: true,
      message: 'Foto guardada y registrada exitosamente.',
      photo: {
        id: fotoGuardada.id,
        usuarioId: fotoGuardada.usuario_id,
        nombreArchivo: fotoGuardada.nombre_archivo,
        urlFoto: fotoGuardada.url_foto,
        tipoResiduo: fotoGuardada.tipo_residuo,
        tamanoBytes: fotoGuardada.tamano_bytes,
        puntosOtorgados: fotoGuardada.puntos_otorgados,
        fechaCreacion: fotoGuardada.fecha_creacion
      },
      usuario: {
        id: usuarioExiste.id,
        nombreCompleto: usuarioExiste.nombre_completo
      }
    });

  } catch (error) {
    console.error('Error al subir foto:', error);
    return res.status(500).json({
      success: false,
      message: 'Ocurrió un error en el servidor al guardar la foto.'
    });
  }
}

/**
 * Obtener fotos de un usuario específico o del usuario autenticado
 * GET /api/photos/user/:userId
 */
async function getUserPhotos(req, res) {
  try {
    const targetUserId = req.params.userId || req.user?.id;

    if (!targetUserId) {
      return res.status(400).json({
        success: false,
        message: 'Identificador de usuario no proporcionado.'
      });
    }

    const fotos = await dbAll(
      'SELECT * FROM Fotos WHERE usuario_id = ? ORDER BY fecha_creacion DESC',
      [targetUserId]
    );

    // Calcular resumen de puntos
    const totalPuntos = fotos.reduce((acc, f) => acc + (f.puntos_otorgados || 0), 0);

    return res.status(200).json({
      success: true,
      usuarioId: parseInt(targetUserId, 10),
      totalFotos: fotos.length,
      totalPuntos,
      photos: fotos.map(f => ({
        id: f.id,
        nombreArchivo: f.nombre_archivo,
        urlFoto: f.url_foto,
        tipoResiduo: f.tipo_residuo,
        tamanoBytes: f.tamano_bytes,
        puntosOtorgados: f.puntos_otorgados,
        fechaCreacion: f.fecha_creacion
      }))
    });

  } catch (error) {
    console.error('Error al consultar fotos del usuario:', error);
    return res.status(500).json({
      success: false,
      message: 'Error en el servidor al obtener historial de fotos.'
    });
  }
}

/**
 * Obtener detalles de una foto individual por ID
 * GET /api/photos/:id
 */
async function getPhotoById(req, res) {
  try {
    const fotoId = req.params.id;
    const foto = await dbGet('SELECT * FROM Fotos WHERE id = ?', [fotoId]);

    if (!foto) {
      return res.status(404).json({
        success: false,
        message: 'Foto no encontrada.'
      });
    }

    return res.status(200).json({
      success: true,
      photo: {
        id: foto.id,
        usuarioId: foto.usuario_id,
        nombreArchivo: foto.nombre_archivo,
        urlFoto: foto.url_foto,
        tipoResiduo: foto.tipo_residuo,
        tamanoBytes: foto.tamano_bytes,
        puntosOtorgados: foto.puntos_otorgados,
        fechaCreacion: foto.fecha_creacion
      }
    });

  } catch (error) {
    console.error('Error al obtener foto por id:', error);
    return res.status(500).json({
      success: false,
      message: 'Error en el servidor al obtener la foto.'
    });
  }
}

module.exports = {
  uploadPhoto,
  getUserPhotos,
  getPhotoById,
  uploadsDir
};
