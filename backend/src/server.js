const path = require('path');
const express = require('express');
const cors = require('cors');
const { initDatabase } = require('./database');
const authRoutes = require('./routes/authRoutes');
const photoRoutes = require('./routes/photoRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares globales (con soporte para payloads grandes de fotos base64)
app.use(cors());
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ limit: '20mb', extended: true }));

// Servir archivos estáticos subidos (fotos escaneadas)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Logging middleware simple
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Ruta de estado / salud
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    app: 'EcoScan Backend API',
    sprint: 'Sprint 2 - Captura y Almacenamiento de Fotos',
    timestamp: new Date().toISOString()
  });
});

// Rutas de la API
app.use('/api/auth', authRoutes);
app.use('/api/photos', photoRoutes);

// Manejador de rutas no encontradas (404)
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Ruta ${req.originalUrl} no encontrada.`
  });
});

// Inicialización del servidor
async function startServer() {
  try {
    await initDatabase();
    app.listen(PORT, '0.0.0.0', () => {
      console.log('========================================================');
      console.log(` Servidor EcoScan API activo en http://localhost:${PORT}`);
      console.log(` Para emulador Android: http://10.0.2.2:${PORT}`);
      console.log(` Para simulador iOS:     http://localhost:${PORT}`);
      console.log('========================================================');
    });
  } catch (error) {
    console.error('Fallo al inicializar servidor:', error);
    process.exit(1);
  }
}

if (process.env.NODE_ENV !== 'test') {
  startServer();
}

module.exports = app;
