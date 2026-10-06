import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app1/main.dart';
import 'package:app1/models/user_model.dart';
import 'package:app1/screens/home_screen.dart';
import 'package:app1/screens/ecoscan_screen.dart';
import 'package:app1/screens/ecoscan_gallery_screen.dart';

void main() {
  testWidgets('1. EcoScan Welcome Screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoScanApp());

    expect(find.text('EcoScan'), findsOneWidget);
    expect(find.text('Escanea, recicla\ny cuida el planeta'), findsOneWidget);
    expect(find.text('Iniciar Sesion'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });

  testWidgets('2. HomeScreen muestra diseño fiel con las 5 tarjetas de acción', (WidgetTester tester) async {
    final testUser = UserModel(
      id: 1,
      nombreCompleto: 'Alexis Hernández',
      correoElectronico: 'alexis@ecoscan.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(user: testUser),
      ),
    );

    expect(find.text('¡Hola!'), findsOneWidget);
    expect(find.text('Haz la diferencia hoy'), findsOneWidget);
    expect(find.text('Alexis Hernández'), findsOneWidget);

    expect(find.text('Escanear residuo'), findsOneWidget);
    expect(find.text('Eco IA'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Mis puntos'), findsOneWidget);
    expect(find.text('EcoCuidados'), findsOneWidget);
  });

  testWidgets('3. Navegación a EcoScanScreen y presencia de elementos de Image 3', (WidgetTester tester) async {
    final testUser = UserModel(
      id: 1,
      nombreCompleto: 'Alexis Hernández',
      correoElectronico: 'alexis@ecoscan.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(user: testUser),
      ),
    );

    await tester.tap(find.text('Escanear residuo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('EcoScan'), findsOneWidget);
    expect(find.text('Enfoca el residuo a escanear'), findsOneWidget);
    expect(find.text('Galería'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('4. EcoScanScreen renderiza directamente el visor HUD', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EcoScanScreen(),
      ),
    );

    expect(find.text('EcoScan'), findsOneWidget);
    expect(find.text('Enfoca el residuo a escanear'), findsOneWidget);
    expect(find.text('Galería'), findsOneWidget);
  });

  testWidgets('5. El botón Galería en EcoScanScreen abre la Galería exclusiva de EcoScan', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EcoScanScreen(),
      ),
    );

    // Tocar el botón Galería
    await tester.tap(find.text('Galería'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Debe abrir la pantalla de Galería exclusiva con los resultados de EcoScan
    expect(find.text('Galería EcoScan'), findsOneWidget);
  });

  testWidgets('6. EcoScanGalleryScreen renderiza correctamente el estado de galería', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EcoScanGalleryScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Galería EcoScan'), findsOneWidget);
  });
}
