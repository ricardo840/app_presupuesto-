# Plan

Trece fases. Cada tarea tiene un identificador, una sugerencia de quién la hace y un "Hecho cuando" que se puede comprobar. Se trabaja en orden; una tarea se marca solo cuando cumple todo lo de `AGENTS.md`, "Una tarea está terminada cuando".

**Quién** (ver `docs/DIRECCION.md`): **D** director · **I** implementador · **M** mecánico · **+R** pasa por el revisor antes del commit · **D→I** el director fija el contrato y el implementador programa. Con un solo modelo, ignora esta marca.

| Fase | Resultado | Tareas |
|---|---|---|
| 0 | Proyecto creado y verificable | 4 |
| 1 | Motor de medición con reja, portón y trabajo libre | 10 |
| 2 | Motor de recetas y `calcularPresupuesto` | 8 |
| 3 | Base de datos, instantáneas y respaldo | 6 |
| 4 | App usable: catálogo, formas de cobrar, presupuestos y proyectos | 11 |
| 5 | Plano, PDF, compartir, modo cliente y montaje sobre foto | 7 |
| 6 | 3D interactivo | 4 |
| 7 | Voz e IA | 8 |
| 8 | Opciones, historial y calibración | 6 |
| 9 | Más plantillas | 7 |
| 10 | Render fotorrealista | 3 |
| 11 | Opcionales | 3 |
| 12 | Cierre | 5 |

La app es útil desde el cierre de la fase 4 y se puede enseñar a un cliente desde la 5.

---

## Fase 0 — Cimientos

Dejar un proyecto de Flutter que compila, con análisis estricto y las pruebas de arquitectura. La hace el director sin delegar, salvo F0-T4.

- [x] **F0-T1 · Entorno** · D
  Ejecuta `flutter --version`, `flutter doctor -v`, `git --version` y `python --version`. Si no hay repositorio, `git init` y un primer commit con el kit tal como llegó (`kit inicial`).
  *Hecho cuando:* `docs/PROGRESO.md` tiene una entrada con las versiones y las plataformas que `flutter doctor` reporta listas; `python tool/oraculo/oraculo.py --verificar` da `ok` en los 9 archivos, o se anotó que no hay Python.

- [x] **F0-T2 · Proyecto de Flutter** · D
  `flutter create --project-name linforge --org mx.lino --platforms android .` Agrega `windows` si está listo para desarrollo. Lee `docs/ARQUITECTURA.md` §7 y §10. Sustituye la app de ejemplo por una pantalla mínima con el nombre de la app y borra la prueba de ejemplo.
  *Hecho cuando:* los archivos del kit siguen intactos (`git diff` solo muestra archivos nuevos); `flutter analyze` limpio; `flutter test` corre; `flutter build apk --debug` compila, o se anotó qué falta.

- [x] **F0-T3 · Análisis, estructura y soporte de pruebas** · D
  `analysis_options.yaml` estricto (`strict-casts`, `strict-inference`, `strict-raw-types`, sin `print`, tipos de retorno declarados). `test/arquitectura_test.dart` con las reglas de `docs/ARQUITECTURA.md` §2. `test/soporte/` con el cargador de `test/fixtures/` y los comparadores con tolerancia.
  *Hecho cuando:* una prueba demuestra que el verificador de arquitectura rechaza un `import` prohibido; el cargador lee los 9 dorados; `/verify` en verde.

- [ ] **F0-T4 · Números y errores del motor** · I
  `lib/motor/numeros.dart` y `lib/motor/error_motor.dart`. Lee `docs/MOTOR_MEDICION.md` §1 y `docs/MOTOR_RECETAS.md` §1.
  *Hecho cuando:* pruebas de `techo(2.0000000001) = 2`, `piso(2.9999999999) = 3`, `redondear(2.5) = 3`, `redondear(-2.5) = -3`, `redondear(1.005, 2) = 1.01`, `centavos(2.345) = 235`, `centavos(-1.005) = -101`, cero y valores de 1e9.

## Fase 1 — Motor de medición

`docs/MOTOR_MEDICION.md` completo. Al cerrar, el motor mide los cinco trabajos dorados.

- [ ] **F1-T1 · Catálogo y derivados** · I +R
  Modelos `Articulo` y `Catalogo`, lectura del formato de `test/fixtures/entradas/catalogo.json`, derivados por familia, familia `otro` y peso manual. §2.
  *Hecho cuando:* coincide con `dorados/catalogo_derivados.json`; clave inexistente da `articulo_desconocido`; el peso manual manda sobre el teórico.

- [ ] **F1-T2 · Calibres y pulgadas** · I
  Tabla de calibres como semilla y conversión de medidas en pulgadas. §2.2.
  *Hecho cuando:* `"1 1/2"`, `"1-1/2"`, `"1.5"`, `"3/4"` y `"2"` se convierten bien; lo inválido da error; calibre 14 → 1.905 mm; ida y vuelta de mm a texto en pulgadas para las medidas comerciales.

- [ ] **F1-T3 · Optimizador de cortes** · I +R
  §5.
  *Hecho cuando:* pasan todos los casos de `dorados/casos_cortes.json`; el resultado es determinista.

- [ ] **F1-T4 · Modelo de piezas** · I
  Clases inmutables y su JSON. §3.
  *Hecho cuando:* para el `esperado.modelo` de cada trabajo dorado, `fromJson(toJson(x))` es igual a `x`.

- [ ] **F1-T5 · Medición** · I +R
  `medir(modelo, catalogo)`. §6.
  *Hecho cuando:* al medir el `esperado.modelo` de cada uno de los 5 trabajos dorados coinciden `despiece`, `cortes`, `por_articulo`, `uniones`, `cantidades` y `advertencias`; las unidades de compra `kg`, `m` y `m2` tienen pruebas con cuentas a mano.

- [ ] **F1-T6 · Plantillas: interfaz, esquema, validación y registro** · D→I
  El director fija la interfaz `Plantilla` y `ParametroDef`. §4.
  *Hecho cuando:* una plantilla de prueba valida cada error genérico (`parametro_faltante`, `fuera_de_rango`, `articulo_desconocido`, `familia_no_permitida`) desde su esquema; el registro devuelve plantillas por id.

- [ ] **F1-T7 · Plantilla `libre`** · I
  §4.3.
  *Hecho cuando:* `dorados/libre_barandal_7500.json` coincide de punta a punta (modelo y medición), con su advertencia de empalme.

- [ ] **F1-T8 · Plantilla `reja_ventana`** · I +R
  §4.1 y §7.
  *Hecho cuando:* `dorados/reja_1200x1000.json` coincide (modelo completo con posiciones, y medición); hay un caso por cada error y por la advertencia `sin_barrotes`.

- [ ] **F1-T9 · Plantilla `porton_abatible`** · I +R
  §4.2, los tres rellenos.
  *Hecho cuando:* coinciden `porton_3000x2200`, `porton_1hoja_barrotes_1000x2100` y `porton_lamina_2400x2000`; errores y advertencia `hoja_ancha` cubiertos.

- [ ] **F1-T10 · Descripción del trabajo** · I
  `describirTrabajo` por plantilla: una frase en español con medidas y materiales. `docs/VISUAL.md` §5.
  *Hecho cuando:* los textos de los 5 dorados están fijados en pruebas y se leen naturales.

## Fase 2 — Motor de recetas

`docs/MOTOR_RECETAS.md` completo. Al cerrar, `calcularPresupuesto` reproduce los dorados al centavo.

- [ ] **F2-T1 · Léxico y sintaxis** · I +R
  §2.1 y §2.2.
  *Hecho cuando:* cada caso de `dorados/casos_formulas.json` con error `sintaxis` da ese código y esa posición; los demás se analizan; hay una función que lista los identificadores y funciones de una fórmula.

- [ ] **F2-T2 · Evaluador** · I +R
  §2.3 a §2.5.
  *Hecho cuando:* pasan todos los casos de `dorados/casos_formulas.json`, valores y códigos de error.

- [ ] **F2-T3 · Receta: modelo y validación** · I +R
  §3, §4 y los pasos 1 a 3 de §5.
  *Hecho cuando:* las cuatro recetas de `entradas/recetas.json` se leen y validan; los casos de nombres, categorías, sintaxis y referencias de `dorados/casos_recetas_error.json` dan su código.

- [ ] **F2-T4 · Evaluación de recetas** · I +R
  Pasos 4 a 6 de §5, ajustes, §6 y rastro.
  *Hecho cuando:* pasa todo `dorados/casos_recetas_error.json`; todas las `evaluaciones` de los 5 trabajos dorados coinciden al centavo en líneas, agregados, `suma`, `ajuste_redondeo` y `total`; cada línea trae su rastro.

- [ ] **F2-T5 · Presentación al cliente** · I +R
  §7.
  *Hecho cuando:* coinciden todas las `presentaciones` de los dorados; una prueba con muchos casos generados con semilla fija confirma que `Σ items + impuesto = total`.

- [ ] **F2-T6 · `calcularPresupuesto`** · D→I
  La puerta de entrada. `docs/ARQUITECTURA.md` §3.
  *Hecho cuando:* los 5 dorados pasan desde su `entrada` hasta la evaluación; una entrada inválida regresa `problemas` con código y no lanza; dos llamadas iguales dan JSON idéntico; se mide y anota el tiempo del portón dorado.

- [ ] **F2-T7 · Calibración** · I
  §8.
  *Hecho cuando:* la prueba sintética recupera `tarifa_m2_reja` con error menor que `1e-4`; reporta el error por caso.

- [ ] **F2-T8 · Variables documentadas y recetas semilla** · M
  Lista de variables con su descripción, generada desde el motor, y las cuatro recetas como semilla en `assets/semillas/`.
  *Hecho cuando:* una prueba confirma que cada cantidad estándar, agregado y función tiene descripción; las recetas semilla validan y evalúan.

## Fase 3 — Datos

`docs/MODELO_DE_DATOS.md`. Al cerrar, todo se guarda, se congela y se respalda.

- [ ] **F3-T1 · Base y esquema** · D→I +R
  Drift, las tablas de §2 y pruebas en memoria.
  *Hecho cuando:* se crea la base vacía; cada tabla tiene una prueba de inserción y lectura; el dinero es entero y las fechas son UTC.

- [ ] **F3-T2 · Repositorios de configuración** · I
  Catálogo con historial, tarifas, campos del trabajo, recetas con versiones, receta por plantilla y ajustes.
  *Hecho cuando:* cambiar un precio agrega una fila al historial; editar una receta crea la versión siguiente; un artículo usado se desactiva en lugar de borrarse; los nombres reservados o repetidos se rechazan.

- [ ] **F3-T3 · Proyectos y opciones** · I +R
  Clientes, proyectos, opciones, fotos y horas. Folio consecutivo por año. Estados de §3.
  *Hecho cuando:* cada transición válida funciona y cada inválida da `transicion_invalida`; un proyecto siempre tiene al menos una opción.

- [ ] **F3-T4 · Instantáneas** · I +R
  §4, "Duplicar para modificar" y "Usar como base".
  *Hecho cuando:* pasan las pruebas (a) y (b) de §4; una opción congelada no se puede editar.

- [ ] **F3-T5 · Semillas** · M +R
  §7. Catálogo inicial con al menos 40 artículos comunes y sus geometrías correctas; calibres, recetas, tarifas y campos.
  *Hecho cuando:* una base vacía carga las semillas una sola vez; todo queda con `es_ejemplo`; el revisor comprobó las conversiones de pulgadas y calibres de una muestra.

- [ ] **F3-T6 · Respaldo** · I +R
  §6.
  *Hecho cuando:* pasa la prueba de ida y vuelta con fotos; un respaldo más nuevo se rechaza con mensaje; las claves de servicios no aparecen en el archivo.

## Fase 4 — App base

`docs/ESPECIFICACION.md` §3 y §4, `.claude/rules/interfaz.md`. Al cerrar, Lino puede cotizar un trabajo real en el teléfono.

- [ ] **F4-T1 · Arranque, navegación y componentes** · D→I
  Tema claro y oscuro, cinco pestañas, estado y rutas, componentes base, `textos.dart`, formato de dinero y medidas.
  *Hecho cuando:* una prueba de widget recorre las cinco pestañas; los formatos `$12,345.00` y `1.20 m` tienen pruebas.

- [ ] **F4-T2 · Catálogo** · I
  §4.9: lista con búsqueda sin acentos, filtro por tipo, alta y edición con campos según la familia, actualización rápida de precio, antigüedad del precio y marca EJEMPLO.
  *Hecho cuando:* pruebas de buscar, crear un PTR desde pulgadas y calibre, y cambiar un precio.

- [ ] **F4-T3 · Tarifas y datos del trabajo** · I
  *Hecho cuando:* se editan, agregan y quitan tarifas y campos con validación de nombres; lo usado por una receta avisa antes de borrarse.

- [ ] **F4-T4 · Formulario generado y cálculo en vivo** · D→I +R
  §4.1. Controlador del presupuesto en edición, formulario desde el esquema, errores junto al campo, total en vivo y guardado automático.
  *Hecho cuando:* con la reja dorada y la receta `despiece` el total en pantalla es $2,800.00; cambiar una medida recalcula; un valor fuera de rango muestra su mensaje; el borrador sobrevive a reabrir.

- [ ] **F4-T5 · Resultado** · I
  Total, forma de cobrar, desglose con rastro, advertencias, y las pestañas Materiales y Cortes (R-16).
  *Hecho cuando:* al tocar una línea se ve su fórmula con valores; Materiales y Cortes coinciden con el dorado del portón.

- [ ] **F4-T6 · Trabajo libre** · I
  §4.4.
  *Hecho cuando:* capturando el barandal dorado se obtiene su total.

- [ ] **F4-T7 · Formas de cobrar** · D→I +R
  Lista, asignación por tipo de trabajo, editor simple y avanzado con validación en vivo, vista previa y comparación.
  *Hecho cuando:* el editor simple produce fórmulas válidas para cada base; el avanzado muestra en español cada error de `docs/MOTOR_RECETAS.md` §2.5; guardar crea una versión; la vista previa coincide con el motor.

- [ ] **F4-T8 · Ajustes del presupuesto** · I
  §4.7.
  *Hecho cuando:* se reproduce `despiece_ajustes_manuales` y `despiece_iva_descuento` del portón dorado desde la interfaz.

- [ ] **F4-T9 · Proyectos** · I +R
  Guardar con cliente, las vistas Pendientes, Opciones y Anteriores, cambios de estado, duplicar y usar como base.
  *Hecho cuando:* un trabajo recorre todos los estados desde la interfaz; al enviarlo queda congelado aunque cambie un precio.

- [ ] **F4-T10 · Negocio, condiciones y preferencias** · M
  Datos del negocio, condiciones por defecto, unidades y tema.
  *Hecho cuando:* se guardan y se leen tras reabrir.

- [ ] **F4-T11 · Respaldo desde Ajustes** · I
  Exportar e importar con confirmación.
  *Hecho cuando:* prueba de widget del flujo con dobles de archivos.

## Fase 5 — Plano, PDF, compartir y montaje

`docs/VISUAL.md` §1, §2, §4 y §5. Al cerrar, el presupuesto se puede enseñar y enviar.

- [ ] **F5-T1 · Plano 2D** · I +R
  `construirPlano`, cotas y `PintorPlano`.
  *Hecho cuando:* pasan las pruebas de §2 para la reja y el portón dorados.

- [ ] **F5-T2 · Plano en el formulario y en el resultado** · I
  *Hecho cuando:* el plano se redibuja al cambiar una medida; admite zoom y desplazamiento.

- [ ] **F5-T3 · PDF** · I +R
  `construirPdf` con fuente incluida, tres presentaciones y página interna.
  *Hecho cuando:* pasan las pruebas de §5.

- [ ] **F5-T4 · Compartir** · I
  PDF e imagen de 1080 × 1350. Al compartir un borrador, ofrece marcarlo como enviado.
  *Hecho cuando:* prueba con el doble de `Compartidor`; el envío congela.

- [ ] **F5-T5 · Modo cliente** · I
  `docs/ESPECIFICACION.md` §4.5.
  *Hecho cuando:* una prueba confirma que no aparecen utilidad, costos ni rastro; se sale con el gesto definido.

- [ ] **F5-T6 · Homografía** · I +R
  `calcularHomografia`. §4.
  *Hecho cuando:* pasan las tres pruebas de §4.

- [ ] **F5-T7 · Montaje sobre la foto** · I
  Tomar o elegir la foto, cuatro puntos con lupa, opacidad y guardar.
  *Hecho cuando:* prueba de widget con una foto de prueba; la imagen compuesta se guarda como foto `montaje` con sus puntos.

## Fase 6 — 3D interactivo

`docs/VISUAL.md` §3.

- [ ] **F6-T1 · Escena** · I +R
  `construirEscena` y catálogo de acabados.
  *Hecho cuando:* para los dorados, el número y tipo de elementos coincide y cada barra conserva sus extremos.

- [ ] **F6-T2 · Visor** · D→I
  Página local con three.js incluido (versión fija y licencia), mensajes de la tabla, luces, sombras y órbita.
  *Hecho cuando:* la página abre sin red en un navegador con una escena de prueba; la pestaña 3D la muestra; queda en "Sin verificar en dispositivo" lo que no se pudo ver.

- [ ] **F6-T3 · Acabados y captura** · I
  Selector de acabado y captura PNG con fondo transparente, usada en el montaje, el PDF y el modo cliente.
  *Hecho cuando:* cambiar el acabado no recarga la escena; la captura llega a Flutter como imagen válida.

- [ ] **F6-T4 · Abrir y cerrar hojas** · I
  *Hecho cuando:* la escena del portón trae sus ejes de giro y el visor los usa.

## Fase 7 — Voz e IA

`docs/IA_Y_VOZ.md`, `.claude/rules/ia.md`. Usa los valores por defecto de P-06 y P-07.

- [ ] **F7-T1 · Acciones y aplicador** · D→I +R
  §2. Esquema en Dart, validación y aplicación sobre el borrador.
  *Hecho cuando:* cada acción válida se aplica y cada inválida regresa su código, sin red.

- [ ] **F7-T2 · Tarjeta de confirmación** · I
  §4, con `InterpreteFalso` y entrada de texto.
  *Hecho cuando:* escribir una descripción produce la tarjeta; Confirmar calcula, Corregir abre el formulario con esos valores.

- [ ] **F7-T3 · Cliente del modelo de lenguaje** · D→I +R
  §8. Lee la documentación vigente del proveedor antes de programar. Ajustes: clave, modelos y botón Probar.
  *Hecho cuando:* el adaptador convierte acciones a herramientas y respuestas a llamadas, probado con respuestas grabadas; la clave nunca aparece en registros.

- [ ] **F7-T4 · Intérprete** · I +R
  §3: ciclo de herramientas, instrucciones, límites y frases de referencia.
  *Hecho cuando:* pasan las pruebas con grabaciones (ciclo, límite de vueltas, respuesta mal formada); existe `test/fixtures/frases.json` con 20 frases y `tool/evaluar_interprete.dart`.

- [ ] **F7-T5 · Dictado y respuesta hablada** · I
  §5.
  *Hecho cuando:* con dobles, pulsar, hablar y soltar produce la tarjeta y, al confirmar, la app "dice" el total; la voz se puede apagar.

- [ ] **F7-T6 · Órdenes sobre el presupuesto** · I
  Cambiar medidas, agregar opción, ajustar, `mostrar_valores`, actualizar precio y registrar horas.
  *Hecho cuando:* cada orden tiene una prueba con `InterpreteFalso`; el precio del catálogo siempre pide confirmación.

- [ ] **F7-T7 · Foto de referencia** · I
  §6.
  *Hecho cuando:* con una respuesta grabada, una foto produce una tarjeta marcada como aproximación.

- [ ] **F7-T8 · Preguntas por faltantes** · I
  Conversación corta de varias vueltas.
  *Hecho cuando:* una descripción incompleta genera la pregunta y la respuesta completa la tarjeta.

## Fase 8 — Opciones, historial y calibración

- [ ] **F8-T1 · Comparador de opciones** · I
  Dos o tres opciones lado a lado, con sus diferencias, y elegir una (R-09).
  *Hecho cuando:* prueba con el portón dorado y una variante.

- [ ] **F8-T2 · Similares y simulación** · I
  Al cotizar, sugiere trabajos anteriores parecidos; "Simular desde un anterior" (R-22).
  *Hecho cuando:* la búsqueda encuentra trabajos de la misma plantilla con medidas cercanas; simular crea un borrador nuevo.

- [ ] **F8-T3 · Horas y real contra estimado** · I
  R-21.
  *Hecho cuando:* un trabajo terminado muestra horas estimadas, horas reales y la diferencia.

- [ ] **F8-T4 · Asistente de calibración** · D→I +R
  `docs/ESPECIFICACION.md` §4.10 y `docs/MOTOR_RECETAS.md` §8.
  *Hecho cuando:* se capturan casos, se prueba una receta contra ellos, se ajusta un parámetro y los casos quedan como pruebas que se reevalúan al editar la receta.

- [ ] **F8-T5 · Receta desde una explicación** · I +R
  `docs/IA_Y_VOZ.md` §7.
  *Hecho cuando:* con respuestas grabadas, una explicación produce una receta válida; una inválida se corrige en el segundo intento; nada se guarda sin aceptar.

- [ ] **F8-T6 · Portafolio** · I
  Fotos de trabajos terminados en Anteriores (R-23).
  *Hecho cuando:* se agregan y se ven fotos; entran al respaldo.

## Fase 9 — Más plantillas

Cada una con el procedimiento `nueva-plantilla`: el director especifica, hace la cuenta a mano y actualiza el oráculo; el implementador programa. Alcance en `docs/MOTOR_MEDICION.md` §8.

- [ ] **F9-T1 · `puerta`** · D→I +R
- [ ] **F9-T2 · `porton_corredizo`** · D→I +R
- [ ] **F9-T3 · `barandal`** · D→I +R
- [ ] **F9-T4 · `techumbre`** · D→I +R
- [ ] **F9-T5 · `escalera_recta`** · D→I +R
- [ ] **F9-T6 · `base_tinaco`** · D→I +R
- [ ] **F9-T7 · Mejoras a reja y portón** · D→I +R
  Relleno horizontal y en cuadrícula, travesaños intermedios, postes, chapa, puerta peatonal integrada y copete.

  *Hecho cuando (cada una):* la sección del documento existe con su caso resuelto; el dorado coincide con la cuenta a mano; pasan sus pruebas; el formulario, el plano y la escena la muestran sin código especial; los supuestos del oficio están en `docs/PENDIENTES_LINO.md`.

## Fase 10 — Render fotorrealista

`docs/VISUAL.md` §6 y §7. Depende de P-08 y P-09; sin respuesta, se construye todo con dobles y se deja listo para conectar.

- [ ] **F10-T1 · Servidor de render** · D→I
  *Hecho cuando:* la construcción de la escena tiene pruebas sin Blender; con Blender instalado, una escena de prueba produce un PNG; `LEEME.md` del servidor explica cómo correrlo en Windows.

- [ ] **F10-T2 · Cliente y cola** · I
  *Hecho cuando:* con un servidor falso, una petición sin red espera y se envía al volver; el resultado queda como foto `render`.

- [ ] **F10-T3 · Armonización del montaje** · I
  *Hecho cuando:* con respuestas grabadas, el resultado se guarda aparte y se descarta si alteró la zona fuera de la máscara.

## Fase 11 — Opcionales

Solo si Lino las pide. Cada una empieza con una investigación corta anotada en `docs/DECISIONES.md`.

- [ ] **F11-T1 · Conversación de voz en tiempo real** · D→I (`docs/IA_Y_VOZ.md` §10)
- [ ] **F11-T2 · Realidad aumentada** · D→I (`docs/VISUAL.md` §8)
- [ ] **F11-T3 · Escalera de caracol y ornamentos** · D→I

## Fase 12 — Cierre

- [ ] **F12-T1 · Recorrido de punta a punta** · I +R
  Una prueba de integración con dobles: crear catálogo, cotizar, agregar opción, enviar, aprobar, registrar horas, terminar, respaldar y restaurar.
  *Hecho cuando:* pasa.

- [ ] **F12-T2 · Pulido** · I
  Estados vacíos y de error, textos, letra al 130 %, listas largas.
  *Hecho cuando:* cada pantalla tiene sus cuatro estados; no hay textos cortados con letra grande.

- [ ] **F12-T3 · Versión para instalar** · D
  `flutter build apk --release`. Instrucciones para que Lino cree su llave de firma fuera del repositorio.
  *Hecho cuando:* existe el instalable, o quedó documentado qué falta para firmarlo.

- [ ] **F12-T4 · Manual de uso** · M
  `docs/MANUAL.md`: cotizar, configurar la forma de cobrar, mantener precios, respaldar.
  *Hecho cuando:* cada flujo de `docs/ESPECIFICACION.md` §4 tiene sus pasos.

- [ ] **F12-T5 · Revisión final** · D
  Tabla de R-01 a R-30: dónde se cumple cada uno, con su prueba o su verificación manual, y lo que quedó fuera.
  *Hecho cuando:* la tabla está en `docs/PROGRESO.md` y no hay requisito sin estado.
