const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

// Crear directorio de datos si no existe
const dataDir = path.resolve(__dirname, '../data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const dbPath = process.env.NODE_ENV === 'test' 
  ? ':memory:' 
  : path.join(dataDir, 'ecoscan.sqlite');

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error al conectar con la base de datos SQLite:', err.message);
  } else {
    console.log(`[Base de Datos] Conectado exitosamente a SQLite (${dbPath})`);
  }
});

// Tarea 900: Diseñar e implementar tabla 'Usuario' en la base de datos (Carolina Bonilla)
// Tarea 970 (Sprint 2): Diseñar e implementar tabla 'Fotos' en la base de datos (Carolina Bonilla / Adriel Ramos)
function initDatabase() {
  return new Promise((resolve, reject) => {
    const createUsuarioTable = `
      CREATE TABLE IF NOT EXISTS Usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_completo TEXT NOT NULL,
        correo_electronico TEXT UNIQUE NOT NULL COLLATE NOCASE,
        password_hash TEXT NOT NULL,
        terminos_aceptados INTEGER NOT NULL DEFAULT 1,
        fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    `;

    const createFotosTable = `
      CREATE TABLE IF NOT EXISTS Fotos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nombre_archivo TEXT NOT NULL,
        ruta_archivo TEXT NOT NULL,
        url_foto TEXT,
        tipo_residuo TEXT DEFAULT 'Plástico PET',
        tamano_bytes INTEGER DEFAULT 0,
        puntos_otorgados INTEGER DEFAULT 50,
        fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (usuario_id) REFERENCES Usuario (id) ON DELETE CASCADE
      );
    `;

    db.serialize(() => {
      db.run(createUsuarioTable, (err) => {
        if (err) {
          console.error('Error al crear tabla Usuario:', err.message);
          return reject(err);
        }
        console.log('[Base de Datos] Tabla "Usuario" inicializada correctamente.');
      });

      db.run(createFotosTable, (err) => {
        if (err) {
          console.error('Error al crear tabla Fotos:', err.message);
          return reject(err);
        }
        console.log('[Base de Datos] Tabla "Fotos" inicializada correctamente.');
        resolve();
      });
    });
  });
}

// Helpers de promesas para operaciones async
function dbGet(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

function dbAll(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

function dbRun(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
}

module.exports = {
  db,
  initDatabase,
  dbGet,
  dbAll,
  dbRun
};
