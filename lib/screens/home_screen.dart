import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import 'ecoscan_screen.dart';
import 'welcome_screen.dart';

/// Pantalla Principal (Dashboard) inspirada en Image 2
class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PhotoService _photoService = PhotoService();

  @override
  void initState() {
    super.initState();
    // Cargar historial de fotos si está conectado
    _photoService.fetchUserPhotos(widget.user.id);
  }

  void _showEcoIAModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.psychology, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 10),
                Text(
                  'Eco IA - Inteligencia Verde',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Eco IA utiliza modelos de visión artificial para clasificar automáticamente tus residuos:',
              style: TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.check_circle, 'Plásticos PET y PEAD (Botellas, envases).'),
            _buildInfoRow(Icons.check_circle, 'Vidrio transparente y de color.'),
            _buildInfoRow(Icons.check_circle, 'Latas de aluminio y metales ferrosos.'),
            _buildInfoRow(Icons.check_circle, 'Cartón corrugado y papel bond.'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EcoScanScreen()),
                  );
                },
                child: const Text('Escanear con Eco IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapaModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 10),
                Text(
                  'Puntos Limpios Cercanos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildMapLocationItem('Contenedor Verde Central', 'Av. Reforma 120 • 350 m de ti', 'Plástico, Vidrio'),
            _buildMapLocationItem('EcoPunto Parque Benito', 'Calle 5 Poniente • 650 m de ti', 'Aluminio, Cartón'),
            _buildMapLocationItem('Centro de Acopio Metropolitano', 'Blvd. Ecológico 45 • 1.2 km de ti', 'Electrónicos, Baterías'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPuntosModal() {
    final scans = _photoService.localScans;
    final totalPoints = _photoService.totalEcoPoints;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.military_tech, color: Colors.amber, size: 28),
                    SizedBox(width: 8),
                    Text('Mis EcoPuntos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$totalPoints pts',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Has acumulado puntos reciclando y fotografiando residuos con EcoScan.',
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            const Text('Historial Reciente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (scans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Aún no has escaneado ningún residuo.\n¡Usa el botón "Escanear residuo" para ganar tus primeros 50 puntos!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: scans.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (ctx, i) {
                    final item = scans[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.recycling, color: AppColors.primaryGreen),
                      ),
                      title: Text(item.tipoResiduo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(item.nombreArchivo, style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        '+${item.puntosOtorgados} pts',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEcoCuidadosModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.park, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 10),
                Text(
                  'EcoCuidados y Hábitos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoRow(Icons.water_drop, 'Lava y seca los recipientes antes de desecharlos.'),
            _buildInfoRow(Icons.compress, 'Aplasta las botellas y latas para optimizar espacio.'),
            _buildInfoRow(Icons.layers_clear, 'Separa las tapas plásticas de los cuerpos metálicos o de vidrio.'),
            _buildInfoRow(Icons.solar_power, 'Reduce tu huella de carbono reutilizando bolsas y termos.'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLocationItem(String title, String subtitle, String tags) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pin_drop, color: AppColors.primaryGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.user.nombreCompleto,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textMuted),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              AuthService().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título principal "¡Hola!" (idéntico a la Image 2)
            const Text(
              '¡Hola!',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B6B27), // Verde bosque de la marca
                letterSpacing: -0.8,
              ),
            ),

            // Subtítulo "Haz la diferencia hoy" (idéntico a la Image 2)
            const Text(
              'Haz la diferencia hoy',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 36),

            // Matriz de tarjetas inspirada fielmente en la Image 2
            Row(
              children: [
                // 1. Escanear residuo
                Expanded(
                  child: _InspirationCard(
                    title: 'Escanear residuo',
                    iconWidget: const Icon(Icons.camera_alt, color: Color(0xFF333333), size: 28),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EcoScanScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 18),
                // 2. Eco IA
                Expanded(
                  child: _InspirationCard(
                    title: 'Eco IA',
                    iconWidget: const _PlantIcon(),
                    onTap: _showEcoIAModal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                // 3. Mapa
                Expanded(
                  child: _InspirationCard(
                    title: 'Mapa',
                    iconWidget: const _MapPinIcon(),
                    onTap: _showMapaModal,
                  ),
                ),
                const SizedBox(width: 18),
                // 4. Mis puntos
                Expanded(
                  child: _InspirationCard(
                    title: 'Mis puntos',
                    iconWidget: const _TargetIcon(),
                    onTap: _showPuntosModal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 5. EcoCuidados (Centrada en la parte inferior, tal como en Image 2)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.44,
                child: _InspirationCard(
                  title: 'EcoCuidados',
                  iconWidget: const _TreeIcon(),
                  onTap: _showEcoCuidadosModal,
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

/// Componente de Tarjeta individual de la cuadrícula (fiel a la Image 2)
class _InspirationCard extends StatelessWidget {
  final String title;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _InspirationCard({
    required this.title,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 145,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF5EE), // Tono menta suave exactamente como en Image 2
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contenedor cuadrado blanco con bordes redondeados y sombra sutil
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 12),
            // Título en texto negro limpio
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícono vectorial estilizado de la plantita con maceta (Eco IA)
class _PlantIcon extends StatelessWidget {
  const _PlantIcon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hojas verdes
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -0.3,
              child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 14),
            ),
            Transform.rotate(
              angle: 0.3,
              child: const Icon(Icons.eco, color: Color(0xFF66BB6A), size: 14),
            ),
          ],
        ),
        const SizedBox(height: 1),
        // Maceta marrón
        Container(
          width: 16,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

/// Ícono vectorial del pin de Mapa (verde redondeado con círculo blanco en Image 2)
class _MapPinIcon extends StatelessWidget {
  const _MapPinIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2E7D32), width: 3.5),
      ),
    );
  }
}

/// Ícono vectorial de Diana / Puntos (concéntrico rojo de Image 2)
class _TargetIcon extends StatelessWidget {
  const _TargetIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE53935), width: 3),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFE53935),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Ícono vectorial de Árbol (EcoCuidados en Image 2)
class _TreeIcon extends StatelessWidget {
  const _TreeIcon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copa del árbol
        const Icon(Icons.park, color: Color(0xFF2E7D32), size: 24),
        // Tronco
        Container(
          width: 4,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF795548),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
