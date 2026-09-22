import 'package:flutter/material.dart';

/// Botón de acceso con redes sociales (Google y Facebook)
class SocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;

  const SocialButton({
    super.key,
    required this.icon,
    this.onTap,
  });

  /// Constructor específico para el botón de Google
  factory SocialButton.google({VoidCallback? onTap}) {
    return SocialButton(
      onTap: onTap,
      icon: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(
          painter: _GoogleIconPainter(),
        ),
      ),
    );
  }

  /// Constructor específico para el botón de Facebook
  factory SocialButton.facebook({VoidCallback? onTap}) {
    return SocialButton(
      onTap: onTap,
      icon: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF1877F2),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 64,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: icon,
        ),
      ),
    );
  }
}

/// Dibuja el logo de Google con los 4 colores oficiales
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Pintar los 4 arcos característicos de Google
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final rect = Rect.fromCircle(center: center, radius: radius - 2);

    // Rojo (arriba)
    canvas.drawArc(rect, -2.3, 1.4, false, redPaint);
    // Amarillo (izquierda)
    canvas.drawArc(rect, -3.7, 1.4, false, yellowPaint);
    // Verde (abajo)
    canvas.drawArc(rect, 0.9, 1.4, false, greenPaint);
    // Azul (derecha)
    canvas.drawArc(rect, -0.9, 1.8, false, bluePaint);

    // Barra horizontal azul en el medio
    final blueBarPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(center.dx - 2, center.dy - 2, radius, 4),
      blueBarPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
