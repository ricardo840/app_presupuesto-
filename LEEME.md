# Cotizador de herrería — cómo empezar

Este paquete trae todo lo que una IA de programación necesita para construir la app de principio a fin: reglas, especificación, plan con tareas, y casos de prueba con resultados ya calculados. Todavía no hay código de la app; eso lo escribe la IA siguiendo el plan.

## Qué trae

```
AGENTS.md                 reglas del proyecto (las lee cualquier agente)
CLAUDE.md                 carga AGENTS.md y agrega lo propio de Claude Code
LEEME.md                  este archivo
.claude/
  settings.json           modelo, permisos y modelo por defecto de los subagentes
  agents/                 subagentes: implementador, mecanico, revisor, Explore
  rules/                  reglas por carpeta: motor, datos, interfaz, ia, visual, pruebas…
  skills/                 procedimientos: continuar, verify, nueva-plantilla, cierre-de-fase, estado
docs/
  PLAN.md                 13 fases, 82 tareas, cada una con su "Hecho cuando"
  ESPECIFICACION.md       qué hace la app, pantallas, flujos y requisitos
  ARQUITECTURA.md         capas, carpetas y dependencias
  MOTOR_MEDICION.md       plantillas, despiece, cortes y cantidades
  MOTOR_RECETAS.md        fórmulas, formas de cobrar, redondeo y presentación
  MODELO_DE_DATOS.md      tablas, estados, instantáneas y respaldo
  VISUAL.md               plano, 3D, montaje sobre foto, PDF y render
  IA_Y_VOZ.md             voz, intérprete y proveedores
  DIRECCION.md            cómo Opus dirige y delega a modelos más económicos
  GLOSARIO.md             palabras del oficio y su nombre en el código
  PENDIENTES_LINO.md      lo que solo tú decides (con valores por defecto)
  PROGRESO.md             bitácora que escribe la IA
  DECISIONES.md           qué se decidió y por qué
test/fixtures/            entradas y resultados esperados ("dorados") del motor
tool/oraculo/oraculo.py   implementación de referencia que generó los dorados
```

## Antes de empezar

En tu computadora necesitas Flutter, Git y, de preferencia, Python (solo para comprobar los casos de prueba con el oráculo).

1. Crea la carpeta del repositorio y copia ahí **todo** el contenido de este paquete, incluida la carpeta `.claude` (empieza con punto; en Windows puede estar oculta).
2. Abre `docs/PENDIENTES_LINO.md` y responde lo que puedas. Si no respondes nada, la IA usa los valores por defecto. Lo que más conviene decidir desde ahora: **P-01** (nombre e identificador de la app), **P-03** (estilo) y **P-04** (qué entiendes por "Opciones").
3. Si puedes, consigue lo de la sección "Lo que hace falta del herrero". No detiene nada, pero mientras falte la app cotiza con formas de cobrar y precios de ejemplo.

## Arrancar

### Con Claude Code

1. Abre la carpeta del repositorio con Claude Code. Instalación: https://code.claude.com/docs/en/quickstart
2. La primera vez te pedirá confiar en la carpeta y te mostrará los permisos de `.claude/settings.json`. Revísalos y acepta.
3. El proyecto pide el modelo **Opus** para la sesión principal. Si no lo toma solo, escribe `/model opus`.
4. Escribe:

```
/continuar
```

Con eso lee las reglas, toma la primera tarea del plan y sigue trabajando tarea por tarea. Cuando una sesión termine o la cierres, abre otra y vuelve a escribir `/continuar`: retoma donde quedó.

### Con otra IA

Si tu herramienta lee `AGENTS.md` por su cuenta, basta con abrir la carpeta. En cualquier caso, este primer mensaje funciona con todas:

```
Lee AGENTS.md completo y sigue sus instrucciones. Después abre .claude/skills/continuar/SKILL.md
y aplica ese procedimiento: toma la siguiente tarea de docs/PLAN.md y trabaja hasta cerrar la fase en curso.
```

Los subagentes y los permisos de `.claude/` son de Claude Code; con otra herramienta el plan funciona igual, con un solo modelo.

## Quién hace qué (y cuánto cuesta)

- **Opus dirige**: elige la tarea, escribe el encargo, revisa y hace el commit.
- **Sonnet implementa y revisa**; **Haiku** hace lo mecánico y las búsquedas. Están definidos en `.claude/agents/` y cada uno trae su modelo fijo.
- Las reglas del reparto están en `docs/DIRECCION.md`. Para cambiar qué modelo usa cada papel, edita la línea `model:` de su archivo.
- Si prefieres otro modelo para la sesión principal, cambia la línea `"model": "opus"` de `.claude/settings.json` o elígelo con `/model`.
- Para ver qué modelo está usando cada subagente: `/tasks`.

Dos hábitos que ahorran: abre una sesión nueva al terminar cada bloque de trabajo (el contexto acumulado se paga en cada mensaje) y deja que avance varias tareas seguidas en lugar de pedirle cosas sueltas.

## Tu parte mientras avanza

- **Para saber cómo va**: escribe `/estado`, o lee el final de `docs/PROGRESO.md`.
- **Al cerrar cada fase** la IA deja en `docs/PROGRESO.md` una lista "Para probar en el teléfono". Pruébala. La IA no puede usar el micrófono, la cámara ni compartir por WhatsApp; eso solo lo puedes comprobar tú.
- **Si algo está mal**, escríbelo en "Correcciones de Lino" de `docs/PENDIENTES_LINO.md`. Es lo primero que atiende en la siguiente sesión.
- **Si se equivoca dos veces en lo mismo**, agrégalo como regla en `AGENTS.md` o en el archivo de `.claude/rules/` que corresponda. Las reglas concretas funcionan mejor que las generales.
- **Nunca sube nada por su cuenta**: `git push` siempre te pide permiso.

## Qué es lo que protege el resultado

- **Casos dorados.** `test/fixtures/dorados/` trae cinco trabajos completos (una reja, tres portones y un barandal capturado a mano) con sus piezas, cortes, kilos y precios al centavo, más 99 casos del lenguaje de fórmulas, 10 de cortes y 25 de recetas (23 de ellas mal formadas a propósito). El motor tiene que reproducirlos exactos.
- **El oráculo.** `tool/oraculo/oraculo.py` los generó. Para comprobarlo: `python tool/oraculo/oraculo.py --verificar`.
- **Los precios y tarifas de esas pruebas son ficticios.** Sirven para comprobar las cuentas, no para cotizar.
- **Verificación antes de cada commit**: formato, análisis, pruebas y oráculo.

## Orden de lo que vas a ver

| Al cerrar la fase | Ya puedes |
|---|---|
| 2 | nada en pantalla todavía; el motor calcula y pasa todos los casos |
| 4 | instalar la app, cargar precios, definir tu forma de cobrar y cotizar |
| 5 | enseñar el plano, mandar el PDF por WhatsApp y montar el dibujo sobre la foto de la casa |
| 6 | girar el trabajo en 3D y cambiarle el acabado |
| 7 | cotizar hablando y proponer desde una foto |
| 8 | comparar opciones y enseñarle a la app cómo cobra el herrero |
| 9 | cotizar puertas, corredizos, barandales, techumbres, escaleras y bases de tinaco |
| 10 | pedir una imagen fotorrealista |
