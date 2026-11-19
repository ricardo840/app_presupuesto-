/// Calibres de lámina y perfil (MOTOR_MEDICION §2.2).
library;

/// Espesor nominal en mm por calibre; semilla editable (la base de datos la
/// copia en F3-T5).
const Map<int, double> calibresMm = {
  10: 3.429,
  11: 3.048,
  12: 2.667,
  13: 2.286,
  14: 1.905,
  16: 1.524,
  18: 1.219,
  20: 0.914,
  22: 0.762,
  24: 0.610,
};

/// Espesor en mm del [calibre] según [tabla]; `null` si no existe.
double? espesorCalibreMm(int calibre, [Map<int, double> tabla = calibresMm]) =>
    tabla[calibre];
