---
paths:
  - "lib/motor/**"
  - "test/motor/**"
---

# Motor: Dart puro

- Imports permitidos: `dart:core`, `dart:math`, `dart:convert`, `dart:collection`, `package:collection`, `package:meta` y otros archivos de `lib/motor/`. Nada de Flutter, `dart:io`, `dart:ui`, base de datos ni red. Lo comprueba `test/arquitectura_test.dart`.
- Sin estado global, sin `DateTime.now()`, sin `Random`. Lo que dependa del momento entra como parámetro.
- Usa `techo`, `piso`, `redondear` y `centavos` de `lib/motor/numeros.dart`. No llames `ceil`, `floor`, `round` ni `toStringAsFixed` para calcular.
- Longitudes en mm, pesos en kg, áreas en m². Documenta con `///` la unidad de cada campo y de cada parámetro público.
- El dinero que sale del motor es `int` en centavos. Dentro de las cantidades va en pesos `double` sin redondear, porque es entrada de las fórmulas.
- Modelos inmutables, con `fromJson` y `toJson` escritos a mano y sin generación de código. El orden de los campos en `toJson` es fijo.
- Orden determinista: conserva el orden de aparición; si ordenas, que el ordenamiento sea estable.
- Los códigos de error y de advertencia son los de la especificación, tal cual (`claro_insuficiente`, `ciclo`). Son parte del contrato: no se traducen ni se renombran.
- Plantilla nueva o cambio de reglas: primero el documento, después las pruebas, después el código. Usa `/nueva-plantilla`.
- Si un dorado no coincide, el error está en tu código hasta que demuestres lo contrario con aritmética. Ver `.claude/rules/pruebas.md`.
- `calcularPresupuesto` de un trabajo típico debe tardar menos de 50 ms en un teléfono de gama media. Nada cuadrático sobre las piezas.
