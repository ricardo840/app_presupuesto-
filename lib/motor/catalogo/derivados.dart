import 'dart:math' as math;

import 'articulo.dart';

/// Valores calculados de un artículo a partir de su geometría.
sealed class Derivados {
  const Derivados();

  Map<String, Object?> toJson();
}

/// Derivados de un perfil.
final class DerivadosPerfil extends Derivados {
  const DerivadosPerfil({
    required this.areaMm2,
    required this.pesoKgM,
    required this.caraMm,
    required this.fondoMm,
    required this.perimetroPinturaMm,
  });

  /// Área de sección en mm²; null en la familia `otro`.
  final double? areaMm2;

  /// Peso en kg/m.
  final double pesoKgM;

  /// Ancho visto de frente, en mm.
  final double caraMm;

  /// Profundidad, en mm.
  final double fondoMm;

  /// Perímetro que se pinta, en mm.
  final double perimetroPinturaMm;

  @override
  Map<String, Object?> toJson() => {
    if (areaMm2 != null) 'area_mm2': areaMm2,
    'peso_kg_m': pesoKgM,
    'cara_mm': caraMm,
    'fondo_mm': fondoMm,
    'perimetro_pintura_mm': perimetroPinturaMm,
  };
}

/// Derivados de una lámina.
final class DerivadosLamina extends Derivados {
  const DerivadosLamina({required this.espesorMm, required this.pesoKgM2});

  /// Espesor en mm.
  final double espesorMm;

  /// Peso en kg/m².
  final double pesoKgM2;

  @override
  Map<String, Object?> toJson() => {
    'espesor_mm': espesorMm,
    'peso_kg_m2': pesoKgM2,
  };
}

/// Herraje y consumible no tienen derivados.
final class SinDerivados extends Derivados {
  const SinDerivados();

  @override
  Map<String, Object?> toJson() => {};
}

/// Calcula los derivados de [articulo] con [densidadKgM3] en kg/m³.
Derivados calcularDerivados(Articulo articulo, double densidadKgM3) {
  final g = articulo.geometria;
  final familia = articulo.familia;
  if (familia == null) return const SinDerivados();
  if (familia == Familia.lamina) {
    return DerivadosLamina(
      espesorMm: g['e']!,
      pesoKgM2: g['e']! * densidadKgM3 / 1000,
    );
  }
  final double? area;
  final double cara, fondo, perimetro;
  switch (familia) {
    case Familia.cuadrado:
      final a = g['a']!;
      (area, cara, fondo, perimetro) = (a * a, a, a, 4 * a);
    case Familia.redondo:
      final d = g['d']!;
      (area, cara, fondo, perimetro) = (math.pi * d * d / 4, d, d, math.pi * d);
    case Familia.solera:
      final (a, e) = (g['a']!, g['e']!);
      (area, cara, fondo, perimetro) = (a * e, a, e, 2 * (a + e));
    case Familia.angulo:
      final (a, e) = (g['a']!, g['e']!);
      (area, cara, fondo, perimetro) = ((2 * a - e) * e, a, a, 4 * a);
    case Familia.tubular:
      final (a, b, e) = (g['a']!, g['b']!, g['e']!);
      (area, cara, fondo, perimetro) = (
        a * b - (a - 2 * e) * (b - 2 * e),
        a,
        b,
        2 * (a + b),
      );
    case Familia.tubo:
      final (d, e) = (g['d']!, g['e']!);
      final interior = d - 2 * e;
      (area, cara, fondo, perimetro) = (
        math.pi / 4 * (d * d - interior * interior),
        d,
        d,
        math.pi * d,
      );
    case Familia.otro:
      final (c, f) = (g['cara']!, g['fondo']!);
      (area, cara, fondo, perimetro) = (null, c, f, 2 * (c + f));
    case Familia.lamina:
      throw StateError('inalcanzable');
  }
  return DerivadosPerfil(
    areaMm2: area,
    pesoKgM: articulo.pesoKgMManual ?? area! * densidadKgM3 / 1e6,
    caraMm: cara,
    fondoMm: fondo,
    perimetroPinturaMm: perimetro,
  );
}
