/// Plantilla `porton_abatible`: portón o zaguán de una o dos hojas
/// (`docs/MOTOR_MEDICION.md` §4.2). Longitudes en mm.
library;

import '../catalogo/articulo.dart';
import '../catalogo/catalogo.dart';
import '../catalogo/derivados.dart';
import '../error_motor.dart';
import '../medicion/modelo.dart';
import '../numeros.dart';
import '../problema.dart';
import 'comunes.dart';
import 'plantilla.dart';

/// Portón abatible: bastidor por hoja, relleno mixto, de barrotes o de lámina,
/// y herrajes.
class PlantillaPortonAbatible implements Plantilla {
  const PlantillaPortonAbatible();

  @override
  String get id => 'porton_abatible';

  @override
  String get nombre => 'Portón abatible';

  @override
  List<ParametroDef> get esquema => const [
    ParametroDef(
      clave: 'ancho',
      etiqueta: 'Ancho del vano',
      tipo: TipoParametro.longitud,
      defecto: 3000,
      min: 600,
      max: 8000,
      ayuda: 'Ancho libre del vano donde va el portón, en mm.',
    ),
    ParametroDef(
      clave: 'alto',
      etiqueta: 'Alto del vano',
      tipo: TipoParametro.longitud,
      defecto: 2200,
      min: 600,
      max: 4000,
      ayuda: 'Alto libre del vano donde va el portón, en mm.',
    ),
    ParametroDef(
      clave: 'hojas',
      etiqueta: 'Número de hojas',
      tipo: TipoParametro.entero,
      defecto: 2,
      min: 1,
      max: 2,
      ayuda: 'Cuántas hojas (puertas que abren) tiene el portón: 1 o 2.',
    ),
    ParametroDef(
      clave: 'holgura_lateral',
      etiqueta: 'Holgura lateral',
      tipo: TipoParametro.longitud,
      defecto: 10,
      min: 0,
      max: 50,
      ayuda: 'Espacio entre cada orilla del vano y la hoja, en mm.',
    ),
    ParametroDef(
      clave: 'holgura_central',
      etiqueta: 'Holgura central',
      tipo: TipoParametro.longitud,
      defecto: 10,
      min: 0,
      max: 50,
      ayuda: 'Espacio entre las dos hojas, en mm; con una hoja no se usa.',
    ),
    ParametroDef(
      clave: 'holgura_piso',
      etiqueta: 'Holgura al piso',
      tipo: TipoParametro.longitud,
      defecto: 50,
      min: 0,
      max: 200,
      ayuda: 'Espacio entre el piso y la parte baja de la hoja, en mm.',
    ),
    ParametroDef(
      clave: 'bastidor',
      etiqueta: 'Perfil del bastidor',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.perfil},
      familias: {Familia.tubular, Familia.angulo},
      ayuda: 'Clave del perfil con el que se hace el marco de cada hoja.',
    ),
    ParametroDef(
      clave: 'relleno',
      etiqueta: 'Relleno',
      tipo: TipoParametro.opcion,
      defecto: 'mixto',
      opciones: ['mixto', 'barrotes', 'lamina'],
      codigoOpcionInvalida: 'relleno_no_soportado',
      ayuda:
          'Cómo se llena cada hoja: mixto (lámina abajo y barrotes arriba), '
          'barrotes (todo de barrotes) o lamina (tablero completo).',
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
      requeridoSi: SiEsOpcion('relleno', ['mixto', 'barrotes']),
      ayuda: 'Clave del perfil de los barrotes; se pide en mixto y barrotes.',
    ),
    ParametroDef(
      clave: 'separacion_max',
      etiqueta: 'Separación máxima',
      tipo: TipoParametro.longitud,
      defecto: 110,
      min: 30,
      max: 300,
      requeridoSi: SiEsOpcion('relleno', ['mixto', 'barrotes']),
      ayuda: 'Hueco libre máximo entre barrotes en mm.',
    ),
    ParametroDef(
      clave: 'lamina',
      etiqueta: 'Lámina',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.lamina},
      requeridoSi: SiEsOpcion('relleno', ['mixto', 'lamina']),
      ayuda: 'Clave de la lámina del relleno; se pide en mixto y lamina.',
    ),
    ParametroDef(
      clave: 'alto_zoclo',
      etiqueta: 'Alto del zoclo',
      tipo: TipoParametro.longitud,
      defecto: 900,
      min: 100,
      max: 3000,
      requeridoSi: SiEsOpcion('relleno', ['mixto']),
      ayuda: 'Altura en mm de la lámina inferior de cada hoja; solo en mixto.',
    ),
    ParametroDef(
      clave: 'travesano',
      etiqueta: 'Perfil del travesaño',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.perfil},
      requeridoSi: SiEsOpcion('relleno', ['mixto', 'lamina']),
      ayuda: 'Clave del perfil del travesaño de cada hoja; en mixto y lamina.',
    ),
    ParametroDef(
      clave: 'paso_punteo',
      etiqueta: 'Paso de punteo',
      tipo: TipoParametro.longitud,
      defecto: 150,
      min: 50,
      max: 500,
      ayuda: 'Distancia en mm entre puntos de soldadura de la lámina.',
    ),
    ParametroDef(
      clave: 'bisagra',
      etiqueta: 'Bisagra',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.herraje},
      ayuda: 'Clave de la bisagra; se usan 2 por hoja, o 3 si la hoja pasa de 2 m.',
    ),
    ParametroDef(
      clave: 'pasador',
      etiqueta: 'Pasador',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.herraje},
      requerido: false,
      ayuda: 'Clave del pasador; opcional, se pone uno por portón.',
    ),
    ParametroDef(
      clave: 'picaporte',
      etiqueta: 'Picaporte',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.herraje},
      requerido: false,
      ayuda: 'Clave del picaporte; opcional, solo se usa con 2 hojas.',
    ),
  ];

  static DerivadosPerfil _perfil(Catalogo catalogo, Object? clave) =>
      catalogo.derivados(clave! as String) as DerivadosPerfil;

  static double _num(Map<String, Object?> p, String k) =>
      (p[k]! as num).toDouble();

  /// Ancho de cada hoja en mm.
  static double _anchoHoja(Map<String, Object?> p) {
    final hojas = p['hojas']! as int;
    return (_num(p, 'ancho') -
            2 * _num(p, 'holgura_lateral') -
            (hojas - 1) * _num(p, 'holgura_central')) /
        hojas;
  }

  @override
  List<Problema> validarReglas(
    Map<String, Object?> parametros,
    Catalogo catalogo,
  ) {
    final c = _perfil(catalogo, parametros['bastidor']).caraMm;
    final claroAncho = _anchoHoja(parametros) - 2 * c;
    final altoHoja =
        _num(parametros, 'alto') - _num(parametros, 'holgura_piso');
    final relleno = parametros['relleno'];
    // Largo del barrote según el relleno; null si no lleva barrotes.
    double? largoBarrote;
    String? parametroBarrote;
    if (relleno == 'mixto') {
      final ct = _perfil(catalogo, parametros['travesano']).caraMm;
      largoBarrote = altoHoja - c - _num(parametros, 'alto_zoclo') - ct / 2;
      parametroBarrote = 'alto_zoclo';
    } else if (relleno == 'barrotes') {
      largoBarrote = altoHoja - 2 * c;
      parametroBarrote = 'alto';
    }
    return [
      if (claroAncho <= eps)
        Problema(
          'claro_insuficiente',
          parametro: 'ancho',
          detalle: '$claroAncho',
        ),
      if (largoBarrote != null && largoBarrote <= eps)
        Problema(
          'claro_insuficiente',
          parametro: parametroBarrote,
          detalle: '$largoBarrote',
        ),
    ];
  }

  static Pieza _barra(
    String id,
    String grupo,
    String articulo,
    double largo,
    TipoCorte corte,
    Punto3 p0,
    Punto3 p1,
    int hoja,
  ) => Pieza(
    id: id,
    grupo: grupo,
    articulo: articulo,
    largo: largo,
    cantidad: 1,
    corte: corte,
    p0: p0,
    p1: p1,
    hoja: hoja,
  );

  @override
  ModeloPiezas generar(Map<String, Object?> parametros, Catalogo catalogo) {
    final ancho = _num(parametros, 'ancho');
    final alto = _num(parametros, 'alto');
    final hojas = parametros['hojas']! as int;
    final lateral = _num(parametros, 'holgura_lateral');
    final central = _num(parametros, 'holgura_central');
    final y0 = _num(parametros, 'holgura_piso');
    final bastidor = parametros['bastidor']! as String;
    final relleno = parametros['relleno'];
    final sepMax = (parametros['separacion_max'] as num?)?.toDouble();
    final paso = _num(parametros, 'paso_punteo');

    final anchoHoja = _anchoHoja(parametros);
    final altoHoja = alto - y0;
    final dBastidor = _perfil(catalogo, bastidor);
    final c = dBastidor.caraMm;
    final claroAncho = anchoHoja - 2 * c;

    Punto3 pt(double x, double y, [double z = 0]) => (x: x, y: y, z: z);

    final piezas = <Pieza>[];
    final paneles = <Panel>[];
    final uniones = <String, int>{'bastidor': 4 * hojas};
    void sumaUniones(String k, int v) => uniones[k] = (uniones[k] ?? 0) + v;
    var barrotesTotal = 0;
    final detalle = <String, Object>{
      'ancho_hoja_mm': anchoHoja,
      'alto_hoja_mm': altoHoja,
      'claro_ancho_mm': claroAncho,
    };

    for (var h = 0; h < hojas; h++) {
      final x0 = lateral + h * (anchoHoja + central);
      final pre = 'h${h + 1}';
      piezas.addAll([
        _barra(
          '$pre-bastidor-izq',
          'bastidor',
          bastidor,
          altoHoja,
          TipoCorte.inglete,
          pt(x0 + c / 2, y0),
          pt(x0 + c / 2, y0 + altoHoja),
          h,
        ),
        _barra(
          '$pre-bastidor-der',
          'bastidor',
          bastidor,
          altoHoja,
          TipoCorte.inglete,
          pt(x0 + anchoHoja - c / 2, y0),
          pt(x0 + anchoHoja - c / 2, y0 + altoHoja),
          h,
        ),
        _barra(
          '$pre-bastidor-inf',
          'bastidor',
          bastidor,
          anchoHoja,
          TipoCorte.inglete,
          pt(x0, y0 + c / 2),
          pt(x0 + anchoHoja, y0 + c / 2),
          h,
        ),
        _barra(
          '$pre-bastidor-sup',
          'bastidor',
          bastidor,
          anchoHoja,
          TipoCorte.inglete,
          pt(x0, y0 + altoHoja - c / 2),
          pt(x0 + anchoHoja, y0 + altoHoja - c / 2),
          h,
        ),
      ]);

      var n = 0;
      var w = 0.0;
      var hueco = 0.0;
      String? barrote;
      if (relleno == 'mixto' || relleno == 'barrotes') {
        barrote = parametros['barrote']! as String;
        w = _perfil(catalogo, barrote).caraMm;
        n = numeroBarrotes(claroAncho, w, sepMax!);
        hueco = (claroAncho - n * w) / (n + 1);
        detalle['hueco_libre_mm'] = hueco;
        detalle['barrotes_por_hoja'] = n;
      }
      var z = 0.0;
      String? lamina;
      if (relleno == 'mixto' || relleno == 'lamina') {
        lamina = parametros['lamina']! as String;
        final espesor =
            (catalogo.derivados(lamina) as DerivadosLamina).espesorMm;
        // Lámina sobrepuesta por fuera del bastidor.
        z = dBastidor.fondoMm / 2 + espesor / 2;
      }

      if (relleno == 'mixto') {
        // Zoclo de lámina abajo, travesaño centrado en su borde superior y
        // barrotes arriba.
        final travesano = parametros['travesano']! as String;
        final ct = _perfil(catalogo, travesano).caraMm;
        final zoclo = _num(parametros, 'alto_zoclo');
        final largoBarrote = altoHoja - c - zoclo - ct / 2;
        piezas.add(
          _barra(
            '$pre-travesano',
            'travesanos',
            travesano,
            claroAncho,
            TipoCorte.recto,
            pt(x0 + c, y0 + zoclo),
            pt(x0 + anchoHoja - c, y0 + zoclo),
            h,
          ),
        );
        for (var i = 1; i <= n; i++) {
          final x = x0 + c + hueco * i + w * (i - 0.5);
          piezas.add(
            _barra(
              '$pre-barrote-$i',
              'barrotes',
              barrote!,
              largoBarrote,
              TipoCorte.recto,
              pt(x, y0 + zoclo + ct / 2),
              pt(x, y0 + altoHoja - c),
              h,
            ),
          );
        }
        paneles.add(
          Panel(
            id: '$pre-zoclo',
            grupo: 'zoclo',
            articulo: lamina!,
            ancho: anchoHoja,
            alto: zoclo,
            cantidad: 1,
            origen: pt(x0, y0, z),
            hoja: h,
          ),
        );
        final puntos = techo(2 * (anchoHoja + zoclo) / paso);
        sumaUniones('travesanos', 2);
        sumaUniones('barrotes', 2 * n);
        sumaUniones('lamina', puntos);
        barrotesTotal += n;
        detalle['largo_barrote_mm'] = largoBarrote;
        detalle['puntos_lamina_por_hoja'] = puntos;
      } else if (relleno == 'barrotes') {
        // Barrotes de bastidor a bastidor, sin lámina ni travesaño.
        final largoBarrote = altoHoja - 2 * c;
        for (var i = 1; i <= n; i++) {
          final x = x0 + c + hueco * i + w * (i - 0.5);
          piezas.add(
            _barra(
              '$pre-barrote-$i',
              'barrotes',
              barrote!,
              largoBarrote,
              TipoCorte.recto,
              pt(x, y0 + c),
              pt(x, y0 + altoHoja - c),
              h,
            ),
          );
        }
        sumaUniones('barrotes', 2 * n);
        barrotesTotal += n;
        detalle['largo_barrote_mm'] = largoBarrote;
      } else if (relleno == 'lamina') {
        // Tablero completo con un travesaño de refuerzo a media altura.
        final travesano = parametros['travesano']! as String;
        piezas.add(
          _barra(
            '$pre-travesano',
            'travesanos',
            travesano,
            claroAncho,
            TipoCorte.recto,
            pt(x0 + c, y0 + altoHoja / 2),
            pt(x0 + anchoHoja - c, y0 + altoHoja / 2),
            h,
          ),
        );
        paneles.add(
          Panel(
            id: '$pre-tablero',
            grupo: 'tablero',
            articulo: lamina!,
            ancho: anchoHoja,
            alto: altoHoja,
            cantidad: 1,
            origen: pt(x0, y0, z),
            hoja: h,
          ),
        );
        final puntos = techo(2 * (anchoHoja + altoHoja) / paso);
        sumaUniones('travesanos', 2);
        sumaUniones('lamina', puntos);
        detalle['puntos_lamina_por_hoja'] = puntos;
      } else {
        throw ErrorMotor('relleno_no_soportado', detalle: '$relleno');
      }
    }

    final herrajes = <Herraje>[];
    final porHoja = altoHoja <= 2000 + eps ? 2 : 3;
    final bisagras = porHoja * hojas;
    herrajes.add(
      Herraje(articulo: parametros['bisagra']! as String, cantidad: bisagras),
    );
    uniones['bisagras'] = 2 * bisagras;
    final pasador = parametros['pasador'] as String?;
    if (pasador != null) {
      herrajes.add(Herraje(articulo: pasador, cantidad: 1));
      uniones['pasador'] = 2;
    }
    final picaporte = parametros['picaporte'] as String?;
    if (picaporte != null && hojas == 2) {
      herrajes.add(Herraje(articulo: picaporte, cantidad: 1));
      uniones['picaporte'] = 2;
    }

    return ModeloPiezas(
      plantilla: id,
      caja: (ancho: ancho, alto: alto),
      numHojas: hojas,
      piezas: piezas,
      paneles: paneles,
      herrajes: herrajes,
      uniones: uniones,
      extras: {'barrotes': barrotesTotal, 'bisagras': bisagras},
      detalle: detalle,
      advertencias: [
        if (anchoHoja > 2500 + eps) Advertencia(codigo: 'hoja_ancha'),
      ],
    );
  }
}
