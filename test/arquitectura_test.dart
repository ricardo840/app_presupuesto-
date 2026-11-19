import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'soporte/arquitectura.dart';

/// Lee todos los `.dart` de `lib/` con rutas relativas y separador `/`.
Map<String, String> _archivosDeLib() => {
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.dart'))
      f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
};

void main() {
  test('lib/ respeta las capas de docs/ARQUITECTURA.md §2', () {
    final archivos = _archivosDeLib();
    expect(archivos, contains('lib/main.dart'));
    expect(violacionesDeArquitectura(archivos), isEmpty);
  });

  group('el verificador', () {
    test('rechaza que el motor importe datos', () {
      final v = violacionesDeArquitectura({
        'lib/motor/a.dart': "import 'package:linforge/datos/b.dart';",
      });
      expect(v, hasLength(1));
      expect(v.single, contains('motor no puede importar datos'));
    });

    test('rechaza una importación relativa que cruza capas', () {
      final v = violacionesDeArquitectura({
        'lib/visual/plano.dart': "import '../datos/tablas.dart';",
      });
      expect(v.single, contains('visual no puede importar datos'));
    });

    test('rechaza Flutter, dart:io y dart:ui en el motor', () {
      final v = violacionesDeArquitectura({
        'lib/motor/a.dart': '''
import 'package:flutter/widgets.dart';
import 'dart:io';
import "dart:ui";
''',
      });
      expect(v, hasLength(3));
    });

    test('rechaza reloj y azar en el motor', () {
      final v = violacionesDeArquitectura({
        'lib/motor/a.dart': '''
final hoy = DateTime.now();
final r = Random(3);
''',
      });
      expect(v, hasLength(2));
    });

    test('rechaza que ia importe voz y que motor importe ui', () {
      final v = violacionesDeArquitectura({
        'lib/ia/a.dart': "import 'package:linforge/voz/b.dart';",
        'lib/motor/c.dart': "export '../ui/d.dart';",
      });
      expect(v, hasLength(2));
    });

    test('rechaza una carpeta de lib/ que no está en la arquitectura', () {
      final v = violacionesDeArquitectura({
        'lib/otra/a.dart': "import 'package:linforge/motor/b.dart';",
      });
      expect(v.single, contains('lib/otra/'));
    });

    test('acepta las dependencias permitidas', () {
      final v = violacionesDeArquitectura({
        'lib/main.dart': "import 'package:linforge/ui/x.dart';",
        'lib/app/rutas.dart': "import 'package:linforge/datos/x.dart';",
        'lib/ui/a.dart': '''
import 'package:linforge/app/tema.dart';
import 'package:linforge/motor/presupuesto.dart';
import '../visual/plano.dart';
''',
        'lib/datos/a.dart': '''
import 'package:drift/drift.dart';
import 'package:linforge/motor/numeros.dart';
''',
        'lib/motor/a.dart': '''
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'numeros.dart';
// Sin Random ni DateTime.now: comentario que no cuenta.
''',
      });
      expect(v, isEmpty);
    });
  });
}
