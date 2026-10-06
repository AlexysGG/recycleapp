import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/photo_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// Servicio para captura, procesamiento y subida de fotos al backend
class PhotoService {
  // Patrón Singleton
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  // Historial local en memoria (fallback en caso de desconexión o modo offline)
  final List<PhotoModel> _localScans = [];
  List<PhotoModel> get localScans => List.unmodifiable(_localScans);

  int get totalEcoPoints => _localScans.fold(0, (sum, item) => sum + item.puntosOtorgados);

  /// Tarea 1000: Subida y registro de foto asociada al usuario
  Future<PhotoUploadResponse> uploadPhoto({
    required Uint8List imageBytes,
    required String tipoResiduo,
    String? nombrePersonalizado,
    String? localPath,
  }) async {
    final user = AuthService().currentUser;
    final token = AuthService().token;
    final userId = user?.id ?? 1;

    final base64Image = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

    final payload = {
      'usuarioId': userId,
      'imageBase64': base64Image,
      'tipoResiduo': tipoResiduo,
      'nombrePersonalizado': nombrePersonalizado ?? 'Residuo escaneado',
    };

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.parse(ApiConfig.uploadPhotoEndpoint);
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json; charset=UTF-8');
      if (token != null) {
        request.headers.set('Authorization', 'Bearer $token');
      }

      request.write(jsonEncode(payload));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final uploadResponse = PhotoUploadResponse.fromJson(data, localFilePath: localPath);
        if (uploadResponse.photo != null) {
          _localScans.insert(0, uploadResponse.photo!);
        }
        return uploadResponse;
      } else {
        // En caso de respuesta con error del servidor
        final Map<String, dynamic> data = jsonDecode(responseBody);
        return _fallbackLocalSave(
          userId: userId,
          tipoResiduo: tipoResiduo,
          bytesLength: imageBytes.length,
          localPath: localPath,
          message: data['message'] ?? 'Guardado localmente (servidor no disponible).',
        );
      }
    } catch (_) {
      // Fallback offline resiliente: se guarda localmente sin interrumpir la experiencia de usuario
      return _fallbackLocalSave(
        userId: userId,
        tipoResiduo: tipoResiduo,
        bytesLength: imageBytes.length,
        localPath: localPath,
        message: 'Foto guardada con éxito en modo local.',
      );
    }
  }

  /// Helper de guardado local ante desconexión
  PhotoUploadResponse _fallbackLocalSave({
    required int userId,
    required String tipoResiduo,
    required int bytesLength,
    String? localPath,
    required String message,
  }) {
    final int points = _getPuntosPorResiduo(tipoResiduo);
    final mockPhoto = PhotoModel(
      id: DateTime.now().millisecondsSinceEpoch,
      usuarioId: userId,
      nombreArchivo: 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      urlFoto: localPath ?? '',
      tipoResiduo: _getNombreResiduo(tipoResiduo),
      tamanoBytes: bytesLength,
      puntosOtorgados: points,
      fechaCreacion: DateTime.now().toIso8601String(),
      localFilePath: localPath,
    );

    _localScans.insert(0, mockPhoto);

    return PhotoUploadResponse(
      success: true,
      message: message,
      photo: mockPhoto,
      puntosGanados: points,
    );
  }

  /// Consulta el historial de fotos del usuario desde el backend
  Future<List<PhotoModel>> fetchUserPhotos(int userId) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse(ApiConfig.userPhotosEndpoint(userId));
      final request = await client.getUrl(uri);

      final token = AuthService().token;
      if (token != null) {
        request.headers.set('Authorization', 'Bearer $token');
      }

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);
        final List list = data['photos'] ?? [];
        final serverPhotos = list.map((item) => PhotoModel.fromJson(item)).toList();
        
        // Sincronizar con _localScans evitando duplicados
        for (final p in serverPhotos) {
          final index = _localScans.indexWhere((x) => x.id == p.id);
          if (index == -1) {
            _localScans.add(p);
          }
        }
        return _localScans;
      }
    } catch (_) {
      // Retornar scans locales si no hay red
    }
    return _localScans;
  }

  int _getPuntosPorResiduo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'aluminio':
        return 70;
      case 'vidrio':
        return 60;
      case 'carton':
        return 40;
      case 'papel':
        return 30;
      case 'organico':
        return 35;
      case 'plastico':
      default:
        return 50;
    }
  }

  String _getNombreResiduo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'aluminio':
        return 'Lata de aluminio';
      case 'vidrio':
        return 'Botella de vidrio';
      case 'carton':
        return 'Caja de cartón';
      case 'papel':
        return 'Papel reciclable';
      case 'organico':
        return 'Residuo orgánico';
      case 'plastico':
      default:
        return 'Botella de plástico PET';
    }
  }
}
