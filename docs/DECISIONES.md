# Decisiones

Registro corto de lo que se decidió y por qué. Se agrega al final. Una decisión no se borra: si cambia, se escribe otra que la sustituye y se cita la anterior.

Formato: `D-NNN · fecha · decisión` y, debajo, el motivo y lo que se descartó.

---

**D-001 · 2026-11-13 · Un solo modelo paramétrico para precio e imagen.**
La IA no dibuja ni calcula: traduce a parámetros. Un motor determinista produce las piezas, y de ellas salen el precio, el despiece, los cortes y todo lo visual. Así lo que ve el cliente coincide con lo que se cobra. Se descartó generar la imagen desde un texto: no respeta medidas ni número de barrotes.

**D-002 · 2026-11-13 · El motor es Dart puro y tiene una sola puerta de entrada.**
`lib/motor/` no importa Flutter ni toca disco o red; todo pasa por `calcularPresupuesto`. Se prueba rápido, corre sin conexión y no puede haber dos cálculos distintos del mismo presupuesto.

**D-003 · 2026-11-13 · Dinero en centavos enteros y redondeo comercial con empuje.**
Cada línea se redondea al calcularse y los agregados suman líneas ya redondeadas, para que lo mostrado sume exacto. Se descartó una biblioteca de decimales: las fórmulas mezclan medidas en punto flotante y habría que convertir en cada paso.

**D-004 · 2026-11-13 · La forma de cobrar es una receta configurable.**
No se sabe cómo cotiza el herrero y puede variar. Una receta es una lista de conceptos con fórmulas sobre las cantidades que mide el motor. Los precios y las tarifas van aparte de las fórmulas.

**D-005 · 2026-11-13 · Evaluador de fórmulas propio.**
Hacen falta mensajes de error en español con posición, extraer las dependencias para ordenar el cálculo, el literal de porcentaje y evaluación perezosa en `si`. Se consideró el paquete `expressions`: habría que envolverlo para lograr lo mismo y le agregaría una dependencia al motor, que debe quedar casi sin ellas. El lenguaje es pequeño y su comportamiento está fijado por `dorados/casos_formulas.json`.

**D-006 · 2026-11-13 · Casos dorados y oráculo en Python.**
Los resultados esperados salen de una implementación de referencia independiente del código en Dart. Cada plantilla nueva se calcula dos veces: a mano y en el oráculo.

**D-007 · 2026-11-13 · Unidades internas en milímetros; nombres del dominio en español sin acentos.**
Evita conversiones a mitad del cálculo y traducciones forzadas del vocabulario del oficio.

**D-008 · 2026-11-13 · SQLite con Drift; recetas con versiones; instantánea al enviar.**
Un presupuesto enviado guarda todo lo necesario para reproducirse. Cambiar precios o recetas no altera cotizaciones viejas.

**D-009 · 2026-11-13 · 3D con three.js dentro de un WebView.**
El 3D nativo de Flutter (`flutter_scene`) seguía en vista previa y pedía el canal de desarrollo. La escena es un JSON que también entiende el servidor de render. Revisar esta decisión al llegar a la fase 6.

**D-010 · 2026-11-13 · Montaje sobre la foto por cuatro puntos, sin IA.**
Es inmediato, funciona sin conexión y respeta las medidas. La IA solo se usa después, de forma opcional, para armonizar la luz.

**D-011 · 2026-11-13 · La IA propone acciones; el usuario confirma; las cifras las dice la app.**
El modelo indica qué valores leer, no cuánto valen.

**D-012 · 2026-11-13 · Sin servidor propio, salvo el de render.**
App personal: los servicios de IA se llaman desde el teléfono con la clave del usuario, guardada en el almacenamiento seguro.

**D-013 · 2026-11-13 · Android como objetivo; Windows como plataforma de desarrollo si está disponible.**
El equipo de Lino es Windows, desde donde no se compila para iOS.

**D-014 · 2026-11-13 · Fable dirige y delega a modelos más económicos.**
La sesión principal decide, encarga y revisa; Sonnet implementa y revisa; Haiku hace lo mecánico y las búsquedas. Los dorados y `verify` son la red de seguridad. Detalle en `docs/DIRECCION.md`.

**D-015 · 2026-11-13 · Las reglas viven en `AGENTS.md`; `CLAUDE.md` solo las importa.**
Para que el proyecto funcione igual con cualquier agente de programación.

**D-016 · 2026-11-19 · Opus dirige en lugar de Fable. Sustituye a D-014 en el modelo del director.**
Lo decidió Lino. El reparto no cambia: Opus decide, encarga y revisa; Sonnet implementa y revisa; Haiku hace lo mecánico y las búsquedas.

**D-017 · 2026-11-19 · El proyecto vive en la raíz del repositorio.**
El kit estaba en la subcarpeta `cotizador-herreria/` y Claude Code no cargaba `.claude/` al abrir el repositorio. Se movió a la raíz con `git mv`, sin cambiar el contenido.

**D-018 · 2026-11-19 · La app se llama LinForge.**
Respuesta de Lino a P-01 (nombre visible). El identificador se fija antes de F0-T2.
