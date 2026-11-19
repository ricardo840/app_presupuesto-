/// Validación genérica de parámetros desde el esquema de la plantilla y
/// aplicación de la plantilla (`docs/MOTOR_MEDICION.md` §4).
library;

import '../catalogo/catalogo.dart';
import '../error_motor.dart';
import '../medicion/modelo.dart';
import '../numeros.dart';
import '../problema.dart';
import 'plantilla.dart';

/// Parámetros normalizados y problemas de una validación.
class ResultadoValidacion {
  ResultadoValidacion(this.parametros, List<Problema> problemas)
    : problemas = List.unmodifiable(problemas);

  /// Parámetros con defectos aplicados y tipos normalizados (`double`, `int`).
  final Map<String, Object?> parametros;
  final List<Problema> problemas;

  bool get hayErrores => problemas.any((p) => p.esError);
}

/// Modelo generado, o los problemas que lo impidieron.
class ResultadoPlantilla {
  ResultadoPlantilla(this.modelo, List<Problema> problemas)
    : problemas = List.unmodifiable(problemas);

  final ModeloPiezas? modelo;
  final List<Problema> problemas;
}

/// Valida [parametros] contra el esquema de [plantilla] y sus reglas propias.
///
/// Un parámetro da a lo más un problema. Las reglas de la plantilla solo se
/// consultan si el esquema no dio errores.
ResultadoValidacion validarParametros(
  Plantilla plantilla,
  Map<String, Object?> parametros,
  Catalogo catalogo,
) {
  final problemas = <Problema>[];
  final normalizados = _validarNivel(
    plantilla.esquema,
    parametros,
    catalogo,
    '',
    problemas,
  );
  if (!problemas.any((p) => p.esError)) {
    problemas.addAll(plantilla.validarReglas(normalizados, catalogo));
  }
  return ResultadoValidacion(normalizados, problemas);
}

/// Valida y, si no hay errores, genera el modelo. Un [ErrorMotor] de
/// `generar` se devuelve como problema; cualquier otra excepción es un bug.
ResultadoPlantilla aplicarPlantilla(
  Plantilla plantilla,
  Map<String, Object?> parametros,
  Catalogo catalogo,
) {
  final v = validarParametros(plantilla, parametros, catalogo);
  if (v.hayErrores) return ResultadoPlantilla(null, v.problemas);
  try {
    return ResultadoPlantilla(
      plantilla.generar(v.parametros, catalogo),
      v.problemas,
    );
  } on ErrorMotor catch (e) {
    return ResultadoPlantilla(null, [
      ...v.problemas,
      Problema(e.codigo, detalle: e.detalle),
    ]);
  }
}

Map<String, Object?> _validarNivel(
  List<ParametroDef> esquema,
  Map<String, Object?> entrada,
  Catalogo catalogo,
  String prefijo,
  List<Problema> problemas,
) {
  // 1. Defectos; solo pasan las claves del esquema.
  final completos = <String, Object?>{
    for (final d in esquema) d.clave: entrada[d.clave] ?? d.defecto,
  };
  final salida = <String, Object?>{};
  for (final d in esquema) {
    final ruta = '$prefijo${d.clave}';
    final valor = completos[d.clave];
    final cond = d.requeridoSi;
    if (cond != null && !cond.seCumple(completos)) {
      salida[d.clave] = valor;
      continue;
    }
    if (valor == null) {
      final exigible = cond != null || d.requerido;
      if (exigible) {
        problemas.add(Problema('parametro_faltante', parametro: ruta));
      }
      salida[d.clave] = null;
      continue;
    }
    final (norm, codigo, detalle) = _validarValor(
      d,
      valor,
      catalogo,
      ruta,
      problemas,
    );
    salida[d.clave] = norm;
    if (codigo != null) {
      problemas.add(Problema(codigo, parametro: ruta, detalle: detalle));
    }
  }
  return salida;
}

/// Devuelve (valor normalizado, código de error o null, detalle).
(Object?, String?, String?) _validarValor(
  ParametroDef d,
  Object valor,
  Catalogo catalogo,
  String ruta,
  List<Problema> problemas,
) {
  final texto = '$valor';
  switch (d.tipo) {
    case TipoParametro.longitud:
      if (valor is! num || !valor.isFinite) {
        return (valor, 'valor_invalido', texto);
      }
      final v = valor.toDouble();
      return (v, _enRango(d, v) ? null : 'fuera_de_rango', texto);
    case TipoParametro.entero:
      if (valor is! num || !valor.isFinite || valor != valor.truncate()) {
        return (valor, 'valor_invalido', texto);
      }
      final v = valor.toInt();
      return (v, _enRango(d, v) ? null : 'fuera_de_rango', texto);
    case TipoParametro.opcion:
      if (valor is! String) return (valor, 'valor_invalido', texto);
      return (
        valor,
        d.opciones.contains(valor) ? null : d.codigoOpcionInvalida,
        texto,
      );
    case TipoParametro.booleano:
      return (valor, valor is bool ? null : 'valor_invalido', texto);
    case TipoParametro.texto:
      if (valor is! String || valor.trim().isEmpty) {
        return (valor, 'valor_invalido', texto);
      }
      return (valor.trim(), null, texto);
    case TipoParametro.articulo:
      if (valor is! String) return (valor, 'valor_invalido', texto);
      if (!catalogo.contiene(valor)) {
        return (valor, 'articulo_desconocido', valor);
      }
      final a = catalogo.articulo(valor);
      final malTipo =
          d.tiposArticulo.isNotEmpty && !d.tiposArticulo.contains(a.tipo);
      final malFamilia =
          d.familias.isNotEmpty && !d.familias.contains(a.familia);
      return (
        valor,
        malTipo || malFamilia ? 'familia_no_permitida' : null,
        valor,
      );
    case TipoParametro.lista:
      if (valor is! List || valor.any((e) => e is! Map)) {
        return (valor, 'valor_invalido', texto);
      }
      final elementos = <Map<String, Object?>>[];
      for (var i = 0; i < valor.length; i++) {
        elementos.add(
          _validarNivel(
            d.campos,
            (valor[i] as Map).cast<String, Object?>(),
            catalogo,
            '$ruta[$i].',
            problemas,
          ),
        );
      }
      return (elementos, null, null);
  }
}

bool _enRango(ParametroDef d, num v) {
  if (d.min != null && v < d.min! - eps) return false;
  if (d.max != null && v > d.max! + eps) return false;
  return true;
}
