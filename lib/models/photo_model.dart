/// Modelo de datos para las fotos de residuos escaneados (Sprint 2 - Tarea 970)
class PhotoModel {
  final int id;
  final int usuarioId;
  final String nombreArchivo;
  final String urlFoto;
  final String tipoResiduo;
  final int tamanoBytes;
  final int puntosOtorgados;
  final String? fechaCreacion;
  final String? localFilePath;

  PhotoModel({
    required this.id,
    required this.usuarioId,
    required this.nombreArchivo,
    required this.urlFoto,
    required this.tipoResiduo,
    required this.tamanoBytes,
    required this.puntosOtorgados,
    this.fechaCreacion,
    this.localFilePath,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json, {String? localFilePath}) {
    return PhotoModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      usuarioId: json['usuarioId'] ?? json['usuario_id'] ?? 0,
      nombreArchivo: json['nombreArchivo'] ?? json['nombre_archivo'] ?? '',
      urlFoto: json['urlFoto'] ?? json['url_foto'] ?? '',
      tipoResiduo: json['tipoResiduo'] ?? json['tipo_residuo'] ?? 'Plástico PET',
      tamanoBytes: json['tamanoBytes'] ?? json['tamano_bytes'] ?? 0,
      puntosOtorgados: json['puntosOtorgados'] ?? json['puntos_otorgados'] ?? 50,
      fechaCreacion: json['fechaCreacion'] ?? json['fecha_creacion'],
      localFilePath: localFilePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'nombreArchivo': nombreArchivo,
      'urlFoto': urlFoto,
      'tipoResiduo': tipoResiduo,
      'tamanoBytes': tamanoBytes,
      'puntosOtorgados': puntosOtorgados,
      'fechaCreacion': fechaCreacion,
    };
  }
}

/// Respuesta de subida y procesamiento de foto
class PhotoUploadResponse {
  final bool success;
  final String message;
  final PhotoModel? photo;
  final int puntosGanados;

  PhotoUploadResponse({
    required this.success,
    required this.message,
    this.photo,
    this.puntosGanados = 0,
  });

  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json, {String? localFilePath}) {
    return PhotoUploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      photo: json['photo'] != null 
          ? PhotoModel.fromJson(json['photo'], localFilePath: localFilePath) 
          : null,
      puntosGanados: json['photo']?['puntosOtorgados'] ?? json['puntosGanados'] ?? 50,
    );
  }
}
