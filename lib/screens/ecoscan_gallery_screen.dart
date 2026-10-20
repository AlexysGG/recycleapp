import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  List<PhotoModel> _allPhotos = [];

  // Variables de Filtro
  String _selectedCategory = 'Todos';
  DateTimeRange? _selectedDateRange;

  // Categorías fijas estándar exigidas para la aplicación
  final List<String> _defaultCategories = [
    'Plástico',
    'Vidrio',
    'Papel',
    'Bolsas de plástico',
  ];

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
        _allPhotos = photos;
        _isLoading = false;
      });
    }
  }

  /// Obtiene la lista combinada de categorías (Fijas + Dinámicas del Backend)
  List<String> get _availableCategories {
    final categoriesSet = <String>{..._defaultCategories};

    // Agregar dinámicamente cualquier otro tipo devuelto por la API
    for (var photo in _allPhotos) {
      final tipo = photo.tipoResiduo.trim();
      if (tipo.isNotEmpty) {
        categoriesSet.add(tipo);
      }
    }

    final categoriesList = categoriesSet.toList()..sort();
    return ['Todos', ...categoriesList];
  }

  /// Aplica los filtros sobre la lista de fotos capturadas
  List<PhotoModel> get _filteredPhotos {
    return _allPhotos.where((photo) {
      // 1. Filtro por tipo de desecho (coincidencia parcial flexible)
      if (_selectedCategory != 'Todos') {
        final photoType = photo.tipoResiduo.toLowerCase();
        final selectedType = _selectedCategory.toLowerCase();

        bool matches = false;
        if (selectedType == 'plástico' || selectedType == 'plastico') {
          matches = photoType.contains('plastico') ||
              photoType.contains('plástico') ||
              photoType.contains('pet');
        } else if (selectedType == 'vidrio') {
          matches = photoType.contains('vidrio') || photoType.contains('cristal');
        } else if (selectedType == 'papel') {
          matches = photoType.contains('papel') || photoType.contains('carton') || photoType.contains('cartón');
        } else if (selectedType == 'bolsas de plástico' || selectedType == 'bolsas de plastico') {
          matches = photoType.contains('bolsa');
        } else {
          matches = photoType == selectedType;
        }

        if (!matches) return false;
      }

      // 2. Filtro por rango de fechas
      if (_selectedDateRange != null && photo.fechaCreacion != null) {
        try {
          final photoDate = DateTime.parse(photo.fechaCreacion!);
          final startDate = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final endDate = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23,
            59,
            59,
          );

          if (photoDate.isBefore(startDate) || photoDate.isAfter(endDate)) {
            return false;
          }
        } catch (_) {}
      }

      return true;
    }).toList();
  }

  /// Selector de Rango de Fechas
  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _selectedDateRange = pickedRange;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'Todos';
      _selectedDateRange = null;
    });
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

            // Preview de la foto
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

            // Fila de detalles técnicos
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

            // Consejo ecológico
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
    if (!kIsWeb && photo.localFilePath != null && photo.localFilePath!.isNotEmpty) {
      final file = File(photo.localFilePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      }
    }

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
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getRecycleTip(String tipo) {
    final lower = tipo.toLowerCase();
    if (lower.contains('bolsa')) {
      return 'Lleva tus bolsas de plástico a Puntos Limpios o reutilízalas para tus compras.';
    } else if (lower.contains('plastico') || lower.contains('plástico') || lower.contains('pet')) {
      return 'Retira la tapa y aplasta la botella antes de depositarla en el contenedor amarillo.';
    } else if (lower.contains('vidrio')) {
      return 'Enjuaga el envase de vidrio y deposítalo sin tapa en el contenedor verde.';
    } else if (lower.contains('carton') || lower.contains('cartón') || lower.contains('papel')) {
      return 'Mantén el papel o cartón seco y doblado antes de depositarlo en el contenedor azul.';
    } else if (lower.contains('aluminio') || lower.contains('lata')) {
      return 'Aplasta la lata para ahorrar espacio en el contenedor de metales.';
    }
    return 'Residuo reciclable clasificado exitosamente. ¡Gracias por cuidar el planeta!';
  }

  /// Barra de Filtros por Fecha y Categorías (Plástico, Vidrio, Papel, Bolsas de plástico)
  Widget _buildFilterSection() {
    final isFiltered = _selectedCategory != 'Todos' || _selectedDateRange != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0EBE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_alt_outlined, color: AppColors.primaryGreen, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Filtrar por:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              if (isFiltered)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 16, color: Colors.redAccent),
                  label: const Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 1. Selector de Tipo de Desecho
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _availableCategories.contains(_selectedCategory)
                          ? _selectedCategory
                          : 'Todos',
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      items: _availableCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Selector de Fecha
              InkWell(
                onTap: _selectDateRange,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedDateRange != null
                        ? AppColors.primaryGreen
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedDateRange != null
                          ? AppColors.primaryGreen
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _selectedDateRange != null
                            ? Colors.white
                            : AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedDateRange != null
                            ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
                            : 'Fecha',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _selectedDateRange != null
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredPhotos;
    final totalPoints = filteredList.fold(0, (sum, p) => sum + p.puntosOtorgados);
    final isFiltered = _selectedCategory != 'Todos' || _selectedDateRange != null;

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
          : RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: _loadEcoScanPhotos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de Resumen
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
                                  '${filteredList.length} ${filteredList.length == 1 ? 'Residuo mostrado' : 'Residuos mostrados'}',
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

                    const SizedBox(height: 18),

                    // Barra de Filtros (SIEMPRE VISIBLE)
                    _buildFilterSection(),

                    const Text(
                      'Historial de Capturas y Resultados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Contenido: Cuadrícula de fotos o Estado sin capturas
                    _allPhotos.isEmpty
                        ? _buildEmptyState()
                        : filteredList.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text(
                                      isFiltered
                                          ? 'No hay capturas de "$_selectedCategory" en el rango seleccionado.'
                                          : 'No se encontraron capturas con los filtros seleccionados.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredList.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.78,
                                ),
                                itemBuilder: (context, index) {
                                  final photo = filteredList[index];
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    child: _buildPhotoWidget(photo),
                  ),
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF5EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primaryGreen,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay fotos en tu Galería EcoScan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Las fotos que captures con el disparador de EcoScan se guardarán aquí con su resultado y puntos ganados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              label: const Text(
                'Tomar mi primer escaneo',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}