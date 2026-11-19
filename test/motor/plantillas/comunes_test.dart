import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/plantillas/comunes.dart';

void main() {
  group('numeroBarrotes', () {
    test('el ejemplo de la especificación da 8', () {
      expect(numeroBarrotes(1149.2, 12.7, 120), 8);
    });

    test('un claro menor que la separación da 0', () {
      expect(numeroBarrotes(100, 12.7, 120), 0);
      expect(numeroBarrotes(120, 12.7, 120), 0);
    });

    test('un claro exacto no suma un barrote de más', () {
      // (252.7 - 120) / (12.7 + 120) = 1 exacto
      expect(numeroBarrotes(252.7, 12.7, 120), 1);
      expect(numeroBarrotes(252.8, 12.7, 120), 2);
    });
  });
}
