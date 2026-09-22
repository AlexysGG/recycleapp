import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Dibujador de la ola decorativa superior verde de la pantalla Crear Cuenta (Referencia 5)
class TopWavePainter extends CustomPainter {
  final Color color;

  TopWavePainter({this.color = AppColors.primaryGreen});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height * 0.78);

    // Curva ondulada suave idéntica a la referencia de diseño
    path.quadraticBezierTo(
      size.width * 0.30,
      size.height * 1.05,
      size.width * 0.60,
      size.height * 0.80,
    );

    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.60,
      size.width,
      size.height * 0.72,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dibujador de la curva decorativa verde inferior izquierda (Referencia 5)
class BottomWavePainter extends CustomPainter {
  final Color color;

  BottomWavePainter({this.color = AppColors.primaryGreen});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // Inicia en la esquina inferior izquierda
    path.moveTo(0, size.height);
    // Sube por el borde izquierdo
    path.lineTo(0, 0);
    // Curva convexa suave hacia el borde inferior derecho
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.15,
      size.width,
      size.height,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
