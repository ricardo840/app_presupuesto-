/// Error esperado del motor, con un código estable de la especificación.
class ErrorMotor implements Exception {
  const ErrorMotor(this.codigo, {this.detalle, this.posicion});

  /// Código estable (p. ej. `sintaxis`, `articulo_desconocido`).
  final String codigo;

  /// Dato técnico (nombre, clave); nunca texto para el usuario.
  final String? detalle;

  /// Posición en la fórmula, cuando aplica.
  final int? posicion;

  @override
  bool operator ==(Object other) =>
      other is ErrorMotor &&
      other.codigo == codigo &&
      other.detalle == detalle &&
      other.posicion == posicion;

  @override
  int get hashCode => Object.hash(codigo, detalle, posicion);

  @override
  String toString() =>
      'ErrorMotor($codigo${detalle != null ? ', detalle: $detalle' : ''}'
      '${posicion != null ? ', posicion: $posicion' : ''})';
}
