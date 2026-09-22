import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Pantalla de Bienvenida de EcoScan (Referencia 3)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 36),

              // 1. Título EcoScan con icono de hoja a la derecha
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'EcoScan',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.rotate(
                    angle: 0.1,
                    child: const Icon(
                      Icons.eco,
                      color: AppColors.leafGreen,
                      size: 40,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. Subtítulo: "Escanea, recicla y cuida el planeta"
              const Text(
                'Escanea, recicla\ny cuida el planeta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),

              // 3. Ilustración central usando la imagen oficial iconapp
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/iconapp.jpeg',
                    width: size.width * 0.72,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Indicador amigable si la imagen no se encuentra en el entorno
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public, size: 120, color: AppColors.primaryGreen.withValues(alpha: 0.7)),
                          const SizedBox(height: 8),
                          const Text(
                            'EcoScan Mascot',
                            style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ),

              // 4. Botón Iniciar Sesión (Verde sólido, bordes redondeados)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Iniciar Sesion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 5. Botón Registrarse (Borde oscuro, fondo blanco)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
