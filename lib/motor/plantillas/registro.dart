/// Registro de las plantillas disponibles.
library;

import '../error_motor.dart';
import 'plantilla.dart';

/// Conjunto de plantillas buscables por `id`.
class RegistroPlantillas {
  /// Lanza [ArgumentError] si dos plantillas comparten `id`.
  RegistroPlantillas(List<Plantilla> plantillas)
    : todas = List.unmodifiable(plantillas),
      _porId = {} {
    for (final p in plantillas) {
      if (_porId.containsKey(p.id)) {
        throw ArgumentError('Plantilla repetida: ${p.id}');
      }
      _porId[p.id] = p;
    }
  }

  /// Plantillas en el orden de entrada (inmodificable).
  final List<Plantilla> todas;
  final Map<String, Plantilla> _porId;

  bool contiene(String id) => _porId.containsKey(id);

  /// Lanza `plantilla_desconocida` si [id] no existe.
  Plantilla porId(String id) =>
      _porId[id] ?? (throw ErrorMotor('plantilla_desconocida', detalle: id));
}
