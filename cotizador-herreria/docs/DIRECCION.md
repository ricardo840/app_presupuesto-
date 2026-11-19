# Dirección del proyecto

Cómo se reparte el trabajo entre modelos para gastar menos sin perder calidad. Aplica a Claude Code; con otra herramienta, usa su mecanismo equivalente o trabaja con un solo modelo siguiendo `AGENTS.md`.

## 1. Papeles

| Papel | Modelo | Definición | Hace |
|---|---|---|---|
| **Director** | Fable (`fable`) | la sesión principal | decide, encarga, revisa y cierra |
| **Implementador** | Sonnet (`sonnet`) | `.claude/agents/implementador.md` | pruebas y código de una tarea ya especificada |
| **Mecánico** | Haiku (`haiku`) | `.claude/agents/mecanico.md` | trabajo repetitivo y de bajo riesgo |
| **Revisor** | Sonnet (`sonnet`) | `.claude/agents/revisor.md` | lee un cambio contra la especificación; no edita |
| **Explore** | Haiku (`haiku`) | `.claude/agents/Explore.md` | busca y localiza en el repositorio; no edita |

La idea: el modelo caro piensa poco y bien; los baratos leen y escriben mucho. Los casos dorados y el procedimiento `verify` son lo que permite delegar con confianza: un error del implementador se nota en una prueba, no en producción.

## 2. Lo que el director no delega

- Elegir la tarea y decidir cómo se parte.
- Definir un contrato que la especificación no fija: una interfaz entre capas, el formato de un JSON nuevo, el esquema de una tabla.
- Todo lo que toque `test/fixtures/`, `tool/oraculo/` o las reglas de los documentos del motor.
- Decidir qué hacer cuando un dorado falla.
- Elegir o cambiar una dependencia.
- Revisar el resultado, hacer el commit, marcar el plan y escribir el progreso.
- El cierre de fase y cualquier caso de "Cuándo detenerte" de `AGENTS.md`.

Tampoco se delega lo diminuto: si explicar el cambio cuesta más que hacerlo (menos de unas 20 líneas en un archivo que el director ya tiene a la vista), lo hace el director.

## 3. A quién se le encarga qué

| Trabajo | Quién |
|---|---|
| Código y pruebas de una tarea del plan con "Hecho cuando" claro | implementador |
| Corregir fallas de pruebas o del análisis en código recién escrito | el mismo implementador, continuando su sesión |
| Semillas y JSON de datos, textos de la app, `fromJson`/`toJson`, renombrados, mover archivos, ajustar formato | mecánico |
| Ejecutar `verify` completo y resumir el resultado | mecánico |
| Actualizar el glosario o la ayuda de parámetros después de un cambio ya decidido | mecánico |
| Leer un cambio grande contra la especificación antes del commit | revisor |
| "¿Dónde está…?", "¿qué archivos usan…?", "¿qué versión tiene…?" | Explore |
| Consultar documentación de un paquete o de un proveedor y traer un resumen | Explore o mecánico |

Cada tarea de `docs/PLAN.md` trae una sugerencia: **D** (director), **I** (implementador), **M** (mecánico), y **+R** cuando conviene pasar por el revisor. Es una guía; el director decide.

## 4. El encargo

Un encargo es un mensaje corto y completo. El subagente empieza en blanco: no vio la conversación ni lo que el director leyó. Recibe `AGENTS.md`, así que las convenciones no se repiten.

```
Tarea: F1-T3 · Optimizador de cortes
Objetivo: función pura que decide cuántos tramos comprar y cómo cortarlos.
Lee: docs/MOTOR_MEDICION.md §1 y §5; .claude/rules/motor.md; lib/motor/numeros.dart
Puedes tocar: lib/motor/medicion/cortes.dart, test/motor/medicion/cortes_test.dart
Contrato: PlanCortes optimizarCortes(List<double> largos, double tramo, double kerf)
          PlanCortes { int tramos; List<List<double>> barras; List<double> sobrantesMm;
                       int segmentos; int cortes; int empalmes; }
Pruebas: todos los casos de test/fixtures/dorados/casos_cortes.json; lista vacía; determinismo.
Hecho cuando: esas pruebas pasan; flutter analyze limpio; nada fuera de los archivos permitidos.
No hagas: commit, cambios en test/fixtures o tool/oraculo, dependencias nuevas.
Entrega: el reporte de tu definición.
```

Reglas del encargo:

- Rutas y secciones, no contenido pegado. El subagente lee lo que necesita.
- Archivos permitidos explícitos. Lo que no está en la lista no se toca.
- El contrato lo fija el director cuando otras tareas dependen de él.
- Una tarea por encargo. Si es grande, se parte en dos encargos seguidos.
- Si el siguiente paso del director depende del resultado, el subagente se lanza en primer plano (`run_in_background: false`).

## 5. Revisión y cierre

Cuando el subagente entrega:

1. `git status` y `git diff --stat`: solo los archivos permitidos.
2. Leer el diff. Completo en `lib/motor/` y `lib/datos/`. En interfaz y visual, las partes con lógica; para lo demás, el reporte del revisor.
3. Para tareas marcadas **+R**: encargar la lectura al revisor y leer su reporte en lugar del diff completo. En el motor se hacen las dos cosas.
4. Ejecutar las pruebas de la zona. El `verify` completo corre una vez, justo antes del commit; se le puede encargar al mecánico.
5. Comparar con el "Hecho cuando", punto por punto.
6. Si algo falla: corrección puntual al **mismo** subagente (se continúa su sesión; conserva su contexto y sale más barato que empezar otro). Máximo dos rondas.
7. Si después de dos rondas sigue mal: el director decide si el encargo estaba mal planteado (lo replantea) o si la tarea es difícil (la hace él). A la tercera falla aplica la regla de bloqueo de `AGENTS.md`.
8. Commit, casilla y progreso, por el director.

Un reporte que dice "todo en verde" no cuenta como verificación. Cuenta el comando que el director vio pasar.

## 6. Cómo ahorrar

- **Buscar con Explore**, no con el director. Una búsqueda amplia hecha por el modelo caro cuesta más que toda la tarea.
- **Leer por secciones.** Los documentos traen secciones numeradas para eso. El plan se lee por fase, el progreso por sus dos últimas entradas.
- **No releer.** Lo que ya está en el contexto de la sesión no se vuelve a abrir.
- **Reportes cortos.** Los subagentes devuelven 15 líneas, no archivos. Si el director necesita ver código, abre el archivo.
- **Pruebas dirigidas primero** (`flutter test test/motor/medicion`), completas al final.
- **Salidas compactas.** Cuando una corrida imprime mucho, pide el reporte más breve que ofrezca tu versión de `flutter test` (uno que solo liste las fallas) o encarga la corrida al mecánico y lee su resumen.
- **Una sesión por bloque de trabajo.** Al terminar una tarea grande o una fase, conviene empezar una sesión nueva: el contexto acumulado se paga en cada mensaje.
- **Escribir de uno en uno.** Dos subagentes no editan al mismo tiempo. En paralelo solo se lanza trabajo de lectura.
- **No subir de modelo para "ver si sale".** Si un subagente no puede con una tarea, el problema casi siempre es el encargo.

## 7. Cuándo trabaja el director solo

- Fase 0, hasta que exista el proyecto y pase `verify`.
- Tareas marcadas **D**.
- Cuando no haya subagentes disponibles (otra herramienta, o un plan sin esos modelos): el flujo de `AGENTS.md` funciona igual con un solo modelo.

## 8. Ajustes que lo sostienen

En `.claude/settings.json`:

- `"model": "fable"` hace que la sesión principal arranque con Fable.
- `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` hace que cualquier subagente sin modelo propio use Sonnet y no el modelo del director.

Cada definición de `.claude/agents/` fija su modelo en la primera sección del archivo (`model:`). Para cambiar el reparto se edita ahí.
