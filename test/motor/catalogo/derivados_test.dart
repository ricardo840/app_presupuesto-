import 'package:linforge/motor/catalogo/articulo.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/catalogo/derivados.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../soporte/comparadores.dart';
import '../../soporte/fixtures.dart';

Articulo _perfil({
  Familia familia = Familia.solera,
  Map<String, double> geometria = const {'a': 25.4, 'e': 3.175},
  double? manual,
}) => Articulo(
  clave: 'p',
  nombre: 'P',
  tipo: TipoArticulo.perfil,
  unidadCompra: UnidadCompra.tramo,
  precio: 1,
  familia: familia,
  geometria: geometria,
  pesoKgMManual: manual,
);

void main() {
  group('derivados del catálogo de prueba', () {
    final catalogo = Catalogo.fromJson(cargarEntrada('catalogo'));
    final dorado = cargarDorado('catalogo_derivados');
    final tol = comoDouble(dorado['tolerancia_abs']);
    final esperados = (dorado['articulos']! as Map).cast<String, Object?>();

    test('el dorado cubre todos los artículos', () {
      expect(esperados.keys.toSet(), {
        for (final a in catalogo.articulos) a.clave,
      });
    });

    for (final clave in esperados.keys) {
      test('coincide con el dorado: $clave', () {
        expect(
          catalogo.derivados(clave).toJson(),
          coincideJson(esperados[clave], tolerancia: tol),
        );
      });
    }
  });

  group('calcularDerivados', () {
    test('el peso manual manda sobre el teórico', () {
      final d =
          calcularDerivados(_perfil(manual: 0.5), 7850) as DerivadosPerfil;
      expect(d.pesoKgM, 0.5);
      expect(d.areaMm2, cercaDe(80.645));
    });

    test('familia otro usa cara, fondo y peso manual, sin área', () {
      final d = calcularDerivados(
        _perfil(
          familia: Familia.otro,
          geometria: const {'cara': 40, 'fondo': 20},
          manual: 1.7,
        ),
        7850,
      ) as DerivadosPerfil;
      expect(d.areaMm2, isNull);
      expect(d.caraMm, 40);
      expect(d.fondoMm, 20);
      expect(d.perimetroPinturaMm, 120);
      expect(d.pesoKgM, 1.7);
      expect(d.toJson().containsKey('area_mm2'), isFalse);
    });

    test('la densidad cambia el peso teórico', () {
      final a = calcularDerivados(_perfil(), 7850) as DerivadosPerfil;
      final b = calcularDerivados(_perfil(), 7000) as DerivadosPerfil;
      expect(b.pesoKgM, cercaDe(a.pesoKgM * 7000 / 7850));
    });

    test('herraje y consumible no tienen derivados', () {
      const h = Articulo(
        clave: 'h',
        nombre: 'H',
        tipo: TipoArticulo.herraje,
        unidadCompra: UnidadCompra.pieza,
        precio: 1,
      );
      expect(calcularDerivados(h, 7850), isA<SinDerivados>());
      expect(calcularDerivados(h, 7850).toJson(), isEmpty);
    });
  });
}
