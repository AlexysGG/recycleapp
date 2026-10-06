import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';

/// Pantalla de Galería Exclusiva de EcoScan
/// Muestra ÚNICAMENTE las fotos tomadas en EcoScan y sus resultados ecológicos
class EcoScanGalleryScreen extends StatefulWidget {
  const EcoScanGalleryScreen({super.key});

  @override
  State<EcoScanGalleryScreen> createState() => _EcoScanGalleryScreenState();
}

class _EcoScanGalleryScreenState extends State<EcoScanGalleryScreen> {
  final PhotoService _photoService = PhotoService();
  bool _isLoading = true;
  List<PhotoModel> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadEcoScanPhotos();
  }

  Future<void> _loadEcoScanPhotos() async {
    setState(() {
      _isLoading = true;
    });

    final userId = AuthService().currentUser?.id ?? 1;
    final photos = await _photoService.fetchUserPhotos(userId);

    if (mounted) {
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    }
  }

  void _showPhotoDetailsModal(PhotoModel photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Foto ampliada o preview
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: _buildPhotoWidget(photo, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Título del residuo y Badge de Puntos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.tipoResiduo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(photo.fechaCreacion),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '+${photo.puntosOtorgados} pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fila de detalles técnicos de la captura
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0EBE2)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.file_present, 'Archivo:', photo.nombreArchivo),
                  const Divider(height: 16),
                  _buildDetailRow(
                    Icons.data_usage,
                    'Tamaño:',
                    photo.tamanoBytes > 0
                        ? '${(photo.tamanoBytes / 1024).toStringAsFixed(1)} KB'
                        : 'Captura optimizada',
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(Icons.eco, 'Impacto:', 'Clasificado y reciclado en EcoScan'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Consejo ecológico según el residuo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getRecycleTip(photo.tipoResiduo),
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoWidget(PhotoModel photo, {BoxFit fit = BoxFit.cover}) {
    // 1. Archivo local guardado en disco del dispositivo
    if (photo.localFilePath != null && photo.localFilePath!.isNotEmpty) {
      final file = File(photo.localFilePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      }
    }

    // 2. URL del backend
    if (photo.urlFoto.isNotEmpty) {
      final fullUrl = ApiConfig.fullPhotoUrl(photo.urlFoto);
      return Image.network(
        fullUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallbackThumbnail(photo),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFEBF5EE),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 2),
            ),
          );
        },
      );
    }

    // 3. Fallback visual con icono temático
    return _fallbackThumbnail(photo);
  }

  Widget _fallbackThumbnail(PhotoModel photo) {
    return Container(
      color: const Color(0xFFEBF5EE),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.recycling, color: AppColors.primaryGreen, size: 36),
            const SizedBox(height: 6),
            Text(
              photo.tipoResiduo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Hoy';
    try {
      final parsed = DateTime.parse(dateStr);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} • ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getRecycleTip(String tipo) {
    final lower = tipo.toLowerCase();
    if (lower.contains('plastico') || lower.contains('pet')) {
      return 'Retira la tapa y aplasta la botella antes de depositarla en el contenedor amarillo.';
    } else if (lower.contains('vidrio')) {
      return 'Enjuaga el envase de vidrio y deposítalo sin tapa en el contenedor verde.';
    } else if (lower.contains('aluminio') || lower.contains('lata')) {
      return 'Aplasta la lata para ahorrar espacio en el contenedor de metales.';
    } else if (lower.contains('carton') || lower.contains('papel')) {
      return 'Mantén el cartón seco y doblado antes de depositarlo en el contenedor azul.';
    }
    return 'Residuo reciclable clasificado exitosamente. ¡Gracias por cuidar el planeta!';
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = _photos.fold(0, (sum, p) => sum + p.puntosOtorgados);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Galería EcoScan',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryGreen),
            tooltip: 'Actualizar',
            onPressed: _loadEcoScanPhotos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _photos.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: _loadEcoScanPhotos,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjeta de Resumen Superior
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5EE),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.photo_library,
                                  color: AppColors.primaryGreen,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_photos.length} ${_photos.length == 1 ? 'Residuo fotografiado' : 'Residuos fotografiados'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Fotos tomadas exclusivamente con EcoScan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
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
                                child: Text(
                                  '$totalPoints pts',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Historial de Capturas y Resultados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Cuadrícula de fotos tomadas con EcoScan
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _photos.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            final photo = _photos[index];
                            return _buildPhotoCard(photo);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPhotoCard(PhotoModel photo) {
    return InkWell(
      onTap: () => _showPhotoDetailsModal(photo),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniatura de la foto tomada con EcoScan
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    child: _buildPhotoWidget(photo),
                  ),
                  // Insignia de EcoPuntos
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '+${photo.puntosOtorgados}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Información y resultado
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.tipoResiduo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(photo.fechaCreacion),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF5EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primaryGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay fotos en tu Galería EcoScan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Las fotos que captures con el disparador de EcoScan se guardarán aquí con su resultado y puntos ganados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              label: const Text(
                'Tomar mi primer escaneo',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
