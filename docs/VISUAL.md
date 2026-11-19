# Visual

Lo que se le enseña al cliente. Todo se dibuja a partir del modelo de piezas (`docs/MOTOR_MEDICION.md` §3); nada se mide aquí. Las reglas de la capa están en `.claude/rules/visual.md`.

| Nivel | Qué es | Dónde corre | Fase |
|---|---|---|---|
| 1 | Plano 2D con cotas | teléfono, sin red | 5 |
| 2 | Montaje sobre la foto del lugar | teléfono, sin red | 5 |
| 3 | 3D interactivo con acabados | teléfono, sin red | 6 |
| 4 | Render fotorrealista | servidor con Blender | 10 |
| 5 | Armonización del montaje con IA | servicio de imagen | 10 |
| 6 | Realidad aumentada (opcional) | teléfono | 11 |

## 1. Proyección de una pieza

Vista de frente: se ignora Z. Una barra de `p0` a `p1` con cara `c` es un rectángulo de ancho `c` centrado en su eje. Un panel es su rectángulo. Las piezas sin posición no se dibujan.

Orden de pintado: de menor a mayor Z del centro; a igual Z, en el orden del modelo.

## 2. Plano 2D

```dart
Plano construirPlano(ModeloPiezas modelo, OpcionesPlano opciones);
```

`Plano` trae `caja` (el rectángulo que lo contiene todo, con margen para cotas), `formas` (polígonos con capa y tipo: `perfil`, `lamina`) y `cotas`.

Cotas, fuera del dibujo, con líneas de referencia y flechas o marcas:

| Cota | Cuándo |
|---|---|
| Ancho total y alto total | siempre |
| Ancho de cada hoja | si hay 2 hojas |
| Hueco libre entre barrotes | una sola vez, en el primer hueco |
| Alto del zoclo | relleno `mixto` |
| Holgura al piso | si es mayor que 0 |

- El texto de la cota va en las unidades del usuario (`1.20 m`), calculado desde los milímetros del modelo.
- `PintorPlano` (un `CustomPainter`) pinta el `Plano` ajustándolo al espacio disponible, con zoom y desplazamiento.
- Estilo: perfiles con relleno sólido y contorno fino; lámina con relleno más claro. En modo cliente, sin cotas secundarias.
- La misma función alimenta la vista en vivo del formulario, la pantalla de resultado y el PDF (dibujo vectorial, no imagen).

Pruebas: para la reja dorada, 13 formas (17 piezas menos 4 anclas sin posición), la caja contiene todas las formas, y existen las cotas `1.20 m` y `1.00 m`. Para el portón dorado, 30 barras, 2 láminas y la cota del zoclo.

## 3. Escena 3D

Un JSON que entienden por igual el visor del teléfono y el servidor de render.

```dart
Escena construirEscena(ModeloPiezas modelo, Catalogo catalogo, Acabado acabado);
```

```json
{
  "version": 1,
  "unidades": "mm",
  "caja": { "ancho": 3000, "alto": 2200, "fondo": 60 },
  "acabado": { "id": "negro_mate", "color": "#1b1b1d", "rugosidad": 0.8, "metalico": 0.2 },
  "elementos": [
    { "id": "h1-bastidor-izq", "tipo": "barra", "seccion": "rectangular",
      "p0": [35.4, 50, 0], "p1": [35.4, 2200, 0], "cara": 50.8, "fondo": 50.8, "hoja": 0 },
    { "id": "h1-barrote-1", "tipo": "barra", "seccion": "redonda",
      "p0": [176.2, 975.4, 0], "p1": [176.2, 2149.2, 0], "cara": 12.7, "fondo": 12.7, "hoja": 0 },
    { "id": "h1-zoclo", "tipo": "panel", "origen": [10, 50, 26.0], "ancho": 1485, "alto": 900,
      "espesor": 1.219, "hoja": 0 }
  ],
  "hojas": [ { "indice": 0, "bisagra_x": 10, "abre_hacia": "adentro", "giro": "izquierda" } ]
}
```

- `seccion` es `redonda` para las familias `redondo` y `tubo`; `rectangular` para las demás. El ángulo se dibuja como caja en la versión 1.
- `hojas` describe el eje de giro de cada hoja para animar la apertura. En un portón de 2 hojas, la izquierda gira sobre su orilla izquierda y la derecha sobre su orilla derecha.
- Acabados iniciales: negro mate, negro brillante, blanco, gris, café óxido, verde, primario rojo y galvanizado.

### Visor

Una página local en `assets/visor3d/` con three.js incluido, dentro de un `WebView`. La app le habla por un canal de mensajes:

| Mensaje | Efecto |
|---|---|
| `cargarEscena(json)` | reemplaza la escena |
| `fijarAcabado(acabado)` | cambia el material sin recargar |
| `fijarVista("frente" \| "tres_cuartos")` | mueve la cámara |
| `abrirHojas(grados)` | gira las hojas sobre su bisagra, de 0 a 90 |
| `capturar({ancho, alto, transparente})` | responde con un PNG en base64 |

Luz ambiental y una luz direccional con sombras suaves, piso neutro y órbita con límites para que el trabajo nunca se pierda de vista. El JavaScript no contiene reglas del negocio.

Pruebas: `construirEscena` para los dorados (número y tipo de elementos, que cada barra conserva sus extremos). El visor se comprueba a mano en el teléfono.

## 4. Montaje sobre la foto

El herrero toma la foto del lugar y arrastra cuatro puntos a las esquinas del vano. La app deforma el dibujo en perspectiva para que caiga en ese cuadrilátero.

```dart
Matrix4 calcularHomografia(Size origen, List<Offset> destino);  // destino: sup-izq, sup-der, inf-der, inf-izq
```

La transformación lleva el rectángulo `(0,0)-(W,H)` al cuadrilátero. Son ocho incógnitas `h11…h32`, con `h33 = 1`; cada par de puntos da dos ecuaciones:

```
x' = (h11·x + h12·y + h13) / (h31·x + h32·y + 1)
y' = (h21·x + h22·y + h23) / (h31·x + h32·y + 1)
```

Se resuelve el sistema lineal de 8 × 8 por eliminación gaussiana con pivoteo. La matriz para `Canvas.transform`, por filas, es:

```
| h11  h12  0  h13 |
| h21  h22  0  h23 |
|  0    0   1   0  |
| h31  h32  0   1  |
```

- Puntos colineales o repetidos: `puntos_invalidos`.
- Lo que se deforma es el dibujo con fondo transparente: el plano relleno o, desde la fase 6, la captura frontal del visor.
- Controles: lupa al arrastrar cada punto, opacidad, acabado. Se guarda la imagen compuesta como foto de tipo `montaje`, junto con sus cuatro puntos.
- Lleva la leyenda "Imagen ilustrativa".

Pruebas: las cuatro esquinas del origen caen exactamente en los cuatro puntos; un rectángulo igual al origen da la identidad; tres puntos en línea dan error.

## 5. PDF e imagen para compartir

```dart
Uint8List construirPdf(DatosPdf datos);
```

Tamaño carta, una página:

1. Encabezado: logo, nombre del negocio, teléfono, folio y fecha.
2. Cliente y lugar de la obra.
3. Imagen: plano con cotas, o el montaje si existe.
4. Descripción del trabajo, generada desde los parámetros y los nombres del catálogo: "Portón abatible de 2 hojas, 3.00 × 2.20 m. Bastidor de PTR 2" × 2" cal. 14, zoclo de lámina cal. 18 y barrotes de tubular 1" × 1" cal. 18. Incluye instalación."
5. Precio según la presentación elegida (`docs/MOTOR_RECETAS.md` §7).
6. Condiciones: anticipo, vigencia, tiempo de entrega, garantía.
7. Leyendas: "Imagen ilustrativa" y, si hay datos de ejemplo, "Precios de EJEMPLO".

Una segunda página, solo para el herrero: lista de compra y lista de cortes por tramo, con sobrantes.

La descripción la arma una función pura por plantilla (`describirTrabajo`), que también se usa en la tarjeta de confirmación y en la voz.

Imagen para WhatsApp: tarjeta vertical de 1080 × 1350 con la imagen del trabajo, el título, el total y el nombre del negocio.

Pruebas: el PDF abre y tiene una o dos páginas; contiene el folio, el total con formato y las leyendas que correspondan; `describirTrabajo` para los dorados.

## 6. Servidor de render (fase 10)

Servicio en Python con Blender sin interfaz (`bpy`).

| Ruta | |
|---|---|
| `GET /salud` | responde si está listo y la versión de Blender |
| `POST /render` | cuerpo: `{ escena, vista, ancho, alto, transparente, calidad }` → `image/png` |

- Autorización con `Authorization: Bearer <token>`.
- Construye la escena desde el JSON de §3: cajas y cilindros con un bisel pequeño, material según el acabado, piso que solo recibe sombra, luz de cielo y un sol.
- `vista`: `frente` o `tres_cuartos`. `calidad`: `rapida` o `alta` (número de muestras). Con reducción de ruido.
- En el teléfono: una cola que guarda las peticiones cuando no hay red, muestra el avance y deja los resultados en las fotos del proyecto como tipo `render`.
- Dónde corre lo decide Lino (`docs/PENDIENTES_LINO.md`, P-08): su PC con tarjeta de video o un servidor rentado.

## 7. Armonización con IA (fase 10, opcional)

Mejora el montaje de §4 para que la herrería tome la luz y las sombras de la foto. Se manda la imagen compuesta y una máscara de la zona del dibujo a un modelo de edición de imagen, con la instrucción de no cambiar la forma de la herrería ni el resto de la foto.

- El montaje sin IA se conserva siempre; la versión armonizada es una foto aparte.
- Se compara con el original: si la zona fuera de la máscara cambió de forma apreciable, se descarta y se avisa.
- El proveedor se elige en `docs/PENDIENTES_LINO.md` (P-09). Lee su documentación vigente antes de escribir el adaptador.

## 8. Realidad aumentada (fase 11, opcional)

Ver el trabajo a escala real en el vano. Empieza con una investigación corta: estado actual de los paquetes de realidad aumentada para Flutter y si conviene exportar el modelo a glTF. Se decide en `docs/DECISIONES.md` antes de programar.
