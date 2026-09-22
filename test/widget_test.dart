import 'package:flutter_test/flutter_test.dart';
import 'package:app1/main.dart';

void main() {
  testWidgets('EcoScan Welcome Screen smoke test', (WidgetTester tester) async {
    // Renderizar la app EcoScan
    await tester.pumpWidget(const EcoScanApp());

    // Verificar presencia del título y subtítulo
    expect(find.text('EcoScan'), findsOneWidget);
    expect(find.text('Escanea, recicla\ny cuida el planeta'), findsOneWidget);

    // Verificar presencia de los botones principales
    expect(find.text('Iniciar Sesion'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });
}
