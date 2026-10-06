import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app1/main.dart';
import 'package:app1/models/user_model.dart';
import 'package:app1/screens/home_screen.dart';
import 'package:app1/screens/ecoscan_screen.dart';

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

    // Verificar encabezado de Image 2
    expect(find.text('¡Hola!'), findsOneWidget);
    expect(find.text('Haz la diferencia hoy'), findsOneWidget);
    expect(find.text('Alexis Hernández'), findsOneWidget);

    // Verificar presencia de las 5 opciones de la interfaz
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

    // Tocar 'Escanear residuo'
    await tester.tap(find.text('Escanear residuo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verificar que estamos en la pantalla de escaneo EcoScan (Image 3)
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
}
