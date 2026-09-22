import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/wave_header_painter.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Tarea 800: Frontend: pantalla de registro con validaciones de formulario (Marisol Moreno)
/// Pantalla fiel a la Referencia 5 ("Crear Cuenta") con ajuste responsivo a la altura de pantalla
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _termsErrorMessage;
  String? _generalErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.description, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Términos y Condiciones'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Bienvenido a EcoScan. Al utilizar nuestra aplicación móvil, te comprometes a '
            'hacer un uso responsable del sistema de reciclaje y cuidado del medio ambiente. '
            'Tus datos personales y de autenticación se almacenan de manera encriptada y segura '
            'conforme a las normativas de protección de datos.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _acceptTerms = true;
                _termsErrorMessage = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Aceptar', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    setState(() {
      _generalErrorMessage = null;
      _termsErrorMessage = null;
    });

    final isFormValid = _formKey.currentState!.validate();

    if (!_acceptTerms) {
      setState(() {
        _termsErrorMessage = 'Debes aceptar los Términos y Condiciones.';
      });
      return;
    }

    if (!isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    final response = await authService.register(
      nombreCompleto: _nameController.text.trim(),
      correoElectronico: _emailController.text.trim(),
      password: _passwordController.text,
      terminosAceptados: _acceptTerms,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success && response.user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(response.message)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(user: response.user!),
        ),
      );
    } else {
      setState(() {
        _generalErrorMessage = response.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(response.message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final topPadding = MediaQuery.of(context).padding.top;
          final bottomPadding = MediaQuery.of(context).padding.bottom;

          // Dimensiones proporcionales a la altura de la pantalla
          final topWaveHeight = (screenHeight * 0.17).clamp(115.0, 145.0);
          final bottomWaveHeight = (screenHeight * 0.10).clamp(65.0, 85.0);
          final bottomWaveWidth = (screenHeight * 0.15).clamp(100.0, 135.0);
          final availableBodyHeight = screenHeight - topPadding - bottomPadding;

          return Stack(
            children: [
              // 1. Ola decorativa superior verde (Referencia 5)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topWaveHeight,
                child: CustomPaint(
                  painter: TopWavePainter(color: AppColors.primaryGreen),
                ),
              ),

              // 2. Curva decorativa inferior izquierda verde (Referencia 5)
              Positioned(
                bottom: 0,
                left: 0,
                width: bottomWaveWidth,
                height: bottomWaveHeight,
                child: CustomPaint(
                  painter: BottomWavePainter(color: AppColors.primaryGreen),
                ),
              ),

              // 3. Botón de cierre "X" superior derecho
              Positioned(
                top: topPadding + 6,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // 4. Formulario con ajuste elástico a la altura completa de la pantalla
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableBodyHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Sección superior: Espacio bajo la ola + Título + Inputs + Términos
                            Column(
                              children: [
                                // Espacio dinámico para que "Crear Cuenta" quede justo bajo la ola
                                SizedBox(height: topWaveHeight * 0.65),

                                // Título: "Crear Cuenta"
                                const Text(
                                  'Crear Cuenta',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Mensaje de error general si aplica
                                if (_generalErrorMessage != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      _generalErrorMessage!,
                                      style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],

                                // Campo 1: Nombre Completo
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
                                  decoration: InputDecoration(
                                    hintText: 'Nombre Completo',
                                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14.5),
                                    prefixIcon: const Icon(Icons.person, color: AppColors.primaryGreen, size: 22),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.6),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.error, width: 1.6),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu nombre completo.';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'El nombre debe tener al menos 2 caracteres.';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Campo 2: Correo Electrónico
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
                                  decoration: InputDecoration(
                                    hintText: 'Correo Electrónico',
                                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14.5),
                                    prefixIcon: const Icon(Icons.mail, color: AppColors.primaryGreen, size: 22),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.6),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.error, width: 1.6),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu correo electrónico.';
                                    }
                                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return 'Ingresa un correo electrónico válido.';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Campo 3: Contraseña
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
                                  decoration: InputDecoration(
                                    hintText: 'Contraseña',
                                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14.5),
                                    prefixIcon: const Icon(Icons.lock, color: AppColors.primaryGreen, size: 22),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: AppColors.textMuted,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.6),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.error, width: 1.6),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingresa una contraseña.';
                                    }
                                    if (value.length < 6) {
                                      return 'La contraseña debe tener al menos 6 caracteres.';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Checkbox: Términos y Condiciones
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: 1.05,
                                      child: Checkbox(
                                        value: _acceptTerms,
                                        activeColor: AppColors.primaryGreen,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        side: const BorderSide(color: Color(0xFF718096), width: 1.5),
                                        onChanged: (val) {
                                          setState(() {
                                            _acceptTerms = val ?? false;
                                            if (_acceptTerms) {
                                              _termsErrorMessage = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _showTermsDialog,
                                        child: RichText(
                                          text: const TextSpan(
                                            style: TextStyle(color: Color(0xFF4A5568), fontSize: 13),
                                            children: [
                                              TextSpan(text: 'Acepto los '),
                                              TextSpan(
                                                text: 'Términos y Condiciones',
                                                style: TextStyle(
                                                  color: AppColors.primaryGreen,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (_termsErrorMessage != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _termsErrorMessage!,
                                        style: const TextStyle(color: AppColors.error, fontSize: 11.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Sección inferior: Botón CREAR CUENTA + Enlace Iniciar Sesión (Centrado sin solapar la curva)
                            Padding(
                              padding: const EdgeInsets.only(top: 14.0, bottom: 20.0),
                              child: Column(
                                children: [
                                  // Botón: CREAR CUENTA
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'CREAR CUENTA',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Enlace: "¿Ya tienes una cuenta? Iniciar Sesión"
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                                      );
                                    },
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(color: Color(0xFF4A5568), fontSize: 13.5),
                                        children: [
                                          TextSpan(text: '¿Ya tienes una cuenta? '),
                                          TextSpan(
                                            text: 'Iniciar Sesión',
                                            style: TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
