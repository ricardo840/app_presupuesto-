import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/error_motor.dart';
import 'package:linforge/motor/medicion/modelo.dart';
import 'package:linforge/motor/plantillas/plantilla.dart';
import 'package:linforge/motor/plantillas/registro.dart';
import 'package:linforge/motor/problema.dart';

class _P implements Plantilla {
  _P(this.id);
  @override
  final String id;
  @override
  String get nombre => id;
  @override
  List<ParametroDef> get esquema => const [];
  @override
  List<Problema> validarReglas(Map<String, Object?> p, Catalogo c) => const [];
  @override
  ModeloPiezas generar(Map<String, Object?> p, Catalogo c) =>
      throw UnimplementedError();
}

void main() {
  group('RegistroPlantillas', () {
    final a = _P('a');
    final b = _P('b');
    final registro = RegistroPlantillas([b, a]);

    test('todas conserva el orden de entrada y no se puede modificar', () {
      expect(registro.todas, [b, a]);
      expect(() => registro.todas.add(_P('c')), throwsUnsupportedError);
    });

    test('contiene y porId encuentran por identificador', () {
      expect(registro.contiene('a'), true);
      expect(registro.contiene('z'), false);
      expect(registro.porId('a'), same(a));
    });

    test('una plantilla inexistente da plantilla_desconocida', () {
      expect(
        () => registro.porId('z'),
        throwsA(const ErrorMotor('plantilla_desconocida', detalle: 'z')),
      );
    });

    test('un id repetido es ArgumentError', () {
      expect(() => RegistroPlantillas([_P('a'), _P('a')]), throwsArgumentError);
    });
  });
}
