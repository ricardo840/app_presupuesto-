import 'package:linforge/motor/catalogo/articulo.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/error_motor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../soporte/fixtures.dart';

const _a = Articulo(
  clave: 'a',
  nombre: 'A',
  tipo: TipoArticulo.herraje,
  unidadCompra: UnidadCompra.pieza,
  precio: 1,
);

Matcher _error(String codigo) =>
    throwsA(isA<ErrorMotor>().having((e) => e.codigo, 'codigo', codigo));

void main() {
  final entrada = cargarEntrada('catalogo');

  group('Catalogo', () {
    test('una clave inexistente da articulo_desconocido', () {
      final c = Catalogo.fromJson(entrada);
      expect(() => c.articulo('nada'), _error('articulo_desconocido'));
      expect(() => c.derivados('nada'), _error('articulo_desconocido'));
      expect(c.contiene('nada'), isFalse);
      expect(c.contiene('ptr-2x2-c14'), isTrue);
    });

    test('el detalle del error desconocido es la clave', () {
      expect(
        () => Catalogo([]).articulo('x'),
        throwsA(isA<ErrorMotor>().having((e) => e.detalle, 'detalle', 'x')),
      );
    });

    test('una clave repetida da articulo_invalido', () {
      expect(() => Catalogo([_a, _a]), _error('articulo_invalido'));
    });

    test('conserva el orden y no se puede modificar la lista', () {
      final c = Catalogo.fromJson(entrada);
      expect(c.articulos.first.clave, 'angulo-1x1-8');
      expect(c.articulos.length, (entrada['articulos']! as List).length);
      expect(() => c.articulos.add(_a), throwsUnsupportedError);
    });

    test('sin constantes usa los valores por defecto', () {
      final c = Catalogo.fromJson({'articulos': <Object?>[]});
      expect(c.constantes, const Constantes());
      expect(c.constantes.densidadKgM3, 7850);
    });

    test('lee las constantes del catálogo de prueba', () {
      final c = Catalogo.fromJson(entrada);
      expect(c.constantes.kerfMm, 3);
      expect(c.constantes.desperdicioLamina, 0.10);
    });

    test('fromJson(toJson(x)) == x para el catálogo de prueba', () {
      final c = Catalogo.fromJson(entrada);
      final otro = Catalogo.fromJson(c.toJson());
      expect(otro, c);
      expect(otro.hashCode, c.hashCode);
    });

    test('un herraje con familia da ErrorMotor y no un TypeError', () {
      expect(
        () => Catalogo.fromJson({
          'articulos': [
            {
              'clave': 'h',
              'nombre': 'H',
              'tipo': 'herraje',
              'familia': 'cuadrado',
              'unidad_compra': 'pieza',
              'precio': 1,
            },
          ],
        }),
        _error('articulo_invalido'),
      );
    });

    test('un artículo inválido dentro del catálogo da articulo_invalido', () {
      expect(
        () => Catalogo.fromJson({
          'articulos': [
            {'clave': 'x'},
          ],
        }),
        _error('articulo_invalido'),
      );
    });
  });
}
