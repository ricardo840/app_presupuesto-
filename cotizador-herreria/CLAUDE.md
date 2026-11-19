@AGENTS.md

## Claude Code

Las instrucciones del proyecto están en `AGENTS.md`, que se carga con la línea de arriba. Esto es lo propio de Claude Code.

### Quién hace qué

- **La sesión principal es el director del proyecto y corre con Fable.** Decide, escribe encargos, revisa y cierra. Escribe poco código: lo delega.
- **Los subagentes de `.claude/agents/` ejecutan** con modelos más económicos: `implementador` (Sonnet) para el código de cada tarea, `mecanico` (Haiku) para lo repetitivo, `revisor` (Sonnet) para leer cambios y `Explore` (Haiku) para buscar.
- Cómo se encarga, se revisa y se ahorra está en `docs/DIRECCION.md`. Léelo antes de delegar por primera vez en una sesión.
- Si eres un subagente, tu papel y tus límites están en tu definición: no diriges, no eliges tareas y no haces commit.

### Lo demás

- Los procedimientos de `.claude/skills/` están disponibles como comandos: `/continuar`, `/verify`, `/nueva-plantilla`, `/cierre-de-fase` y `/estado`.
- Las reglas de `.claude/rules/` se cargan solas al abrir archivos de cada carpeta.
- `.claude/settings.json` fija el modelo de la sesión (`fable`), el modelo por defecto de los subagentes (`sonnet`) y los permisos: las ediciones y los comandos de Flutter, Dart y git local corren sin preguntar; `git push` siempre pregunta.
- Si cambias una regla, cámbiala en `AGENTS.md`, en `docs/DIRECCION.md` o en `.claude/rules/`, no aquí.
