/// Optimizador de cortes: primer ajuste decreciente con kerf
/// (MOTOR_MEDICION §5).
library;

import 'package:collection/collection.dart';

import '../numeros.dart';

/// Resultado de cortar un perfil: barras a comprar y qué va en cada una.
class PlanCortes {
  /// Copia las listas y las vuelve inmodificables.
  PlanCortes({
    required this.tramos,
    required List<List<double>> barras,
    required List<double> sobrantesMm,
    required this.segmentos,
    required this.cortes,
    required this.empalmes,
  }) : barras = List.unmodifiable([
         for (final b in barras) List<double>.unmodifiable(b),
       ]),
       sobrantesMm = List.unmodifiable(sobrantesMm);

  /// Barras a comprar.
  final int tramos;

  /// Largos de cada barra, en orden de colocación (mm).
  final List<List<double>> barras;

  /// Sobrante de cada barra (mm).
  final List<double> sobrantesMm;

  /// Segmentos en que quedaron las piezas tras partir las más largas que el tramo.
  final int segmentos;

  /// Segmentos que requieren corte (un tramo completo no se corta).
  final int cortes;

  /// Uniones necesarias por piezas más largas que el tramo.
  final int empalmes;

  static const _igualdad = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is PlanCortes &&
      tramos == other.tramos &&
      segmentos == other.segmentos &&
      cortes == other.cortes &&
      empalmes == other.empalmes &&
      _igualdad.equals(barras, other.barras) &&
      _igualdad.equals(sobrantesMm, other.sobrantesMm);

  @override
  int get hashCode => Object.hash(
    tramos,
    segmentos,
    cortes,
    empalmes,
    _igualdad.hash(barras),
    _igualdad.hash(sobrantesMm),
  );

  /// Mismas claves y orden que el dorado.
  Map<String, Object?> toJson() => {
    'tramos': tramos,
    'barras': [for (final b in barras) List<double>.of(b)],
    'sobrantes_mm': List<double>.of(sobrantesMm),
    'segmentos': segmentos,
    'cortes': cortes,
    'empalmes': empalmes,
  };
}

List<double> _partirEnSegmentos(double largo, double tramo) {
  if (cabe(largo, tramo)) return [largo];
  final completos = piso(largo / tramo);
  final resto = largo - completos * tramo;
  return [...List<double>.filled(completos, tramo), if (resto > eps) resto];
}

/// Decide cuántos tramos de [tramo] comprar y cómo cortar [largos].
///
/// Todo en mm. Precondición: [tramo] > 0, [kerf] >= 0 y cada largo > 0; si
/// no, lanza [ArgumentError] (las plantillas ya validaron).
PlanCortes optimizarCortes(List<double> largos, double tramo, double kerf) {
  if (!(tramo > 0)) throw ArgumentError.value(tramo, 'tramo', 'debe ser > 0');
  if (!(kerf >= 0)) throw ArgumentError.value(kerf, 'kerf', 'debe ser >= 0');
  for (final l in largos) {
    if (!(l > 0)) {
      throw ArgumentError.value(l, 'largos', 'cada largo debe ser > 0');
    }
  }

  final segmentos = <double>[];
  var empalmes = 0;
  for (final largo in largos) {
    final partes = _partirEnSegmentos(largo, tramo);
    empalmes += partes.length - 1;
    segmentos.addAll(partes);
  }

  // Mayor primero; el empate conserva el orden de aparición.
  final orden = List<int>.generate(segmentos.length, (i) => i)
    ..sort((a, b) {
      final c = segmentos[b].compareTo(segmentos[a]);
      return c != 0 ? c : a.compareTo(b);
    });

  final barras = <List<double>>[];
  final sumas = <double>[];
  for (final i in orden) {
    final largo = segmentos[i];
    var colocado = false;
    for (var j = 0; j < barras.length; j++) {
      // Entre cada par de piezas se pierde un kerf.
      if (sumas[j] + kerf * barras[j].length + largo <= tramo + eps) {
        barras[j].add(largo);
        sumas[j] += largo;
        colocado = true;
        break;
      }
    }
    if (!colocado) {
      barras.add([largo]);
      sumas.add(largo);
    }
  }

  final sobrantes = [
    for (var j = 0; j < barras.length; j++)
      (tramo - sumas[j] - kerf * barras[j].length).clamp(0.0, double.infinity),
  ];
  final cortes = segmentos.where((s) => s < tramo - eps).length;

  return PlanCortes(
    tramos: barras.length,
    barras: barras,
    sobrantesMm: sobrantes,
    segmentos: segmentos.length,
    cortes: cortes,
    empalmes: empalmes,
  );
}
