/// Plantilla `reja_ventana`: protección de ventana
/// (`docs/MOTOR_MEDICION.md` §4.1). Longitudes en mm.
library;

import '../catalogo/articulo.dart';
import '../catalogo/catalogo.dart';
import '../catalogo/derivados.dart';
import '../medicion/modelo.dart';
import '../numeros.dart';
import '../problema.dart';
import 'comunes.dart';
import 'plantilla.dart';

/// Reja de ventana: marco a inglete, barrotes verticales, soleras de amarre
/// por detrás y anclas al muro.
class PlantillaRejaVentana implements Plantilla {
  const PlantillaRejaVentana();

  @override
  String get id => 'reja_ventana';

  @override
  String get nombre => 'Reja de ventana';

  @override
  List<ParametroDef> get esquema => const [
    ParametroDef(
      clave: 'ancho',
      etiqueta: 'Ancho',
      tipo: TipoParametro.longitud,
      defecto: 1200,
      min: 200,
      max: 6000,
      ayuda: 'Ancho exterior del marco en mm.',
    ),
    ParametroDef(
      clave: 'alto',
      etiqueta: 'Alto',
      tipo: TipoParametro.longitud,
      defecto: 1000,
      min: 200,
      max: 3000,
      ayuda: 'Alto exterior del marco en mm.',
    ),
    ParametroDef(
      clave: 'marco',
      etiqueta: 'Perfil del marco',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.perfil},
      familias: {Familia.angulo, Familia.tubular, Familia.solera},
      ayuda: 'Clave del perfil con el que se hace el marco perimetral.',
    ),
    ParametroDef(
      clave: 'barrote',
      etiqueta: 'Perfil de los barrotes',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.perfil},
      familias: {
        Familia.cuadrado,
        Familia.redondo,
        Familia.tubular,
        Familia.tubo,
      },
      ayuda: 'Clave del perfil de los barrotes verticales.',
    ),
    ParametroDef(
      clave: 'separacion_max',
      etiqueta: 'Separación máxima',
      tipo: TipoParametro.longitud,
      defecto: 120,
      min: 30,
      max: 300,
      ayuda: 'Hueco libre máximo entre barrotes en mm.',
    ),
    ParametroDef(
      clave: 'travesanos',
      etiqueta: 'Número de travesaños',
      tipo: TipoParametro.entero,
      defecto: 1,
      min: 0,
      max: 6,
      ayuda: 'Cuántas soleras de amarre horizontales lleva por detrás.',
    ),
    ParametroDef(
      clave: 'travesano',
      etiqueta: 'Perfil del travesaño',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.perfil},
      requeridoSi: SiMayorQue('travesanos', 0),
      ayuda: 'Clave del perfil de los travesaños; se pide si hay travesaños.',
    ),
    ParametroDef(
      clave: 'anclas',
      etiqueta: 'Número de anclas',
      tipo: TipoParametro.entero,
      defecto: 4,
      min: 0,
      max: 12,
      ayuda: 'Cuántas anclas fijan la reja al muro.',
    ),
    ParametroDef(
      clave: 'ancla',
      etiqueta: 'Perfil del ancla',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.perfil},
      requeridoSi: SiMayorQue('anclas', 0),
      ayuda: 'Clave del perfil de las anclas; se pide si hay anclas.',
    ),
    ParametroDef(
      clave: 'largo_ancla',
      etiqueta: 'Largo del ancla',
      tipo: TipoParametro.longitud,
      defecto: 100,
      min: 30,
      max: 300,
      ayuda: 'Largo de cada ancla en mm.',
    ),
  ];

  static DerivadosPerfil _perfil(Catalogo catalogo, Object? clave) =>
      catalogo.derivados(clave! as String) as DerivadosPerfil;

  @override
  List<Problema> validarReglas(
    Map<String, Object?> parametros,
    Catalogo catalogo,
  ) {
    final c = _perfil(catalogo, parametros['marco']).caraMm;
    final ancho = (parametros['ancho']! as num).toDouble();
    final alto = (parametros['alto']! as num).toDouble();
    return [
      if (ancho - 2 * c <= eps)
        Problema(
          'claro_insuficiente',
          parametro: 'ancho',
          detalle: '${ancho - 2 * c}',
        ),
      if (alto - 2 * c <= eps)
        Problema(
          'claro_insuficiente',
          parametro: 'alto',
          detalle: '${alto - 2 * c}',
        ),
    ];
  }

  static Pieza _barra(
    String id,
    String grupo,
    String articulo,
    double largo,
    TipoCorte corte,
    Punto3? p0,
    Punto3? p1,
  ) => Pieza(
    id: id,
    grupo: grupo,
    articulo: articulo,
    largo: largo,
    cantidad: 1,
    corte: corte,
    p0: p0,
    p1: p1,
  );

  @override
  ModeloPiezas generar(Map<String, Object?> parametros, Catalogo catalogo) {
    final ancho = (parametros['ancho']! as num).toDouble();
    final alto = (parametros['alto']! as num).toDouble();
    final marco = parametros['marco']! as String;
    final barrote = parametros['barrote']! as String;
    final sepMax = (parametros['separacion_max']! as num).toDouble();
    final t = parametros['travesanos']! as int;
    final anclas = parametros['anclas']! as int;
    final largoAncla = (parametros['largo_ancla']! as num).toDouble();

    final c = _perfil(catalogo, marco).caraMm;
    final dBarrote = _perfil(catalogo, barrote);
    final w = dBarrote.caraMm;
    final claroAncho = ancho - 2 * c;
    final claroAlto = alto - 2 * c;
    final n = numeroBarrotes(claroAncho, w, sepMax);
    final hueco = (claroAncho - n * w) / (n + 1);

    Punto3 pt(double x, double y, [double z = 0]) => (x: x, y: y, z: z);

    final piezas = <Pieza>[
      _barra(
        'marco-inf',
        'marco',
        marco,
        ancho,
        TipoCorte.inglete,
        pt(0, c / 2),
        pt(ancho, c / 2),
      ),
      _barra(
        'marco-sup',
        'marco',
        marco,
        ancho,
        TipoCorte.inglete,
        pt(0, alto - c / 2),
        pt(ancho, alto - c / 2),
      ),
      _barra(
        'marco-izq',
        'marco',
        marco,
        alto,
        TipoCorte.inglete,
        pt(c / 2, 0),
        pt(c / 2, alto),
      ),
      _barra(
        'marco-der',
        'marco',
        marco,
        alto,
        TipoCorte.inglete,
        pt(ancho - c / 2, 0),
        pt(ancho - c / 2, alto),
      ),
    ];
    final centros = <double>[];
    for (var i = 1; i <= n; i++) {
      final x = c + hueco * i + w * (i - 0.5);
      centros.add(x);
      piezas.add(
        _barra(
          'barrote-$i',
          'barrotes',
          barrote,
          claroAlto,
          TipoCorte.recto,
          pt(x, c),
          pt(x, alto - c),
        ),
      );
    }
    final alturas = <double>[];
    if (t > 0) {
      final travesano = parametros['travesano']! as String;
      // La solera de amarre va por detrás de los barrotes.
      final z =
          -(dBarrote.fondoMm / 2 + _perfil(catalogo, travesano).fondoMm / 2);
      for (var j = 1; j <= t; j++) {
        final y = c + claroAlto * j / (t + 1);
        alturas.add(y);
        piezas.add(
          _barra(
            'travesano-$j',
            'travesanos',
            travesano,
            claroAncho,
            TipoCorte.recto,
            pt(c, y, z),
            pt(ancho - c, y, z),
          ),
        );
      }
    }
    for (var k = 1; k <= anclas; k++) {
      // Las anclas cuentan como material pero no se dibujan.
      piezas.add(
        _barra(
          'ancla-$k',
          'anclas',
          parametros['ancla']! as String,
          largoAncla,
          TipoCorte.recto,
          null,
          null,
        ),
      );
    }

    return ModeloPiezas(
      plantilla: id,
      caja: (ancho: ancho, alto: alto),
      numHojas: 0,
      piezas: piezas,
      uniones: {
        'marco': 4,
        'barrotes': 2 * n,
        'travesanos': t * (2 + n),
        'anclas': anclas,
      },
      extras: {'barrotes': n, 'travesanos': t, 'anclas': anclas},
      detalle: {
        'claro_ancho_mm': claroAncho,
        'claro_alto_mm': claroAlto,
        'hueco_libre_mm': hueco,
        'x_centros_barrotes_mm': centros,
        'y_travesanos_mm': alturas,
      },
      advertencias: [if (n == 0) Advertencia(codigo: 'sin_barrotes')],
    );
  }
}
