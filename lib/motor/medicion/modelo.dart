/// Modelo de piezas: el contrato entre plantillas, medición y todo lo visual
/// (`docs/MOTOR_MEDICION.md` §3). Longitudes en mm.
library;

import 'package:collection/collection.dart';

const DeepCollectionEquality _igualdad = DeepCollectionEquality();

/// Punto en el espacio, en mm. En JSON es `[x, y, z]`.
typedef Punto3 = ({double x, double y, double z});

Punto3? _punto(Object? json) {
  if (json == null) return null;
  final l = json as List<Object?>;
  return (
    x: (l[0]! as num).toDouble(),
    y: (l[1]! as num).toDouble(),
    z: (l[2]! as num).toDouble(),
  );
}

List<double>? _puntoJson(Punto3? p) => p == null ? null : [p.x, p.y, p.z];

/// Tipo de corte de una barra.
enum TipoCorte {
  /// Corte a escuadra.
  recto,

  /// 45° en ambos extremos; el largo es el exterior.
  inglete,
}

/// Una barra. `p0` y `p1` son los extremos de su eje; sin ellos no se dibuja.
class Pieza {
  const Pieza({
    required this.id,
    required this.grupo,
    required this.articulo,
    required this.largo,
    required this.cantidad,
    required this.corte,
    this.p0,
    this.p1,
    this.hoja,
  });

  factory Pieza.fromJson(Map<String, Object?> json) => Pieza(
    id: json['id']! as String,
    grupo: json['grupo']! as String,
    articulo: json['articulo']! as String,
    largo: (json['largo']! as num).toDouble(),
    cantidad: (json['cantidad']! as num).toInt(),
    corte: TipoCorte.values.byName(json['corte']! as String),
    p0: _punto(json['p0']),
    p1: _punto(json['p1']),
    hoja: (json['hoja'] as num?)?.toInt(),
  );

  final String id;
  final String grupo;
  final String articulo;

  /// Largo de corte, en mm.
  final double largo;
  final int cantidad;
  final TipoCorte corte;

  /// Extremos del eje, en mm.
  final Punto3? p0;
  final Punto3? p1;

  /// Índice de la hoja a la que pertenece, o null.
  final int? hoja;

  Map<String, Object?> toJson() => {
    'id': id,
    'grupo': grupo,
    'articulo': articulo,
    'largo': largo,
    'cantidad': cantidad,
    'corte': corte.name,
    'p0': _puntoJson(p0),
    'p1': _puntoJson(p1),
    'hoja': hoja,
  };

  @override
  bool operator ==(Object other) =>
      other is Pieza &&
      id == other.id &&
      grupo == other.grupo &&
      articulo == other.articulo &&
      largo == other.largo &&
      cantidad == other.cantidad &&
      corte == other.corte &&
      p0 == other.p0 &&
      p1 == other.p1 &&
      hoja == other.hoja;

  @override
  int get hashCode =>
      Object.hash(id, grupo, articulo, largo, cantidad, corte, p0, p1, hoja);
}

/// Rectángulo de lámina en un plano paralelo a XY.
class Panel {
  const Panel({
    required this.id,
    required this.grupo,
    required this.articulo,
    required this.ancho,
    required this.alto,
    required this.cantidad,
    this.origen,
    this.hoja,
  });

  factory Panel.fromJson(Map<String, Object?> json) => Panel(
    id: json['id']! as String,
    grupo: json['grupo']! as String,
    articulo: json['articulo']! as String,
    ancho: (json['ancho']! as num).toDouble(),
    alto: (json['alto']! as num).toDouble(),
    cantidad: (json['cantidad']! as num).toInt(),
    origen: _punto(json['origen']),
    hoja: (json['hoja'] as num?)?.toInt(),
  );

  final String id;
  final String grupo;
  final String articulo;

  /// Medidas en mm.
  final double ancho;
  final double alto;
  final int cantidad;

  /// Esquina inferior izquierda, en mm; `z` es el centro del espesor.
  /// Null en trabajos libres.
  final Punto3? origen;
  final int? hoja;

  Map<String, Object?> toJson() => {
    'id': id,
    'grupo': grupo,
    'articulo': articulo,
    'ancho': ancho,
    'alto': alto,
    'cantidad': cantidad,
    'origen': _puntoJson(origen),
    'hoja': hoja,
  };

  @override
  bool operator ==(Object other) =>
      other is Panel &&
      id == other.id &&
      grupo == other.grupo &&
      articulo == other.articulo &&
      ancho == other.ancho &&
      alto == other.alto &&
      cantidad == other.cantidad &&
      origen == other.origen &&
      hoja == other.hoja;

  @override
  int get hashCode =>
      Object.hash(id, grupo, articulo, ancho, alto, cantidad, origen, hoja);
}

/// Herraje contado por piezas.
class Herraje {
  const Herraje({required this.articulo, required this.cantidad});

  factory Herraje.fromJson(Map<String, Object?> json) => Herraje(
    articulo: json['articulo']! as String,
    cantidad: (json['cantidad']! as num).toInt(),
  );

  final String articulo;
  final int cantidad;

  Map<String, Object?> toJson() => {'articulo': articulo, 'cantidad': cantidad};

  @override
  bool operator ==(Object other) =>
      other is Herraje &&
      articulo == other.articulo &&
      cantidad == other.cantidad;

  @override
  int get hashCode => Object.hash(articulo, cantidad);
}

/// Aviso con un código estable y los datos que lo ubican (textos o números).
class Advertencia {
  Advertencia({required this.codigo, Map<String, Object> datos = const {}})
    : datos = Map.unmodifiable(datos);

  /// JSON plano: `{"codigo": ..., ...datos}`.
  factory Advertencia.fromJson(Map<String, Object?> json) {
    final datos = <String, Object>{};
    for (final e in json.entries) {
      if (e.key != 'codigo') datos[e.key] = e.value!;
    }
    return Advertencia(codigo: json['codigo']! as String, datos: datos);
  }

  final String codigo;
  final Map<String, Object> datos;

  Map<String, Object?> toJson() => {'codigo': codigo, ...datos};

  @override
  bool operator ==(Object other) =>
      other is Advertencia &&
      codigo == other.codigo &&
      _igualdad.equals(datos, other.datos);

  @override
  int get hashCode => Object.hash(codigo, _igualdad.hash(datos));
}

Object _congelar(Object v) => v is List
    ? List<Object>.unmodifiable(v.map((e) => _congelar(e as Object)))
    : v;

/// Resultado de una plantilla: todo lo que se cotiza y se dibuja.
class ModeloPiezas {
  ModeloPiezas({
    required this.plantilla,
    required this.caja,
    required this.numHojas,
    List<Pieza> piezas = const [],
    List<Panel> paneles = const [],
    List<Herraje> herrajes = const [],
    Map<String, int> uniones = const {},
    Map<String, int> extras = const {},
    Map<String, Object> detalle = const {},
    List<Advertencia> advertencias = const [],
  }) : piezas = List.unmodifiable(piezas),
       paneles = List.unmodifiable(paneles),
       herrajes = List.unmodifiable(herrajes),
       uniones = Map.unmodifiable(uniones),
       extras = Map.unmodifiable(extras),
       detalle = Map.unmodifiable({
         for (final e in detalle.entries) e.key: _congelar(e.value),
       }),
       advertencias = List.unmodifiable(advertencias);

  factory ModeloPiezas.fromJson(Map<String, Object?> json) {
    final caja = json['caja']! as Map<String, Object?>;
    List<T> lista<T>(String k, T Function(Map<String, Object?>) f) => [
      for (final e in json[k]! as List<Object?>) f(e! as Map<String, Object?>),
    ];
    Map<String, int> conteos(String k) => {
      for (final e in (json[k]! as Map<String, Object?>).entries)
        e.key: (e.value! as num).toInt(),
    };
    return ModeloPiezas(
      plantilla: json['plantilla']! as String,
      caja: (
        ancho: (caja['ancho']! as num).toDouble(),
        alto: (caja['alto']! as num).toDouble(),
      ),
      numHojas: (json['num_hojas']! as num).toInt(),
      piezas: lista('piezas', Pieza.fromJson),
      paneles: lista('paneles', Panel.fromJson),
      herrajes: lista('herrajes', Herraje.fromJson),
      uniones: conteos('uniones'),
      extras: conteos('extras'),
      detalle: {
        for (final e in (json['detalle']! as Map<String, Object?>).entries)
          e.key: e.value!,
      },
      advertencias: lista('advertencias', Advertencia.fromJson),
    );
  }

  final String plantilla;

  /// Caja envolvente del trabajo, en mm.
  final ({double ancho, double alto}) caja;
  final int numHojas;
  final List<Pieza> piezas;
  final List<Panel> paneles;
  final List<Herraje> herrajes;

  /// Concepto → número de uniones soldadas.
  final Map<String, int> uniones;

  /// Conteos propios de la plantilla; llegan a las recetas como `x_<clave>`.
  final Map<String, int> extras;

  /// Valores intermedios (num o lista de num); no se usan para cotizar.
  final Map<String, Object> detalle;
  final List<Advertencia> advertencias;

  /// Suma de todas las uniones.
  int get totalUniones => uniones.values.fold(0, (a, b) => a + b);

  Map<String, Object?> toJson() => {
    'plantilla': plantilla,
    'caja': {'ancho': caja.ancho, 'alto': caja.alto},
    'num_hojas': numHojas,
    'piezas': [for (final p in piezas) p.toJson()],
    'paneles': [for (final p in paneles) p.toJson()],
    'herrajes': [for (final h in herrajes) h.toJson()],
    'uniones': uniones,
    'extras': extras,
    'detalle': detalle,
    'advertencias': [for (final a in advertencias) a.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is ModeloPiezas &&
      plantilla == other.plantilla &&
      caja == other.caja &&
      numHojas == other.numHojas &&
      _igualdad.equals(piezas, other.piezas) &&
      _igualdad.equals(paneles, other.paneles) &&
      _igualdad.equals(herrajes, other.herrajes) &&
      _igualdad.equals(uniones, other.uniones) &&
      _igualdad.equals(extras, other.extras) &&
      _igualdad.equals(detalle, other.detalle) &&
      _igualdad.equals(advertencias, other.advertencias);

  @override
  int get hashCode => Object.hash(
    plantilla,
    caja,
    numHojas,
    _igualdad.hash(piezas),
    _igualdad.hash(paneles),
    _igualdad.hash(herrajes),
    _igualdad.hash(uniones),
    _igualdad.hash(extras),
    _igualdad.hash(detalle),
    _igualdad.hash(advertencias),
  );
}
