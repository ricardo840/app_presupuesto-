import 'package:collection/collection.dart';

import '../error_motor.dart';

/// Tipo de artículo del catálogo.
enum TipoArticulo { perfil, lamina, herraje, consumible }

/// Familia geométrica de un perfil o lámina.
enum Familia { cuadrado, redondo, solera, angulo, tubular, tubo, otro, lamina }

/// Unidad en que se compra un artículo (en JSON se usa el `name`).
enum UnidadCompra { tramo, kg, m, m2, hoja, pieza, litro }

const Map<TipoArticulo, Set<UnidadCompra>> _unidadesPorTipo = {
  TipoArticulo.perfil: {UnidadCompra.tramo, UnidadCompra.kg, UnidadCompra.m},
  TipoArticulo.lamina: {UnidadCompra.hoja, UnidadCompra.m2, UnidadCompra.kg},
  TipoArticulo.herraje: {UnidadCompra.pieza},
  TipoArticulo.consumible: {
    UnidadCompra.pieza,
    UnidadCompra.kg,
    UnidadCompra.litro,
  },
};

const Map<Familia, List<String>> _medidasPorFamilia = {
  Familia.cuadrado: ['a'],
  Familia.redondo: ['d'],
  Familia.solera: ['a', 'e'],
  Familia.angulo: ['a', 'e'],
  Familia.tubular: ['a', 'b', 'e'],
  Familia.tubo: ['d', 'e'],
  Familia.otro: ['cara', 'fondo'],
  Familia.lamina: ['e'],
};

/// Artículo del catálogo: perfil, lámina, herraje o consumible.
class Articulo {
  const Articulo({
    required this.clave,
    required this.nombre,
    required this.tipo,
    required this.unidadCompra,
    required this.precio,
    this.familia,
    this.geometria = const {},
    this.largoTramoMm,
    this.hojaMm,
    this.pesoKgMManual,
  });

  /// Lee y valida un artículo; lanza `articulo_invalido` si está mal formado.
  factory Articulo.fromJson(Map<String, Object?> json) {
    final clave = json['clave'];
    final id = clave is String ? clave : '?';
    Never falla(String motivo) =>
        throw ErrorMotor('articulo_invalido', detalle: '$id: $motivo');

    for (final campo in [
      'clave',
      'nombre',
      'tipo',
      'unidad_compra',
      'precio',
    ]) {
      if (json[campo] == null) falla('falta $campo');
    }
    if (clave is! String || json['nombre'] is! String) {
      falla('clave o nombre no son texto');
    }
    if (json['precio'] is! num) falla('precio no es número');
    if (!((json['precio']! as num) >= 0)) falla('precio negativo');

    T? porNombre<T extends Enum>(List<T> valores, Object? v) {
      for (final e in valores) {
        if (e.name == v) return e;
      }
      return null;
    }

    final tipo = porNombre(TipoArticulo.values, json['tipo']);
    if (tipo == null) falla('tipo desconocido ${json['tipo']}');
    final unidad = porNombre(UnidadCompra.values, json['unidad_compra']);
    if (unidad == null) falla('unidad desconocida ${json['unidad_compra']}');
    if (!_unidadesPorTipo[tipo]!.contains(unidad)) {
      falla('unidad ${unidad.name} no válida para ${tipo.name}');
    }

    Familia? familia;
    if (json['familia'] != null) {
      familia = porNombre(Familia.values, json['familia']);
      if (familia == null) falla('familia desconocida ${json['familia']}');
    }
    final esPerfil = tipo == TipoArticulo.perfil;
    final esLamina = tipo == TipoArticulo.lamina;
    if (!esPerfil && !esLamina && familia != null) {
      falla('familia no aplica a ${tipo.name}');
    }
    if (esPerfil || esLamina) {
      if (familia == null) falla('falta familia');
      if (esLamina != (familia == Familia.lamina)) {
        falla('familia ${familia.name} no corresponde a ${tipo.name}');
      }
    }

    final geometria = <String, double>{};
    final g = json['geometria'];
    if (g != null) {
      if (g is! Map) falla('geometria no es un objeto');
      for (final e in g.entries) {
        if (e.value is! num) falla('geometria.${e.key} no es número');
        if (!((e.value! as num) > 0)) {
          falla('geometria.${e.key} debe ser mayor que cero');
        }
        geometria['${e.key}'] = (e.value! as num).toDouble();
      }
    }
    if (familia != null && (esPerfil || esLamina)) {
      for (final m in _medidasPorFamilia[familia]!) {
        if (!geometria.containsKey(m)) falla('falta la medida $m');
      }
    }

    ({double ancho, double largo})? hoja;
    if (esLamina) {
      final h = json['hoja_mm'];
      if (h is! List || h.length != 2 || h.any((x) => x is! num)) {
        falla('hoja_mm debe ser [ancho, largo]');
      }
      if (!((h[0] as num) > 0) || !((h[1] as num) > 0)) {
        falla('hoja_mm debe ser mayor que cero');
      }
      hoja = (ancho: (h[0] as num).toDouble(), largo: (h[1] as num).toDouble());
    }

    final manual = json['peso_kg_m_manual'];
    if (manual != null && manual is! num) {
      falla('peso_kg_m_manual no es número');
    }
    if (manual != null && !((manual as num) > 0)) {
      falla('peso_kg_m_manual debe ser mayor que cero');
    }
    if (familia == Familia.otro && manual == null) {
      falla('familia otro exige peso_kg_m_manual');
    }
    final largo = json['largo_tramo_mm'];
    if (largo != null && largo is! num) falla('largo_tramo_mm no es número');
    if (largo != null && !((largo as num) > 0)) {
      falla('largo_tramo_mm debe ser mayor que cero');
    }

    return Articulo(
      clave: clave,
      nombre: json['nombre']! as String,
      tipo: tipo,
      unidadCompra: unidad,
      precio: (json['precio']! as num).toDouble(),
      familia: familia,
      geometria: Map.unmodifiable(geometria),
      largoTramoMm: esPerfil ? ((largo as num?)?.toDouble() ?? 6000) : null,
      hojaMm: hoja,
      pesoKgMManual: (manual as num?)?.toDouble(),
    );
  }

  final String clave;
  final String nombre;
  final TipoArticulo tipo;
  final UnidadCompra unidadCompra;

  /// Precio en pesos, como en el JSON.
  final double precio;

  /// Null en herraje y consumible.
  final Familia? familia;

  /// Medidas en mm: a, b, d, e, cara, fondo según la familia.
  final Map<String, double> geometria;

  /// Largo del tramo en mm (perfil; 6000 si el JSON no lo trae).
  final double? largoTramoMm;

  /// Hoja de lámina en mm (lámina).
  final ({double ancho, double largo})? hojaMm;

  /// Peso por metro del proveedor en kg/m; manda sobre el teórico.
  final double? pesoKgMManual;

  Map<String, Object?> toJson() => {
    'clave': clave,
    'nombre': nombre,
    'tipo': tipo.name,
    if (familia != null) 'familia': familia!.name,
    if (geometria.isNotEmpty) 'geometria': Map<String, Object?>.of(geometria),
    'unidad_compra': unidadCompra.name,
    if (largoTramoMm != null) 'largo_tramo_mm': largoTramoMm,
    if (hojaMm != null) 'hoja_mm': [hojaMm!.ancho, hojaMm!.largo],
    if (pesoKgMManual != null) 'peso_kg_m_manual': pesoKgMManual,
    'precio': precio,
  };

  @override
  bool operator ==(Object other) =>
      other is Articulo &&
      other.clave == clave &&
      other.nombre == nombre &&
      other.tipo == tipo &&
      other.unidadCompra == unidadCompra &&
      other.precio == precio &&
      other.familia == familia &&
      const MapEquality<String, double>().equals(other.geometria, geometria) &&
      other.largoTramoMm == largoTramoMm &&
      other.hojaMm == hojaMm &&
      other.pesoKgMManual == pesoKgMManual;

  @override
  int get hashCode => Object.hash(
    clave,
    nombre,
    tipo,
    unidadCompra,
    precio,
    familia,
    const MapEquality<String, double>().hash(geometria),
    largoTramoMm,
    hojaMm,
    pesoKgMManual,
  );
}
