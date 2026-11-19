# Glosario

Palabras del oficio como se usan en México, y cómo se llaman en el código. Sirve para nombrar las cosas igual en todos lados y como base del vocabulario que recibe la IA.

## Materiales

| Término | Qué es | En el código |
|---|---|---|
| Perfil | barra de acero que se vende por tramo | `tipo: perfil` |
| PTR | perfil tubular rectangular o cuadrado, de pared gruesa, para estructura | `familia: tubular` |
| Tubular | perfil hueco cuadrado o rectangular de pared delgada (calibres 18 y 20), para rellenos y marcos ligeros | `familia: tubular` |
| Cuadrado | barra maciza de sección cuadrada: "cuadrado de media" es de 1/2" | `familia: cuadrado` |
| Redondo | barra maciza redonda | `familia: redondo` |
| Solera | barra plana: "solera de una por un octavo" | `familia: solera` |
| Ángulo | perfil en L de lados iguales | `familia: angulo` |
| Tubo | tubo redondo hueco | `familia: tubo` |
| Montén o polín | perfil en C para techumbres | `familia: otro` |
| Lámina | hoja de acero: lisa, antiderrapante, galvanizada o pintada | `tipo: lamina` |
| Calibre | número que indica el espesor; a mayor calibre, más delgada | tabla de calibres |
| Tramo | barra completa como se vende, por lo común de 6 m | `largo_tramo_mm` |
| Hoja (de lámina) | pieza completa de lámina, por ejemplo de 4 × 10 pies | `hoja_mm`, `hojas_lamina` |
| Herraje | bisagras, pasadores, chapas, rodajas | `tipo: herraje` |
| Consumibles | soldadura, discos de corte y desbaste, gas | parámetro `consumibles_kg` |
| Primario | pintura anticorrosiva de fondo | parte de `precio_pintura_m2` |

## Partes de un trabajo

| Término | Qué es | En el código |
|---|---|---|
| Vano o claro | hueco del muro donde va el trabajo | `ancho`, `alto` de la `caja` |
| Marco | perímetro fijo de una reja o puerta | grupo `marco` |
| Bastidor | perímetro de una hoja que abre | grupo `bastidor` |
| Hoja (de portón) | cada parte que abre | `hojas`, `num_hojas` |
| Barrote | barra del relleno, por lo común vertical | grupo `barrotes` |
| Travesaño | barra horizontal intermedia | grupo `travesanos` |
| Solera de amarre | solera horizontal que une los barrotes de una reja | grupo `travesanos` |
| Zoclo | tablero de lámina en la parte baja | grupo `zoclo` |
| Tablero | lámina que cubre una hoja completa | grupo `tablero` |
| Ancla | pieza que se empotra o atornilla al muro | grupo `anclas` |
| Holgura | espacio libre para que la hoja abra sin rozar | `holgura_*` |
| Bisagra de tejuelo | bisagra soldable de perno | herraje |
| Pasador y portacandado | cierre para candado | herraje |
| Picaporte de piso | varilla que fija una hoja al piso | herraje |
| Chapa | cerradura | herraje |
| Pasamanos, poste | partes de un barandal | fase 9 |
| Alfarda, huella, contrahuella | viga lateral, parte donde se pisa y altura del escalón | fase 9 |

## Tipos de trabajo

| Término | Qué es | Plantilla |
|---|---|---|
| Protección o reja de ventana | reja fija para ventana | `reja_ventana` |
| Portón o zaguán | puerta grande para cochera; abatible, corredizo o tipo libro | `porton_abatible`, `porton_corredizo` |
| Puerta | puerta peatonal con marco | `puerta` |
| Cancel | cerramiento de herrería, a veces con vidrio | `libre` |
| Barandal | protección de escalera, balcón o azotea | `barandal` |
| Tejabán o techumbre | techo ligero de estructura y lámina | `techumbre` |
| Escalera | recta o de caracol | `escalera_recta` |
| Base de tinaco | plataforma elevada | `base_tinaco` |

## Fabricación

| Término | Qué es | En el código |
|---|---|---|
| Despiece | lista de piezas con su largo | `despiece` |
| Corte a inglete | corte a 45° para armar una esquina | `corte: inglete` |
| Kerf | ancho de material que se pierde en cada corte | `kerf_mm` |
| Sobrante | pedazo que queda de un tramo | `sobrantes_mm` |
| Empalme | unión de dos tramos para lograr una pieza más larga | `empalmes` |
| Merma | desperdicio que se cobra | parámetro `merma` |
| Punteo | puntos de soldadura, por ejemplo para fijar lámina | `paso_punteo` |
| Unión | cada encuentro de piezas que se suelda | `uniones` |

## Cotización

| Término | Qué es | En el código | En la app |
|---|---|---|---|
| Receta | manera de calcular el precio | `Receta` | "Forma de cobrar" |
| Concepto | cada renglón del cálculo | `Concepto` | "Concepto" |
| Parámetro | valor que el herrero fija: tarifa por hora, utilidad | `parametros` | "Tarifa" |
| Campo del trabajo | dato que cambia en cada trabajo: distancia, con instalación | `datos_trabajo` | "Datos del trabajo" |
| Cantidades | lo que el motor mide: kilos, metros, uniones | `cantidades` | — |
| Plantilla | tipo de trabajo con sus medidas | `Plantilla` | "Tipo de trabajo" |
| Opción | alternativa de un mismo trabajo | `opciones` | "Opción" |
| Instantánea | copia congelada de un presupuesto enviado | `instantanea_json` | — |
| Anticipo, vigencia | condiciones del presupuesto | `ajustes_app` | iguales |

## Del proyecto

| Término | Qué es |
|---|---|
| Motor | la parte en Dart puro que mide y calcula (`lib/motor/`) |
| Dorado | resultado esperado de un caso de prueba (`test/fixtures/dorados/`) |
| Oráculo | implementación de referencia que genera los dorados (`tool/oraculo/oraculo.py`) |
| Rastro | explicación de dónde salió cada número |
| Modo cliente | pantalla limpia para enseñar el presupuesto |
