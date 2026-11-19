import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/medicion/medir.dart';
import 'package:linforge/motor/plantillas/libre.dart';
import 'package:linforge/motor/plantillas/plantilla.dart';
import 'package:linforge/motor/plantillas/validacion.dart';

import '../../soporte/comparadores.dart';
import '../../soporte/fixtures.dart';

void main() {
  final catalogo = Catalogo.fromJson(cargarEntrada('catalogo'));
  const plantilla = PlantillaLibre();

  Map<String, Object?> base({
    List<Object?> piezas = const [],
    List<Object?> paneles = const [],
    List<Object?> herrajes = const [],
  }) => {
    'ancho': 1000,
    'alto': 900,
    'piezas': piezas,
    'paneles': paneles,
    'herrajes': herrajes,
  };

  Map<String, Object?> pieza([Map<String, Object?> cambios = const {}]) => {
    'articulo': 'ptr-2x2-c14',
    'largo': 1000,
    'cantidad': 2,
    ...cambios,
  };

  group('PlantillaLibre', () {
    test('el dorado libre_barandal_7500 coincide de punta a punta', () {
      final dorado = cargarDorado('libre_barandal_7500');
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
      expect(
        (m['advertencias']! as List).single,
        containsPair('codigo', 'pieza_mayor_que_tramo'),
      );
    });

    test('grupo y corte faltantes toman sus valores por defecto', () {
      final r = aplicarPlantilla(
        plantilla,
        base(
          piezas: [pieza()],
          paneles: [
            {
              'articulo': 'lamina-c18',
              'ancho': 500,
              'alto': 400,
              'cantidad': 1,
            },
          ],
        ),
        catalogo,
      );
      expect(r.problemas, isEmpty);
      expect(r.modelo!.piezas.single.grupo, 'piezas');
      expect(r.modelo!.piezas.single.corte.name, 'recto');
      expect(r.modelo!.paneles.single.grupo, 'paneles');
      expect(r.modelo!.paneles.single.id, 'panel-1');
      expect(r.modelo!.uniones, {'manual': 0});
    });

    group('errores con su ruta', () {
      void espera(Map<String, Object?> p, String codigo, String ruta) {
        final r = aplicarPlantilla(plantilla, p, catalogo);
        expect(r.modelo, isNull);
        expect(r.problemas.map((e) => (e.codigo, e.parametro)), [
          (codigo, ruta),
        ]);
      }

      test('pieza con una lámina', () {
        espera(
          base(
            piezas: [
              pieza({'articulo': 'lamina-c18'}),
            ],
          ),
          'familia_no_permitida',
          'piezas[0].articulo',
        );
      });
      test('largo 0', () {
        espera(
          base(
            piezas: [
              pieza({'largo': 0}),
            ],
          ),
          'fuera_de_rango',
          'piezas[0].largo',
        );
      });
      test('cantidad con decimales', () {
        espera(
          base(
            piezas: [
              pieza({'cantidad': 1.5}),
            ],
          ),
          'valor_invalido',
          'piezas[0].cantidad',
        );
      });
      test('falta el ancho', () {
        espera({'alto': 900}, 'parametro_faltante', 'ancho');
      });
      test('artículo inexistente', () {
        espera(
          base(
            piezas: [
              pieza(),
              pieza({'articulo': 'no-existe'}),
            ],
          ),
          'articulo_desconocido',
          'piezas[1].articulo',
        );
      });
    });

    test('sin piezas, paneles ni herrajes el modelo es vacío y válido', () {
      final r = aplicarPlantilla(plantilla, {
        'ancho': 1000,
        'alto': 900,
      }, catalogo);
      expect(r.problemas, isEmpty);
      final m = r.modelo!;
      expect(m.piezas, isEmpty);
      expect(m.paneles, isEmpty);
      expect(m.herrajes, isEmpty);
      expect(m.uniones, {'manual': 0});
      expect(m.caja, (ancho: 1000.0, alto: 900.0));
    });

    test('todo parámetro del esquema tiene etiqueta y ayuda', () {
      void revisa(List<ParametroDef> defs) {
        for (final d in defs) {
          expect(d.etiqueta, isNotEmpty, reason: d.clave);
          expect(d.ayuda, isNotEmpty, reason: d.clave);
          revisa(d.campos);
        }
      }

      revisa(plantilla.esquema);
      expect(plantilla.esquema.map((d) => d.clave), [
        'ancho',
        'alto',
        'piezas',
        'paneles',
        'herrajes',
        'uniones',
      ]);
    });
  });
}
