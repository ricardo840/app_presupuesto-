/// Medición: del modelo de piezas al despiece, los cortes, los pesos y las
/// cantidades que ven las recetas (`docs/MOTOR_MEDICION.md` §6).
library;

import '../catalogo/articulo.dart';
import '../catalogo/catalogo.dart';
import '../catalogo/derivados.dart';
import '../error_motor.dart';
import '../numeros.dart';
import 'cortes.dart';
import 'modelo.dart';

/// Piezas iguales agrupadas del despiece.
class LineaDespiece {
  const LineaDespiece({
    required this.grupo,
    required this.articulo,
    required this.largo,
    required this.cantidad,
    required this.corte,
  });

  final String grupo;
  final String articulo;

  /// Largo de corte, en mm.
  final double largo;
  final int cantidad;
  final TipoCorte corte;

  Map<String, Object?> toJson() => {
    'grupo': grupo,
    'articulo': articulo,
    'largo': largo,
    'cantidad': cantidad,
    'corte': corte.name,
  };
}

/// Lo que consume un trabajo de un artículo del catálogo.
class MedicionArticulo {
  const MedicionArticulo({
    required this.tipo,
    required this.piezas,
    required this.metros,
    required this.kg,
    required this.tramos,
    required this.m2,
    required this.hojas,
    required this.cantidad,
    required this.costoCompra,
    required this.costoUsado,
  });

  final TipoArticulo tipo;

  /// Piezas diseñadas (perfil).
  final int piezas;

  /// Metros de perfil.
  final double metros;

  /// Peso en kg.
  final double kg;

  /// Tramos a comprar (perfil).
  final int tramos;

  /// Área de lámina, en m².
  final double m2;

  /// Hojas a comprar (lámina).
  final int hojas;

  /// Piezas de herraje.
  final int cantidad;

  /// Lo que se paga en la tienda, en pesos sin redondear.
  final double costoCompra;

  /// Parte proporcional realmente usada, en pesos sin redondear.
  final double costoUsado;

  Map<String, Object?> toJson() => {
    'tipo': tipo.name,
    'piezas': piezas,
    'metros': metros,
    'kg': kg,
    'tramos': tramos,
    'm2': m2,
    'hojas': hojas,
    'cantidad': cantidad,
    'costo_compra': costoCompra,
    'costo_usado': costoUsado,
  };
}

/// Resultado de [medir].
class Medicion {
  Medicion({
    required List<LineaDespiece> despiece,
    required Map<String, PlanCortes> cortes,
    required Map<String, MedicionArticulo> porArticulo,
    required Map<String, int> uniones,
    required Map<String, double> cantidades,
    required List<Advertencia> advertencias,
  }) : despiece = List.unmodifiable(despiece),
       cortes = Map.unmodifiable(cortes),
       porArticulo = Map.unmodifiable(porArticulo),
       uniones = Map.unmodifiable(uniones),
       cantidades = Map.unmodifiable(cantidades),
       advertencias = List.unmodifiable(advertencias);

  final List<LineaDespiece> despiece;

  /// Plan de cortes por clave de perfil.
  final Map<String, PlanCortes> cortes;
  final Map<String, MedicionArticulo> porArticulo;
  final Map<String, int> uniones;

  /// Variables de las recetas; el dinero va en pesos sin redondear.
  final Map<String, double> cantidades;
  final List<Advertencia> advertencias;

  Map<String, Object?> toJson() => {
    'despiece': [for (final l in despiece) l.toJson()],
    'cortes': {
      for (final e in cortes.entries)
        e.key: {
          'tramos': e.value.tramos,
          'barras': [for (final b in e.value.barras) List<double>.of(b)],
          'sobrantes_mm': List<double>.of(e.value.sobrantesMm),
          'empalmes': e.value.empalmes,
        },
    },
    'por_articulo': {
      for (final e in porArticulo.entries) e.key: e.value.toJson(),
    },
    'uniones': Map<String, int>.of(uniones),
    'cantidades': Map<String, double>.of(cantidades),
    'advertencias': [for (final a in advertencias) a.toJson()],
  };
}

bool _cabeEnHoja(double ancho, double alto, ({double ancho, double largo}) h) {
  double menor(double a, double b) => a < b ? a : b;
  double mayor(double a, double b) => a > b ? a : b;
  return menor(ancho, alto) <= menor(h.ancho, h.largo) + eps &&
      mayor(ancho, alto) <= mayor(h.ancho, h.largo) + eps;
}

Articulo _articuloDe(Catalogo catalogo, String clave, TipoArticulo tipo) {
  final a = catalogo.articulo(clave);
  if (a.tipo != tipo) {
    throw ErrorMotor('familia_no_permitida', detalle: clave);
  }
  return a;
}

/// Mide [modelo] con los precios y derivados de [catalogo].
Medicion medir(ModeloPiezas modelo, Catalogo catalogo) {
  final k = catalogo.constantes;
  final advertencias = [...modelo.advertencias];

  // Despiece agrupado en orden de aparición.
  final despiece = <LineaDespiece>[];
  final indice = <(String, String, double, TipoCorte), int>{};
  for (final pz in modelo.piezas) {
    final llave = (pz.grupo, pz.articulo, redondear(pz.largo, 4), pz.corte);
    final i = indice[llave];
    if (i == null) {
      indice[llave] = despiece.length;
      despiece.add(
        LineaDespiece(
          grupo: pz.grupo,
          articulo: pz.articulo,
          largo: pz.largo,
          cantidad: pz.cantidad,
          corte: pz.corte,
        ),
      );
    } else {
      final l = despiece[i];
      despiece[i] = LineaDespiece(
        grupo: l.grupo,
        articulo: l.articulo,
        largo: l.largo,
        cantidad: l.cantidad + pz.cantidad,
        corte: l.corte,
      );
    }
  }

  final largosPorArticulo = <String, List<double>>{};
  for (final pz in modelo.piezas) {
    largosPorArticulo
        .putIfAbsent(pz.articulo, () => [])
        .addAll(List<double>.filled(pz.cantidad, pz.largo));
  }

  final cortes = <String, PlanCortes>{};
  final perfiles = <String, MedicionArticulo>{};
  final laminas = <String, MedicionArticulo>{};
  final herrajes = <String, MedicionArticulo>{};
  var kgPerfiles = 0.0;
  var mPerfiles = 0.0;
  var m2Pintura = 0.0;
  var costoPerfilesCompra = 0.0;
  var costoPerfilesUsado = 0.0;
  var kgLaminas = 0.0;
  var m2Lamina = 0.0;
  var costoLaminasCompra = 0.0;
  var costoLaminasUsado = 0.0;
  var costoHerrajes = 0.0;
  var tramos = 0;
  var hojasLamina = 0;
  var nCortes = 0;
  var empalmes = 0;

  for (final MapEntry(key: clave, value: largos) in largosPorArticulo.entries) {
    final a = _articuloDe(catalogo, clave, TipoArticulo.perfil);
    final d = catalogo.derivados(clave) as DerivadosPerfil;
    final tramo = a.largoTramoMm!;
    final plan = optimizarCortes(largos, tramo, k.kerfMm);
    if (plan.empalmes > 0) {
      advertencias.add(
        Advertencia(
          codigo: 'pieza_mayor_que_tramo',
          datos: {'articulo': clave},
        ),
      );
    }
    final metros = largos.fold(0.0, (s, l) => s + l) / 1000.0;
    final kg = metros * d.pesoKgM;
    final precio = a.precio;
    final double compra;
    final double usado;
    switch (a.unidadCompra) {
      case UnidadCompra.tramo:
        compra = plan.tramos * precio;
        usado = metros / (tramo / 1000.0) * precio;
      case UnidadCompra.kg:
        compra = plan.tramos * (tramo / 1000.0) * d.pesoKgM * precio;
        usado = kg * precio;
      case UnidadCompra.m:
        compra = usado = metros * precio;
      default:
        throw ErrorMotor('unidad_no_soportada', detalle: clave);
    }
    cortes[clave] = plan;
    perfiles[clave] = MedicionArticulo(
      tipo: TipoArticulo.perfil,
      piezas: largos.length,
      metros: metros,
      kg: kg,
      tramos: plan.tramos,
      m2: 0.0,
      hojas: 0,
      cantidad: 0,
      costoCompra: compra,
      costoUsado: usado,
    );
    kgPerfiles += kg;
    mPerfiles += metros;
    m2Pintura += d.perimetroPinturaMm / 1000.0 * metros;
    costoPerfilesCompra += compra;
    costoPerfilesUsado += usado;
    tramos += plan.tramos;
    nCortes += plan.cortes;
    empalmes += plan.empalmes;
  }

  final m2PorLamina = <String, double>{};
  for (final pn in modelo.paneles) {
    final a = _articuloDe(catalogo, pn.articulo, TipoArticulo.lamina);
    if (!_cabeEnHoja(pn.ancho, pn.alto, a.hojaMm!)) {
      advertencias.add(
        Advertencia(
          codigo: 'panel_no_cabe_en_hoja',
          datos: {'articulo': pn.articulo, 'panel': pn.id},
        ),
      );
    }
    m2PorLamina[pn.articulo] =
        (m2PorLamina[pn.articulo] ?? 0.0) +
        pn.ancho * pn.alto / 1e6 * pn.cantidad;
  }
  for (final MapEntry(key: clave, value: m2) in m2PorLamina.entries) {
    final a = catalogo.articulo(clave);
    final d = catalogo.derivados(clave) as DerivadosLamina;
    final areaHoja = a.hojaMm!.ancho * a.hojaMm!.largo / 1e6;
    final hojas = techo(m2 * (1 + k.desperdicioLamina) / areaHoja);
    final kg = m2 * d.pesoKgM2;
    final precio = a.precio;
    final double compra;
    final double usado;
    switch (a.unidadCompra) {
      case UnidadCompra.hoja:
        compra = hojas * precio;
        usado = m2 / areaHoja * precio;
      case UnidadCompra.m2:
        compra = m2 * (1 + k.desperdicioLamina) * precio;
        usado = m2 * precio;
      case UnidadCompra.kg:
        compra = hojas * areaHoja * d.pesoKgM2 * precio;
        usado = kg * precio;
      default:
        throw ErrorMotor('unidad_no_soportada', detalle: clave);
    }
    laminas[clave] = MedicionArticulo(
      tipo: TipoArticulo.lamina,
      piezas: 0,
      metros: 0.0,
      kg: kg,
      tramos: 0,
      m2: m2,
      hojas: hojas,
      cantidad: 0,
      costoCompra: compra,
      costoUsado: usado,
    );
    kgLaminas += kg;
    m2Lamina += m2;
    m2Pintura += 2 * m2; // dos caras
    costoLaminasCompra += compra;
    costoLaminasUsado += usado;
    hojasLamina += hojas;
  }

  for (final h in modelo.herrajes) {
    final a = _articuloDe(catalogo, h.articulo, TipoArticulo.herraje);
    final costo = h.cantidad * a.precio;
    final previo = herrajes[h.articulo];
    herrajes[h.articulo] = MedicionArticulo(
      tipo: TipoArticulo.herraje,
      piezas: 0,
      metros: 0.0,
      kg: 0.0,
      tramos: 0,
      m2: 0.0,
      hojas: 0,
      cantidad: (previo?.cantidad ?? 0) + h.cantidad,
      costoCompra: (previo?.costoCompra ?? 0.0) + costo,
      costoUsado: (previo?.costoUsado ?? 0.0) + costo,
    );
    costoHerrajes += costo;
  }

  final uniones = {...modelo.uniones};
  if (empalmes > 0) uniones['empalmes'] = empalmes;
  final ancho = modelo.caja.ancho;
  final alto = modelo.caja.alto;
  final cantidades = <String, double>{
    'ancho_m': ancho / 1000.0,
    'alto_m': alto / 1000.0,
    'largo_m': ancho / 1000.0,
    'area_m2': ancho * alto / 1e6,
    'perimetro_m': 2 * (ancho + alto) / 1000.0,
    'num_hojas': modelo.numHojas.toDouble(),
    'kg_acero': kgPerfiles + kgLaminas,
    'kg_perfiles': kgPerfiles,
    'kg_laminas': kgLaminas,
    'm_perfiles': mPerfiles,
    'tramos': tramos.toDouble(),
    'm2_lamina': m2Lamina,
    'hojas_lamina': hojasLamina.toDouble(),
    'piezas': modelo.piezas.fold(0, (s, p) => s + p.cantidad).toDouble(),
    'paneles': modelo.paneles.fold(0, (s, p) => s + p.cantidad).toDouble(),
    'cortes': nCortes.toDouble(),
    'ingletes': modelo.piezas
        .where((p) => p.corte == TipoCorte.inglete)
        .fold(0, (s, p) => s + 2 * p.cantidad)
        .toDouble(),
    'uniones': uniones.values.fold(0, (s, v) => s + v).toDouble(),
    'm2_pintura': m2Pintura,
    'costo_perfiles_compra': costoPerfilesCompra,
    'costo_perfiles_usado': costoPerfilesUsado,
    'costo_laminas_compra': costoLaminasCompra,
    'costo_laminas_usado': costoLaminasUsado,
    'costo_herrajes': costoHerrajes,
    'costo_material_compra':
        costoPerfilesCompra + costoLaminasCompra + costoHerrajes,
    'costo_material_usado':
        costoPerfilesUsado + costoLaminasUsado + costoHerrajes,
  };
  for (final e in modelo.extras.entries) {
    cantidades['x_${e.key}'] = e.value.toDouble();
  }

  return Medicion(
    despiece: despiece,
    cortes: cortes,
    porArticulo: {...perfiles, ...laminas, ...herrajes},
    uniones: uniones,
    cantidades: cantidades,
    advertencias: advertencias,
  );
}
