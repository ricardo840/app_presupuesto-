import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/medicion/modelo.dart';
import 'package:linforge/motor/plantillas/descripcion.dart';
import 'package:linforge/motor/plantillas/libre.dart';
import 'package:linforge/motor/plantillas/plantilla.dart';
import 'package:linforge/motor/plantillas/porton_abatible.dart';
import 'package:linforge/motor/plantillas/reja_ventana.dart';
import 'package:linforge/motor/plantillas/validacion.dart';

import '../../soporte/fixtures.dart';

void main() {
  final catalogo = Catalogo.fromJson(cargarEntrada('catalogo'));

  Plantilla porId(String id) => switch (id) {
    'reja_ventana' => const PlantillaRejaVentana(),
    'porton_abatible' => const PlantillaPortonAbatible(),
    _ => const PlantillaLibre(),
  };

  group('dorados', () {
    final casos = <String, String>{
      'reja_1200x1000':
          'Reja de ventana de 1.20 × 1.00 m: marco de angulo 1" x 1/8", '
          '8 barrotes de cuadrado macizo 1/2", 1 travesaño de solera 1" x 1/8" '
          'y 4 anclas. Incluye instalación.',
      'porton_3000x2200':
          'Portón abatible de 2 hojas, 3.00 × 2.20 m. Bastidor de PTR 2" x 2" '
          'cal. 14, zoclo de lamina lisa cal. 18 y barrotes de tubular 1" x 1" '
          'cal. 18. Incluye instalación.',
      'porton_1hoja_barrotes_1000x2100':
          'Portón abatible de 1 hoja, 1.00 × 2.10 m. Bastidor de PTR 2" x 2" '
          'cal. 14 y barrotes de redondo macizo 1/2". Incluye instalación.',
      'porton_lamina_2400x2000':
          'Portón abatible de 2 hojas, 2.40 × 2.00 m. Bastidor de PTR 2" x 2" '
          'cal. 14 y tablero de lamina lisa cal. 18.',
      'libre_barandal_7500':
          'Trabajo libre de 7.50 × 0.90 m: pasamanos y postes de PTR 2" x 2" '
          'cal. 14, y barrotes de tubular 1" x 1" cal. 18. Incluye '
          'instalación.',
    };
    casos.forEach((nombre, texto) {
      test(nombre, () {
        final entrada =
            cargarDorado(nombre)['entrada']! as Map<String, Object?>;
        final plantilla = porId(entrada['plantilla']! as String);
        final params = entrada['parametros']! as Map<String, Object?>;
        final r = aplicarPlantilla(plantilla, params, catalogo);
        expect(r.problemas, isEmpty);
        final v = validarParametros(plantilla, params, catalogo);
        expect(
          describirTrabajo(
            r.modelo!,
            v.parametros,
            catalogo,
            datosTrabajo: entrada['datos_trabajo']! as Map<String, Object?>,
          ),
          texto,
        );
      });
    });
  });

  group('reglas sueltas', () {
    ModeloPiezas reja({int b = 8, int t = 0, int a = 0, double ancho = 1200}) =>
        ModeloPiezas(
          plantilla: 'reja_ventana',
          caja: (ancho: ancho, alto: 1000),
          numHojas: 1,
          extras: {'barrotes': b, 'travesanos': t, 'anclas': a},
        );

    late Map<String, Object?> claves;
    setUpAll(() {
      final entrada =
          cargarDorado('reja_1200x1000')['entrada']! as Map<String, Object?>;
      claves = validarParametros(
        const PlantillaRejaVentana(),
        entrada['parametros']! as Map<String, Object?>,
        catalogo,
      ).parametros;
    });

    test('sin travesaños ni anclas', () {
      expect(
        describirTrabajo(reja(), claves, catalogo),
        'Reja de ventana de 1.20 × 1.00 m: marco de angulo 1" x 1/8" y '
        '8 barrotes de cuadrado macizo 1/2".',
      );
    });
    test('plurales y singular', () {
      final t = describirTrabajo(reja(t: 2, a: 1), claves, catalogo);
      expect(t, contains('2 travesaños de solera'));
      expect(t, endsWith('y 1 ancla.'));
    });
    test('sin barrotes no se mencionan', () {
      final t = describirTrabajo(reja(b: 0, a: 4), claves, catalogo);
      expect(t, isNot(contains('barrote')));
      expect(t, endsWith('marco de angulo 1" x 1/8" y 4 anclas.'));
    });
    test('instalación false o ausente no agrega sufijo', () {
      expect(
        describirTrabajo(
          reja(),
          claves,
          catalogo,
          datosTrabajo: {'con_instalacion': false},
        ),
        isNot(contains('Incluye')),
      );
      expect(
        describirTrabajo(reja(), claves, catalogo),
        isNot(contains('Incluye')),
      );
    });
    test('plantilla desconocida', () {
      final m = ModeloPiezas(
        plantilla: 'otra',
        caja: (ancho: 2000, alto: 1500),
        numHojas: 1,
      );
      expect(
        describirTrabajo(m, const {}, catalogo),
        'Trabajo de 2.00 × 1.50 m.',
      );
    });
    test('nombre con paréntesis y con sigla', () {
      final m = ModeloPiezas(
        plantilla: 'porton_abatible',
        caja: (ancho: 1000, alto: 2000),
        numHojas: 1,
      );
      final t = describirTrabajo(m, {
        'bastidor': 'ptr-2x2-c14',
        'relleno': 'lamina',
        'lamina': 'lamina-c18',
      }, catalogo);
      expect(t, contains('Bastidor de PTR 2" x 2" cal. 14'));
      expect(t, contains('tablero de lamina lisa cal. 18.'));
      expect(t, isNot(contains('(')));
    });
    test('redondeo comercial de medidas', () {
      expect(
        describirTrabajo(reja(ancho: 1234.5), claves, catalogo),
        contains('1.23 × 1.00 m'),
      );
      expect(
        describirTrabajo(reja(ancho: 1235), claves, catalogo),
        contains('1.24 × 1.00 m'),
      );
    });
  });
}
