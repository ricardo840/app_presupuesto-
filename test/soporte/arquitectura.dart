/// Verificador de las reglas de capas de `docs/ARQUITECTURA.md` §2.
///
/// Es una función pura sobre (ruta → contenido) para poder probarla con
/// archivos inventados, además de correrla sobre `lib/`.
library;

/// Qué capas puede importar cada capa. `main.dart` y `app/` no aparecen:
/// arman la app completa (rutas, proveedores) y pueden importar cualquiera.
const Map<String, Set<String>> capasPermitidas = {
  'ui': {'app', 'visual', 'voz', 'ia', 'datos', 'motor'},
  'visual': {'motor'},
  'ia': {'motor'},
  'voz': {'motor'},
  'datos': {'motor'},
  'motor': {},
};

/// Paquetes externos que puede usar el motor, además de sí mismo.
const Set<String> paquetesDelMotor = {'collection', 'meta'};

/// Bibliotecas de Dart prohibidas en el motor: disco, red, pantalla, hilos.
const Set<String> bibliotecasDartProhibidasEnMotor = {
  'dart:io',
  'dart:ui',
  'dart:isolate',
  'dart:ffi',
  'dart:html',
  'dart:js_interop',
  'dart:mirrors',
};

/// Usos de reloj y azar prohibidos en el motor (misma entrada, misma salida).
final List<RegExp> _relojYAzar = [
  RegExp(r'DateTime\s*\.\s*now\b'),
  RegExp(r'\bStopwatch\b'),
  RegExp(r'\bRandom\b'),
];

final RegExp _directiva = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

const String _paquete = 'linforge';

/// Devuelve una línea por cada regla rota. Lista vacía: todo en orden.
///
/// [archivos] usa rutas relativas a la raíz con `/`, como `lib/motor/a.dart`.
List<String> violacionesDeArquitectura(Map<String, String> archivos) {
  final violaciones = <String>[];
  final rutas = archivos.keys.toList()..sort();
  for (final ruta in rutas) {
    final origen = capaDe(ruta);
    if (origen == null) continue;
    final contenido = archivos[ruta]!;

    for (final m in _directiva.allMatches(contenido)) {
      final destino = m.group(1)!;
      final problema = _revisarDirectiva(ruta, origen, destino);
      if (problema != null) violaciones.add('$ruta: $problema');
    }

    if (origen == 'motor') {
      for (final patron in _relojYAzar) {
        if (patron.hasMatch(_sinComentarios(contenido))) {
          violaciones.add('$ruta: el motor no usa reloj ni azar ($patron)');
        }
      }
    }
  }
  return violaciones;
}

/// Capas que arman la app completa y pueden importar cualquier otra.
const Set<String> _capasLibres = {'raiz', 'app'};

/// Capa de un archivo de `lib/`: la primera carpeta, o `raiz` para los
/// archivos sueltos como `main.dart`. `null` si no está en `lib/`.
String? capaDe(String ruta) {
  if (!ruta.startsWith('lib/')) return null;
  final partes = ruta.substring(4).split('/');
  return partes.length == 1 ? 'raiz' : partes.first;
}

String? _revisarDirectiva(String ruta, String origen, String destino) {
  if (destino.startsWith('dart:')) {
    if (origen == 'motor' &&
        bibliotecasDartProhibidasEnMotor.contains(destino)) {
      return 'el motor no puede importar $destino';
    }
    return null;
  }

  String? rutaDestino;
  if (destino.startsWith('package:')) {
    final sinEsquema = destino.substring('package:'.length);
    final paquete = sinEsquema.split('/').first;
    if (paquete != _paquete) {
      if (origen == 'motor' && !paquetesDelMotor.contains(paquete)) {
        return 'el motor no puede importar $destino';
      }
      return null;
    }
    rutaDestino = 'lib/${sinEsquema.substring(paquete.length + 1)}';
  } else {
    // Importación relativa: se resuelve contra la ruta del archivo.
    rutaDestino = Uri.parse(ruta).resolve(destino).path;
  }

  final capaDestino = capaDe(rutaDestino);
  if (capaDestino == null) {
    return 'importa $destino, que está fuera de lib/';
  }
  if (capaDestino == origen || _capasLibres.contains(origen)) return null;
  final permitidas = capasPermitidas[origen];
  if (permitidas == null) {
    return 'la carpeta lib/$origen/ no está en docs/ARQUITECTURA.md §2';
  }
  if (!permitidas.contains(capaDestino)) {
    return '$origen no puede importar $capaDestino ($destino)';
  }
  return null;
}

/// Quita comentarios de línea para que un `// Random` explicativo no cuente.
String _sinComentarios(String codigo) =>
    codigo.replaceAll(RegExp(r'//[^\n]*'), '');
