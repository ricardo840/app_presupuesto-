import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/error_motor.dart';
import 'package:linforge/motor/medicion/medir.dart';
import 'package:linforge/motor/medicion/modelo.dart';

import '../../soporte/comparadores.dart';
import '../../soporte/fixtures.dart';

/// Catálogo pequeño: un perfil de peso manual 2 kg/m, una
/// lámina de 1000 × 2000 mm de 2 mm (15.7 kg/m²) y un herraje de $30.
Catalogo _catalogo({
  String unidadPerfil = 'tramo',
  String unidadLamina = 'hoja',
  double precioPerfil = 100,
  double precioLamina = 100,
}) => Catalogo.fromJson({
  'articulos': [
    {
      'clave': 'perfil',
      'nombre': 'Perfil',
      'tipo': 'perfil',
      'familia': 'otro',
      'geometria': {'cara': 10, 'fondo': 10},
      'peso_kg_m_manual': 2.0,
      'unidad_compra': unidadPerfil,
      'largo_tramo_mm': 6000,
      'precio': precioPerfil,
    },
    {
      'clave': 'lamina',
      'nombre': 'Lámina',
      'tipo': 'lamina',
      'familia': 'lamina',
      'geometria': {'e': 2},
      'unidad_compra': unidadLamina,
      'hoja_mm': [1000, 2000],
      'precio': precioLamina,
    },
    {
      'clave': 'bisagra',
      'nombre': 'Bisagra',
      'tipo': 'herraje',
      'unidad_compra': 'pieza',
      'precio': 30,
    },
  ],
});

ModeloPiezas _modelo({
  List<Pieza> piezas = const [],
  List<Panel> paneles = const [],
  List<Herraje> herrajes = const [],
}) => ModeloPiezas(
  plantilla: 'prueba',
  caja: (ancho: 1000, alto: 2000),
  numHojas: 0,
  piezas: piezas,
  paneles: paneles,
  herrajes: herrajes,
);

// Tres barras de 2500 mm del perfil.
Pieza _barras([String articulo = 'perfil']) => Pieza(
  id: 'p',
  grupo: 'g',
  articulo: articulo,
  largo: 2500,
  cantidad: 3,
  corte: TipoCorte.recto,
);

Panel _panel(double ancho, double alto, {int cantidad = 1, String id = 'a'}) =>
    Panel(
      id: id,
      grupo: 'g',
      articulo: 'lamina',
      ancho: ancho,
      alto: alto,
      cantidad: cantidad,
    );

void main() {
  group('medir contra los dorados', () {
    for (final nombre in nombresTrabajosDorados()) {
      final dorado = cargarDorado(nombre);
      final esperado = dorado['esperado']! as Map<String, Object?>;
      final tol = ((dorado['tolerancias']! as Map)['cantidad_abs']! as num)
          .toDouble();
      final catalogo = Catalogo.fromJson(cargarEntrada('catalogo'));
      final medicion = medir(
        ModeloPiezas.fromJson(esperado['modelo']! as Map<String, Object?>),
        catalogo,
      );
      final json = medicion.toJson();

      for (final campo in [
        'despiece',
        'cortes',
        'por_articulo',
        'uniones',
        'cantidades',
        'advertencias',
      ]) {
        test('$nombre: $campo', () {
          expect(json[campo], coincideJson(esperado[campo], tolerancia: tol));
        });
      }
    }

    test('el libre avisa pieza_mayor_que_tramo y suma empalmes', () {
      final esperado =
          cargarDorado('libre_barandal_7500')['esperado']!
              as Map<String, Object?>;
      final m = medir(
        ModeloPiezas.fromJson(esperado['modelo']! as Map<String, Object?>),
        Catalogo.fromJson(cargarEntrada('catalogo')),
      );
      expect(
        m.advertencias.map((a) => a.codigo),
        contains('pieza_mayor_que_tramo'),
      );
      expect(m.uniones['empalmes'], 2);
    });
  });

  group('unidades de compra', () {
    // Tres barras de 2500 mm en tramos de 6000 con kerf 3: dos caben en una
    // barra (5000 + 2·3 = 5006), la tercera abre otra: 2 tramos.
    // metros = 7.5; kg = 7.5 · 2 = 15.
    test('perfil por tramo', () {
      // compra = 2 · 100 = 200; usado = 7.5 / 6 · 100 = 125
      final a = medir(_modelo(piezas: [_barras()]), _catalogo()).porArticulo;
      expect(a['perfil']!.tramos, 2);
      expect(a['perfil']!.metros, cercaDe(7.5));
      expect(a['perfil']!.kg, cercaDe(15));
      expect(a['perfil']!.piezas, 3);
      expect(a['perfil']!.costoCompra, cercaDe(200));
      expect(a['perfil']!.costoUsado, cercaDe(125));
    });

    test('perfil por kg', () {
      // precio 10/kg. compra = 2 · 6 m · 2 kg/m · 10 = 240; usado = 15 · 10 = 150
      final a = medir(
        _modelo(piezas: [_barras()]),
        _catalogo(unidadPerfil: 'kg', precioPerfil: 10),
      ).porArticulo['perfil']!;
      expect(a.costoCompra, cercaDe(240));
      expect(a.costoUsado, cercaDe(150));
    });

    test('perfil por m', () {
      // precio 4/m. compra = usado = 7.5 · 4 = 30
      final a = medir(
        _modelo(piezas: [_barras()]),
        _catalogo(unidadPerfil: 'm', precioPerfil: 4),
      ).porArticulo['perfil']!;
      expect(a.costoCompra, cercaDe(30));
      expect(a.costoUsado, cercaDe(30));
    });

    // Dos paneles de 1000 × 1500: m2 = 3.0; hoja de 2 m²;
    // hojas = techo(3 · 1.1 / 2) = techo(1.65) = 2; kg = 3 · 15.7 = 47.1.
    final paneles = [_panel(1000, 1500, cantidad: 2)];

    test('lámina por hoja', () {
      // compra = 2 · 100 = 200; usado = 3 / 2 · 100 = 150
      final a = medir(
        _modelo(paneles: paneles),
        _catalogo(),
      ).porArticulo['lamina']!;
      expect(a.m2, cercaDe(3));
      expect(a.hojas, 2);
      expect(a.kg, cercaDe(47.1));
      expect(a.costoCompra, cercaDe(200));
      expect(a.costoUsado, cercaDe(150));
    });

    test('lámina por m2', () {
      // precio 50. compra = 3 · 1.1 · 50 = 165; usado = 3 · 50 = 150
      final a = medir(
        _modelo(paneles: paneles),
        _catalogo(unidadLamina: 'm2', precioLamina: 50),
      ).porArticulo['lamina']!;
      expect(a.costoCompra, cercaDe(165));
      expect(a.costoUsado, cercaDe(150));
    });

    test('lámina por kg', () {
      // precio 3. compra = 2 hojas · 2 m² · 15.7 · 3 = 188.4; usado = 47.1 · 3 = 141.3
      final a = medir(
        _modelo(paneles: paneles),
        _catalogo(unidadLamina: 'kg', precioLamina: 3),
      ).porArticulo['lamina']!;
      expect(a.costoCompra, cercaDe(188.4));
      expect(a.costoUsado, cercaDe(141.3));
    });

    test('herraje: cantidad por precio, y se acumula', () {
      // (2 + 3) · 30 = 150
      final m = medir(
        _modelo(
          herrajes: [
            const Herraje(articulo: 'bisagra', cantidad: 2),
            const Herraje(articulo: 'bisagra', cantidad: 3),
          ],
        ),
        _catalogo(),
      );
      expect(m.porArticulo['bisagra']!.cantidad, 5);
      expect(m.porArticulo['bisagra']!.costoCompra, cercaDe(150));
      expect(m.cantidades['costo_herrajes'], cercaDe(150));
    });

    test('por_articulo va en orden perfiles, láminas, herrajes', () {
      final m = medir(
        _modelo(
          piezas: [_barras()],
          paneles: [_panel(500, 500)],
          herrajes: [const Herraje(articulo: 'bisagra', cantidad: 1)],
        ),
        _catalogo(),
      );
      expect(m.porArticulo.keys.toList(), ['perfil', 'lamina', 'bisagra']);
    });
  });

  group('paneles y hojas', () {
    test('un panel más grande que la hoja avisa', () {
      // 1100 × 1900: el lado corto 1100 supera el lado corto de la hoja, 1000
      final m = medir(
        _modelo(paneles: [_panel(1100, 1900, id: 'grande')]),
        _catalogo(),
      );
      expect(m.advertencias, hasLength(1));
      expect(m.advertencias.single.codigo, 'panel_no_cabe_en_hoja');
      expect(m.advertencias.single.datos, {
        'articulo': 'lamina',
        'panel': 'grande',
      });
    });

    test('un panel girado que sí cabe no avisa', () {
      // 1900 × 900 cabe en 1000 × 2000 girado
      final m = medir(_modelo(paneles: [_panel(1900, 900)]), _catalogo());
      expect(m.advertencias, isEmpty);
    });
  });

  group('errores', () {
    test('pieza con un artículo que no es perfil', () {
      expect(
        () => medir(_modelo(piezas: [_barras('bisagra')]), _catalogo()),
        throwsA(const ErrorMotor('familia_no_permitida', detalle: 'bisagra')),
      );
    });

    test('panel con un artículo que no es lámina', () {
      final p = Panel(
        id: 'a',
        grupo: 'g',
        articulo: 'perfil',
        ancho: 100,
        alto: 100,
        cantidad: 1,
      );
      expect(
        () => medir(_modelo(paneles: [p]), _catalogo()),
        throwsA(const ErrorMotor('familia_no_permitida', detalle: 'perfil')),
      );
    });

    test('herraje con un artículo que no es herraje', () {
      expect(
        () => medir(
          _modelo(herrajes: [const Herraje(articulo: 'lamina', cantidad: 1)]),
          _catalogo(),
        ),
        throwsA(const ErrorMotor('familia_no_permitida', detalle: 'lamina')),
      );
    });

    test('clave inexistente', () {
      expect(
        () => medir(_modelo(piezas: [_barras('nada')]), _catalogo()),
        throwsA(const ErrorMotor('articulo_desconocido', detalle: 'nada')),
      );
    });
  });

  group('caminos que los dorados no tocan', () {
    Pieza pieza(String grupo, double largo, int cantidad, {String id = 'p'}) =>
        Pieza(
          id: id,
          grupo: grupo,
          articulo: 'perfil',
          largo: largo,
          cantidad: cantidad,
          corte: TipoCorte.recto,
        );

    test('paneles de la misma lámina se suman en un solo m2', () {
      // 1000·1000/1e6 + 500·1000/1e6 = 1.0 + 0.5 = 1.5 m²
      // hojas = techo(1.5 · 1.1 / 2) = techo(0.825) = 1
      final m = medir(
        _modelo(
          paneles: [
            _panel(1000, 1000, id: 'a'),
            _panel(500, 1000, id: 'b'),
          ],
        ),
        _catalogo(),
      );
      expect(m.porArticulo.keys.toList(), ['lamina']);
      expect(m.porArticulo['lamina']!.m2, cercaDe(1.5));
      expect(m.porArticulo['lamina']!.hojas, 1);
      expect(m.cantidades['m2_lamina'], cercaDe(1.5));
      expect(m.cantidades['paneles'], 2.0);
    });

    test('un perfil en dos grupos: un plan, un por_articulo, dos líneas', () {
      // 2 × 2500 (grupo a) + 1 × 1000 (grupo b): 3 piezas, 6.0 m.
      // Barra 1: 2500 + 3 + 2500 = 5003; el 1000 haría 6006 > 6000: barra 2.
      final m = medir(
        _modelo(piezas: [pieza('a', 2500, 2), pieza('b', 1000, 1)]),
        _catalogo(),
      );
      expect(m.despiece, hasLength(2));
      expect(m.cortes.keys.toList(), ['perfil']);
      expect(m.porArticulo.keys.toList(), ['perfil']);
      expect(m.porArticulo['perfil']!.piezas, 3);
      expect(m.porArticulo['perfil']!.metros, cercaDe(6));
      expect(m.cortes['perfil']!.tramos, 2);
    });

    test('largos que difieren en el 5.º decimal se agrupan', () {
      // redondear(·, 4) deja ambos en 1000.0
      final m = medir(
        _modelo(piezas: [pieza('g', 1000.00001, 1), pieza('g', 1000.00002, 1)]),
        _catalogo(),
      );
      expect(m.despiece, hasLength(1));
      expect(m.despiece.single.cantidad, 2);
    });

    test('largos que difieren en el 3.er decimal no se agrupan', () {
      // 1000.001 y 1000.002 siguen distintos a 4 decimales
      final m = medir(
        _modelo(piezas: [pieza('g', 1000.001, 1), pieza('g', 1000.002, 1)]),
        _catalogo(),
      );
      expect(m.despiece, hasLength(2));
    });

    test('las advertencias del modelo van antes que las de la medición', () {
      final modelo = ModeloPiezas(
        plantilla: 'prueba',
        caja: (ancho: 1000, alto: 2000),
        numHojas: 0,
        paneles: [_panel(1100, 1900)],
        advertencias: [Advertencia(codigo: 'del_modelo')],
      );
      final m = medir(modelo, _catalogo());
      expect(m.advertencias.map((a) => a.codigo), [
        'del_modelo',
        'panel_no_cabe_en_hoja',
      ]);
    });

    test('uniones del modelo se conservan y empalmes va al final', () {
      // 7000 mm en tramo de 6000: segmentos 6000 + 1000, 1 empalme.
      // uniones = 5 + 3 + 1 = 9
      final modelo = ModeloPiezas(
        plantilla: 'prueba',
        caja: (ancho: 1000, alto: 2000),
        numHojas: 0,
        piezas: [pieza('g', 7000, 1)],
        uniones: {'soldadas': 5, 'otras': 3},
      );
      final m = medir(modelo, _catalogo());
      expect(m.uniones.keys.toList(), ['soldadas', 'otras', 'empalmes']);
      expect(m.uniones['empalmes'], 1);
      expect(m.cantidades['uniones'], 9.0);
    });
  });

  group('casos de borde', () {
    test('modelo vacío: todas las cantidades existen y valen 0', () {
      final m = medir(_modelo(), _catalogo());
      expect(m.despiece, isEmpty);
      expect(m.porArticulo, isEmpty);
      expect(m.cantidades.length, 26);
      const caja = {
        'ancho_m': 1.0,
        'alto_m': 2.0,
        'largo_m': 1.0,
        'area_m2': 2.0,
        'perimetro_m': 6.0,
      };
      for (final e in m.cantidades.entries) {
        expect(e.value, caja[e.key] ?? 0.0, reason: e.key);
      }
    });

    test('los extras entran como x_<nombre> al final', () {
      final modelo = ModeloPiezas(
        plantilla: 'prueba',
        caja: (ancho: 1000, alto: 2000),
        numHojas: 2,
        extras: {'anclas': 4},
      );
      final c = medir(modelo, _catalogo()).cantidades;
      expect(c.keys.last, 'x_anclas');
      expect(c['x_anclas'], 4.0);
      expect(c['num_hojas'], 2.0);
    });

    test('piezas iguales se agrupan en el despiece', () {
      final m = medir(_modelo(piezas: [_barras(), _barras()]), _catalogo());
      expect(m.despiece, hasLength(1));
      expect(m.despiece.single.cantidad, 6);
    });

    test('determinismo: dos llamadas dan el mismo JSON', () {
      final esperado =
          cargarDorado('porton_3000x2200')['esperado']! as Map<String, Object?>;
      final modelo = ModeloPiezas.fromJson(
        esperado['modelo']! as Map<String, Object?>,
      );
      final catalogo = Catalogo.fromJson(cargarEntrada('catalogo'));
      expect(
        medir(modelo, catalogo).toJson(),
        equals(medir(modelo, catalogo).toJson()),
      );
    });
  });
}
