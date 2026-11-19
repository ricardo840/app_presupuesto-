/// Comparadores con las tolerancias de `.claude/rules/pruebas.md`:
/// conteos y centavos exactos; longitudes, pesos y áreas con 1e-5.
library;

import 'package:flutter_test/flutter_test.dart';

/// Tolerancia para longitudes, pesos y áreas.
const double toleranciaMedida = 1e-5;

/// Número cercano a [esperado] con diferencia absoluta menor que [tolerancia].
Matcher cercaDe(num esperado, {double tolerancia = toleranciaMedida}) =>
    _CercaDe(esperado.toDouble(), tolerancia);

/// Compara dos valores de JSON en profundidad.
///
/// Dos enteros se comparan exactos (conteos, centavos). Si alguno es decimal,
/// se acepta una diferencia menor que [tolerancia]. Al fallar dice la ruta
/// de la primera diferencia, por ejemplo `despiece[3].largo_mm`.
Matcher coincideJson(
  Object? esperado, {
  double tolerancia = toleranciaMedida,
}) => _CoincideJson(esperado, tolerancia);

/// Primera diferencia entre dos valores de JSON, o `null` si coinciden.
String? diferenciaJson(
  Object? esperado,
  Object? real, {
  double tolerancia = toleranciaMedida,
  String ruta = r'$',
}) {
  if (esperado is int && real is int) {
    return esperado == real
        ? null
        : '$ruta: se esperaba $esperado, llegó $real';
  }
  if (esperado is num && real is num) {
    final dif = (esperado - real).abs();
    return dif < tolerancia
        ? null
        : '$ruta: se esperaba $esperado, llegó $real (diferencia $dif)';
  }
  if (esperado is Map && real is Map) {
    final faltan = esperado.keys.where((k) => !real.containsKey(k)).toList();
    if (faltan.isNotEmpty) return '$ruta: faltan las claves $faltan';
    final sobran = real.keys.where((k) => !esperado.containsKey(k)).toList();
    if (sobran.isNotEmpty) return '$ruta: sobran las claves $sobran';
    for (final clave in esperado.keys) {
      final d = diferenciaJson(
        esperado[clave],
        real[clave],
        tolerancia: tolerancia,
        ruta: '$ruta.$clave',
      );
      if (d != null) return d;
    }
    return null;
  }
  if (esperado is List && real is List) {
    if (esperado.length != real.length) {
      return '$ruta: se esperaban ${esperado.length} elementos, '
          'llegaron ${real.length}';
    }
    for (var i = 0; i < esperado.length; i++) {
      final d = diferenciaJson(
        esperado[i],
        real[i],
        tolerancia: tolerancia,
        ruta: '$ruta[$i]',
      );
      if (d != null) return d;
    }
    return null;
  }
  return esperado == real ? null : '$ruta: se esperaba $esperado, llegó $real';
}

class _CercaDe extends Matcher {
  const _CercaDe(this.esperado, this.tolerancia);

  final double esperado;
  final double tolerancia;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) =>
      item is num && (item - esperado).abs() < tolerancia;

  @override
  Description describe(Description description) =>
      description.add('$esperado ± $tolerancia');
}

class _CoincideJson extends Matcher {
  const _CoincideJson(this.esperado, this.tolerancia);

  final Object? esperado;
  final double tolerancia;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    final d = diferenciaJson(esperado, item, tolerancia: tolerancia);
    if (d != null) matchState['diferencia'] = d;
    return d == null;
  }

  @override
  Description describe(Description description) =>
      description.add('JSON igual al esperado (tolerancia $tolerancia)');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) => mismatchDescription.add(matchState['diferencia'].toString());
}
