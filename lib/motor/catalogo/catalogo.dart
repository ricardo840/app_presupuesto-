import '../error_motor.dart';
import 'articulo.dart';
import 'derivados.dart';

/// Constantes del motor, editables en Ajustes.
class Constantes {
  const Constantes({
    this.densidadKgM3 = 7850,
    this.kerfMm = 3,
    this.desperdicioLamina = 0.10,
  });

  factory Constantes.fromJson(Map<String, Object?> json) {
    const base = Constantes();
    double leer(String k, double def) {
      final v = json[k];
      return v == null ? def : (v as num).toDouble();
    }

    return Constantes(
      densidadKgM3: leer('densidad_kg_m3', base.densidadKgM3),
      kerfMm: leer('kerf_mm', base.kerfMm),
      desperdicioLamina: leer('desperdicio_lamina', base.desperdicioLamina),
    );
  }

  /// Densidad del acero en kg/m³.
  final double densidadKgM3;

  /// Material que se pierde en cada corte, en mm.
  final double kerfMm;

  /// Holgura (fracción) al estimar hojas de lámina.
  final double desperdicioLamina;

  Map<String, Object?> toJson() => {
    'densidad_kg_m3': densidadKgM3,
    'kerf_mm': kerfMm,
    'desperdicio_lamina': desperdicioLamina,
  };

  @override
  bool operator ==(Object other) =>
      other is Constantes &&
      other.densidadKgM3 == densidadKgM3 &&
      other.kerfMm == kerfMm &&
      other.desperdicioLamina == desperdicioLamina;

  @override
  int get hashCode => Object.hash(densidadKgM3, kerfMm, desperdicioLamina);
}

/// Conjunto de artículos con sus derivados precalculados.
class Catalogo {
  Catalogo(List<Articulo> articulos, {this.constantes = const Constantes()})
    : articulos = List.unmodifiable(articulos),
      _porClave = {},
      _derivados = {} {
    for (final a in articulos) {
      if (_porClave.containsKey(a.clave)) {
        throw ErrorMotor(
          'articulo_invalido',
          detalle: '${a.clave}: clave repetida',
        );
      }
      _porClave[a.clave] = a;
      _derivados[a.clave] = calcularDerivados(a, constantes.densidadKgM3);
    }
  }

  factory Catalogo.fromJson(Map<String, Object?> json) {
    final c = json['constantes'];
    final lista = json['articulos'];
    return Catalogo(
      [
        for (final a in (lista as List? ?? const []))
          Articulo.fromJson((a as Map).cast<String, Object?>()),
      ],
      constantes: c == null
          ? const Constantes()
          : Constantes.fromJson((c as Map).cast<String, Object?>()),
    );
  }

  final Constantes constantes;

  /// Artículos en el orden de entrada (inmodificable).
  final List<Articulo> articulos;
  final Map<String, Articulo> _porClave;
  final Map<String, Derivados> _derivados;

  bool contiene(String clave) => _porClave.containsKey(clave);

  Articulo articulo(String clave) =>
      _porClave[clave] ??
      (throw ErrorMotor('articulo_desconocido', detalle: clave));

  Derivados derivados(String clave) =>
      _derivados[clave] ??
      (throw ErrorMotor('articulo_desconocido', detalle: clave));

  Map<String, Object?> toJson() => {
    'constantes': constantes.toJson(),
    'articulos': [for (final a in articulos) a.toJson()],
  };

  @override
  bool operator ==(Object other) {
    if (other is! Catalogo ||
        other.constantes != constantes ||
        other.articulos.length != articulos.length) {
      return false;
    }
    for (var i = 0; i < articulos.length; i++) {
      if (other.articulos[i] != articulos[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(constantes, Object.hashAll(articulos));
}
