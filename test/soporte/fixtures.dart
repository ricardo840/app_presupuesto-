/// Cargador de `test/fixtures/`: entradas y dorados.
library;

import 'dart:convert';
import 'dart:io';

const String _raiz = 'test/fixtures';

/// Lee un JSON de `test/fixtures/`, por ejemplo `entradas/catalogo.json`.
Map<String, Object?> cargarFixture(String rutaRelativa) {
  final archivo = File('$_raiz/$rutaRelativa');
  if (!archivo.existsSync()) {
    throw StateError('No existe ${archivo.path}');
  }
  final dato = jsonDecode(archivo.readAsStringSync());
  if (dato is! Map<String, Object?>) {
    throw StateError('${archivo.path} no es un objeto JSON');
  }
  return dato;
}

/// Lee `test/fixtures/entradas/<nombre>.json`.
Map<String, Object?> cargarEntrada(String nombre) =>
    cargarFixture('entradas/$nombre.json');

/// Lee `test/fixtures/dorados/<nombre>.json`.
Map<String, Object?> cargarDorado(String nombre) =>
    cargarFixture('dorados/$nombre.json');

/// Nombres (sin `.json`) de todos los dorados, en orden alfabético.
List<String> nombresDorados() {
  final nombres =
      Directory('$_raiz/dorados')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.json'))
          .map((n) => n.substring(0, n.length - '.json'.length))
          .toList()
        ..sort();
  return nombres;
}

/// Los dorados de trabajos completos (traen `entrada` y `esperado`).
List<String> nombresTrabajosDorados() => [
  for (final n in nombresDorados())
    if (cargarDorado(n).containsKey('esperado')) n,
];

/// Convierte un número de JSON, entero o decimal, a `double`.
double comoDouble(Object? valor) => (valor! as num).toDouble();
