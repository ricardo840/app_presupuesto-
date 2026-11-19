---
name: nueva-plantilla
description: Agrega una plantilla paramétrica al motor del cotizador de herrería (puerta, portón corredizo, barandal, techumbre, escalera, base de tinaco) o cambia las reglas de una existente. Úsalo cuando una tarea del plan pida una plantilla nueva o Lino diga "agrega la plantilla de…".
argument-hint: "<id de la plantilla, por ejemplo barandal>"
---

# Nueva plantilla: $ARGUMENTS

El orden importa: documento, cuentas, oráculo, pruebas y al final el código. Así el resultado esperado no depende de lo que programes.

## 1. Entiende el trabajo

- Lee `docs/MOTOR_MEDICION.md` §3, §4 y §8, y `docs/GLOSARIO.md`.
- Describe en cinco líneas cómo se fabrica ese trabajo: qué piezas lleva, cómo se unen y qué decide el herrero. Si algo del oficio no te consta, anótalo como supuesto.

## 2. Especifica

Agrega una sección a `docs/MOTOR_MEDICION.md` con el mismo formato de `reja_ventana`:

- tabla de parámetros: tipo, valor por defecto, rango, familias permitidas y significado;
- reglas numeradas con las fórmulas exactas de cada grupo de piezas: largo, corte y posición;
- uniones, herrajes, extras, `num_hojas` y `caja`;
- errores de validación y advertencias.

Cada supuesto sobre el oficio va a `docs/PENDIENTES_LINO.md`, en "Para validar con el herrero", con el valor que usaste mientras tanto.

## 3. Calcula un caso a mano

Elige medidas realistas y resuelve el caso paso a paso en el documento, como en §7: despiece, cortes, pesos, uniones y costo del material con el catálogo de prueba.

## 4. Llévalo al oráculo

1. Agrega la plantilla a `tool/oraculo/oraculo.py` y el trabajo a `test/fixtures/entradas/trabajos.json`.
2. `python tool/oraculo/oraculo.py --generar`
3. Compara el dorado nuevo con tu cuenta a mano. Deben coincidir. Si no coinciden, encuentra cuál de los dos está mal antes de seguir.
4. Confirma con `git diff` que los demás dorados no cambiaron.

## 5. Pruebas en Dart

- El caso dorado completo: modelo, despiece, cortes, cantidades y al menos una evaluación con la receta `despiece`.
- Un caso por cada error de validación y cada advertencia.
- Casos de borde: medidas mínimas y máximas, cero barrotes, una pieza más larga que el tramo.

## 6. Código

- `lib/motor/plantillas/<id>.dart`: esquema, validación y generación. Regístrala en el registro de plantillas.
- Agrega los términos nuevos a `docs/GLOSARIO.md` y la ayuda de cada parámetro al esquema; de ahí la toman el formulario y la IA.
- Comprueba que el plano 2D y la escena 3D la dibujan sin código especial. Si necesitan algo nuevo, el cambio va en el modelo de piezas.

## 7. Cierre

Procedimiento `verify`, commit `<ID>: plantilla <id>` y un commit aparte `dorados: plantilla <id>` para el oráculo y sus archivos.
