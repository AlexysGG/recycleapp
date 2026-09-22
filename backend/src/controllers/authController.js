const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { dbGet, dbRun } = require('../database');

const JWT_SECRET = process.env.JWT_SECRET || 'ecoscan_jwt_secret_key_sprint_1_2026';
const JWT_EXPIRES_IN = '24h';

// Regex de validación de correo electrónico
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Tarea 950: Backend: encriptado de contraseñas (bcrypt o similar) (Adriel Ramos)
 * Genera hash seguro con salt de 10 rondas
 */
async function hashPassword(plainPassword) {
  const saltRounds = 10;
  return await bcrypt.hash(plainPassword, saltRounds);
}

/**
 * Compara contraseña en texto plano con el hash almacenado
 */
async function comparePassword(plainPassword, hashedPassword) {
  return await bcrypt.compare(plainPassword, hashedPassword);
}

/**
 * Tarea 970: Generación de token JWT para manejo de sesión
 */
function generateToken(user) {
  const payload = {
    id: user.id,
    nombreCompleto: user.nombre_completo,
    correoElectronico: user.correo_electronico
  };
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

/**
 * Tarea 1000: Backend: endpoint de registro con validación de datos (Alexis Hernandez)
 * POST /api/auth/register
 */
async function register(req, res) {
  try {
    const { nombreCompleto, correoElectronico, password, terminosAceptados } = req.body;

    // 1. Validaciones de presencia
    if (!nombreCompleto || typeof nombreCompleto !== 'string' || nombreCompleto.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'El nombre completo es requerido y no puede estar vacío.'
      });
    }

    if (nombreCompleto.trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: 'El nombre completo debe tener al menos 2 caracteres.'
      });
    }

    if (!correoElectronico || typeof correoElectronico !== 'string' || correoElectronico.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'El correo electrónico es requerido.'
      });
    }

    // 2. Validación de formato de correo
    const emailNormalizado = correoElectronico.trim().toLowerCase();
    if (!EMAIL_REGEX.test(emailNormalizado)) {
      return res.status(400).json({
        success: false,
        message: 'El formato del correo electrónico no es válido.'
      });
    }

    // 3. Validación de contraseña (mínimo 6 caracteres)
    if (!password || typeof password !== 'string' || password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'La contraseña debe tener al menos 6 caracteres.'
      });
    }

    // 4. Validación de términos y condiciones
    if (terminosAceptados !== true && terminosAceptados !== 1 && terminosAceptados !== 'true') {
      return res.status(400).json({
        success: false,
        message: 'Debes aceptar los Términos y Condiciones para registrarte.'
      });
    }

    // 5. Verificar si el usuario ya existe
    const usuarioExistente = await dbGet(
      'SELECT id FROM Usuario WHERE correo_electronico = ?',
      [emailNormalizado]
    );

    if (usuarioExistente) {
      return res.status(409).json({
        success: false,
        message: 'El correo electrónico ya está registrado. Por favor inicia sesión.'
      });
    }

    // 6. Encriptación de contraseña (Tarea 950)
    const passwordHash = await hashPassword(password);

    // 7. Inserción en base de datos (Tarea 900)
    const resultado = await dbRun(
      `INSERT INTO Usuario (nombre_completo, correo_electronico, password_hash, terminos_aceptados) 
       VALUES (?, ?, ?, 1)`,
      [nombreCompleto.trim(), emailNormalizado, passwordHash]
    );

    const nuevoUsuario = {
      id: resultado.lastID,
      nombre_completo: nombreCompleto.trim(),
      correo_electronico: emailNormalizado,
      terminos_aceptados: 1
    };

    // 8. Generación de token JWT (Tarea 970)
    const token = generateToken(nuevoUsuario);

    return res.status(201).json({
      success: true,
      message: 'Usuario registrado exitosamente en EcoScan.',
      token,
      user: {
        id: nuevoUsuario.id,
        nombreCompleto: nuevoUsuario.nombre_completo,
        correoElectronico: nuevoUsuario.correo_electronico
      }
    });
  } catch (error) {
    console.error('Error en register:', error);
    return res.status(500).json({
      success: false,
      message: 'Ocurrió un error en el servidor al procesar el registro.'
    });
  }
}

/**
 * Tarea 970: Backend: endpoint de login + manejo de sesión/token (JWT) (Marisol Moreno)
 * POST /api/auth/login
 */
async function login(req, res) {
  try {
    const { correoElectronico, password } = req.body;

    // 1. Validaciones básicas de entrada
    if (!correoElectronico || !password) {
      return res.status(400).json({
        success: false,
        message: 'Debes proporcionar correo electrónico y contraseña.'
      });
    }

    const emailNormalizado = correoElectronico.trim().toLowerCase();

    // 2. Buscar usuario por correo electrónico
    const usuario = await dbGet(
      'SELECT * FROM Usuario WHERE correo_electronico = ?',
      [emailNormalizado]
    );

    if (!usuario) {
      return res.status(401).json({
        success: false,
        message: 'Credenciales inválidas. Correo o contraseña incorrectos.'
      });
    }

    // 3. Comparar contraseña encriptada con bcrypt (Tarea 950)
    const esPasswordValido = await comparePassword(password, usuario.password_hash);
    if (!esPasswordValido) {
      return res.status(401).json({
        success: false,
        message: 'Credenciales inválidas. Correo o contraseña incorrectos.'
      });
    }

    // 4. Generar token de sesión JWT (Tarea 970)
    const token = generateToken(usuario);

    return res.status(200).json({
      success: true,
      message: 'Inicio de sesión exitoso.',
      token,
      user: {
        id: usuario.id,
        nombreCompleto: usuario.nombre_completo,
        correoElectronico: usuario.correo_electronico,
        fechaCreacion: usuario.fecha_creacion
      }
    });
  } catch (error) {
    console.error('Error en login:', error);
    return res.status(500).json({
      success: false,
      message: 'Ocurrió un error en el servidor al iniciar sesión.'
    });
  }
}

/**
 * Endpoint de verificación de sesión mediante JWT
 * GET /api/auth/verify
 */
async function verifySession(req, res) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Token de autorización ausente o inválido.'
      });
    }

    const token = authHeader.split(' ')[1];
    jwt.verify(token, JWT_SECRET, async (err, decoded) => {
      if (err) {
        return res.status(401).json({
          success: false,
          message: 'Token expirado o inválido.'
        });
      }

      const usuario = await dbGet(
        'SELECT id, nombre_completo, correo_electronico, fecha_creacion FROM Usuario WHERE id = ?',
        [decoded.id]
      );

      if (!usuario) {
        return res.status(404).json({
          success: false,
          message: 'Usuario no encontrado.'
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Sesión válida.',
        user: {
          id: usuario.id,
          nombreCompleto: usuario.nombre_completo,
          correoElectronico: usuario.correo_electronico,
          fechaCreacion: usuario.fecha_creacion
        }
      });
    });
  } catch (error) {
    console.error('Error en verifySession:', error);
    return res.status(500).json({
      success: false,
      message: 'Error al verificar sesión.'
    });
  }
}

module.exports = {
  register,
  login,
  verifySession,
  hashPassword,
  comparePassword,
  generateToken,
  JWT_SECRET
};
