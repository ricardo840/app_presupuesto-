import 'package:flutter_test/flutter_test.dart';

import 'comparadores.dart';

void main() {
  group('cercaDe', () {
    test('acepta una diferencia menor que la tolerancia', () {
      expect(1200.000004, cercaDe(1200));
    });

    test('rechaza una diferencia igual o mayor', () {
      expect(1200.00002, isNot(cercaDe(1200)));
    });
  });

  group('diferenciaJson', () {
    test('los enteros se comparan exactos', () {
      expect(diferenciaJson(280000, 280000), isNull);
      expect(diferenciaJson(280000, 280001), contains('280001'));
    });

    test('entero contra decimal usa la tolerancia', () {
      expect(diferenciaJson(1200, 1200.000001), isNull);
      expect(diferenciaJson(1200, 1200.1), isNotNull);
    });

    test('dice la ruta de la primera diferencia', () {
      final esperado = {
        'despiece': [
          {'largo_mm': 1000},
          {'largo_mm': 1200.5},
        ],
      };
      final real = {
        'despiece': [
          {'largo_mm': 1000},
          {'largo_mm': 1201.5},
        ],
      };
      expect(
        diferenciaJson(esperado, real),
        startsWith(r'$.despiece[1].largo_mm'),
      );
    });

    test('detecta claves que faltan o sobran y largos distintos', () {
      expect(diferenciaJson({'a': 1}, {'b': 1}), contains('faltan'));
      expect(diferenciaJson({'a': 1}, {'a': 1, 'b': 2}), contains('sobran'));
      expect(diferenciaJson([1, 2], [1]), contains('2 elementos'));
    });

    test('compara textos, booleanos y nulos tal cual', () {
      expect(diferenciaJson('reja', 'reja'), isNull);
      expect(diferenciaJson(true, false), isNotNull);
      expect(diferenciaJson(null, 0), isNotNull);
    });
  });

  test('coincideJson explica la diferencia al fallar', () {
    final m = coincideJson({'total': 280000});
    expect({'total': 280000}, m);
    final estado = <Object?, Object?>{};
    expect(m.matches({'total': 1}, estado), isFalse);
    expect(estado['diferencia'], contains(r'$.total'));
  });
}
