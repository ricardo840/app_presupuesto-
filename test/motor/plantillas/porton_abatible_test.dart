import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/medicion/medir.dart';
import 'package:linforge/motor/plantillas/porton_abatible.dart';
import 'package:linforge/motor/plantillas/validacion.dart';

import '../../soporte/comparadores.dart';
import '../../soporte/fixtures.dart';

void main() {
  final catalogo = Catalogo.fromJson(cargarEntrada('catalogo'));
  const plantilla = PlantillaPortonAbatible();

  Map<String, Object?> base([Map<String, Object?> cambios = const {}]) => {
    'ancho': 3000,
    'alto': 2200,
    'hojas': 2,
    'bastidor': 'ptr-2x2-c14',
    'relleno': 'mixto',
    'barrote': 'tubular-1x1-c18',
    'separacion_max': 110,
    'lamina': 'lamina-c18',
    'alto_zoclo': 900,
    'travesano': 'ptr-2x2-c14',
    'bisagra': 'bisagra-tejuelo',
    ...cambios,
  };

  // Catálogo con un perfil de 250 mm de cara para forzar claros negativos.
  final json = cargarEntrada('catalogo');
  (json['articulos']! as List<Object?>).add({
    'clave': 'ptr-enorme',
    'nombre': 'PTR de prueba',
    'tipo': 'perfil',
    'familia': 'tubular',
    'geometria': {'a': 250.0, 'b': 250.0, 'e': 3.0},
    'unidad_compra': 'tramo',
    'largo_tramo_mm': 6000,
    'precio': 1.0,
  });
  final catEnorme = Catalogo.fromJson(json);

  group('PlantillaPortonAbatible', () {
    for (final nombre in [
      'porton_3000x2200',
      'porton_1hoja_barrotes_1000x2100',
      'porton_lamina_2400x2000',
    ]) {
      test('el dorado $nombre coincide de punta a punta', () {
        final dorado = cargarDorado(nombre);
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
    }

    group('errores con su parámetro', () {
      void espera(
        Map<String, Object?> p,
        List<(String, String?)> esperados, [
        Catalogo? cat,
      ]) {
        final r = aplicarPlantilla(plantilla, p, cat ?? catalogo);
        expect(r.modelo, isNull);
        expect(r.problemas.map((e) => (e.codigo, e.parametro)), esperados);
      }

      test('relleno desconocido', () {
        espera(base({'relleno': 'reja'}), [
          ('relleno_no_soportado', 'relleno'),
        ]);
      });
      test('barrotes sin perfil de barrote', () {
        final p = base({'relleno': 'barrotes'})..remove('barrote');
        espera(p, [('parametro_faltante', 'barrote')]);
      });
      test('con lámina no se exige el barrote', () {
        final p = base({'relleno': 'lamina'})..remove('barrote');
        expect(aplicarPlantilla(plantilla, p, catalogo).problemas, isEmpty);
      });
      test('mixto sin lámina', () {
        final p = base()..remove('lamina');
        espera(p, [('parametro_faltante', 'lamina')]);
      });
      test('bastidor de familia solera', () {
        espera(base({'bastidor': 'solera-1x1-8'}), [
          ('familia_no_permitida', 'bastidor'),
        ]);
      });
      test('bisagra que es un perfil', () {
        espera(base({'bisagra': 'ptr-2x2-c14'}), [
          ('familia_no_permitida', 'bisagra'),
        ]);
      });
      test('tres hojas', () {
        espera(base({'hojas': 3}), [('fuera_de_rango', 'hojas')]);
      });
    });

    group('claro_insuficiente', () {
      List<(String, String?)> problemas(Map<String, Object?> p) =>
          aplicarPlantilla(
            plantilla,
            p,
            catEnorme,
          ).problemas.map((e) => (e.codigo, e.parametro)).toList();

      test('por ancho', () {
        // ancho_hoja = (600 − 20 − 10)/2 = 285; claro = 285 − 2·250 = −215.
        expect(problemas(base({'ancho': 600, 'bastidor': 'ptr-enorme'})), [
          ('claro_insuficiente', 'ancho'),
        ]);
      });
      test('por alto_zoclo en mixto', () {
        // alto_hoja = 2200 − 50 = 2150; c = 50.8, ct = 50.8 (ptr-2x2-c14).
        // largo = 2150 − 50.8 − 2100 − 25.4 = −26.2 ≤ 0.
        expect(problemas(base({'alto_zoclo': 2100})), [
          ('claro_insuficiente', 'alto_zoclo'),
        ]);
      });
      test('por alto en barrotes', () {
        // alto_hoja = 600 − 200 = 400; c = 250: 400 − 500 = −100 ≤ 0.
        expect(
          problemas(
            base({
              'relleno': 'barrotes',
              'alto': 600,
              'holgura_piso': 200,
              'bastidor': 'ptr-enorme',
            }),
          ),
          [('claro_insuficiente', 'alto')],
        );
      });
      test('en lámina no se revisa el largo de barrote', () {
        expect(
          problemas(
            base({
              'relleno': 'lamina',
              'alto': 600,
              'holgura_piso': 200,
              'bastidor': 'ptr-enorme',
            }),
          ),
          isEmpty,
        );
      });
    });

    group('advertencia hoja_ancha', () {
      test('una hoja de 2980 mm avisa', () {
        // ancho_hoja = 3000 − 2·10 − 0 = 2980 > 2500.
        final m = aplicarPlantilla(
          plantilla,
          base({'hojas': 1}),
          catalogo,
        ).modelo!;
        expect(m.detalle['ancho_hoja_mm'], 2980);
        expect(m.advertencias.map((a) => a.codigo), ['hoja_ancha']);
      });
      test('dos hojas de 3000 no avisan', () {
        final m = aplicarPlantilla(plantilla, base(), catalogo).modelo!;
        expect(m.advertencias, isEmpty);
      });
    });

    group('bisagras', () {
      int bisagras(double alto) {
        final m = aplicarPlantilla(
          plantilla,
          base({'alto': alto}),
          catalogo,
        ).modelo!;
        expect(m.extras['bisagras'], m.herrajes.first.cantidad);
        return m.herrajes.first.cantidad;
      }

      test('alto_hoja de 2000 exacto: 2 por hoja', () {
        expect(bisagras(2050), 4);
      });
      test('alto_hoja de 2001: 3 por hoja', () {
        expect(bisagras(2051), 6);
      });
    });

    group('herrajes opcionales', () {
      test('sin pasador no hay herraje ni uniones de pasador', () {
        final m = aplicarPlantilla(plantilla, base(), catalogo).modelo!;
        expect(m.herrajes.map((h) => h.articulo), ['bisagra-tejuelo']);
        expect(m.uniones.containsKey('pasador'), isFalse);
        // alto_hoja 2150 > 2000: 3 por hoja, 6 bisagras, 2 uniones cada una.
        expect(m.uniones['bisagras'], 12);
      });
      test('con pasador suma un herraje y 2 uniones', () {
        final m = aplicarPlantilla(
          plantilla,
          base({'pasador': 'pasador-portacandado'}),
          catalogo,
        ).modelo!;
        expect(m.herrajes.last.articulo, 'pasador-portacandado');
        expect(m.uniones['pasador'], 2);
      });
      test('el picaporte con una hoja no se usa', () {
        final m = aplicarPlantilla(
          plantilla,
          base({'hojas': 1, 'picaporte': 'picaporte-piso'}),
          catalogo,
        ).modelo!;
        expect(m.herrajes.map((h) => h.articulo), ['bisagra-tejuelo']);
        expect(m.uniones.containsKey('picaporte'), isFalse);
      });
      test('el picaporte con dos hojas sí', () {
        final m = aplicarPlantilla(
          plantilla,
          base({'picaporte': 'picaporte-piso'}),
          catalogo,
        ).modelo!;
        expect(m.herrajes.last.articulo, 'picaporte-piso');
        expect(m.uniones['picaporte'], 2);
      });
    });

    test('mixto con n = 0 conserva claves y orden, sin piezas de barrotes', () {
      // ancho_hoja = (600 − 20 − 10)/2 = 285; c = 50.8;
      // claro_ancho = 285 − 101.6 = 183.4 ≤ separacion_max 300, así que n = 0.
      final m = aplicarPlantilla(
        plantilla,
        base({'ancho': 600, 'separacion_max': 300}),
        catalogo,
      ).modelo!;
      expect(m.piezas.where((p) => p.grupo == 'barrotes'), isEmpty);
      expect(m.uniones['barrotes'], 0);
      expect(m.extras['barrotes'], 0);
      expect(m.uniones.keys.toList(), [
        'bastidor',
        'travesanos',
        'barrotes',
        'lamina',
        'bisagras',
      ]);
      expect(m.detalle.keys.toList(), [
        'ancho_hoja_mm',
        'alto_hoja_mm',
        'claro_ancho_mm',
        'hueco_libre_mm',
        'barrotes_por_hoja',
        'largo_barrote_mm',
        'puntos_lamina_por_hoja',
      ]);
      expect(m.detalle['barrotes_por_hoja'], 0);
    });

    test('relleno barrotes con 2 hojas: orden de uniones y hoja 2', () {
      // ancho_hoja = (3000 − 20 − 10)/2 = 1485; c = 50.8.
      // x del bastidor izquierdo de la hoja 2 = 10 + 1485 + 10 + 25.4 = 1530.4.
      final m = aplicarPlantilla(
        plantilla,
        base({'relleno': 'barrotes'}),
        catalogo,
      ).modelo!;
      expect(m.uniones.keys.toList(), ['bastidor', 'barrotes', 'bisagras']);
      final izq = m.piezas.firstWhere((p) => p.id == 'h2-bastidor-izq');
      expect(izq.p0!.x, closeTo(10 + 1485 + 10 + 50.8 / 2, 1e-9));
      final h2 = m.piezas.where((p) => p.id.startsWith('h2-'));
      expect(h2, isNotEmpty);
      expect(h2.every((p) => p.hoja == 1), isTrue);
      expect(
        m.piezas.where((p) => p.id.startsWith('h1-')).every((p) => p.hoja == 0),
        isTrue,
      );
    });

    test('lámina con 1 hoja: detalle y z del tablero', () {
      // z = fondo(ptr-2x2-c14)/2 + e/2 = 50.8/2 + 1.219/2 = 26.0095.
      final m = aplicarPlantilla(
        plantilla,
        base({'relleno': 'lamina', 'hojas': 1}),
        catalogo,
      ).modelo!;
      expect(m.detalle.keys.toList(), [
        'ancho_hoja_mm',
        'alto_hoja_mm',
        'claro_ancho_mm',
        'puntos_lamina_por_hoja',
      ]);
      expect(m.paneles.single.origen!.z, closeTo(26.0095, 1e-9));
    });

    test('todo parámetro del esquema tiene etiqueta y ayuda', () {
      for (final d in plantilla.esquema) {
        expect(d.etiqueta, isNotEmpty, reason: d.clave);
        expect(d.ayuda, isNotEmpty, reason: d.clave);
      }
      expect(plantilla.esquema.map((d) => d.clave), [
        'ancho',
        'alto',
        'hojas',
        'holgura_lateral',
        'holgura_central',
        'holgura_piso',
        'bastidor',
        'relleno',
        'barrote',
        'separacion_max',
        'lamina',
        'alto_zoclo',
        'travesano',
        'paso_punteo',
        'bisagra',
        'pasador',
        'picaporte',
      ]);
    });
  });
}
