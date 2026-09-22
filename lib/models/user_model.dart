/// Modelo de datos para la entidad Usuario (Sprint 1)
class UserModel {
  final int id;
  final String nombreCompleto;
  final String correoElectronico;
  final bool terminosAceptados;
  final String? fechaCreacion;

  UserModel({
    required this.id,
    required this.nombreCompleto,
    required this.correoElectronico,
    this.terminosAceptados = true,
    this.fechaCreacion,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombreCompleto: json['nombreCompleto'] ?? json['nombre_completo'] ?? '',
      correoElectronico: json['correoElectronico'] ?? json['correo_electronico'] ?? '',
      terminosAceptados: json['terminosAceptados'] == 1 || json['terminosAceptados'] == true,
      fechaCreacion: json['fechaCreacion'] ?? json['fecha_creacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreCompleto': nombreCompleto,
      'correoElectronico': correoElectronico,
      'terminosAceptados': terminosAceptados ? 1 : 0,
      'fechaCreacion': fechaCreacion,
    };
  }
}

/// Respuesta de autenticación con token JWT
class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
