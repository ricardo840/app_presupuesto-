---
name: cierre-de-fase
description: Cierra una fase del plan del cotizador de herrería. Comprueba que todo lo de la fase está hecho y verificado, escribe la lista de prueba manual para Lino, etiqueta el repositorio y prepara la fase siguiente. Úsalo cuando todas las casillas de una fase estén marcadas.
argument-hint: "[número de fase]"
---

# Cierre de fase $ARGUMENTS

1. **Comprueba.** Todas las casillas de la fase están marcadas en `docs/PLAN.md` y cada una tiene su commit. Ejecuta el procedimiento `verify` completo.
2. **Revisa contra la especificación.** Recorre los requisitos de `docs/ESPECIFICACION.md` §5 que la fase dice cubrir. Para cada uno anota dónde se cumple (archivo y prueba). Lo que falte se vuelve una tarea nueva al inicio de la fase siguiente; no lo des por hecho.
3. **Construye.** Si el equipo lo permite: `flutter build apk --debug`. Si no se puede, dilo y explica por qué.
4. **Escribe la prueba manual.** En `docs/PROGRESO.md`, bajo "Para probar en el teléfono — fase N", una lista de 5 a 12 pasos concretos con el resultado esperado de cada uno. Empieza por lo que no pudiste verificar en dispositivo.
5. **Resume.** En la misma entrada: qué se construyó, qué decisiones se tomaron por defecto, qué quedó pendiente y qué necesita Lino responder antes o durante la fase siguiente.
6. **Etiqueta.** Commit `fase-N: cierre` y `git tag fase-N`.
7. **Prepara lo que sigue.** Lee completa la fase siguiente en `docs/PLAN.md`. Si con lo aprendido alguna tarea ya no tiene sentido, está mal ordenada o le falta un paso, corrige el plan y deja una línea en `docs/DECISIONES.md` con el motivo.
8. **Continúa** con la primera tarea de la fase siguiente. No esperes la revisión de Lino: sus observaciones llegarán a "Correcciones de Lino" y se atienden primero en cuanto aparezcan.

Al cerrar la última fase, en lugar del paso 8 entrega el resumen final: la tabla de requisitos con su estado y lo que quedó fuera.
