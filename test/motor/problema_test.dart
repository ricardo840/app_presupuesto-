import 'package:linforge/motor/problema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Problema', () {
    test('toJson omite lo que no tiene', () {
      expect(const Problema('sin_barrotes').toJson(), {
        'codigo': 'sin_barrotes',
        'gravedad': 'error',
      });
      expect(
        const Problema(
          'hoja_ancha',
          gravedad: Gravedad.advertencia,
          parametro: 'ancho',
          detalle: '900',
        ).toJson(),
        {
          'codigo': 'hoja_ancha',
          'gravedad': 'advertencia',
          'parametro': 'ancho',
          'detalle': '900',
        },
      );
    });

    test('igualdad por valor y esError según la gravedad', () {
      expect(
        const Problema('a', parametro: 'x', detalle: '1'),
        const Problema('a', parametro: 'x', detalle: '1'),
      );
      expect(const Problema('a').hashCode, const Problema('a').hashCode);
      expect(const Problema('a') == const Problema('a', parametro: 'x'), false);
      expect(
        const Problema('a') ==
            const Problema('a', gravedad: Gravedad.advertencia),
        false,
      );
      expect(const Problema('a').esError, true);
      expect(
        const Problema('a', gravedad: Gravedad.advertencia).esError,
        false,
      );
    });
  });
}
