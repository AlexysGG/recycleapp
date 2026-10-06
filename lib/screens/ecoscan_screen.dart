import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import 'ecoscan_gallery_screen.dart';

/// Pantalla de Escaneo y Captura de Residuos (Sprint 2 - Tarea 900)
/// Integra visor de cámara en vivo directamente dentro del recuadro (Image 3)
class EcoScanScreen extends StatefulWidget {
  const EcoScanScreen({super.key});

  @override
  State<EcoScanScreen> createState() => _EcoScanScreenState();
}

class _EcoScanScreenState extends State<EcoScanScreen> with SingleTickerProviderStateMixin {
  final PhotoService _photoService = PhotoService();

  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  Uint8List? _imageBytes;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    // 1. Inicializar animación de la línea láser
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    // 2. Inicializar la cámara nativa integrada dentro del recuadro
    _initLiveCamera();
  }

  Future<void> _initLiveCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Seleccionar cámara trasera principal
        final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Cámara en vivo no disponible: $e');
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  /// Disparo directo desde el recuadro de cámara integrado
  Future<void> _snapLivePhoto() async {
    if (_isProcessing) return;

    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.isTakingPicture) {
      try {
        setState(() {
          _isProcessing = true;
        });

        final XFile photo = await _cameraController!.takePicture();
        final bytes = await photo.readAsBytes();
        await _processAndSavePhoto(bytes, photo.path, 'plastico');
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        _handleCaptureError('cámara integrada', e.toString());
      }
    } else {
      // Si la cámara en vivo no está lista o estamos en emulador sin cámara, simula o usa fallback
      _simulateCapture();
    }
  }

  /// Abre la galería exclusiva con únicamente las fotos capturadas en EcoScan
  void _openEcoScanGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EcoScanGalleryScreen()),
    );
  }

  /// Tarea 800: Diálogo descriptivo y resiliente ante fallas de hardware
  void _handleCaptureError(String origen, String errorDetails) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Aviso de Dispositivo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se pudo capturar desde la $origen.',
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Detalles: $errorDetails',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            const Text(
              '¿Deseas simular una captura de residuo para probar el registro y los EcoPuntos?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _simulateCapture();
            },
            child: const Text('Simular Captura', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Simulación para pruebas en entornos sin cámara física
  void _simulateCapture() {
    final dummyBytes = Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
      0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
      0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xD9
    ]);
    _processAndSavePhoto(dummyBytes, 'demo_pet_bottle.jpg', 'plastico');
  }

  /// Tarea 1000 & 850: Subir foto y mostrar confirmación visual
  Future<void> _processAndSavePhoto(Uint8List bytes, String path, String tipoResiduo) async {
    setState(() {
      _isProcessing = true;
      _imageBytes = bytes;
    });

    try {
      final response = await _photoService.uploadPhoto(
        imageBytes: bytes,
        tipoResiduo: tipoResiduo,
        nombrePersonalizado: 'Botella PET Escaneada',
        localPath: path,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      // Tarea 850: Frontend - Confirmación visual tras guardar la foto
      _showConfirmationDialog(response);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Tarea 850: Confirmación visual tras guardar la foto (modal enriquecido)
  void _showConfirmationDialog(PhotoUploadResponse response) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(26),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 46,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '¡Foto Guardada y Registrada!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              response.message,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE0EBE2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.eco, color: AppColors.primaryGreen, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          response.photo?.tipoResiduo ?? 'Botella de plástico PET',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Categoría: Plásticos reciclables',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+${response.puntosGanados} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Consejo: Recuerda retirar la tapa y aplastar la botella para optimizar el contenedor.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón directo para revisar la foto recién tomada en la galería
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openEcoScanGallery();
                },
                icon: const Icon(Icons.photo_library, color: Colors.white, size: 20),
                label: const Text(
                  'Ver en Galería EcoScan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Escanear Otro',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.textMuted, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Ir al Inicio',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra superior con botón regresar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Título y Subtítulo centrados
            Center(
              child: Column(
                children: [
                  Text(
                    'EcoScan',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.leafGreen.withValues(alpha: 0.95),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enfoca el residuo a escanear',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Visor de Cámara Integrado dentro del Recuadro
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2320),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Vista de la cámara en vivo integrada en el recuadro
                            if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized)
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _cameraController!.value.previewSize?.height ?? 1,
                                  height: _cameraController!.value.previewSize?.width ?? 1,
                                  child: CameraPreview(_cameraController!),
                                ),
                              )
                            else
                              // Ilustración de reserva si la cámara está iniciando o no disponible
                              const Center(
                                child: _BottleIllustration(),
                              ),

                            // 2. Indicador si se está procesando
                            if (_isProcessing)
                              Container(
                                color: Colors.black.withValues(alpha: 0.65),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Color(0xFF66BB6A),
                                        strokeWidth: 3,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Analizando residuo...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // 3. Guía de silueta central translúcida si la cámara está activa
                            if (_isCameraReady && !_isProcessing)
                              Center(
                                child: Opacity(
                                  opacity: 0.35,
                                  child: Container(
                                    width: 70,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.center_focus_strong,
                                        color: Colors.white70,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // 4. Línea láser animada de escaneo
                            if (!_isProcessing)
                              AnimatedBuilder(
                                animation: _scanAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: MediaQuery.of(context).size.height * 0.35 * _scanAnimation.value,
                                    left: 36,
                                    right: 36,
                                    child: Container(
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF69F0AE),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF69F0AE).withValues(alpha: 0.8),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // 5. Esquinas HUD verdes distintivas sobre la cámara en vivo
                            const Positioned.fill(
                              child: _ScannerCornersOverlay(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Barra inferior de controles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón Galería (Abre el visor exclusivo de fotos EcoScan)
                  InkWell(
                    onTap: _isProcessing ? null : _openEcoScanGallery,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E4E6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Galería',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),

                  // Botón Disparador de Cámara Integrado
                  InkWell(
                    onTap: _isProcessing ? null : _snapLivePhoto,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF14531E),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14531E).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(7),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay de las 4 esquinas verdes HUD del visor de escaneo
class _ScannerCornersOverlay extends StatelessWidget {
  const _ScannerCornersOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornersPainter(),
    );
  }
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 32.0;
    const padding = 42.0;

    // Esquina superior izquierda
    final pathTL = Path()
      ..moveTo(padding, padding + cornerLength)
      ..lineTo(padding, padding)
      ..lineTo(padding + cornerLength, padding);
    canvas.drawPath(pathTL, paint);

    // Esquina superior derecha
    final pathTR = Path()
      ..moveTo(size.width - padding - cornerLength, padding)
      ..lineTo(size.width - padding, padding)
      ..lineTo(size.width - padding, padding + cornerLength);
    canvas.drawPath(pathTR, paint);

    // Esquina inferior izquierda
    final pathBL = Path()
      ..moveTo(padding, size.height - padding - cornerLength)
      ..lineTo(padding, size.height - padding)
      ..lineTo(padding + cornerLength, size.height - padding);
    canvas.drawPath(pathBL, paint);

    // Esquina inferior derecha
    final pathBR = Path()
      ..moveTo(size.width - padding - cornerLength, size.height - padding)
      ..lineTo(size.width - padding, size.height - padding)
      ..lineTo(size.width - padding, size.height - padding - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración vectorial de la botella reciclable celeste
class _BottleIllustration extends StatelessWidget {
  const _BottleIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3EA),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            color: const Color(0xFF64B5F6),
          ),
          Expanded(
            child: Container(
              width: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
