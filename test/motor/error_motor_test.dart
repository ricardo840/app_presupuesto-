import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/error_motor.dart';

void main() {
  group('ErrorMotor', () {
    test('dos errores con los mismos datos son iguales', () {
      const a = ErrorMotor('sintaxis', detalle: 'x', posicion: 3);
      const b = ErrorMotor('sintaxis', detalle: 'x', posicion: 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('difieren si cambia código, detalle o posición', () {
      const base = ErrorMotor('sintaxis', detalle: 'x', posicion: 3);
      expect(base, isNot(const ErrorMotor('ciclo', detalle: 'x', posicion: 3)));
      expect(
        base,
        isNot(const ErrorMotor('sintaxis', detalle: 'y', posicion: 3)),
      );
      expect(
        base,
        isNot(const ErrorMotor('sintaxis', detalle: 'x', posicion: 4)),
      );
    });
    test('detalle y posición son opcionales', () {
      const e = ErrorMotor('ciclo');
      expect(e.detalle, isNull);
      expect(e.posicion, isNull);
    });
    test('toString incluye el código', () {
      expect(
        const ErrorMotor('ciclo', detalle: 'a').toString(),
        contains('ciclo'),
      );
    });
  });
}
