import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/main.dart';

void main() {
  testWidgets('la app arranca y muestra su nombre', (tester) async {
    await tester.pumpWidget(const LinForgeApp());

    expect(find.text('LinForge'), findsOneWidget);
    expect(find.text('Cotizador de herrería'), findsOneWidget);
  });
}
