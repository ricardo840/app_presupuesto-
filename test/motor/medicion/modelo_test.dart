import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/medicion/modelo.dart';

import '../../soporte/comparadores.dart';
import '../../soporte/fixtures.dart';

Map<String, Object?> _modelo(String dorado) =>
    (cargarDorado(dorado)['esperado']! as Map<String, Object?>)['modelo']!
        as Map<String, Object?>;

void main() {
  group('modelo de piezas contra los dorados', () {
    for (final nombre in nombresTrabajosDorados()) {
      test('$nombre: ida y vuelta, JSON igual y orden de claves', () {
        final json = _modelo(nombre);
        final x = ModeloPiezas.fromJson(json);

        expect(ModeloPiezas.fromJson(x.toJson()), x);
        expect(x.toJson(), coincideJson(json));

        expect(x.toJson().keys.toList(), [
          'plantilla',
          'caja',
          'num_hojas',
          'piezas',
          'paneles',
          'herrajes',
          'uniones',
          'extras',
          'detalle',
          'advertencias',
        ]);
        if (x.piezas.isNotEmpty) {
          expect(x.piezas.first.toJson().keys.toList(), [
            'id',
            'grupo',
            'articulo',
            'largo',
            'cantidad',
            'corte',
            'p0',
            'p1',
            'hoja',
          ]);
        }
        if (x.paneles.isNotEmpty) {
          expect(x.paneles.first.toJson().keys.toList(), [
            'id',
            'grupo',
            'articulo',
            'ancho',
            'alto',
            'cantidad',
            'origen',
            'hoja',
          ]);
        }
      });
    }
  });

  group('comportamiento del modelo', () {
    test('totalUniones del portón 3000x2200 es la suma de sus uniones', () {
      final json = _modelo('porton_3000x2200');
      final m = ModeloPiezas.fromJson(json);
      final suma = (json['uniones']! as Map<String, Object?>).values.fold<int>(
        0,
        (a, b) => a + (b! as num).toInt(),
      );
      expect(m.totalUniones, suma);
      expect(m.totalUniones, greaterThan(0));
    });

    test('dos modelos que difieren en una coordenada no son iguales', () {
      final json = _modelo('reja_1200x1000');
      final a = ModeloPiezas.fromJson(json);
      final p = a.piezas.first;
      final b = ModeloPiezas(
        plantilla: a.plantilla,
        caja: a.caja,
        numHojas: a.numHojas,
        piezas: [
          Pieza(
            id: p.id,
            grupo: p.grupo,
            articulo: p.articulo,
            largo: p.largo,
            cantidad: p.cantidad,
            corte: p.corte,
            p0: (x: p.p0!.x + 1, y: p.p0!.y, z: p.p0!.z),
            p1: p.p1,
            hoja: p.hoja,
          ),
          ...a.piezas.skip(1),
        ],
        paneles: a.paneles,
        herrajes: a.herrajes,
        uniones: a.uniones,
        extras: a.extras,
        detalle: a.detalle,
        advertencias: a.advertencias,
      );
      expect(a, isNot(b));
      expect(a, ModeloPiezas.fromJson(json));
      expect(a.hashCode, ModeloPiezas.fromJson(json).hashCode);
    });

    test('las listas y mapas expuestos son inmodificables', () {
      final m = ModeloPiezas.fromJson(_modelo('porton_3000x2200'));
      expect(() => m.piezas.clear(), throwsUnsupportedError);
      expect(() => m.paneles.clear(), throwsUnsupportedError);
      expect(() => m.herrajes.clear(), throwsUnsupportedError);
      expect(() => m.advertencias.clear(), throwsUnsupportedError);
      expect(() => m.uniones['x'] = 1, throwsUnsupportedError);
      expect(() => m.extras['x'] = 1, throwsUnsupportedError);
      expect(() => m.detalle['x'] = 1, throwsUnsupportedError);
    });

    test('una advertencia se escribe plana y vuelve igual', () {
      final a = Advertencia(codigo: 'x', datos: {'articulo': 'a', 'panel': 2});
      expect(a.toJson(), {'codigo': 'x', 'articulo': 'a', 'panel': 2});
      expect(a.toJson().keys.toList(), ['codigo', 'articulo', 'panel']);
      expect(Advertencia.fromJson(a.toJson()), a);
    });
  });
}
