# Progreso

Bitácora del proyecto. La escribe el agente al terminar cada tarea. La entrada más reciente va **al final**. Al empezar una sesión se leen solo las dos últimas.

Formato de una entrada:

```
## AAAA-MM-DD · F1-T3 · Optimizador de cortes
- Hecho: qué se construyó, en una o dos líneas.
- Verificación: resultado de verify (número de pruebas) y commit.
- Decisiones: lo que se eligió y no estaba escrito. Si fue una decisión de fondo, va también a DECISIONES.md.
- Sin verificar en dispositivo: lo que necesita un teléfono para probarse.
- Para revisar por Lino: cambios a dorados, supuestos del oficio, cosas raras.
- Sigue: la siguiente tarea.
```

Solo se incluyen los renglones que tengan algo que decir. Al cerrar una fase se agrega una entrada "Cierre de fase N" con el resumen y la lista "Para probar en el teléfono".

---

## 2026-11-13 · Kit inicial

- Hecho: reglas, especificación, plan, casos dorados y oráculo. Todavía no existe el proyecto de Flutter.
- Verificación: `python tool/oraculo/oraculo.py --verificar` da `ok` en los 9 archivos de `test/fixtures/dorados/`.
- Para revisar por Lino: las decisiones de `docs/PENDIENTES_LINO.md`. Las más urgentes son P-01 (nombre e identificador), P-03 (estilo) y P-04 (qué significa "Opciones").
- Sigue: F0-T1.
