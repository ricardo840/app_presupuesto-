---
paths:
  - "test/**"
  - "tool/oraculo/**"
---

# Pruebas

- La carpeta `test/` refleja a `lib/`. Los nombres de `group` y `test` van en español y describen el comportamiento: `'una pieza más larga que el tramo se parte y suma un empalme'`.
- Entradas en `test/fixtures/entradas/`, resultados esperados en `test/fixtures/dorados/`. Cárgalos con un ayudante común en `test/soporte/`.
- Tolerancias: conteos exactos; longitudes, pesos y áreas con diferencia absoluta menor que `1e-5`; dinero exacto en centavos.
- Los números de un JSON pueden llegar como entero o decimal: convierte con `(x as num).toDouble()`.
- Sin red, sin reloj real, sin esperas. Todo lo externo (IA, voz, cámara, almacenamiento seguro, compartir) se prueba con dobles que implementan la misma interfaz.
- Nunca se llama a un servicio de pago desde una prueba automática. Las respuestas reales de un proveedor se graban una vez, sin datos personales ni claves, en `test/fixtures/grabaciones/`.
- Base de datos: Drift en memoria.
- Widgets: prueba lo que hace la pantalla, no sus pixeles. Las imágenes de referencia solo se usan donde sean estables.
- Una prueba que falla no se borra, no se salta y no se debilita para avanzar.

## Dorados y oráculo

Los archivos de `test/fixtures/` y `tool/oraculo/oraculo.py` son el contrato del motor. Si una prueba contra un dorado falla:

1. Detente. No toques el dorado ni el oráculo.
2. Haz la cuenta a mano, paso por paso, citando la sección de la especificación. Escríbela en `docs/DECISIONES.md` y concluye cuál está mal: tu código, el oráculo o el documento.
3. Si es tu código, que es lo normal, corrígelo.
4. Si es el oráculo o el documento: corrige el que esté mal, ejecuta `python tool/oraculo/oraculo.py --generar`, revisa línea por línea el diff de `test/fixtures/dorados/` y haz un commit aparte titulado `dorados: <motivo>`. Anótalo en `docs/PROGRESO.md` bajo "Para revisar por Lino".
5. Un valor esperado nunca se cambia a mano: siempre sale del oráculo.

Para una plantilla o regla nueva, el caso dorado se calcula dos veces: a mano en el documento y en el oráculo. Los dos resultados deben coincidir antes de escribir el código en Dart.

Al generar, el oráculo falla si algún valor de dinero queda a menos de una milésima de centavo de un empate de redondeo. Si pasa, cambia un dato del caso (una medida o un precio de prueba), no el redondeo.
