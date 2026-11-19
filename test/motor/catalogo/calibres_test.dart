import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/calibres.dart';

import '../../soporte/comparadores.dart';

void main() {
  group('calibres', () {
    test('el calibre 14 mide 1.905 mm', () {
      expect(espesorCalibreMm(14), cercaDe(1.905));
    });

    test('la tabla por defecto trae los diez calibres', () {
      expect(calibresMm.length, 10);
      expect(espesorCalibreMm(24), cercaDe(0.610));
      expect(espesorCalibreMm(10), cercaDe(3.429));
    });

    test('un calibre inexistente da null', () {
      expect(espesorCalibreMm(15), isNull);
    });

    test('acepta una tabla propia', () {
      expect(espesorCalibreMm(15, {15: 1.7}), cercaDe(1.7));
      expect(espesorCalibreMm(14, {15: 1.7}), isNull);
    });
  });
}
