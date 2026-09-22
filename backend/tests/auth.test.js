const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const { initDatabase, dbRun, dbGet, db } = require('../src/database');
const { hashPassword, comparePassword, generateToken, JWT_SECRET } = require('../src/controllers/authController');
const jwt = require('jsonwebtoken');

describe('Pruebas Unitarias de Autenticación - EcoScan (Sprint 1)', () => {
  before(async () => {
    // Asegurar base de datos limpia para pruebas
    await initDatabase();
    await dbRun('DELETE FROM Usuario');
  });

  after(async () => {
    await new Promise((resolve) => db.close(resolve));
  });

  // Tarea 900: Tabla Usuario
  test('1. [BD] La tabla Usuario debe existir y permitir inserción de registros válidos', async () => {
    const tableInfo = await dbGet("SELECT name FROM sqlite_master WHERE type='table' AND name='Usuario'");
    assert.strictEqual(tableInfo.name, 'Usuario', 'La tabla Usuario debe existir en SQLite');
  });

  // Tarea 950: Encriptado de contraseñas (bcrypt)
  test('2. [Seguridad] Debe encriptar contraseñas usando bcrypt con hash seguro', async () => {
    const plainPass = 'EcoPass2026!';
    const hashed = await hashPassword(plainPass);

    assert.notStrictEqual(hashed, plainPass, 'El hash no debe coincidir con la contraseña plana');
    assert.ok(hashed.startsWith('$2a$') || hashed.startsWith('$2b$'), 'El hash debe tener formato bcrypt');

    const isValid = await comparePassword(plainPass, hashed);
    assert.strictEqual(isValid, true, 'comparePassword debe validar la contraseña correcta');

    const isInvalid = await comparePassword('ContraseñaErronea', hashed);
    assert.strictEqual(isInvalid, false, 'comparePassword debe rechazar contraseñas incorrectas');
  });

  // Tarea 970: Generación y verificación de token JWT
  test('3. [Sesión] Debe generar y verificar tokens JWT con payload de usuario', () => {
    const mockUser = {
      id: 1,
      nombre_completo: 'Alexis Hernandez',
      correo_electronico: 'alexis@ecoscan.com'
    };

    const token = generateToken(mockUser);
    assert.ok(token && typeof token === 'string', 'Debe generar un token string');

    const decoded = jwt.verify(token, JWT_SECRET);
    assert.strictEqual(decoded.id, mockUser.id);
    assert.strictEqual(decoded.nombreCompleto, mockUser.nombre_completo);
    assert.strictEqual(decoded.correoElectronico, mockUser.correo_electronico);
  });

  // Tarea 1000: Endpoint de registro y validaciones
  test('4. [Registro] Registro exitoso con datos válidos y contraseña encriptada', async () => {
    const plainPassword = 'password123';
    const hashedPassword = await hashPassword(plainPassword);

    const resultado = await dbRun(
      `INSERT INTO Usuario (nombre_completo, correo_electronico, password_hash, terminos_aceptados)
       VALUES (?, ?, ?, 1)`,
      ['Alexis Hernandez', 'alexis.test@ecoscan.com', hashedPassword]
    );

    assert.ok(resultado.lastID > 0, 'Debe insertar y retornar ID de usuario');

    const usuarioGuardado = await dbGet(
      'SELECT * FROM Usuario WHERE correo_electronico = ?',
      ['alexis.test@ecoscan.com']
    );

    assert.strictEqual(usuarioGuardado.nombre_completo, 'Alexis Hernandez');
    assert.strictEqual(usuarioGuardado.correo_electronico, 'alexis.test@ecoscan.com');
    assert.strictEqual(usuarioGuardado.terminos_aceptados, 1);
    assert.strictEqual(usuarioGuardado.password_hash, hashedPassword);
  });

  test('5. [Registro] Debe impedir el registro con correo duplicado', async () => {
    const emailExistente = 'alexis.test@ecoscan.com';
    const usuarioDuplicado = await dbGet(
      'SELECT id FROM Usuario WHERE correo_electronico = ?',
      [emailExistente]
    );

    assert.ok(usuarioDuplicado, 'Debe detectar que el correo ya está registrado');
  });

  // Tarea 970: Login con manejo de credenciales
  test('6. [Login] Login exitoso con credenciales correctas', async () => {
    const usuario = await dbGet(
      'SELECT * FROM Usuario WHERE correo_electronico = ?',
      ['alexis.test@ecoscan.com']
    );

    assert.ok(usuario, 'El usuario debe existir');
    const esPasswordValido = await comparePassword('password123', usuario.password_hash);
    assert.strictEqual(esPasswordValido, true, 'La contraseña ingresada debe ser válida');

    const token = generateToken(usuario);
    assert.ok(token, 'Debe generar el token de sesión JWT');
  });

  test('7. [Login] Debe rechazar credenciales con contraseña incorrecta', async () => {
    const usuario = await dbGet(
      'SELECT * FROM Usuario WHERE correo_electronico = ?',
      ['alexis.test@ecoscan.com']
    );

    const esPasswordValido = await comparePassword('contraseñaFalsa', usuario.password_hash);
    assert.strictEqual(esPasswordValido, false, 'Debe rechazar la contraseña incorrecta');
  });

  test('8. [Login] Debe rechazar inicio de sesión con correo no registrado', async () => {
    const usuarioNoExiste = await dbGet(
      'SELECT * FROM Usuario WHERE correo_electronico = ?',
      ['noexiste@ecoscan.com']
    );

    assert.strictEqual(usuarioNoExiste, undefined, 'No debe encontrar usuario');
  });

  test('9. [Sesión] Debe rechazar tokens manipulados o inválidos', () => {
    assert.throws(() => {
      jwt.verify('token_invalido_12345', JWT_SECRET);
    }, /jwt malformed|invalid token/i);
  });
});
