const { test, describe, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

// Forzar entorno de pruebas con base en memoria
process.env.NODE_ENV = 'test';

const { db, initDatabase, dbGet, dbRun, dbAll } = require('../src/database');
const { hashPassword, generateToken } = require('../src/controllers/authController');
const { uploadPhoto, getUserPhotos, getPhotoById } = require('../src/controllers/photoController');

describe('Pruebas Unitarias de Fotos y Subida - EcoScan (Sprint 2)', async () => {
  let testUserId = null;
  let testUserToken = null;

  // Imagen dummy base64 de 1x1 pixel JPEG
  const sampleBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';

  before(async () => {
    await initDatabase();

    // Crear un usuario de prueba en la tabla Usuario
    const passwordHash = await hashPassword('Eco123456');
    const userRes = await dbRun(
      'INSERT INTO Usuario (nombre_completo, correo_electronico, password_hash) VALUES (?, ?, ?)',
      ['Adriel Ramos Tester', 'adriel.test@ecoscan.com', passwordHash]
    );
    testUserId = userRes.lastID;
    testUserToken = generateToken({
      id: testUserId,
      nombre_completo: 'Adriel Ramos Tester',
      correo_electronico: 'adriel.test@ecoscan.com'
    });
  });

  test('1. [BD - Tarea 970] La tabla Fotos debe existir y tener la estructura correcta', async () => {
    // Verificar tabla en sqlite_master
    const tableInfo = await dbGet(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='Fotos'"
    );
    assert.ok(tableInfo, 'La tabla Fotos debe existir en la base de datos');
    assert.equal(tableInfo.name, 'Fotos');

    // Verificar columnas de la tabla Fotos
    const columns = await dbAll("PRAGMA table_info(Fotos)");
    const columnNames = columns.map(c => c.name);

    assert.ok(columnNames.includes('id'), 'Debe incluir id');
    assert.ok(columnNames.includes('usuario_id'), 'Debe incluir usuario_id');
    assert.ok(columnNames.includes('nombre_archivo'), 'Debe incluir nombre_archivo');
    assert.ok(columnNames.includes('ruta_archivo'), 'Debe incluir ruta_archivo');
    assert.ok(columnNames.includes('url_foto'), 'Debe incluir url_foto');
    assert.ok(columnNames.includes('tipo_residuo'), 'Debe incluir tipo_residuo');
    assert.ok(columnNames.includes('tamano_bytes'), 'Debe incluir tamano_bytes');
    assert.ok(columnNames.includes('puntos_otorgados'), 'Debe incluir puntos_otorgados');
    assert.ok(columnNames.includes('fecha_creacion'), 'Debe incluir fecha_creacion');
  });

  test('2. [Backend - Tarea 1000] Subir y guardar foto asociada al usuario exitosamente', async () => {
    let responseStatus = null;
    let responseData = null;

    const mockReq = {
      user: { id: testUserId },
      body: {
        imageBase64: sampleBase64,
        tipoResiduo: 'plastico',
        nombrePersonalizado: 'Botella de refresco PET'
      }
    };

    const mockRes = {
      status(code) {
        responseStatus = code;
        return this;
      },
      json(data) {
        responseData = data;
        return this;
      }
    };

    await uploadPhoto(mockReq, mockRes);

    assert.equal(responseStatus, 201, 'Debe responder con status 201 Created');
    assert.equal(responseData.success, true);
    assert.ok(responseData.photo, 'Debe devolver el objeto de foto');
    assert.equal(responseData.photo.usuarioId, testUserId, 'Debe estar asociada al usuario');
    assert.equal(responseData.photo.puntosOtorgados, 50, 'El residuo plástico otorga 50 puntos');
    assert.ok(responseData.photo.urlFoto.startsWith('/uploads/photos/'));

    // Verificar persistencia en base de datos
    const dbRecord = await dbGet('SELECT * FROM Fotos WHERE id = ?', [responseData.photo.id]);
    assert.ok(dbRecord, 'El registro debe existir en SQLite');
    assert.equal(dbRecord.usuario_id, testUserId);
  });

  test('3. [Validación] Debe rechazar subida si no se envía imagen', async () => {
    let responseStatus = null;
    let responseData = null;

    const mockReq = {
      user: { id: testUserId },
      body: {
        tipoResiduo: 'vidrio'
      }
    };

    const mockRes = {
      status(code) {
        responseStatus = code;
        return this;
      },
      json(data) {
        responseData = data;
        return this;
      }
    };

    await uploadPhoto(mockReq, mockRes);

    assert.equal(responseStatus, 400);
    assert.equal(responseData.success, false);
    assert.match(responseData.message, /Base64 es obligatoria/i);
  });

  test('4. [Validación] Debe rechazar subida si el usuario no existe', async () => {
    let responseStatus = null;
    let responseData = null;

    const mockReq = {
      body: {
        usuarioId: 999999, // ID inexistente
        imageBase64: sampleBase64,
        tipoResiduo: 'aluminio'
      }
    };

    const mockRes = {
      status(code) {
        responseStatus = code;
        return this;
      },
      json(data) {
        responseData = data;
        return this;
      }
    };

    await uploadPhoto(mockReq, mockRes);

    assert.equal(responseStatus, 404);
    assert.equal(responseData.success, false);
    assert.match(responseData.message, /no existe/i);
  });

  test('5. [Puntos] Asignación correcta de EcoPuntos según residuo', async () => {
    let responseStatus = null;
    let responseData = null;

    const mockReq = {
      user: { id: testUserId },
      body: {
        imageBase64: sampleBase64,
        tipoResiduo: 'aluminio'
      }
    };

    const mockRes = {
      status(code) {
        responseStatus = code;
        return this;
      },
      json(data) {
        responseData = data;
        return this;
      }
    };

    await uploadPhoto(mockReq, mockRes);

    assert.equal(responseStatus, 201);
    assert.equal(responseData.photo.puntosOtorgados, 70, 'El aluminio otorga 70 puntos');
  });

  test('6. [Consulta] Obtener fotos e historial del usuario', async () => {
    let responseStatus = null;
    let responseData = null;

    const mockReq = {
      params: { userId: testUserId.toString() }
    };

    const mockRes = {
      status(code) {
        responseStatus = code;
        return this;
      },
      json(data) {
        responseData = data;
        return this;
      }
    };

    await getUserPhotos(mockReq, mockRes);

    assert.equal(responseStatus, 200);
    assert.equal(responseData.success, true);
    assert.ok(responseData.photos.length >= 2, 'Debe contener al menos 2 fotos guardadas');
    assert.ok(responseData.totalPuntos >= 120, 'Debe sumar el total de puntos acumulados');
  });

  test('7. [Consulta Individual] Obtener foto por su ID', async () => {
    // Obtener la última foto
    const ultimaFoto = await dbGet('SELECT id FROM Fotos ORDER BY id DESC LIMIT 1');

    let responseStatus = null;
    let responseData = null;

    const mockReq = {
      params: { id: ultimaFoto.id.toString() }
    };

    const mockRes = {
      status(code) {
        responseStatus = code;
        return this;
      },
      json(data) {
        responseData = data;
        return this;
      }
    };

    await getPhotoById(mockReq, mockRes);

    assert.equal(responseStatus, 200);
    assert.equal(responseData.success, true);
    assert.equal(responseData.photo.id, ultimaFoto.id);
  });
});
