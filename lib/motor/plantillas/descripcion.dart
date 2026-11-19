/// Descripción en español de un trabajo (`docs/VISUAL.md` §5): la usan el PDF,
/// la tarjeta de confirmación y la voz.
library;

import '../catalogo/catalogo.dart';
import '../medicion/modelo.dart';
import '../numeros.dart';

/// Frase del trabajo con medidas y materiales.
///
/// [parametros] son los normalizados de la validación (mm). [datosTrabajo]
/// solo se consulta por `con_instalacion`.
String describirTrabajo(
  ModeloPiezas modelo,
  Map<String, Object?> parametros,
  Catalogo catalogo, {
  Map<String, Object?> datosTrabajo = const {},
}) {
  final medidas =
      '${_metros(modelo.caja.ancho)} × ${_metros(modelo.caja.alto)} m';
  String mat(String param) => _material(catalogo, parametros[param]! as String);

  final String base;
  switch (modelo.plantilla) {
    case 'reja_ventana':
      final partes = <String>['marco de ${mat('marco')}'];
      final barrotes = modelo.extras['barrotes'] ?? 0;
      final travesanos = modelo.extras['travesanos'] ?? 0;
      final anclas = modelo.extras['anclas'] ?? 0;
      if (barrotes > 0) {
        partes.add(
          '$barrotes ${_plural(barrotes, 'barrote', 'barrotes')} '
          'de ${mat('barrote')}',
        );
      }
      if (travesanos > 0) {
        partes.add(
          '$travesanos ${_plural(travesanos, 'travesaño', 'travesaños')} '
          'de ${mat('travesano')}',
        );
      }
      if (anclas > 0) {
        partes.add('$anclas ${_plural(anclas, 'ancla', 'anclas')}');
      }
      base = 'Reja de ventana de $medidas: ${_unir(partes)}.';
    case 'porton_abatible':
      final h = modelo.numHojas;
      final partes = <String>['Bastidor de ${mat('bastidor')}'];
      switch (parametros['relleno']) {
        case 'mixto':
          partes
            ..add('zoclo de ${mat('lamina')}')
            ..add('barrotes de ${mat('barrote')}');
        case 'barrotes':
          partes.add('barrotes de ${mat('barrote')}');
        case 'lamina':
          partes.add('tablero de ${mat('lamina')}');
      }
      base =
          'Portón abatible de $h ${_plural(h, 'hoja', 'hojas')}, $medidas. '
          '${_unir(partes)}.';
    case 'libre':
      // Grupos por artículo, en orden de aparición en piezas y luego paneles.
      final grupos = <String, List<String>>{};
      void agrega(String articulo, String grupo) {
        final l = grupos.putIfAbsent(articulo, () => []);
        if (!l.contains(grupo)) l.add(grupo);
      }

      for (final p in modelo.piezas) {
        agrega(p.articulo, p.grupo);
      }
      for (final p in modelo.paneles) {
        agrega(p.articulo, p.grupo);
      }
      final partes = [
        for (final e in grupos.entries)
          '${_unir(e.value)} de ${_material(catalogo, e.key)}',
      ];
      base = 'Trabajo libre de $medidas: ${_unir(partes)}.';
    default:
      base = 'Trabajo de $medidas.';
  }
  return datosTrabajo['con_instalacion'] == true
      ? '$base Incluye instalación.'
      : base;
}

/// Metros con dos decimales fijos a partir de [mm].
String _metros(double mm) => redondear(mm / 1000, 2).toStringAsFixed(2);

/// Nombre del catálogo sin paréntesis final y con minúscula inicial, salvo
/// que la primera palabra sea una sigla (`PTR`).
String _material(Catalogo catalogo, String clave) {
  var n = catalogo.articulo(clave).nombre.trim();
  if (n.endsWith(')')) {
    final i = n.lastIndexOf('(');
    if (i > 0) n = n.substring(0, i).trimRight();
  }
  if (n.isEmpty) return n;
  final primera = n.split(' ').first;
  if (RegExp(r'^[A-Z]{2,}$').hasMatch(primera)) return n;
  return n[0].toLowerCase() + n.substring(1);
}

/// Une con coma y "y"; si algún elemento ya contiene " y ", usa ", y".
String _unir(List<String> items) {
  if (items.length <= 1) return items.join();
  final ultimo = items.last;
  final inicio = items.sublist(0, items.length - 1);
  final conY = items.any((e) => e.contains(' y '));
  return '${inicio.join(', ')}${conY ? ', y ' : ' y '}$ultimo';
}

String _plural(int n, String singular, String plural) =>
    n == 1 ? singular : plural;
