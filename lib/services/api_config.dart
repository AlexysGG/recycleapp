import 'dart:io';

/// Configuración de endpoints de red para plataformas móviles (Android & iOS)
class ApiConfig {
  // IP personalizada para dispositivos físicos en la red local (modificar si se prueba en teléfono real)
  static String? customServerHost;

  /// Retorna la URL base correspondiente a la plataforma móvil
  static String get baseUrl {
    if (customServerHost != null && customServerHost!.isNotEmpty) {
      return 'http://$customServerHost:3000/api';
    }

    // Android Emulator mapea localhost de la máquina host a 10.0.2.2
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }

    // iOS Simulator utiliza localhost directamente
    if (Platform.isIOS) {
      return 'http://localhost:3000/api';
    }

    return 'http://127.0.0.1:3000/api';
  }

  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get verifyEndpoint => '$baseUrl/auth/verify';
}
