import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/numeros.dart';

void main() {
  group('techo', () {
    test('absorbe el ruido por encima de un entero', () {
      expect(techo(2.0000000001), 2);
    });
    test('sube cuando el exceso es real', () {
      expect(techo(2.001), 3);
    });
    test('respeta enteros exactos y negativos', () {
      expect(techo(3.0), 3);
      expect(techo(-2.5), -2);
      expect(techo(-3.0), -3);
    });
    test('con cero da cero', () => expect(techo(0), 0));
    test('con valores del orden de 1e9', () {
      expect(techo(1e9), 1000000000);
      expect(techo(1e9 + 0.5), 1000000001);
    });
  });

  group('piso', () {
    test('absorbe el ruido por debajo de un entero', () {
      expect(piso(2.9999999999), 3);
    });
    test('baja cuando la diferencia es real', () {
      expect(piso(2.999), 2);
    });
    test('respeta enteros exactos y negativos', () {
      expect(piso(3.0), 3);
      expect(piso(-2.5), -3);
      expect(piso(-3.0), -3);
    });
    test('con cero da cero', () => expect(piso(0), 0));
    test('con valores del orden de 1e9', () {
      expect(piso(1e9), 1000000000);
      expect(piso(1e9 - 0.5), 999999999);
    });
  });

  group('cabe', () {
    test('cabe en el límite exacto', () => expect(cabe(2400, 2400), isTrue));
    test('cabe con ruido sobre el límite', () {
      expect(cabe(2400.0000000001, 2400), isTrue);
    });
    test('no cabe cuando excede de verdad', () {
      expect(cabe(2400.001, 2400), isFalse);
    });
  });

  group('redondear', () {
    test('la mitad se aleja de cero', () {
      expect(redondear(2.5), 3);
      expect(redondear(-2.5), -3);
    });
    test('absorbe el ruido binario en decimales', () {
      expect(redondear(1.005, 2), 1.01);
    });
    test('con cero da cero, sin signo negativo', () {
      expect(redondear(0), 0);
      expect(redondear(-0.0).isNegative, isFalse);
      expect(redondear(-0.2).isNegative, isFalse);
    });
    test('con valores del orden de 1e9', () {
      expect(redondear(1e9 + 0.4), 1e9);
      expect(redondear(-1e9 - 0.5), -1000000001);
    });
  });

  group('centavos', () {
    test('redondea la mitad hacia arriba', () => expect(centavos(2.345), 235));
    test('la mitad negativa se aleja de cero', () {
      expect(centavos(-1.005), -101);
    });
    test('con cero da cero', () {
      expect(centavos(0), 0);
      expect(centavos(-0.0), 0);
    });
    test('con valores del orden de 1e9', () {
      expect(centavos(1e9), 100000000000);
      expect(centavos(-1e9), -100000000000);
    });
  });
}
