---
name: verify
description: Verificación obligatoria antes de cada commit del cotizador de herrería. Comprueba formato, análisis estático, pruebas y casos dorados. Úsalo al terminar cualquier cambio de código y antes de marcar una tarea como hecha.
---

# Verificar

Ejecuta todo, en este orden, desde la raíz del repositorio. Un paso en rojo detiene el commit.

1. **Código generado.** Solo si cambiaste tablas de Drift u otro archivo con generación:
   `dart run build_runner build --delete-conflicting-outputs`
2. **Formato.** `dart format --output=none --set-exit-if-changed lib test tool`
   Si marca diferencias: `dart format lib test tool` y vuelve a comprobar.
3. **Análisis.** `flutter analyze`
   Debe terminar sin errores, advertencias ni avisos. No silencies una regla con `// ignore` sin explicar el motivo en la misma línea.
4. **Pruebas.** `flutter test`
   Todas en verde. Ninguna saltada sin una razón escrita junto al `skip`.
5. **Oráculo.** Solo si tocaste `lib/motor/`, `test/fixtures/` o `tool/oraculo/`:
   `python tool/oraculo/oraculo.py --verificar` (en Linux y macOS, `python3`)
   Si no hay Python en el equipo, dilo en el reporte; no es motivo para detener el commit.
6. **Repaso del diff.** `git diff --stat` y una lectura rápida del diff completo. Busca:
   - archivos que no son de la tarea;
   - claves, rutas personales o datos de clientes;
   - `print`, código comentado y `TODO` sin identificador de tarea;
   - cambios en `test/fixtures/` o `tool/oraculo/` que no pasaron por el procedimiento de excepción.

Antes de la fase 0 no hay proyecto de Flutter: en ese caso solo aplican los pasos 5 y 6.

## Reporte

Termina con una tabla breve: cada paso, su resultado y, si algo falló, el primer error textual. No digas que está en verde si no ejecutaste el comando en esta sesión.
