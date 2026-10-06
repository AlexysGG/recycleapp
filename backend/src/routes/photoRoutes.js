const express = require('express');
const router = express.Router();
const { uploadPhoto, getUserPhotos, getPhotoById } = require('../controllers/photoController');
const { optionalAuth, authenticateToken } = require('../middlewares/authMiddleware');

// Tarea 1000: Endpoint para subir y guardar la foto asociada al usuario
// Soporta tanto token Bearer como usuarioId en el body
router.post('/upload', optionalAuth, uploadPhoto);

// Consultar fotos de un usuario específico
router.get('/user/:userId', optionalAuth, getUserPhotos);

// Consultar fotos del usuario autenticado actualmente
router.get('/my-photos', authenticateToken, getUserPhotos);

// Consultar foto por ID
router.get('/:id', optionalAuth, getPhotoById);

module.exports = router;
