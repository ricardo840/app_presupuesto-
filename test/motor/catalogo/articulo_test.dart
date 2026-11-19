import 'package:linforge/motor/catalogo/articulo.dart';
import 'package:linforge/motor/error_motor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../soporte/fixtures.dart';

Map<String, Object?> _perfil() => {
  'clave': 'p1',
  'nombre': 'Perfil',
  'tipo': 'perfil',
  'familia': 'solera',
  'geometria': {'a': 25.4, 'e': 3.175},
  'unidad_compra': 'tramo',
  'precio': 100,
};

Map<String, Object?> _lamina() => {
  'clave': 'l1',
  'nombre': 'Lámina',
  'tipo': 'lamina',
  'familia': 'lamina',
  'geometria': {'e': 1.2},
  'unidad_compra': 'hoja',
  'hoja_mm': [1219, 3048],
  'precio': 1000,
};

void main() {
  group('Articulo.fromJson', () {
    test('largo_tramo_mm por defecto es 6000', () {
      expect(Articulo.fromJson(_perfil()).largoTramoMm, 6000);
    });

    test('respeta un largo de tramo explícito', () {
      final j = _perfil()..['largo_tramo_mm'] = 6100;
      expect(Articulo.fromJson(j).largoTramoMm, 6100);
    });

    test('lee la hoja de lámina como ancho y largo', () {
      final a = Articulo.fromJson(_lamina());
      expect(a.hojaMm, (ancho: 1219.0, largo: 3048.0));
    });

    test('el detalle del error lleva la clave y el motivo', () {
      final j = _perfil()..remove('familia');
      expect(
        () => Articulo.fromJson(j),
        throwsA(
          isA<ErrorMotor>().having(
            (e) => e.detalle,
            'detalle',
            startsWith('p1: '),
          ),
        ),
      );
    });

    final casos = <String, Map<String, Object?> Function()>{
      'falta clave': () => _perfil()..remove('clave'),
      'falta nombre': () => _perfil()..remove('nombre'),
      'falta tipo': () => _perfil()..remove('tipo'),
      'falta unidad_compra': () => _perfil()..remove('unidad_compra'),
      'falta precio': () => _perfil()..remove('precio'),
      'tipo desconocido': () => _perfil()..['tipo'] = 'mueble',
      'familia desconocida': () => _perfil()..['familia'] = 'hexagono',
      'unidad desconocida': () => _perfil()..['unidad_compra'] = 'caja',
      'unidad no válida para perfil': () =>
          _perfil()..['unidad_compra'] = 'hoja',
      'unidad no válida para lámina': () =>
          _lamina()..['unidad_compra'] = 'tramo',
      'unidad no válida para herraje': () => {
        'clave': 'h',
        'nombre': 'H',
        'tipo': 'herraje',
        'unidad_compra': 'kg',
        'precio': 1,
      },
      'unidad no válida para consumible': () => {
        'clave': 'c',
        'nombre': 'C',
        'tipo': 'consumible',
        'unidad_compra': 'm',
        'precio': 1,
      },
      'perfil sin familia': () => _perfil()..remove('familia'),
      'perfil con familia lamina': () => _perfil()..['familia'] = 'lamina',
      'lámina sin familia': () => _lamina()..remove('familia'),
      'lámina con familia de perfil': () => _lamina()..['familia'] = 'solera',
      'falta medida de solera': () => _perfil()..['geometria'] = {'a': 25.4},
      'falta medida de cuadrado': () => _perfil()
        ..['familia'] = 'cuadrado'
        ..['geometria'] = <String, Object?>{},
      'falta medida de redondo': () => _perfil()
        ..['familia'] = 'redondo'
        ..['geometria'] = {'e': 1},
      'falta medida de angulo': () => _perfil()
        ..['familia'] = 'angulo'
        ..['geometria'] = {'a': 25},
      'falta medida de tubular': () => _perfil()
        ..['familia'] = 'tubular'
        ..['geometria'] = {'a': 25, 'b': 25},
      'falta medida de tubo': () => _perfil()
        ..['familia'] = 'tubo'
        ..['geometria'] = {'d': 25},
      'falta medida de otro': () => _perfil()
        ..['familia'] = 'otro'
        ..['peso_kg_m_manual'] = 2
        ..['geometria'] = {'cara': 30},
      'falta espesor de lámina': () => _lamina()..['geometria'] = {},
      'lámina sin hoja_mm': () => _lamina()..remove('hoja_mm'),
      'lámina con hoja_mm de un número': () => _lamina()..['hoja_mm'] = [1219],
      'familia otro sin peso manual': () => _perfil()
        ..['familia'] = 'otro'
        ..['geometria'] = {'cara': 30, 'fondo': 20},
      'herraje con familia': () => {
        'clave': 'h',
        'nombre': 'H',
        'tipo': 'herraje',
        'familia': 'cuadrado',
        'unidad_compra': 'pieza',
        'precio': 1,
      },
      'consumible con familia': () => {
        'clave': 'h',
        'nombre': 'H',
        'tipo': 'consumible',
        'familia': 'solera',
        'unidad_compra': 'pieza',
        'precio': 1,
      },
      'geometria con valor no numérico': () =>
          _perfil()..['geometria'] = {'a': 'x', 'e': 3.0},
      'geometria con valor cero': () =>
          _perfil()..['geometria'] = {'a': 0, 'e': 3.0},
      'geometria con valor negativo': () =>
          _perfil()..['geometria'] = {'a': 25.4, 'e': -1},
      'precio en texto': () => _perfil()..['precio'] = '100',
      'precio negativo': () => _perfil()..['precio'] = -1,
      'peso manual en texto': () => _perfil()..['peso_kg_m_manual'] = '2',
      'peso manual cero': () => _perfil()..['peso_kg_m_manual'] = 0,
      'peso manual negativo': () => _perfil()..['peso_kg_m_manual'] = -2,
      'largo de tramo cero': () => _perfil()..['largo_tramo_mm'] = 0,
      'largo de tramo negativo': () => _perfil()..['largo_tramo_mm'] = -6000,
      'hoja con ancho cero': () => _lamina()..['hoja_mm'] = [0, 3048],
      'hoja con largo negativo': () => _lamina()..['hoja_mm'] = [1219, -1],
    };
    // Palabra que debe aparecer en el motivo, para que un motivo equivocado
    // no pase por casualidad.
    const palabras = <String, String>{
      'falta clave': 'clave',
      'falta nombre': 'nombre',
      'falta tipo': 'tipo',
      'falta unidad_compra': 'unidad_compra',
      'falta precio': 'precio',
      'tipo desconocido': 'tipo',
      'familia desconocida': 'familia',
      'unidad desconocida': 'unidad',
      'unidad no válida para perfil': 'unidad',
      'unidad no válida para lámina': 'unidad',
      'unidad no válida para herraje': 'unidad',
      'unidad no válida para consumible': 'unidad',
      'perfil sin familia': 'familia',
      'perfil con familia lamina': 'familia',
      'lámina sin familia': 'familia',
      'lámina con familia de perfil': 'familia',
      'falta medida de solera': 'medida',
      'falta medida de cuadrado': 'medida',
      'falta medida de redondo': 'medida',
      'falta medida de angulo': 'medida',
      'falta medida de tubular': 'medida',
      'falta medida de tubo': 'medida',
      'falta medida de otro': 'medida',
      'falta espesor de lámina': 'medida',
      'lámina sin hoja_mm': 'hoja_mm',
      'lámina con hoja_mm de un número': 'hoja_mm',
      'familia otro sin peso manual': 'peso_kg_m_manual',
      'herraje con familia': 'familia',
      'consumible con familia': 'familia',
      'geometria con valor no numérico': 'geometria',
      'geometria con valor cero': 'geometria',
      'geometria con valor negativo': 'geometria',
      'precio en texto': 'precio',
      'precio negativo': 'precio',
      'peso manual en texto': 'peso_kg_m_manual',
      'peso manual cero': 'peso_kg_m_manual',
      'peso manual negativo': 'peso_kg_m_manual',
      'largo de tramo cero': 'largo_tramo_mm',
      'largo de tramo negativo': 'largo_tramo_mm',
      'hoja con ancho cero': 'hoja_mm',
      'hoja con largo negativo': 'hoja_mm',
    };
    for (final e in casos.entries) {
      test('${e.key} da articulo_invalido', () {
        final json = e.value();
        final clave = json['clave'] is String ? json['clave'] : '?';
        expect(
          () => Articulo.fromJson(json),
          throwsA(
            isA<ErrorMotor>()
                .having((x) => x.codigo, 'codigo', 'articulo_invalido')
                .having((x) => x.detalle, 'detalle', startsWith('$clave: '))
                .having(
                  (x) => x.detalle,
                  'detalle',
                  contains(palabras[e.key]!),
                ),
          ),
        );
      });
    }

    test('un precio de cero es válido', () {
      expect(Articulo.fromJson(_perfil()..['precio'] = 0).precio, 0);
    });
  });

  group('Articulo ida y vuelta', () {
    test(
      'fromJson(toJson(x)) == x para cada artículo del catálogo de prueba',
      () {
        final lista = cargarEntrada('catalogo')['articulos']! as List;
        expect(lista, isNotEmpty);
        for (final j in lista) {
          final a = Articulo.fromJson((j as Map).cast<String, Object?>());
          expect(Articulo.fromJson(a.toJson()), a);
          expect(Articulo.fromJson(a.toJson()).hashCode, a.hashCode);
        }
      },
    );

    test('toJson omite los campos nulos', () {
      final j = Articulo.fromJson({
        'clave': 'h',
        'nombre': 'H',
        'tipo': 'herraje',
        'unidad_compra': 'pieza',
        'precio': 5,
      }).toJson();
      expect(j.keys, ['clave', 'nombre', 'tipo', 'unidad_compra', 'precio']);
    });

    test('dos artículos con distinta geometría no son iguales', () {
      final a = Articulo.fromJson(_perfil());
      final b = Articulo.fromJson(
        _perfil()..['geometria'] = {'a': 30.0, 'e': 3.175},
      );
      expect(a == b, isFalse);
    });
  });
}
