---
name: continuar
description: Continúa el desarrollo del cotizador de herrería. Toma la siguiente tarea de docs/PLAN.md, la implementa con pruebas, la verifica, hace commit y sigue con la próxima. Úsalo cuando Lino diga "continúa", "sigue", "sigue con el plan", o al empezar una sesión de trabajo.
argument-hint: "[tarea opcional, por ejemplo F2-T3]"
---

# Continuar con el plan

Tarea pedida (puede venir vacío): $ARGUMENTS

## 1. Ubícate

1. Lee las dos últimas entradas de `docs/PROGRESO.md`.
2. Lee "Correcciones de Lino" y "Bloqueos" en `docs/PENDIENTES_LINO.md`.
3. Abre `docs/PLAN.md` y localiza la fase en curso: la primera que tenga casillas sin marcar.
4. Ejecuta `git status`. Si hay cambios sin commit de una sesión anterior, revísalos: termínalos si están bien encaminados o descártalos con `git restore .` si no. Anota lo que decidas.
5. Ejecuta `flutter --version`. Si falla, detente y explica qué falta. En la fase 0 el proyecto todavía no existe: eso es normal.

## 2. Elige la tarea

- Si hay correcciones de Lino sin atender, van primero. Cada corrección se trata como una tarea: pruebas, verificación, commit, y se marca como atendida.
- Si se pidió una tarea concreta, toma esa.
- Si no, toma la primera sin marcar de la fase en curso.
- Si la tarea depende de una decisión de `docs/PENDIENTES_LINO.md` que sigue sin respuesta, usa el valor por defecto y escribe una línea en `docs/DECISIONES.md`.

## 3. Hazla

**Si puedes delegar a otros modelos (Claude Code):** eres el director. Sigue `docs/DIRECCION.md`: mira la sugerencia de la tarea (D, I, M, +R), escribe el encargo, lánzalo al subagente que corresponde y revisa lo que entrega. Lo marcado con D, y lo diminuto, lo haces tú.

**Si trabajas con un solo modelo**, o la tarea te toca a ti:

1. Lee las secciones que la tarea cita y las reglas de la carpeta que vas a tocar (`.claude/rules/`).
2. Escribe las pruebas que pide el "Hecho cuando". Ejecútalas y confirma que fallan por la razón correcta.
3. Escribe el código mínimo que las hace pasar. Después limpia.

En los dos casos:

4. Ejecuta el procedimiento `verify` antes del commit.
5. Si falla, corrige. Al tercer intento distinto sin éxito aplica la regla de "Cuándo detenerte" de `AGENTS.md`.

## 4. Ciérrala

1. `git add` de lo que corresponde a la tarea y `git commit -m "<ID>: <qué se hizo>"`.
2. Marca la casilla en `docs/PLAN.md`.
3. Agrega una entrada a `docs/PROGRESO.md` con el formato que está al inicio de ese archivo.
4. Haz commit de esos dos archivos junto con la tarea o inmediatamente después.

## 5. Sigue

Vuelve al paso 2 sin preguntar. Si se terminó la fase, sigue el procedimiento `cierre-de-fase` y continúa con la siguiente.

Detente solo en los casos de "Cuándo detenerte". Al detenerte, deja un resumen breve: qué quedó hecho, qué sigue y qué necesitas de Lino.
