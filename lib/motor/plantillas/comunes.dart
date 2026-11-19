/// Funciones compartidas por las plantillas (`docs/MOTOR_MEDICION.md` §4, §7).
library;

import '../numeros.dart';

/// Número de barrotes que caben en [claro] sin que el hueco entre ellos pase
/// de [separacionMax]: `max(0, techo((claro − sep) / (cara + sep)))`.
///
/// Todo en mm: [claro] es el espacio libre, [cara] el ancho de un barrote y
/// [separacionMax] el hueco máximo permitido.
int numeroBarrotes(double claro, double cara, double separacionMax) {
  final n = techo((claro - separacionMax) / (cara + separacionMax));
  return n < 0 ? 0 : n;
}
