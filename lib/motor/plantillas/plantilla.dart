/// Interfaz de las plantillas y esquema de sus parámetros
/// (`docs/MOTOR_MEDICION.md` §4). Contrato fijado por el director en F1-T6.
library;

import '../catalogo/articulo.dart';
import '../catalogo/catalogo.dart';
import '../medicion/modelo.dart';
import '../problema.dart';

/// Tipo de valor de un parámetro.
enum TipoParametro {
  /// Número en mm.
  longitud,

  /// Número entero (un `3.0` cuenta como entero).
  entero,

  /// Clave de un artículo del catálogo.
  articulo,

  /// Texto que debe estar en `opciones`.
  opcion,

  /// Verdadero o falso.
  booleano,

  /// Texto libre no vacío (el `grupo` de una pieza del trabajo libre).
  texto,

  /// Lista de objetos; cada uno se valida con `campos`.
  lista,
}

/// Condición de `requerido_si` sobre otro parámetro del mismo nivel.
sealed class Condicion {
  const Condicion(this.clave);

  /// Parámetro del que depende.
  final String clave;

  /// Si se cumple con los parámetros ya completados con sus valores por defecto.
  bool seCumple(Map<String, Object?> parametros);

  Map<String, Object?> toJson();
}

/// `clave > valor` (por ejemplo `travesanos > 0`).
final class SiMayorQue extends Condicion {
  const SiMayorQue(super.clave, this.valor);

  final num valor;

  @override
  bool seCumple(Map<String, Object?> parametros) {
    final v = parametros[clave];
    return v is num && v > valor;
  }

  @override
  Map<String, Object?> toJson() => {'clave': clave, 'mayor_que': valor};
}

/// `clave` es una de [opciones] (por ejemplo `relleno` en `mixto`, `barrotes`).
final class SiEsOpcion extends Condicion {
  const SiEsOpcion(super.clave, this.opciones);

  final List<String> opciones;

  @override
  bool seCumple(Map<String, Object?> parametros) =>
      opciones.contains(parametros[clave]);

  @override
  Map<String, Object?> toJson() => {'clave': clave, 'en': opciones};
}

/// Descripción de un parámetro. El formulario y las herramientas de la IA se
/// generan a partir de esto.
class ParametroDef {
  const ParametroDef({
    required this.clave,
    required this.etiqueta,
    required this.tipo,
    this.defecto,
    this.min,
    this.max,
    this.opciones = const [],
    this.codigoOpcionInvalida = 'fuera_de_rango',
    this.tiposArticulo = const {},
    this.familias = const {},
    this.requerido = true,
    this.requeridoSi,
    this.ayuda = '',
    this.campos = const [],
  });

  final String clave;

  /// Nombre corto para el formulario.
  final String etiqueta;
  final TipoParametro tipo;

  /// Valor que se usa cuando no llega uno; `null` si no hay.
  final Object? defecto;

  /// Límites inclusivos para `longitud` (mm) y `entero`.
  final num? min;
  final num? max;

  /// Valores válidos de un parámetro `opcion`, en el orden en que se ofrecen.
  final List<String> opciones;

  /// Código cuando la opción no está en [opciones] (`relleno_no_soportado`).
  final String codigoOpcionInvalida;

  /// Tipos de artículo aceptados; vacío acepta cualquiera.
  final Set<TipoArticulo> tiposArticulo;

  /// Familias aceptadas; vacío acepta cualquiera (un herraje no tiene familia).
  final Set<Familia> familias;

  /// Si es `false`, puede quedar vacío (`pasador`, "artículo o nulo").
  final bool requerido;

  /// Si se da, el parámetro solo se exige y se valida cuando se cumple.
  final Condicion? requeridoSi;

  /// Una frase que explica el parámetro; también la lee la IA.
  final String ayuda;

  /// Esquema de cada elemento de un parámetro `lista`.
  final List<ParametroDef> campos;

  Map<String, Object?> toJson() => {
    'clave': clave,
    'etiqueta': etiqueta,
    'tipo': tipo.name,
    if (defecto != null) 'defecto': defecto,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (opciones.isNotEmpty) 'opciones': opciones,
    if (tiposArticulo.isNotEmpty)
      'tipos_articulo': [for (final t in tiposArticulo) t.name],
    if (familias.isNotEmpty) 'familias': [for (final f in familias) f.name],
    'requerido': requerido,
    if (requeridoSi != null) 'requerido_si': requeridoSi!.toJson(),
    if (ayuda.isNotEmpty) 'ayuda': ayuda,
    if (campos.isNotEmpty) 'campos': [for (final c in campos) c.toJson()],
  };
}

/// Una plantilla paramétrica: esquema, reglas propias y generación del modelo.
abstract interface class Plantilla {
  /// Identificador estable, por ejemplo `reja_ventana`.
  String get id;

  /// Nombre para mostrar.
  String get nombre;

  /// Parámetros en el orden en que se piden.
  List<ParametroDef> get esquema;

  /// Errores propios de la plantilla (`claro_insuficiente`).
  ///
  /// Recibe los parámetros ya completados y sin errores de esquema. Las
  /// advertencias (`sin_barrotes`, `hoja_ancha`) no van aquí: las pone
  /// [generar] en `ModeloPiezas.advertencias`.
  List<Problema> validarReglas(
    Map<String, Object?> parametros,
    Catalogo catalogo,
  );

  /// Genera el modelo de piezas.
  ///
  /// Precondición: `validarParametros` no dio errores con estos parámetros.
  ModeloPiezas generar(Map<String, Object?> parametros, Catalogo catalogo);
}
