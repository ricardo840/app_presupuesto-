/// Problemas que el motor devuelve en lugar de lanzar (`docs/ARQUITECTURA.md` §3).
library;

/// Un error impide calcular; una advertencia solo avisa.
enum Gravedad { error, advertencia }

/// Error o advertencia con un código estable de la especificación.
///
/// No lleva texto para el usuario: la interfaz traduce [codigo].
class Problema {
  const Problema(
    this.codigo, {
    this.gravedad = Gravedad.error,
    this.parametro,
    this.detalle,
  });

  /// Código estable, por ejemplo `fuera_de_rango`.
  final String codigo;
  final Gravedad gravedad;

  /// Parámetro al que se refiere; en listas, con índice: `piezas[2].largo`.
  final String? parametro;

  /// Dato técnico que ayuda a ubicarlo (una clave, un valor); no es para el usuario.
  final String? detalle;

  bool get esError => gravedad == Gravedad.error;

  Map<String, Object?> toJson() => {
    'codigo': codigo,
    'gravedad': gravedad.name,
    if (parametro != null) 'parametro': parametro,
    if (detalle != null) 'detalle': detalle,
  };

  @override
  bool operator ==(Object other) =>
      other is Problema &&
      codigo == other.codigo &&
      gravedad == other.gravedad &&
      parametro == other.parametro &&
      detalle == other.detalle;

  @override
  int get hashCode => Object.hash(codigo, gravedad, parametro, detalle);

  @override
  String toString() =>
      'Problema($codigo, ${gravedad.name}'
      '${parametro != null ? ', $parametro' : ''}'
      '${detalle != null ? ', $detalle' : ''})';
}
