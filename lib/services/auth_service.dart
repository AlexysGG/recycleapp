import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';
import 'api_config.dart';

/// Servicio de Autenticación para el Frontend Móvil de EcoScan
class AuthService {
  // Patrón Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  String? _token;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  // Base de datos local simulada en memoria (fallback en caso de servidor offline)
  final Map<String, Map<String, dynamic>> _mockLocalUsers = {};

  /// Tarea 1000: Registro de usuario con validación
  Future<AuthResponse> register({
    required String nombreCompleto,
    required String correoElectronico,
    required String password,
    required bool terminosAceptados,
  }) async {
    final payload = {
      'nombreCompleto': nombreCompleto.trim(),
      'correoElectronico': correoElectronico.trim().toLowerCase(),
      'password': password,
      'terminosAceptados': terminosAceptados,
    };

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse(ApiConfig.registerEndpoint);
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=UTF-8');
      request.write(jsonEncode(payload));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(data);
        _currentUser = authResponse.user;
        _token = authResponse.token;
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Error al registrar el usuario.',
        );
      }
    } catch (e) {
      // Fallback local en caso de que el servidor backend no esté corriendo en el host
      return _registerFallback(nombreCompleto, correoElectronico, password, terminosAceptados);
    }
  }

  /// Tarea 970: Inicio de sesión con JWT
  Future<AuthResponse> login({
    required String correoElectronico,
    required String password,
  }) async {
    final payload = {
      'correoElectronico': correoElectronico.trim().toLowerCase(),
      'password': password,
    };

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse(ApiConfig.loginEndpoint);
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=UTF-8');
      request.write(jsonEncode(payload));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);
        _currentUser = authResponse.user;
        _token = authResponse.token;
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Credenciales inválidas.',
        );
      }
    } catch (e) {
      // Fallback local en caso de que el servidor backend no esté encendido
      return _loginFallback(correoElectronico, password);
    }
  }

  /// Cierra la sesión activa
  void logout() {
    _currentUser = null;
    _token = null;
  }

  // --- Implementación de respaldo local para pruebas sin backend encendido ---
  AuthResponse _registerFallback(
    String nombre,
    String email,
    String password,
    bool terminos,
  ) {
    final emailNorm = email.trim().toLowerCase();
    if (_mockLocalUsers.containsKey(emailNorm)) {
      return AuthResponse(
        success: false,
        message: 'El correo electrónico ya está registrado. Por favor inicia sesión.',
      );
    }

    final newId = _mockLocalUsers.length + 1;
    _mockLocalUsers[emailNorm] = {
      'id': newId,
      'nombre': nombre.trim(),
      'email': emailNorm,
      'password': password,
      'fecha': DateTime.now().toIso8601String(),
    };

    final user = UserModel(
      id: newId,
      nombreCompleto: nombre.trim(),
      correoElectronico: emailNorm,
      terminosAceptados: true,
      fechaCreacion: DateTime.now().toIso8601String(),
    );

    final mockToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    _currentUser = user;
    _token = mockToken;

    return AuthResponse(
      success: true,
      message: 'Usuario registrado exitosamente (Modo Local).',
      token: mockToken,
      user: user,
    );
  }

  AuthResponse _loginFallback(String email, String password) {
    final emailNorm = email.trim().toLowerCase();

    // Cuenta de demostración por defecto si aún no se ha registrado nadie
    if (!_mockLocalUsers.containsKey(emailNorm)) {
      if (emailNorm == 'test@ecoscan.com' && password == 'password123') {
        final demoUser = UserModel(
          id: 99,
          nombreCompleto: 'Usuario Demo EcoScan',
          correoElectronico: 'test@ecoscan.com',
          fechaCreacion: DateTime.now().toIso8601String(),
        );
        _currentUser = demoUser;
        _token = 'demo_jwt_token_ecoscan';
        return AuthResponse(
          success: true,
          message: 'Inicio de sesión exitoso (Cuenta Demo).',
          token: _token,
          user: demoUser,
        );
      }
      return AuthResponse(
        success: false,
        message: 'Credenciales inválidas. Correo o contraseña incorrectos.',
      );
    }

    final stored = _mockLocalUsers[emailNorm]!;
    if (stored['password'] != password) {
      return AuthResponse(
        success: false,
        message: 'Credenciales inválidas. Correo o contraseña incorrectos.',
      );
    }

    final user = UserModel(
      id: stored['id'],
      nombreCompleto: stored['nombre'],
      correoElectronico: stored['email'],
      fechaCreacion: stored['fecha'],
    );
    final mockToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    _currentUser = user;
    _token = mockToken;

    return AuthResponse(
      success: true,
      message: 'Inicio de sesión exitoso.',
      token: mockToken,
      user: user,
    );
  }
}
