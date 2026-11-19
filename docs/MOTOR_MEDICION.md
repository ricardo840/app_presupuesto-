# Motor de medición

Convierte los parámetros de un trabajo en un **modelo de piezas** y, a partir de él, en despiece, lista de corte y cantidades. Es Dart puro (`lib/motor/`). El precio lo calcula después el motor de recetas (`docs/MOTOR_RECETAS.md`) usando las cantidades que salen de aquí.

```
parámetros + catálogo ──plantilla──▶ modelo de piezas ──medir──▶ despiece, cortes, por artículo, cantidades
```

La implementación de referencia es `tool/oraculo/oraculo.py`. Los resultados esperados están en `test/fixtures/dorados/`. Si este documento y el oráculo no coinciden, sigue el procedimiento de `.claude/rules/pruebas.md`.

## 1. Convenciones numéricas

| Magnitud | Unidad interna | Tipo |
|---|---|---|
| Longitud | mm | `double` |
| Peso | kg | `double` |
| Área | m² | `double` |
| Dinero dentro de las cantidades | pesos, sin redondear | `double` |
| Conteos (piezas, tramos, uniones) | unidades | `int` |

- `EPS = 1e-9`.
- `techo(x) = ceil(x − EPS)` y `piso(x) = floor(x + EPS)`. Úsalos siempre en lugar de `ceil` y `floor` para que el ruido binario no cambie un conteo (`techo(2.0000000001) = 2`).
- Una longitud "cabe" si `largo ≤ límite + EPS`.
- El orden de los resultados es determinista: se conserva el orden de aparición y los ordenamientos son estables.
- La conversión a metros, centímetros o pulgadas ocurre solo en los bordes (pantalla, PDF, voz).

Constantes del motor (editables en Ajustes, con estos valores iniciales):

| Constante | Valor | Uso |
|---|---|---|
| `densidad_kg_m3` | 7850 | acero al carbón |
| `kerf_mm` | 3 | material que se pierde en cada corte |
| `desperdicio_lamina` | 0.10 | holgura al estimar hojas de lámina |

## 2. Catálogo

Un artículo tiene `clave` (única, minúsculas, con guiones: `ptr-2x2-c14`), `nombre`, `tipo`, `unidad_compra` y `precio`. Según el tipo lleva además:

| Tipo | Campos | Unidades de compra |
|---|---|---|
| `perfil` | `familia`, `geometria`, `largo_tramo_mm` (6000 por defecto; hay tramos de 6100), `peso_kg_m_manual` opcional | `tramo`, `kg`, `m` |
| `lamina` | `geometria.e`, `hoja_mm` `[ancho, largo]` (1219×3048 = 4'×10') | `hoja`, `m2`, `kg` |
| `herraje` | — | `pieza` |
| `consumible` | — (soldadura, discos, pintura). No entra al despiece; su precio se consulta desde las fórmulas con `art_precio` | `pieza`, `kg`, `litro` |

En los JSON el precio va en pesos con dos decimales. En la base de datos se guarda en centavos enteros.

Un artículo mal formado (falta un campo que su tipo exige, falta una medida de su `geometria`, tipo, familia o unidad de compra desconocidos o no válidos para su tipo, `otro` sin `peso_kg_m_manual`, herraje o consumible con `familia`, una medida, largo de tramo, hoja o peso manual que no sea mayor que cero, precio negativo, clave repetida) da el error `articulo_invalido`, con la clave y el motivo en el detalle.

### 2.1 Valores derivados de un perfil

Con `geometria` en mm. Las esquinas se toman rectas (aproximación suficiente para cotizar).

| Familia | Geometría | Área de sección (mm²) | Cara | Fondo | Perímetro de pintura |
|---|---|---|---|---|---|
| `cuadrado` (macizo) | `a` | `a²` | `a` | `a` | `4a` |
| `redondo` (macizo) | `d` | `π·d²/4` | `d` | `d` | `π·d` |
| `solera` | `a`, `e` | `a·e` | `a` | `e` | `2(a + e)` |
| `angulo` (lados iguales) | `a`, `e` | `(2a − e)·e` | `a` | `a` | `4a` |
| `tubular` (PTR y perfil tubular) | `a`, `b`, `e` | `a·b − (a − 2e)(b − 2e)` | `a` | `b` | `2(a + b)` |
| `tubo` (redondo hueco) | `d`, `e` | `π/4·(d² − (d − 2e)²)` | `d` | `d` | `π·d` |
| `otro` | `cara`, `fondo` | — (exige `peso_kg_m_manual`) | `cara` | `fondo` | `2(cara + fondo)` |

- `peso_kg_m = área · densidad / 1 000 000`. Si el artículo trae `peso_kg_m_manual`, ese valor manda (los pesos de tabla del proveedor son más fieles que el teórico).
- **Cara** es el ancho que se ve de frente; **fondo**, la profundidad. Las plantillas colocan las piezas usando la cara.
- Lámina: `peso_kg_m2 = e · densidad / 1000`.

Resultados esperados: `test/fixtures/dorados/catalogo_derivados.json`.

### 2.2 Calibres y pulgadas

Espesores nominales que usan los proveedores en México (semilla editable; el espesor real puede venir más delgado):

| Calibre | 10 | 11 | 12 | 13 | 14 | 16 | 18 | 20 | 22 | 24 |
|---|---|---|---|---|---|---|---|---|---|---|
| mm | 3.429 | 3.048 | 2.667 | 2.286 | 1.905 | 1.524 | 1.219 | 0.914 | 0.762 | 0.610 |

Las medidas comerciales se capturan en pulgadas y fracciones (`1 1/2`, `3/4`, `2`). Conversión: `mm = pulgadas · 25.4`. El analizador acepta `"1 1/2"`, `"1-1/2"`, `"1.5"` y `"3/4"`, con espacios alrededor y un `"` final opcional. Un texto vacío, que no sea medida, con denominador cero, con fracción impropia en la forma mixta (`1 3/2`) o que no dé más de cero, da el error `medida_invalida`.

De mm a texto: se escribe en dieciseisavos simplificados (`2`, `3/4`, `1 1/2`, `1 3/16`) cuando la medida queda a menos de 0.01 mm de uno; si no, no hay texto en pulgadas y se muestra en mm.

## 3. Modelo de piezas

Es el contrato entre el motor y todo lo visual. Sistema de coordenadas, en mm:

- **X** hacia la derecha, **Y** hacia arriba, **Z** hacia quien mira desde afuera.
- Origen en la esquina inferior izquierda del trabajo visto de frente. En portones es la esquina inferior izquierda del vano, a nivel de piso.
- `z = 0` es el plano medio del marco o bastidor.

```json
{
  "plantilla": "reja_ventana",
  "caja": { "ancho": 1200, "alto": 1000 },
  "num_hojas": 0,
  "piezas": [
    { "id": "marco-inf", "grupo": "marco", "articulo": "angulo-1x1-8", "largo": 1200,
      "cantidad": 1, "corte": "inglete", "p0": [0, 12.7, 0], "p1": [1200, 12.7, 0], "hoja": null }
  ],
  "paneles": [
    { "id": "h1-zoclo", "grupo": "zoclo", "articulo": "lamina-c18", "ancho": 1485, "alto": 900,
      "cantidad": 1, "origen": [10, 50, 26.0095], "hoja": 0 }
  ],
  "herrajes": [ { "articulo": "bisagra-tejuelo", "cantidad": 6 } ],
  "uniones": { "marco": 4, "barrotes": 16 },
  "extras": { "barrotes": 8 },
  "detalle": { "hueco_libre_mm": 116.4 },
  "advertencias": []
}
```

- **Pieza**: una barra. `p0` y `p1` son los extremos de su eje (el centro de la sección). `largo` es la longitud de corte. `corte` es `recto` o `inglete` (45° en ambos extremos; el largo de corte es el largo exterior). `hoja` es el índice de la hoja a la que pertenece, o `null`. Una pieza sin posición (`p0` y `p1` nulos) cuenta como material pero no se dibuja.
- **Panel**: un rectángulo de lámina en un plano paralelo a XY. `origen` es su esquina inferior izquierda; `z` es el centro de su espesor.
- **Uniones**: mapa de concepto → número de uniones soldadas. El total es la suma.
- **Extras**: conteos propios de la plantilla. Llegan a las recetas con el prefijo `x_` (`x_barrotes`).
- **Detalle**: valores intermedios útiles para pruebas y para explicar el resultado. No se usan para cotizar. Las llaves de cada plantilla son las que aparecen en su dorado (`claro_ancho_mm`, `hueco_libre_mm`…).
- **Advertencias**: lista de objetos con `codigo` y los datos que la ubican (`articulo`, `panel`).

Para dibujar, cada barra es una caja de `cara × fondo × largo` centrada en su eje. Las esquinas a inglete se dibujan traslapadas (simplificación aceptada en la versión 1).

## 4. Plantillas

Una plantilla es una función pura `(parámetros, catálogo) → modelo de piezas`, más un **esquema** que describe sus parámetros. El formulario de la app y las herramientas de la IA se generan desde el esquema: agregar una plantilla no requiere tocar la interfaz.

Cada parámetro del esquema declara: `clave`, `etiqueta`, `tipo` (`longitud`, `entero`, `articulo`, `opcion`, `booleano`, `texto`, `lista`), `defecto`, `min`, `max`, `opciones`, los tipos de artículo y las `familias` permitidas (para artículos; un herraje no tiene familia), si es `requerido`, `requerido_si` y `ayuda` (una frase que también lee la IA). Un parámetro `lista` declara además los `campos` de cada elemento con el mismo formato (lo usa `libre`). `requerido_si` es una condición sobre otro parámetro: "mayor que un número" (`travesanos > 0`) o "es una de estas opciones" (`relleno` en `mixto`, `barrotes`). Si la condición no se cumple, el parámetro no se exige ni se valida.

Validación, antes de generar. Primero se ponen los valores por defecto donde falte un valor; después se revisa cada parámetro contra el esquema; si no hubo errores, la plantilla aplica sus reglas propias (`claro_insuficiente`). Devuelve una lista de problemas, cada uno con su código y el parámetro al que se refiere (en una lista, `piezas[2].largo`); si hay errores no se genera el modelo.

| Código de error | Cuándo |
|---|---|
| `parametro_faltante` | falta un parámetro requerido y no tiene valor por defecto |
| `valor_invalido` | el valor no es del tipo del parámetro (texto donde va una medida, un entero con decimales) |
| `fuera_de_rango` | un valor queda fuera de `min`–`max`, o una opción no está en `opciones` (salvo que el parámetro declare otro código para eso) |
| `articulo_desconocido` | la clave no está en el catálogo |
| `familia_no_permitida` | el artículo no es del tipo o de una familia aceptada |
| `claro_insuficiente` | las medidas no dejan espacio entre los marcos |
| `relleno_no_soportado` | opción de relleno que la plantilla no conoce (el código que declara el parámetro `relleno` del portón) |
| `plantilla_desconocida` | el registro no tiene una plantilla con ese id |

Función compartida:

```
numero_barrotes(claro, cara, separacion_max) = max(0, techo((claro − separacion_max) / (cara + separacion_max)))
```

Es el menor número de barrotes para que ningún hueco libre supere `separacion_max`. Con `n` barrotes quedan `n + 1` huecos iguales de `(claro − n·cara) / (n + 1)`.

### 4.1 `reja_ventana` — protección de ventana

Marco perimetral, barrotes verticales, soleras de amarre horizontales y anclas.

| Parámetro | Tipo | Defecto | Rango | Significado |
|---|---|---|---|---|
| `ancho` | longitud | 1200 | 200–6000 | ancho exterior del marco |
| `alto` | longitud | 1000 | 200–3000 | alto exterior del marco |
| `marco` | artículo | — | ángulo, tubular, solera | perfil del marco |
| `barrote` | artículo | — | cuadrado, redondo, tubular, tubo | perfil de los barrotes |
| `separacion_max` | longitud | 120 | 30–300 | hueco libre máximo entre barrotes |
| `travesanos` | entero | 1 | 0–6 | soleras de amarre horizontales |
| `travesano` | artículo | — | requerido si `travesanos > 0` | |
| `anclas` | entero | 4 | 0–12 | anclas para fijar al muro |
| `ancla` | artículo | — | requerido si `anclas > 0` | |
| `largo_ancla` | longitud | 100 | 30–300 | |

Reglas, con `c = cara(marco)` y `w = cara(barrote)`:

1. `claro_ancho = ancho − 2c`, `claro_alto = alto − 2c`. Si alguno es ≤ 0: `claro_insuficiente`.
2. Marco, a inglete: `marco-inf` y `marco-sup` de largo `ancho`; `marco-izq` y `marco-der` de largo `alto`. Ejes: inferior en `y = c/2`, superior en `y = alto − c/2`, izquierdo en `x = c/2`, derecho en `x = ancho − c/2`.
3. `n = numero_barrotes(claro_ancho, w, separacion_max)`; `hueco = (claro_ancho − n·w) / (n + 1)`.
4. Barrote `i` (1…n), corte recto, largo `claro_alto`, en `x = c + hueco·i + w·(i − 0.5)`, de `y = c` a `y = alto − c`.
5. Travesaño `j` (1…t), corte recto, largo `claro_ancho`, en `y = c + claro_alto·j/(t + 1)`, de `x = c` a `x = ancho − c`. Va por detrás de los barrotes: `z = −(fondo(barrote)/2 + fondo(travesano)/2)`.
6. Anclas: `anclas` piezas de `largo_ancla`, corte recto, sin posición.
7. Uniones: `marco: 4`, `barrotes: 2n`, `travesanos: t·(2 + n)`, `anclas: anclas`.
8. Extras: `barrotes: n`, `travesanos: t`, `anclas`. `num_hojas = 0`. `caja = ancho × alto`.

Advertencia `sin_barrotes` si `n = 0`.

### 4.2 `porton_abatible` — portón o zaguán de una o dos hojas

| Parámetro | Tipo | Defecto | Rango | Significado |
|---|---|---|---|---|
| `ancho` | longitud | 3000 | 600–8000 | ancho libre del vano |
| `alto` | longitud | 2200 | 600–4000 | alto libre del vano |
| `hojas` | entero | 2 | 1–2 | |
| `holgura_lateral` | longitud | 10 | 0–50 | entre cada orilla y la hoja |
| `holgura_central` | longitud | 10 | 0–50 | entre las dos hojas |
| `holgura_piso` | longitud | 50 | 0–200 | |
| `bastidor` | artículo | — | tubular, ángulo | perfil del bastidor de cada hoja |
| `relleno` | opción | `mixto` | `mixto`, `barrotes`, `lamina` | |
| `barrote` | artículo | — | requerido en `mixto` y `barrotes` | |
| `separacion_max` | longitud | 110 | 30–300 | requerido en `mixto` y `barrotes` |
| `lamina` | artículo | — | requerido en `mixto` y `lamina` | |
| `alto_zoclo` | longitud | 900 | requerido en `mixto` | altura de la lámina inferior |
| `travesano` | artículo | — | requerido en `mixto` y `lamina` | |
| `paso_punteo` | longitud | 150 | 50–500 | distancia entre puntos de soldadura de la lámina |
| `bisagra` | artículo | — | herraje | |
| `pasador` | artículo o nulo | nulo | herraje | |
| `picaporte` | artículo o nulo | nulo | herraje; solo se usa con 2 hojas | |

Reglas, con `c = cara(bastidor)`:

1. `ancho_hoja = (ancho − 2·holgura_lateral − (hojas − 1)·holgura_central) / hojas`; `alto_hoja = alto − holgura_piso`; `claro_ancho = ancho_hoja − 2c`.
2. Hoja `h` (0, 1): `x0 = holgura_lateral + h·(ancho_hoja + holgura_central)`, `y0 = holgura_piso`. Los ids llevan el prefijo `h1-`, `h2-`.
3. Bastidor de cada hoja, a inglete: dos verticales de largo `alto_hoja` (ejes en `x0 + c/2` y `x0 + ancho_hoja − c/2`) y dos horizontales de largo `ancho_hoja` (ejes en `y0 + c/2` y `y0 + alto_hoja − c/2`).
4. En `mixto` y `barrotes`: `n = numero_barrotes(claro_ancho, cara(barrote), separacion_max)` por hoja y `hueco` como en la reja. Barrote `i` en `x = x0 + c + hueco·i + w·(i − 0.5)`.
5. Lámina, en `mixto` y `lamina`: sobrepuesta por fuera, cubre todo el ancho de la hoja. `z = fondo(bastidor)/2 + e/2`. Puntos de soldadura por hoja: `techo(perímetro del panel / paso_punteo)`.
6. Relleno **`mixto`**, con `ct = cara(travesano)`:
   - Panel `zoclo` de `ancho_hoja × alto_zoclo`, con origen en `(x0, y0)`.
   - Un travesaño por hoja, corte recto, largo `claro_ancho`, con eje en `y = y0 + alto_zoclo` (centrado en el borde superior de la lámina).
   - Barrotes de largo `alto_hoja − c − alto_zoclo − ct/2`, de `y = y0 + alto_zoclo + ct/2` a `y = y0 + alto_hoja − c`.
7. Relleno **`barrotes`**: barrotes de largo `alto_hoja − 2c`, de `y = y0 + c` a `y = y0 + alto_hoja − c`. Sin lámina ni travesaño.
8. Relleno **`lamina`**: panel `tablero` de `ancho_hoja × alto_hoja` con origen en `(x0, y0)` y un travesaño de refuerzo por hoja, largo `claro_ancho`, con eje en `y = y0 + alto_hoja/2`.
9. Herrajes: bisagras `2` por hoja si `alto_hoja ≤ 2000`, `3` si es mayor. Un `pasador` si se indicó. Un `picaporte` si se indicó y hay 2 hojas.
10. Uniones: `bastidor: 4` por hoja; `travesanos: 2` por travesaño; `barrotes: 2` por barrote; `lamina`: los puntos; `bisagras: 2` por bisagra; `pasador: 2`; `picaporte: 2`.
11. Extras: `barrotes` (total), `bisagras`. `num_hojas = hojas`. `caja = ancho × alto` del vano.

Advertencias: `hoja_ancha` si `ancho_hoja > 2500` (conviene rueda o tensor); `panel_no_cabe_en_hoja` (la produce la medición).

### 4.3 `libre` — despiece capturado a mano

Para cualquier diseño que no quepa en una plantilla. El usuario (o la IA) da la lista directamente.

| Parámetro | Significado |
|---|---|
| `ancho`, `alto` | medidas generales, solo para `area_m2` y similares |
| `piezas` | lista de `{grupo, articulo, largo, cantidad, corte}` |
| `paneles` | lista de `{grupo, articulo, ancho, alto, cantidad}` |
| `herrajes` | lista de `{articulo, cantidad}` |
| `uniones` | número de uniones, contado a mano |

Las piezas conservan su `cantidad` y no tienen posición. Sus ids son `pieza-1`, `pieza-2`… y los de los paneles `panel-1`, `panel-2`…, en el orden capturado. Si falta `grupo` se usa `piezas` o `paneles`; si falta `corte`, `recto`. `uniones: { manual: n }`. Sin extras. `caja = ancho × alto`.

## 5. Optimizador de cortes

Decide cuántos tramos comprar de cada perfil y cómo cortarlos. Método: primer ajuste decreciente.

1. **Empalmes**. Una pieza más larga que el tramo se parte en `piso(largo / tramo)` tramos completos más el resto (si el resto es mayor que `EPS`). Cada pieza partida suma `segmentos − 1` empalmes.
2. Ordena los segmentos de mayor a menor, de forma estable.
3. Coloca cada segmento en la primera barra donde quepa: cabe si `suma(barra) + kerf·(piezas en la barra) + largo ≤ tramo + EPS`. Entre cada par de piezas se pierde un kerf. Si no cabe en ninguna, abre una barra nueva.
4. Sobrante de cada barra: `max(0, tramo − suma(barra) − kerf·(piezas en la barra))`.
5. `cortes` = segmentos más cortos que el tramo (un tramo completo no se corta).

Resultado: `tramos`, `barras` (listas de largos en orden de colocación), `sobrantes_mm`, `segmentos`, `cortes`, `empalmes`.

Casos: `test/fixtures/dorados/casos_cortes.json` (ajuste exacto, pieza que no cabe por el kerf, mezcla, empalmes, tramo de 6100, lista vacía).

No es el óptimo matemático, pero es estable y suficiente. Mejorarlo es una tarea aparte y no puede cambiar los dorados sin el procedimiento de excepción.

## 6. Medición

`medir(modelo, catálogo)` produce:

**Despiece**: piezas agrupadas por `(grupo, artículo, largo, corte)` en orden de aparición, con su cantidad. Dos largos son el mismo si coinciden a 4 decimales.

**Cortes**: por cada perfil, el plan del optimizador: `tramos`, `barras`, `sobrantes_mm` y `empalmes`.

**Uniones**: el mapa del modelo; si hubo empalmes se le agrega la entrada `empalmes`.

**Por artículo**, en orden de aparición (perfiles, luego láminas, luego herrajes):

| Campo | Perfil | Lámina | Herraje |
|---|---|---|---|
| `piezas` | piezas diseñadas | 0 | 0 |
| `metros` | `Σ largos / 1000` | 0 | 0 |
| `kg` | `metros · peso_kg_m` | `m2 · peso_kg_m2` | 0 |
| `tramos` | barras del optimizador | 0 | 0 |
| `m2` | 0 | `Σ ancho·alto·cantidad / 1e6` | 0 |
| `hojas` | 0 | `techo(m2·(1 + desperdicio_lamina) / área de la hoja)` | 0 |
| `cantidad` | 0 | 0 | piezas |
| `costo_compra` | ver abajo | ver abajo | `cantidad · precio` |
| `costo_usado` | ver abajo | ver abajo | `cantidad · precio` |

Costo según la unidad de compra:

| Tipo | Unidad | `costo_compra` | `costo_usado` |
|---|---|---|---|
| perfil | `tramo` | `tramos · precio` | `metros / (largo_tramo/1000) · precio` |
| perfil | `kg` | `tramos · (largo_tramo/1000) · peso_kg_m · precio` | `kg · precio` |
| perfil | `m` | `metros · precio` | `metros · precio` |
| lámina | `hoja` | `hojas · precio` | `m2 / área de la hoja · precio` |
| lámina | `m2` | `m2 · (1 + desperdicio_lamina) · precio` | `m2 · precio` |
| lámina | `kg` | `hojas · área de la hoja · peso_kg_m2 · precio` | `kg · precio` |

`costo_compra` es lo que se paga en la tienda (tramos y hojas completos). `costo_usado` es la parte proporcional. La receta decide cuál cobra.

**Cantidades**: las variables que ven las recetas. Siempre existen todas; valen 0 cuando no aplican.

| Variable | Definición |
|---|---|
| `ancho_m`, `alto_m` | medidas de `caja`, en metros |
| `largo_m` | longitud lineal del trabajo; por defecto igual a `ancho_m` |
| `area_m2` | `ancho_m · alto_m` |
| `perimetro_m` | `2·(ancho_m + alto_m)` |
| `num_hojas` | hojas del portón o puerta; 0 si no aplica |
| `kg_perfiles`, `kg_laminas`, `kg_acero` | pesos; `kg_acero` es la suma |
| `m_perfiles` | metros de perfil |
| `tramos` | tramos a comprar, sumando todos los perfiles |
| `m2_lamina`, `hojas_lamina` | área de lámina y hojas a comprar |
| `piezas` | barras diseñadas |
| `paneles` | paneles de lámina |
| `cortes` | cortes de perfil (del optimizador) |
| `ingletes` | extremos a 45°: 2 por cada pieza con corte `inglete` |
| `uniones` | total de uniones del modelo, más los empalmes |
| `m2_pintura` | `Σ perímetro de pintura · metros` de cada perfil, más `2 · m2` de cada lámina |
| `costo_perfiles_compra`, `costo_perfiles_usado` | sumas por perfil |
| `costo_laminas_compra`, `costo_laminas_usado` | sumas por lámina |
| `costo_herrajes` | suma de herrajes |
| `costo_material_compra`, `costo_material_usado` | perfiles + láminas + herrajes |
| `x_<extra>` | los extras de la plantilla; solo existen si la plantilla los declara |

Advertencias de la medición: `pieza_mayor_que_tramo` (hubo empalmes) y `panel_no_cabe_en_hoja` (el lado corto del panel supera el lado corto de la hoja, o el largo supera el largo).

## 7. Ejemplo resuelto: reja de 1.20 × 1.00 m

Caso `reja_1200x1000`: marco de ángulo 1" × 1/8", barrotes de cuadrado 1/2", separación máxima 120 mm, una solera de amarre de 1" × 1/8" y 4 anclas de 100 mm.

- `c = 25.4`, `w = 12.7`. `claro_ancho = 1200 − 50.8 = 1149.2`; `claro_alto = 949.2`.
- `n = techo((1149.2 − 120) / (12.7 + 120)) = techo(7.756) = 8`; `hueco = (1149.2 − 8·12.7) / 9 = 116.4`.
- Despiece: 2 × 1200 y 2 × 1000 de ángulo; 8 × 949.2 de cuadrado; 1 × 1149.2 y 4 × 100 de solera.
- Cortes: ángulo, 1 tramo (sobran 1588); cuadrado, 2 tramos (6 piezas + 2 piezas); solera, 1 tramo. Total 4 tramos.
- Pesos por metro: ángulo `(2·25.4 − 3.175)·3.175 = 151.209 mm²` → 1.18699 kg/m; cuadrado 161.29 mm² → 1.26613 kg/m; solera 80.645 mm² → 0.63306 kg/m.
- `kg_acero = 4.4·1.18699 + 7.5936·1.26613 + 1.5492·0.63306 = 15.818`.
- `m2_pintura = 0.1016·4.4 + 0.0508·7.5936 + 0.05715·1.5492 = 0.9213`.
- `uniones = 4 + 16 + 10 + 4 = 34`; `cortes = 17`; `ingletes = 8`.
- `costo_material_compra = 285 + 2·240 + 150 = 915.00`; `costo_material_usado = 551.47`.

## 8. Plantillas siguientes (fase 9)

Cada una se especifica en este documento antes de programarla, con sus reglas numeradas y un caso calculado a mano. Usa `/nueva-plantilla`. Alcance mínimo:

| Plantilla | Qué modela | Parámetros clave |
|---|---|---|
| `puerta` | marco fijo (dos jambas y cabezal) y una hoja abatible | vano, holguras, relleno, chapa, bisagras |
| `porton_corredizo` | una hoja corrediza con riel, rodajas, guía superior y tope | vano, traslape, relleno, riel, rodajas, motor con cremallera |
| `barandal` | tramo recto con postes, pasamanos y barrotes | largo, altura, separación de postes y de barrotes, placas de anclaje |
| `techumbre` | tejabán a un agua: postes, vigas, polines y lámina de cubierta | largo, ancho, altura, pendiente, separación de polines, traslape |
| `escalera_recta` | dos alfardas, escalones y descanso opcional | altura total, huella, contrahuella máxima, ancho, tipo de escalón |
| `base_tinaco` | plataforma con cuatro postes y crucetas | lado, altura, perfil, placas base |

Mejoras a las plantillas existentes, en la misma fase: relleno horizontal y en cuadrícula, travesaños intermedios en `barrotes`, postes, chapa, puerta peatonal integrada y copete.

## 9. Pruebas obligatorias

| Qué | Contra qué |
|---|---|
| Derivados de cada familia | `dorados/catalogo_derivados.json` |
| Optimizador de cortes | `dorados/casos_cortes.json` |
| `reja_ventana` completa | `dorados/reja_1200x1000.json` |
| `porton_abatible` en sus tres rellenos | `dorados/porton_3000x2200.json`, `porton_1hoja_barrotes_1000x2100.json`, `porton_lamina_2400x2000.json` |
| `libre` y empalmes | `dorados/libre_barandal_7500.json` |
| Validación | pruebas propias: un caso por cada código de error de la sección 4 |
| Determinismo | misma entrada dos veces → JSON idéntico |

Cada dorado trae `entrada` (plantilla, parámetros, datos del trabajo) y `esperado` (`modelo`, `despiece`, `cortes`, `por_articulo`, `uniones`, `cantidades`, `advertencias`, `evaluaciones`). Compara cantidades con tolerancia absoluta de `1e-5` y conteos de forma exacta. Los números del JSON pueden llegar como enteros o decimales: convierte con `(x as num).toDouble()`.
