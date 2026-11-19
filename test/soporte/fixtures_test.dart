import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('lee los 9 dorados', () {
    final nombres = nombresDorados();
    expect(nombres, hasLength(9));
    for (final n in nombres) {
      expect(cargarDorado(n), isNotEmpty, reason: n);
    }
  });

  test('distingue los 5 trabajos dorados completos', () {
    expect(nombresTrabajosDorados(), [
      'libre_barandal_7500',
      'porton_1hoja_barrotes_1000x2100',
      'porton_3000x2200',
      'porton_lamina_2400x2000',
      'reja_1200x1000',
    ]);
  });

  test('lee las entradas', () {
    expect(cargarEntrada('catalogo'), contains('articulos'));
    expect(cargarEntrada('recetas'), contains('recetas'));
  });

  test('un archivo que no existe da un error claro', () {
    expect(() => cargarEntrada('no_existe'), throwsStateError);
  });

  test('comoDouble acepta enteros y decimales de JSON', () {
    expect(comoDouble(3), 3.0);
    expect(comoDouble(2.5), 2.5);
  });
}
