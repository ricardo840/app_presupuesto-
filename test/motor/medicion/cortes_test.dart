import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/medicion/cortes.dart';

import '../../soporte/comparadores.dart';
import '../../soporte/fixtures.dart';

void main() {
  final casos = (cargarDorado('casos_cortes')['casos']! as List)
      .cast<Map<String, Object?>>();

  group('dorados de cortes', () {
    for (final caso in casos) {
      test(caso['id']! as String, () {
        final largos = [for (final l in caso['largos']! as List) comoDouble(l)];
        final plan = optimizarCortes(
          largos,
          comoDouble(caso['tramo_mm']),
          comoDouble(caso['kerf_mm']),
        );
        expect(plan.toJson(), coincideJson(caso['esperado']));
      });
    }
  });

  test('lista vacía no compra tramos', () {
    final plan = optimizarCortes([], 6000, 3);
    expect(plan.tramos, 0);
    expect(plan.barras, isEmpty);
    expect(plan.sobrantesMm, isEmpty);
    expect(plan.segmentos, 0);
    expect(plan.cortes, 0);
    expect(plan.empalmes, 0);
  });

  test('es determinista', () {
    final a = optimizarCortes([2500, 7000, 1200, 1200], 6000, 3);
    final b = optimizarCortes([2500, 7000, 1200, 1200], 6000, 3);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.toJson(), b.toJson());
  });

  test('no modifica la lista de entrada', () {
    final largos = [1000.0, 7000.0, 500.0];
    optimizarCortes(largos, 6000, 3);
    expect(largos, [1000.0, 7000.0, 500.0]);
  });

  test('las listas del plan son inmodificables', () {
    final plan = optimizarCortes([1000], 6000, 3);
    expect(() => plan.barras.add([1]), throwsUnsupportedError);
    expect(() => plan.barras.first.add(1), throwsUnsupportedError);
    expect(() => plan.sobrantesMm.add(1), throwsUnsupportedError);
  });

  group('precondiciones', () {
    test('tramo 0', () {
      expect(() => optimizarCortes([100], 0, 3), throwsArgumentError);
    });
    test('kerf negativo', () {
      expect(() => optimizarCortes([100], 6000, -1), throwsArgumentError);
    });
    test('largo 0', () {
      expect(() => optimizarCortes([0], 6000, 3), throwsArgumentError);
    });
  });

  group('bordes', () {
    test('un largo igual al tramo con ruido no se parte ni se corta', () {
      final p = optimizarCortes([6000.0000000001, 5999.9999999999], 6000, 3);
      expect(p.segmentos, 2);
      expect(p.empalmes, 0);
      expect(p.cortes, 0);
      expect(p.tramos, 2);
    });

    test('el doble exacto del tramo da dos tramos y un empalme, sin resto', () {
      final p = optimizarCortes([12000.0000000001], 6000, 3);
      expect(p.segmentos, 2);
      expect(p.empalmes, 1);
      expect(p.barras, [
        [6000.0],
        [6000.0],
      ]);
    });

    test('la primera pieza de una barra no paga kerf; las siguientes sí', () {
      // 2998.5 + 3 + 2998.5 = 6000 cabe; con 2998.6 ya no.
      expect(optimizarCortes([2998.5, 2998.5], 6000, 3).tramos, 1);
      expect(optimizarCortes([2998.6, 2998.5], 6000, 3).tramos, 2);
    });

    test('los empates conservan el orden de aparición', () {
      final p = optimizarCortes([1000, 2000, 1000, 2000], 2500, 3);
      expect(p.barras, [
        [2000.0],
        [2000.0],
        [1000.0, 1000.0],
      ]);
    });
  });
}
