import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de integración y preparación para Supabase (Auth, Database y Storage)
/// 
/// Para activar Supabase en el proyecto:
/// 1. Crea un proyecto en https://supabase.com
/// 2. Copia la URL del proyecto y la anon public key desde Settings -> API
/// 3. Asigna [supabaseUrl] y [supabaseAnonKey] o llámalos mediante variables de entorno / compilación
class SupabaseService {
  // Patrón Singleton
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Configuración de credenciales de Supabase
  // Reemplaza con tus credenciales reales del panel de Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qrmnhnwodolpfwxvnmss.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFybW5obndvZG9scGZ3eHZubXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0NTYyMzIsImV4cCI6MjEwODAzMjIzMn0.a3OGmGXTkZ4cSFBGzWBdyoA3jfEwUi5AvrxmGeHZNB0',
  );

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Obtiene la instancia del cliente de Supabase
  SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase no ha sido inicializado. Llama a SupabaseService.initialize() primero con credenciales válidas.',
      );
    }
    return Supabase.instance.client;
  }

  /// Verifica si las credenciales configuradas son válidas (no valores por defecto)
  static bool get hasValidCredentials {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('TU-PROYECTO') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('TU-ANON-KEY');
  }

  /// Inicializa Supabase de manera segura para la aplicación
  static Future<void> initialize() async {
    if (!hasValidCredentials) {
      debugPrint(
        '⚠️ [Supabase] Credenciales no configuradas o con valores de plantilla. '
        'Para activar Supabase, configura SUPABASE_URL y SUPABASE_ANON_KEY.',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      _instance._isInitialized = true;
      debugPrint('✅ [Supabase] Inicializado exitosamente.');
    } catch (e) {
      debugPrint('❌ [Supabase] Error al inicializar: $e');
    }
  }

  // ==========================================
  // AUTENTICACIÓN (Auth)
  // ==========================================

  User? get currentUser => _isInitialized ? client.auth.currentUser : null;
  Session? get currentSession => _isInitialized ? client.auth.currentSession : null;
  bool get isAuthenticated => currentUser != null;

  /// Stream para escuchar cambios en el estado de autenticación
  Stream<AuthState>? get authStateChanges =>
      _isInitialized ? client.auth.onAuthStateChange : null;

  /// Registro de usuario con correo y contraseña
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// Inicio de sesión con correo y contraseña
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    if (_isInitialized) {
      await client.auth.signOut();
    }
  }

  // ==========================================
  // STORAGE (Subida y Gestión de Fotos)
  // ==========================================

  static const String photoBucket = 'residues-photos';

  /// Sube una foto a Supabase Storage y retorna la URL pública
  Future<String?> uploadPhoto({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (!_isInitialized) return null;

    final userId = currentUser?.id ?? 'anonymous';
    final path = '$userId/$fileName';

    await client.storage.from(photoBucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return client.storage.from(photoBucket).getPublicUrl(path);
  }

  // ==========================================
  // BASE DE DATOS (PostgreSQL / Tablas)
  // ==========================================

  /// Inserta un registro de residuo/foto en la tabla 'fotos'
  Future<Map<String, dynamic>?> insertPhotoRecord({
    required String photoUrl,
    required String residueType,
    required int points,
  }) async {
    if (!_isInitialized) return null;

    final response = await client.from('fotos').insert({
      'user_id': currentUser?.id,
      'photo_url': photoUrl,
      'tipo_residuo': residueType,
      'puntos_otorgados': points,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    return response;
  }

  /// Obtiene el historial de fotos del usuario actual
  Future<List<Map<String, dynamic>>> getUserPhotos() async {
    if (!_isInitialized || currentUser == null) return [];

    final response = await client
        .from('fotos')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
