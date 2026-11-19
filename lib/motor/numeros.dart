/// Funciones numéricas base del motor (MOTOR_MEDICION §1, MOTOR_RECETAS §1).
library;

/// Tolerancia para absorber el ruido binario en conteos y comparaciones.
const double eps = 1e-9;

/// Empuje que absorbe el ruido binario al redondear dinero.
const double _empuje = 1e-7;

/// Techo tolerante: `ceil(x − eps)`. [x] sin unidad; devuelve un conteo.
int techo(double x) => (x - eps).ceil();

/// Piso tolerante: `floor(x + eps)`. [x] sin unidad; devuelve un conteo.
int piso(double x) => (x + eps).floor();

/// Una longitud "cabe" si [largo] <= [limite] + [eps]. Ambos en mm.
bool cabe(double largo, double limite) => largo <= limite + eps;

/// Redondeo comercial: la mitad se aleja de cero, con un empuje para el
/// ruido binario. [decimales] es el número de decimales que se conservan.
double redondear(double x, [int decimales = 0]) {
  var factor = 1.0;
  for (var i = 0; i < decimales; i++) {
    factor *= 10;
  }
  final n = ((x.abs() * factor) + 0.5 + _empuje).floor();
  if (n == 0) return 0.0; // evita -0.0
  final r = n / factor;
  return x < 0 ? -r : r;
}

/// Convierte pesos [x] a centavos enteros con el redondeo comercial.
int centavos(double x) {
  final n = ((x.abs() * 100) + 0.5 + _empuje).floor();
  return x < 0 ? -n : n;
}
