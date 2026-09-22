const express = require('express');
const cors = require('cors');
const { initDatabase } = require('./database');
const authRoutes = require('./routes/authRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares globales
app.use(cors());
app.use(express.json());

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
    sprint: 'Sprint 1 - Autenticación',
    timestamp: new Date().toISOString()
  });
});

// Rutas de autenticación (Sprint 1)
app.use('/api/auth', authRoutes);

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
