import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/pulgadas.dart';
import 'package:linforge/motor/error_motor.dart';

import '../../soporte/comparadores.dart';

void main() {
  group('pulgadasAMm', () {
    test('acepta las formas válidas', () {
      expect(pulgadasAMm('1 1/2'), cercaDe(38.1));
      expect(pulgadasAMm('1-1/2'), cercaDe(38.1));
      expect(pulgadasAMm('1.5'), cercaDe(38.1));
      expect(pulgadasAMm('3/4'), cercaDe(19.05));
      expect(pulgadasAMm('2'), cercaDe(50.8));
    });

    test('acepta espacios alrededor y comilla final', () {
      expect(pulgadasAMm('  1 1/2" '), cercaDe(38.1));
      expect(pulgadasAMm('3/4"'), cercaDe(19.05));
      expect(pulgadasAMm(' 2 " '), cercaDe(50.8));
    });

    for (final malo in [
      '1 1/2 3',
      '1//2',
      '1.5.2',
      '-1',
      '0',
      '0.0',
      '0/4',
      '',
      '   ',
      'abc',
      '1/0',
      '1/99999999999999999999',
      '1 3/2',
      '1 - 1/2',
      '1 1/0',
      '""',
    ]) {
      test('rechaza "$malo" con medida_invalida', () {
        expect(
          () => pulgadasAMm(malo),
          throwsA(
            isA<ErrorMotor>()
                .having((e) => e.codigo, 'codigo', 'medida_invalida')
                .having((e) => e.detalle, 'detalle', malo),
          ),
        );
      });
    }
  });

  group('mmATextoPulgadas', () {
    test('escribe dieciseisavos simplificados', () {
      expect(mmATextoPulgadas(50.8), '2');
      expect(mmATextoPulgadas(19.05), '3/4');
      expect(mmATextoPulgadas(38.1), '1 1/2');
      expect(mmATextoPulgadas(pulgadasAMm('1 3/16')), '1 3/16');
    });

    test('ida y vuelta con medidas comerciales', () {
      for (final t in [
        '1/8', '3/16', '1/4', '5/16', '3/8', '1/2', '5/8', '3/4', //
        '1', '1 1/4', '1 1/2', '2', '2 1/2', '3', '4',
      ]) {
        expect(mmATextoPulgadas(pulgadasAMm(t)), t, reason: t);
      }
    });

    test('una medida que no es dieciseisavo da null', () {
      expect(mmATextoPulgadas(40), isNull);
    });

    test('acepta ruido de 0.005 mm y rechaza 0.02 mm', () {
      expect(mmATextoPulgadas(19.05 + 0.005), '3/4');
      expect(mmATextoPulgadas(19.05 - 0.005), '3/4');
      expect(mmATextoPulgadas(19.05 + 0.02), isNull);
    });

    test('cero y negativos dan null', () {
      expect(mmATextoPulgadas(0), isNull);
      expect(mmATextoPulgadas(-25.4), isNull);
    });
  });
}
