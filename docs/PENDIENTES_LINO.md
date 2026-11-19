# Pendientes de Lino

Lo que solo tú puedes decidir o conseguir. El agente no se detiene por esto: usa el valor **por defecto** y sigue. Cuando respondas, escribe tu respuesta en el renglón "Respuesta" y el agente la toma en la siguiente sesión.

## Decisiones

**P-01 · Nombre e identificador de la app** — antes de F0-T2
Por defecto: nombre visible "Cotizador de herrería"; organización `mx.lino` (la app queda como `mx.lino.cotizador_herreria`). El identificador conviene decidirlo antes de instalar en el teléfono: cambiarlo después obliga a reinstalar y restaurar el respaldo.
Respuesta: nombre visible **LinForge** (2026-11-19). Identificador: pendiente.

**P-02 · Teléfono o tableta** — antes de la fase 4
Por defecto: teléfono Android en vertical; debe verse bien también en tableta.
Respuesta:

**P-03 · Estilo visual** — antes de la fase 4
Por defecto: componentes de estilo Cupertino, con tema claro y oscuro. Se puede cambiar a Material sin rehacer las pantallas, porque todas usan los componentes de `lib/ui/componentes/`.
Respuesta:

**P-04 · Qué significa "Opciones"** — antes de la fase 4
Pediste tres secciones: anteriores, opciones y pendientes. Por defecto, "Opciones" reúne (a) los modelos o simulaciones guardados para enseñar o reutilizar, sin cliente, y (b) los presupuestos con varias alternativas por decidir, que se comparan lado a lado. Si pensabas en otra cosa, dilo aquí.
Respuesta:

**P-05 · Datos del negocio para el PDF** — antes de la fase 5
Nombre del taller, teléfono, logo, anticipo habitual (%), vigencia del presupuesto (días), texto de garantía y si se cobra IVA.
Por defecto: campos vacíos que se llenan en Ajustes; 50 % de anticipo; 15 días de vigencia; sin IVA.
Respuesta:

**P-06 · Servicio de IA para interpretar voz, texto y fotos** — antes de la fase 7
Por defecto: API de Claude con tu propia clave, capturada en Ajustes. Mientras no haya clave, todo se construye y se prueba con dobles.
Respuesta:

**P-07 · Voz** — antes de la fase 7
Por defecto: el reconocimiento y la voz del propio teléfono (sin costo). Opción: un servicio en la nube que entienda mejor la jerga, con costo.
Respuesta:

**P-08 · Dónde corre el render de Blender** — antes de la fase 10
Opciones: tu PC, si tiene tarjeta de video dedicada, o un servidor rentado con GPU.
Por defecto: se construye para correr en tu PC y se deja listo para mover a un servidor.
Respuesta:

**P-09 · Servicio para armonizar el montaje con IA** — antes de F10-T3
Por defecto: ninguno. Se deja la interfaz y un doble; el montaje sin IA funciona siempre.
Respuesta:

**P-10 · Repositorio remoto** — cuando quieras
¿Subir el repositorio a GitHub como privado? El agente nunca hace `git push` sin que lo pidas.
Por defecto: solo local.
Respuesta:

**P-11 · Fases opcionales** — al cerrar la fase 10
Conversación de voz en tiempo real, realidad aumentada, escalera de caracol y ornamentos.
Por defecto: no se hacen.
Respuesta:

## Lo que hace falta del herrero

Sin esto la app funciona, pero cotiza con recetas y precios de ejemplo.

**H-01 · De 3 a 5 cotizaciones reales recientes**, con medidas, materiales, precio cobrado y, si se puede, cómo lo calculó. Con eso se calibra su forma de cobrar (fase 8; se puede adelantar en cuanto cierre la fase 2).
Respuesta:

**H-02 · Lista de los materiales que más usa y a cuánto los compra hoy**, y si compra por tramo o por kilo.
Respuesta:

**H-03 · Qué considera al cotizar que no esté en la app**: ¿viáticos?, ¿ayudante?, ¿galvanizado?, ¿renta de andamio?, ¿urgencia? Cada cosa se vuelve un dato del trabajo o una tarifa.
Respuesta:

**H-04 · Cómo le gusta presentar el precio**: ¿solo el total?, ¿material y mano de obra por separado?
Respuesta:

## Para validar con el herrero

Supuestos del oficio que el agente tomó al especificar plantillas. Cada uno con el valor usado.

- Reja de ventana: 1 solera de amarre y 4 anclas por defecto; separación máxima entre barrotes de 12 cm.
- Portón: 2 bisagras por hoja hasta 2.00 m de alto y 3 si es más alta; lámina sobrepuesta por fuera; puntos de soldadura cada 15 cm.
- Corte: se pierden 3 mm por corte; tramos de 6.00 m.
- Rendimientos de la receta de ejemplo `despiece`: 4 minutos por corte, 3 por unión y media hora de pintura por metro cuadrado. Son de ejemplo.

## Correcciones de Lino

Escribe aquí lo que veas mal al probar. El agente lo atiende antes que cualquier otra tarea y lo marca como atendido.

- (vacío)

## Bloqueos

Lo que el agente no pudo resolver después de tres intentos. Lo escribe el agente.

- (vacío)

## Preguntas nuevas

Dudas que surgieron al trabajar. El agente las escribe con el valor que usó mientras tanto.

- (vacío)
