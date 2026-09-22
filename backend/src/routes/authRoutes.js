const express = require('express');
const router = express.Router();
const { register, login, verifySession } = require('../controllers/authController');

// Tarea 1000: Endpoint de registro con validación de datos
router.post('/register', register);

// Tarea 970: Endpoint de login + manejo de sesión/token (JWT)
router.post('/login', login);

// Verificación de sesión/token
router.get('/verify', verifySession);

module.exports = router;
