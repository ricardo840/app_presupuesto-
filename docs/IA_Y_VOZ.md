# IA y voz

La voz y la IA sirven para capturar más rápido, no para calcular. Las reglas de la capa están en `.claude/rules/ia.md`.

```
voz ─▶ texto ─┐
texto libre ──┼─▶ intérprete (modelo de lenguaje) ─▶ acciones propuestas ─▶ tarjeta de confirmación
foto ─────────┘                                                                   │ confirmar
                                                                                  ▼
                                    respuesta en pantalla y en voz ◀── motor ◀── aplicar
```

## 1. Principios

1. El modelo de lenguaje **traduce**; no mide, no suma, no decide precios.
2. Todo cambio pasa por la **tarjeta de confirmación**.
3. Las cifras que la app muestra o dice salen del motor. El modelo indica **qué** valores leer, no cuánto valen.
4. Sin red o sin clave, estas funciones se apagan con un aviso y el resto de la app sigue igual.
5. El intérprete es intercambiable: la app conoce una interfaz, no un proveedor.

## 2. Acciones

Es el contrato entre el intérprete y la app. Se define una sola vez en Dart (`lib/ia/acciones/`) y de ahí se genera el formato de herramientas de cada proveedor.

**Consultas.** Se ejecutan en el teléfono, sin confirmación, y su resultado regresa al modelo:

| Herramienta | Argumentos | Devuelve |
|---|---|---|
| `buscar_articulo` | `texto`, `tipo?`, `familia?` | hasta 8 artículos: `clave`, `nombre`, `tipo`, `familia` |
| `ver_plantilla` | `plantilla` | el esquema: parámetros con ayuda, rangos y valores por defecto |
| `consultar_presupuesto` | — | el borrador actual: plantilla, parámetros, líneas y total calculados por el motor |

**Cambios.** Se juntan en una propuesta y esperan confirmación:

| Acción | Argumentos | Efecto |
|---|---|---|
| `proponer_trabajo` | `plantilla`, `parametros`, `datos_trabajo?`, `titulo?` | crea o reemplaza el borrador |
| `cambiar_parametros` | `cambios` | modifica medidas o materiales del borrador |
| `cambiar_datos_trabajo` | `cambios` | "con instalación", "a quince kilómetros" |
| `cambiar_receta` | `receta` | usa otra forma de cobrar |
| `ajustar` | `parametros?`, `linea_fija?`, `linea_extra?`, `quitar?` | ajustes de este presupuesto (`docs/MOTOR_RECETAS.md` §5) |
| `agregar_opcion` | `nombre`, `cambios_parametros?`, `cambios_datos?`, `receta?` | otra alternativa a partir de la actual |
| `actualizar_precio` | `articulo`, `precio` | cambia el precio en el catálogo |
| `registrar_horas` | `horas`, `personas?`, `proyecto?`, `nota?` | `proyecto` es el texto que dijo el usuario; la app busca el proyecto en el teléfono |

**Diálogo:**

| Acción | Argumentos | Efecto |
|---|---|---|
| `preguntar` | `texto`, `parametro?` | pide un dato indispensable que falta |
| `mostrar_valores` | `claves` | la app lee esos valores del resultado: `total`, `total_material`, `mano_obra`… |
| `responder` | `texto` | respuesta breve sin cifras de dinero. Si trae alguna, la app la descarta y remite al desglose |

Reglas de aplicación:

- Cada acción se valida contra el esquema de la plantilla, el catálogo y las reglas del motor antes de mostrarse. Si es inválida no se muestra: el error (`fuera_de_rango`, `articulo_desconocido`…) regresa al modelo para que corrija o pregunte.
- Las medidas viajan en milímetros; los artículos, por su `clave` (obtenida con `buscar_articulo`).
- Una propuesta puede traer varias acciones; se confirman juntas.

## 3. Intérprete

```dart
abstract class Interprete {
  Future<Propuesta> interpretar(EntradaIa entrada, ContextoIa contexto);
}
```

- `EntradaIa`: texto (dictado o escrito) y, opcionalmente, una foto.
- `ContextoIa`: lista de plantillas con una línea cada una, el esquema de la plantilla en uso, el catálogo resumido, los campos del trabajo, las recetas disponibles (clave y nombre) y el borrador actual.
- `Propuesta`: acciones de cambio, y una pregunta o una respuesta si las hay.

`InterpreteLlm` hace un ciclo corto de herramientas: manda el mensaje, ejecuta las consultas que el modelo pida, le regresa los resultados y repite hasta que el modelo entrega una propuesta, una pregunta o una respuesta. Máximo 6 vueltas y un tiempo límite total; si se excede: "No entendí, intenta de nuevo o captura a mano".

`InterpreteFalso` devuelve propuestas programadas. Con él se prueba toda la interfaz sin red.

### Instrucciones para el modelo

En `lib/ia/instrucciones/`, versionadas. Contenido mínimo:

- Papel: asistente de un herrero mexicano; convierte lo que dice en acciones; nunca calcula precios ni totales.
- Vocabulario del oficio: `docs/GLOSARIO.md`, resumido.
- Unidades habladas: "uno veinte" son 1.20 m; "de dos" en un perfil son 2 pulgadas; "calibre catorce"; "de media" es 1/2". Las medidas del trabajo se convierten a milímetros.
- Si falta un dato sin valor por defecto, se usa `preguntar`. Si lo tiene, se usa y se avisa en la tarjeta.
- Si lo dicho admite dos lecturas razonables (¿1.20 de ancho o de alto?), se pregunta.
- Para decir cifras se usa `mostrar_valores`.
- Lo que no sea del presupuesto se responde en una frase y se regresa al tema.

## 4. Tarjeta de confirmación

Muestra, en lenguaje llano, lo que la app va a hacer:

> **Reja de ventana** · 1.20 × 1.00 m
> Marco de ángulo 1" × 1/8" · Barrotes de cuadrado 1/2" cada 12 cm · 1 solera de amarre · 4 anclas
> Con instalación
> *Usé por defecto: 1 solera de amarre, 4 anclas.*

Botones: **Confirmar**, **Corregir** (abre el formulario con esos valores) y **Repetir** (vuelve a escuchar). El texto lo genera la app con `describirTrabajo` (`docs/VISUAL.md` §5), no el modelo. Lo que se tomó por defecto se señala aparte.

Al confirmar, la app aplica las acciones, llama al motor y responde. Los cambios de precio del catálogo se confirman siempre, uno por uno.

## 5. Voz

| Interfaz | Implementación inicial | Notas |
|---|---|---|
| `Transcriptor` | reconocimiento de voz del teléfono, en español de México | pulsar para hablar; el texto parcial se ve mientras se habla |
| `Locutor` | síntesis de voz del teléfono | frases armadas por la app desde el resultado |

- **Pulsar para hablar**, no escucha continua: el taller es ruidoso.
- El texto reconocido se muestra y se puede editar antes de interpretarlo.
- Lo que la app dice: el resumen de la tarjeta ("Reja de uno veinte por uno, con instalación. ¿Confirmas?") y el resultado ("Son dos mil ochocientos pesos."). Las cantidades se dicen en pesos enteros; el detalle queda en pantalla.
- La voz se puede apagar; todo lo que se dice también se ve.
- Más adelante se puede agregar un `Transcriptor` en la nube con vocabulario del oficio, sin tocar el resto.

## 6. Foto de referencia

Entrada: una foto de un diseño o de un croquis con medidas. El modelo con visión devuelve `proponer_trabajo` con la plantilla más parecida y los parámetros que alcance a leer. La tarjeta avisa que es una aproximación y que hay que poner las medidas reales. Si nada se parece a una plantilla, propone `libre` con la lista de piezas que reconoce, o pregunta.

La foto solo se envía cuando el usuario toca "Proponer desde foto".

## 7. Receta a partir de una explicación

Parte de la calibración (`docs/MOTOR_RECETAS.md` §8). El herrero explica, hablando o escribiendo, cómo sacó el precio de un trabajo. El modelo recibe la explicación, la lista de variables disponibles con su descripción y un ejemplo de receta, y devuelve una receta en JSON.

- La app la valida con el motor. Si tiene errores, se los regresa al modelo (hasta 3 intentos).
- Después la evalúa contra los casos de calibración y muestra la diferencia en cada uno.
- Nada se guarda sin que el usuario lo acepte.

La lista de variables con su descripción se genera desde el código del motor, para que el editor de recetas y el modelo vean siempre lo mismo.

## 8. Proveedores

| Función | Interfaz | Primer adaptador |
|---|---|---|
| Interpretar texto y fotos, redactar recetas | `ClienteLlm` | API de Claude: mensajes con herramientas y visión |
| Voz a texto y texto a voz | `Transcriptor`, `Locutor` | los del teléfono |
| Armonizar el montaje | `EditorDeImagen` | el que Lino elija (P-09) |
| Render | `ServicioDeRender` | servidor propio (`docs/VISUAL.md` §6) |

- Los modelos se eligen en Ajustes. Valores sugeridos: `claude-haiku-5-5` para interpretar texto, por rapidez, y `claude-sonnet-5-5` para fotos y recetas. Confirma en https://docs.claude.com los identificadores vigentes y cómo se declaran herramientas e imágenes antes de escribir el adaptador.
- `ClienteLlm` expone lo mínimo: enviar mensajes con herramientas y recibir texto o llamadas a herramientas. Otro proveedor se agrega con otro adaptador.
- La clave se captura en Ajustes y se guarda en el almacenamiento seguro. Un botón "Probar" hace una llamada mínima y dice si funcionó.

## 9. Pruebas

- Aplicador de acciones: cada acción válida y cada error, sin red.
- `InterpreteLlm`: con un `ClienteLlm` falso que reproduce respuestas grabadas (`test/fixtures/grabaciones/`), incluidos el ciclo de herramientas, el límite de vueltas y las respuestas mal formadas.
- Interfaz: con `InterpreteFalso`, el flujo completo de dictar, confirmar, corregir y calcular.
- Frases de referencia: `test/fixtures/frases.json`, con al menos 20 frases típicas y las acciones esperadas. Una herramienta manual, `dart run tool/evaluar_interprete.dart`, las corre contra el proveedor real con la clave de Lino y reporta aciertos. Cuesta dinero: nunca corre sola.

## 10. Conversación en tiempo real (fase 11, opcional)

Voz a voz con un modelo que escucha, habla y llama herramientas en la misma conexión. Usa las mismas acciones de §2. Antes de programar: revisar qué servicios existen en ese momento, cuáles hablan español de México y cuánto cuestan, y anotar la decisión en `docs/DECISIONES.md`. La confirmación sigue siendo obligatoria, ahora también por voz ("¿Confirmas?" — "Sí").

## 11. Privacidad

- El catálogo, las tarifas y las medidas se envían al modelo solo al usar estas funciones.
- La app no agrega datos de clientes al contexto. Si el usuario los dicta, viajan en su frase; la pantalla de ajustes de voz lo advierte.
- Las fotos se envían solo con una acción explícita.
- No se guardan audios. El texto reconocido se conserva en el registro local solo en modo de depuración.
