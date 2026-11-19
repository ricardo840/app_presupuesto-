import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/medicion/medir.dart';
import 'package:linforge/motor/plantillas/reja_ventana.dart';
import 'package:linforge/motor/plantillas/validacion.dart';

import '../../soporte/comparadores.dart';
import '../../soporte/fixtures.dart';

void main() {
  final catalogo = Catalogo.fromJson(cargarEntrada('catalogo'));
  const plantilla = PlantillaRejaVentana();

  Map<String, Object?> base([Map<String, Object?> cambios = const {}]) => {
    'ancho': 1200,
    'alto': 1000,
    'marco': 'angulo-1x1-8',
    'barrote': 'cuadrado-1-2',
    'separacion_max': 120,
    'travesanos': 1,
    'travesano': 'solera-1x1-8',
    'anclas': 4,
    'ancla': 'solera-1x1-8',
    'largo_ancla': 100,
    ...cambios,
  };

  group('PlantillaRejaVentana', () {
    test('el dorado reja_1200x1000 coincide de punta a punta', () {
      final dorado = cargarDorado('reja_1200x1000');
      final entrada = dorado['entrada']! as Map<String, Object?>;
      final esperado = dorado['esperado']! as Map<String, Object?>;
      final r = aplicarPlantilla(
        plantilla,
        entrada['parametros']! as Map<String, Object?>,
        catalogo,
      );
      expect(r.problemas, isEmpty);
      expect(r.modelo!.toJson(), coincideJson(esperado['modelo']));
      final m = medir(r.modelo!, catalogo).toJson();
      for (final k in [
        'despiece',
        'cortes',
        'por_articulo',
        'uniones',
        'cantidades',
        'advertencias',
      ]) {
        expect(m[k], coincideJson(esperado[k]), reason: k);
      }
    });

    test('las cuentas del ejemplo resuelto de la especificación', () {
      final r = aplicarPlantilla(plantilla, base(), catalogo);
      final modelo = r.modelo!;
      expect(modelo.extras['barrotes'], 8);
      expect(modelo.detalle['hueco_libre_mm'], closeTo(116.4, 1e-9));
      expect(modelo.advertencias, isEmpty);
      final c =
          medir(modelo, catalogo).toJson()['cantidades']!
              as Map<String, Object?>;
      expect(c['tramos'], 4);
      expect(c['uniones'], 34);
      expect(c['cortes'], 17);
      expect(c['ingletes'], 8);
    });

    group('errores con su parámetro', () {
      void espera(Map<String, Object?> p, List<(String, String)> esperados) {
        final r = aplicarPlantilla(plantilla, p, catalogo);
        expect(r.modelo, isNull);
        expect(r.problemas.map((e) => (e.codigo, e.parametro)), esperados);
      }

      test('sin marco', () {
        final p = base()..remove('marco');
        espera(p, [('parametro_faltante', 'marco')]);
      });
      test('ancho 100', () {
        espera(base({'ancho': 100}), [('fuera_de_rango', 'ancho')]);
      });
      test('artículo desconocido', () {
        espera(base({'barrote': 'no-existe'}), [
          ('articulo_desconocido', 'barrote'),
        ]);
      });
      test('barrote de familia solera', () {
        espera(base({'barrote': 'solera-1x1-8'}), [
          ('familia_no_permitida', 'barrote'),
        ]);
      });
      test('marco que es un herraje', () {
        espera(base({'marco': 'bisagra-tejuelo'}), [
          ('familia_no_permitida', 'marco'),
        ]);
      });
      test('travesanos con decimales', () {
        espera(base({'travesanos': 1.5}), [('valor_invalido', 'travesanos')]);
      });
      test('travesaños sin perfil de travesaño', () {
        final p = base({'travesanos': 2})..remove('travesano');
        espera(p, [('parametro_faltante', 'travesano')]);
      });
      test('con cero travesaños no se exige el perfil', () {
        final p = base({'travesanos': 0})..remove('travesano');
        expect(aplicarPlantilla(plantilla, p, catalogo).problemas, isEmpty);
      });
    });

    group('claro_insuficiente', () {
      // Perfil tubular de 150 mm de cara: con 300 mm de lado no queda claro.
      final json = cargarEntrada('catalogo');
      (json['articulos']! as List<Object?>).add({
        'clave': 'ptr-grande',
        'nombre': 'PTR de prueba',
        'tipo': 'perfil',
        'familia': 'tubular',
        'geometria': {'a': 150.0, 'b': 150.0, 'e': 3.0},
        'unidad_compra': 'tramo',
        'largo_tramo_mm': 6000,
        'precio': 1.0,
      });
      final cat = Catalogo.fromJson(json);

      List<(String, String?)> problemas(Map<String, Object?> p) =>
          aplicarPlantilla(
            plantilla,
            base({'marco': 'ptr-grande', ...p}),
            cat,
          ).problemas.map((e) => (e.codigo, e.parametro)).toList();

      test('fallan ancho y alto: un problema por cada uno', () {
        expect(problemas({'ancho': 300, 'alto': 300}), [
          ('claro_insuficiente', 'ancho'),
          ('claro_insuficiente', 'alto'),
        ]);
      });
      test('falla solo el ancho', () {
        expect(problemas({'ancho': 300, 'alto': 1000}), [
          ('claro_insuficiente', 'ancho'),
        ]);
      });
      test('falla solo el alto', () {
        expect(problemas({'ancho': 1000, 'alto': 300}), [
          ('claro_insuficiente', 'alto'),
        ]);
      });
    });

    test('con n = 0 avisa sin_barrotes', () {
      final r = aplicarPlantilla(
        plantilla,
        base({'ancho': 300, 'separacion_max': 300}),
        catalogo,
      );
      expect(r.problemas, isEmpty);
      expect(r.modelo!.extras['barrotes'], 0);
      expect(r.modelo!.advertencias.single.codigo, 'sin_barrotes');
    });

    test('sin travesaños ni anclas no hay esas piezas ni uniones', () {
      final r = aplicarPlantilla(
        plantilla,
        base({'travesanos': 0, 'anclas': 0}),
        catalogo,
      );
      final m = r.modelo!;
      expect(m.piezas.where((p) => p.grupo == 'travesanos'), isEmpty);
      expect(m.piezas.where((p) => p.grupo == 'anclas'), isEmpty);
      expect(m.uniones['travesanos'], 0);
      expect(m.uniones['anclas'], 0);
      expect(m.detalle['y_travesanos_mm'], isEmpty);
    });

    test('con dos travesaños se reparten en tercios y por detrás', () {
      // c = 25.4 (ángulo 1"), claro_alto = 1000 − 50.8 = 949.2, n = 8.
      // y1 = 25.4 + 949.2·1/3 = 341.8; y2 = 25.4 + 949.2·2/3 = 658.2.
      // z = −(12.7/2 + 3.175/2) = −7.9375 (fondo cuadrado 1/2", solera 1/8").
      // uniones travesaños = 2·(2 + 8) = 20.
      final m = aplicarPlantilla(
        plantilla,
        base({'travesanos': 2}),
        catalogo,
      ).modelo!;
      final tr = m.piezas.where((p) => p.grupo == 'travesanos').toList();
      expect(tr.length, 2);
      expect(tr[0].p0!.y, closeTo(25.4 + 949.2 / 3, 1e-9));
      expect(tr[1].p0!.y, closeTo(25.4 + 949.2 * 2 / 3, 1e-9));
      expect(tr[0].p0!.y, closeTo(341.8, 1e-9));
      expect(tr[1].p0!.y, closeTo(658.2, 1e-9));
      for (final p in tr) {
        expect(p.p0!.z, closeTo(-7.9375, 1e-9));
        expect(p.p1!.z, closeTo(-7.9375, 1e-9));
        expect(p.largo, closeTo(1200 - 50.8, 1e-9));
      }
      expect(m.detalle['y_travesanos_mm'], coincideJson([341.8, 658.2]));
      expect(m.uniones['travesanos'], 20);
    });

    test('en un marco tubular desigual c es la cara mayor', () {
      // PTR de 50.8 × 25.4: cara = a = 50.8, así que c = 50.8.
      // claro_ancho = 1200 − 2·50.8 = 1098.4; marco-izq en x = c/2 = 25.4.
      final json = cargarEntrada('catalogo');
      (json['articulos']! as List<Object?>).add({
        'clave': 'ptr-desigual',
        'nombre': 'PTR 2" x 1" cal. 16',
        'tipo': 'perfil',
        'familia': 'tubular',
        'geometria': {'a': 50.8, 'b': 25.4, 'e': 1.5},
        'unidad_compra': 'tramo',
        'largo_tramo_mm': 6000,
        'precio': 1.0,
      });
      final m = aplicarPlantilla(
        plantilla,
        base({'marco': 'ptr-desigual'}),
        Catalogo.fromJson(json),
      ).modelo!;
      expect(m.detalle['claro_ancho_mm'], closeTo(1098.4, 1e-9));
      expect(m.detalle['claro_alto_mm'], closeTo(898.4, 1e-9));
      final izq = m.piezas.firstWhere((p) => p.id == 'marco-izq');
      expect(izq.p0!.x, closeTo(25.4, 1e-9));
    });

    test('con n = 0 no hay barrotes y el hueco es todo el claro', () {
      // ángulo 1": claro_ancho = 300 − 50.8 = 249.2 ≤ 300, n = 0,
      // hueco = (249.2 − 0)/1 = 249.2.
      final m = aplicarPlantilla(
        plantilla,
        base({'ancho': 300, 'separacion_max': 300}),
        catalogo,
      ).modelo!;
      expect(m.piezas.where((p) => p.grupo == 'barrotes'), isEmpty);
      expect(m.detalle['claro_ancho_mm'], closeTo(249.2, 1e-9));
      expect(m.detalle['hueco_libre_mm'], m.detalle['claro_ancho_mm']);
      expect(m.detalle['x_centros_barrotes_mm'], isEmpty);
    });

    test('todo parámetro del esquema tiene etiqueta y ayuda', () {
      for (final d in plantilla.esquema) {
        expect(d.etiqueta, isNotEmpty, reason: d.clave);
        expect(d.ayuda, isNotEmpty, reason: d.clave);
      }
      expect(plantilla.esquema.map((d) => d.clave), [
        'ancho',
        'alto',
        'marco',
        'barrote',
        'separacion_max',
        'travesanos',
        'travesano',
        'anclas',
        'ancla',
        'largo_ancla',
      ]);
    });
  });
}
