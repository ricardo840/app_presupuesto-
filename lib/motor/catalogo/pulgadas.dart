/// Medidas comerciales en pulgadas (MOTOR_MEDICION §2.2).
library;

import '../error_motor.dart';
import '../numeros.dart';

/// Milímetros por pulgada.
const double mmPorPulgada = 25.4;

/// Tolerancia en mm para considerar que una medida es un dieciseisavo.
const double _tolerancia = 0.01;

final RegExp _decimal = RegExp(r'^\d+(\.\d+)?$');
final RegExp _fraccion = RegExp(r'^(\d+)/(\d+)$');
final RegExp _mixta = RegExp(r'^(\d+)(?: +|-)(\d+)/(\d+)$');

/// Convierte [texto] en pulgadas (`2`, `3/4`, `1 1/2`, `1-1/2`, `1.5`, con
/// espacios alrededor y `"` final opcional) a mm.
///
/// Lanza `ErrorMotor('medida_invalida')` con [texto] en el detalle si no es
/// una medida o no da más de cero. En la forma mixta la fracción debe ser
/// propia y el guion no lleva espacios (`1 - 1/2` es inválido).
double pulgadasAMm(String texto) {
  final error = ErrorMotor('medida_invalida', detalle: texto);
  var t = texto.trim();
  if (t.endsWith('"')) t = t.substring(0, t.length - 1).trim();

  // Un número con demasiados dígitos no cabe en int: también es inválido.
  int entero(String? s) => int.tryParse(s!) ?? (throw error);

  double pulgadas;
  final mixta = _mixta.firstMatch(t);
  final fraccion = _fraccion.firstMatch(t);
  if (_decimal.hasMatch(t)) {
    pulgadas = double.parse(t);
  } else if (fraccion != null) {
    final den = entero(fraccion.group(2));
    if (den == 0) throw error;
    pulgadas = entero(fraccion.group(1)) / den;
  } else if (mixta != null) {
    final numerador = entero(mixta.group(2));
    final den = entero(mixta.group(3));
    if (den == 0 || numerador >= den) throw error;
    pulgadas = entero(mixta.group(1)) + numerador / den;
  } else {
    throw error;
  }
  if (!(pulgadas > 0)) throw error;
  return pulgadas * mmPorPulgada;
}

int _mcd(int a, int b) => b == 0 ? a : _mcd(b, a % b);

/// Escribe [mm] en dieciseisavos simplificados (`2`, `3/4`, `1 1/2`,
/// `1 3/16`) si queda a menos de 0.01 mm de uno; si no, `null`.
String? mmATextoPulgadas(double mm) {
  if (!(mm > 0)) return null;
  final n = redondear(mm / mmPorPulgada * 16).toInt();
  if (n == 0) return null;
  if ((n * mmPorPulgada / 16 - mm).abs() >= _tolerancia) return null;
  final enteras = n ~/ 16;
  final resto = n % 16;
  if (resto == 0) return '$enteras';
  final d = _mcd(resto, 16);
  final frac = '${resto ~/ d}/${16 ~/ d}';
  return enteras == 0 ? frac : '$enteras $frac';
}
