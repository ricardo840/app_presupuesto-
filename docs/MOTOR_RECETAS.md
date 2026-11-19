# Motor de recetas

Convierte las cantidades de un trabajo en un precio, según la **receta** del herrero: una lista de conceptos con fórmulas. La forma de cobrar es configuración, no código. Es Dart puro (`lib/motor/recetas/`).

```
cantidades + datos del trabajo + parámetros + receta + ajustes ──evaluar──▶ líneas, agregados, total ──presentar──▶ lo que ve el cliente
```

La implementación de referencia es `tool/oraculo/oraculo.py`; los resultados esperados están en `test/fixtures/dorados/`.

## 1. Dinero y redondeo

- El motor entrega el dinero en **centavos enteros** (`int`). En los JSON de prueba aparece en pesos con dos decimales; al comparar usa `centavos == (esperado * 100).round()`.
- Redondeo comercial, la mitad se aleja de cero, con un empuje para absorber el ruido binario:

```
redondear(x, d) = signo(x) · floor(|x| · 10^d + 0.5 + 1e-7) / 10^d
centavos(x)     = signo(x) · floor(|x| · 100 + 0.5 + 1e-7)        // entero
```

  Así `redondear(2.5) = 3`, `redondear(-2.5) = -3` y `redondear(1.005, 2) = 1.01`. No uses `double.round()` ni `toStringAsFixed` para calcular.
- Cada línea de dinero se redondea a centavos en cuanto se calcula. Las líneas siguientes y los agregados usan el valor ya redondeado, de modo que lo que se muestra siempre suma exacto.
- Dentro de las fórmulas el dinero se expresa en pesos: cuando una fórmula nombra otra línea o un agregado, recibe sus centavos divididos entre 100.
- Las líneas `auxiliar` (horas, por ejemplo) no son dinero y no se redondean.

## 2. Lenguaje de fórmulas

Expresiones, nada más: sin asignaciones, sin ciclos, sin acceso a nada fuera del contexto.

### 2.1 Léxico

El texto completo se separa en componentes antes de analizar la sintaxis; un carácter inválido se reporta primero.

| Componente | Forma |
|---|---|
| Número | dígitos, con punto decimal opcional seguido de dígitos: `12`, `0.5`. No se aceptan `.5`, `1.`, coma decimal ni notación científica |
| Porcentaje | un número con `%` pegado: `30%` vale `0.30`. `5 %` y `(5 + 5)%` son errores |
| Cadena | entre comillas dobles o simples, sin escapes: `"ptr-2x2-c14"` |
| Identificador | letra ASCII o `_`, seguida de letras ASCII, dígitos o `_`. La `ñ` y los acentos no se aceptan |
| Palabras | `verdadero`, `falso` |
| Operadores | `+ - * / ( ) ,` `< <= > >= == !=` `&& || !` |

Los espacios, tabuladores y saltos de línea se ignoran.

### 2.2 Gramática

De menor a mayor precedencia. Todos los operadores binarios asocian por la izquierda.

```
expr     := y ( "||" y )*
y        := igual ( "&&" igual )*
igual    := comp ( ("==" | "!=") comp )*
comp     := suma ( ("<" | "<=" | ">" | ">=") suma )?      // no se encadenan: 3 < 4 < 5 es error
suma     := prod ( ("+" | "-") prod )*
prod     := unario ( ("*" | "/") unario )*
unario   := ("-" | "!") unario | primario
primario := NÚMERO | CADENA | "verdadero" | "falso"
          | IDENT | IDENT "(" [ expr ("," expr)* ] ")" | "(" expr ")"
```

### 2.3 Tipos y operadores

Tres tipos: número, booleano y cadena. No hay conversiones automáticas.

| Operación | Operandos | Resultado |
|---|---|---|
| `+ - * /`, `-x` | números | número. Dividir entre 0 es error |
| `< <= > >=` | números | booleano |
| `== !=` | dos números, dos booleanos o dos cadenas | booleano. Entre números la comparación es exacta |
| `&& \|\| !x` | booleanos | booleano. `&&` y `\|\|` evalúan el lado derecho solo si hace falta |

### 2.4 Funciones

| Función | Resultado |
|---|---|
| `si(cond, a, b)` | `a` si `cond` es verdadero; si no, `b`. Solo evalúa la rama elegida |
| `min(a, b, …)`, `max(a, b, …)` | de 2 argumentos en adelante |
| `abs(x)` | |
| `redondear(x)`, `redondear(x, d)` | redondeo comercial a `d` decimales (entero de 0 a 6) |
| `techo(x)`, `piso(x)` | con la tolerancia `EPS` del motor |
| `multiplo_arriba(x, m)` | `techo(x/m)·m`, con `m > 0` |
| `multiplo_abajo(x, m)` | `piso(x/m)·m` |
| `multiplo_cercano(x, m)` | `piso(x/m + 0.5)·m` |
| `art_kg(clave)`, `art_metros(clave)`, `art_tramos(clave)`, `art_m2(clave)`, `art_hojas(clave)`, `art_cantidad(clave)` | dato de ese artículo en este trabajo; 0 si el trabajo no lo usa |
| `art_precio(clave)` | precio del artículo en el catálogo |

Las funciones `art_*` reciben una cadena. Si la clave no existe en el catálogo: `articulo_desconocido`.

### 2.5 Errores

Todo error lleva un código estable; los de sintaxis llevan además la posición (índice desde 0).

| Código | Cuándo |
|---|---|
| `sintaxis` | carácter inválido, número mal escrito, cadena sin cerrar, falta un valor o un paréntesis, sobra texto. Posición: el inicio del componente inesperado, o la longitud del texto si este se acabó |
| `variable_desconocida` | identificador que no está en el contexto |
| `funcion_desconocida` | |
| `argumentos` | número de argumentos incorrecto, o un argumento fuera de su dominio (decimales, múltiplo) |
| `tipo` | operando o argumento del tipo equivocado |
| `division_entre_cero` | |
| `no_finito` | el resultado no es un número finito |
| `articulo_desconocido` | clave que no está en el catálogo |

Los mensajes para el usuario se redactan en español a partir del código y del detalle (`"1,5"` → "usa punto decimal"; `"año"` → "los nombres no llevan ñ ni acentos").

Casos: `test/fixtures/dorados/casos_formulas.json`. Cada caso trae `formula` y `esperado`, o `error` y, en los de sintaxis, `posicion`.

## 3. Receta

```json
{
  "clave": "despiece",
  "nombre": "Despiece detallado",
  "version": 1,
  "descripcion": "…",
  "redondeo_total": { "modo": "arriba", "multiplo": 50 },
  "conceptos": [
    { "clave": "material", "nombre": "Material", "categoria": "material",
      "formula": "costo_material_compra * (1 + merma)" },
    { "clave": "instalacion", "nombre": "Instalación", "categoria": "extra",
      "formula": "instalacion_base + distancia_km * costo_km", "condicion": "con_instalacion" },
    { "clave": "utilidad", "nombre": "Utilidad", "categoria": "utilidad",
      "formula": "costo_directo * pct_utilidad", "visible_cliente": false }
  ]
}
```

Un **concepto** es una línea del presupuesto:

| Campo | Significado |
|---|---|
| `clave` | identificador: minúscula inicial, luego minúsculas, dígitos o `_` |
| `nombre` | texto que se muestra |
| `categoria` | ver tabla siguiente |
| `formula` | debe dar un número |
| `condicion` | opcional; debe dar un booleano. Si es falso, la línea vale 0 y no aplica |
| `visible_cliente` | opcional, verdadero por defecto |

Categorías y agregados. Los agregados se calculan solos y se pueden usar en las fórmulas.

| Categoría | Para qué | Agregado |
|---|---|---|
| `material` | acero, herrajes, pintura, consumibles | `total_material` |
| `mano_obra` | trabajo por hora, por día o por rendimiento | `total_mano_obra` |
| `global` | precio todo incluido: por m², por kilo, por pieza | `total_global` |
| `extra` | instalación, flete, motor, viáticos | `total_extra` |
| `utilidad` | | `total_utilidad` |
| `descuento` | su valor es negativo | `total_descuento` |
| `impuesto` | IVA | `total_impuesto` |
| `auxiliar` | valor intermedio que no es dinero (horas) | — |

```
costo_directo = total_material + total_mano_obra + total_global + total_extra
subtotal      = costo_directo + total_utilidad
base_impuesto = subtotal + total_descuento
suma          = base_impuesto + total_impuesto
total         = redondeo de suma (sección 6)
```

Un concepto puede usar otros conceptos y agregados mientras no se forme un ciclo. Por eso la utilidad puede usar `costo_directo`, el descuento `subtotal` y el IVA `base_impuesto`, pero un concepto de `material` no puede usar `costo_directo`. Un concepto `auxiliar` puede usar cualquier agregado, incluso `suma`.

## 4. Contexto y nombres

Lo que una fórmula puede nombrar:

| Origen | Ejemplos |
|---|---|
| Cantidades del trabajo (`docs/MOTOR_MEDICION.md` §6) | `kg_acero`, `area_m2`, `uniones`, `costo_material_compra`, `x_barrotes` |
| Datos del trabajo: `tipo` (id de la plantilla) y los campos que el usuario defina | `tipo`, `con_instalacion`, `distancia_km`, `lleva_motor` |
| Parámetros del usuario, con los ajustes del presupuesto encima | `tarifa_hora`, `merma`, `pct_utilidad`, `con_iva` |
| Conceptos de la misma receta y agregados | `material`, `horas`, `costo_directo` |

Todos los nombres comparten un solo espacio y no pueden repetirse.

- **Reservados**: las cantidades estándar, los agregados, `total`, `ajuste_redondeo`, `tipo`, `verdadero`, `falso`, los nombres de función y todo lo que empiece con `x_`.
- Los parámetros, los campos del trabajo y los conceptos siguen la misma regla de `clave` y no pueden chocar entre sí ni con un reservado.

## 5. Validación y evaluación

`evaluarReceta(receta, medición, catálogo, parámetros, datos del trabajo, tipo, ajustes)`.

**Ajustes del presupuesto**, todos opcionales:

| Ajuste | Efecto |
|---|---|
| `parametros` `{nombre: valor}` | sustituye parámetros solo para este presupuesto. Nombre inexistente: `parametro_desconocido` |
| `lineas_fijas` `{clave: valor}` | fija a mano el valor de un concepto: se ignoran su fórmula y su condición. Clave inexistente: `linea_fija_desconocida` |
| `lineas_extra` `[{clave, nombre, categoria, valor}]` | agrega líneas de dinero solo a este presupuesto; entran a los agregados de su categoría. No pueden ser `auxiliar` y siempre son visibles para el cliente |

Pasos, en este orden. El primer error detiene el proceso.

1. **Estructura y nombres.** Por cada concepto, y luego por cada línea extra: `clave_invalida`, `categoria_invalida`, `nombre_reservado`, `nombre_duplicado` (ya existe como concepto, parámetro, campo del trabajo o línea extra). Después se aplican `parametros` y se comprueban las `lineas_fijas`.
2. **Sintaxis.** Se analizan todas las fórmulas y condiciones.
3. **Referencias.** Cada función debe existir (`funcion_desconocida`) y cada identificador debe ser un nombre conocido (`variable_desconocida`). Los que empiezan con `x_` se aceptan aquí y se comprueban al evaluar, porque dependen de la plantilla.
4. **Orden.** Dependencias de un concepto: los conceptos y agregados que nombra en su fórmula y su condición (ninguna si está fijado a mano). Cada `total_<categoría>` depende de todos los conceptos y líneas extra de esa categoría; los agregados compuestos, de sus partes. Orden topológico; si no se puede completar: `ciclo`.
5. **Evaluación**, en ese orden:
   - línea extra: `centavos(valor)`;
   - concepto fijado: `centavos(valor)` (o el valor tal cual si es `auxiliar`), origen `fijo`;
   - concepto con condición falsa: 0, `aplica = falso`;
   - en otro caso: evaluar la fórmula; si no da un número, `tipo`; redondear a centavos salvo en `auxiliar`;
   - agregado: suma de sus dependencias.
6. **Total**: redondeo de `suma`; `ajuste_redondeo = total − suma`.

Resultado: las líneas en el orden de la receta (las extra al final), cada una con `clave`, `nombre`, `categoria`, `valor`, `aplica`, `origen` (`formula`, `fijo`, `extra`) y `visible_cliente`; los agregados; `suma`, `ajuste_redondeo` y `total`.

**Rastro.** Cada línea guarda además de dónde salió: el texto de la fórmula y el valor de cada nombre que usó. La app lo muestra al tocar la línea ("Mano de obra = horas × tarifa_hora × personas = 3.29 × 150 × 1").

Casos de error: `test/fixtures/dorados/casos_recetas_error.json`.

## 6. Redondeo del total

`redondeo_total: { modo, multiplo }`, con `multiplo` en pesos (1, 5, 10, 50, 100). Si falta: `ninguno`.

| Modo | Total |
|---|---|
| `ninguno` | `suma` |
| `arriba` | `techo(suma / m) · m` |
| `abajo` | `piso(suma / m) · m` |
| `cercano` | `piso(suma / m + 0.5) · m` |

## 7. Presentación al cliente

`presentar(evaluación, modo)` arma lo que se enseña y se imprime. Lo que no es visible (la utilidad, los consumibles, el ajuste por redondeo) se reparte entre lo visible; la suma siempre da el total. Todo en centavos enteros.

1. `T = total`, `I = total_impuesto`, `B = base_impuesto`.
2. Si `I ≠ 0`: `tasa = I / B`; `base_mostrada = redondear(T / (1 + tasa))`; `impuesto_mostrado = T − base_mostrada`. Si no: `base_mostrada = T`, `impuesto_mostrado = 0`.
3. Líneas visibles: las de categoría `material`, `mano_obra`, `global`, `extra` o `descuento` que aplican, son visibles y no valen 0.
4. Renglones según el modo:
   - `conceptos`: un renglón por línea visible, en orden.
   - `categorias`: un renglón por categoría con valor distinto de 0, en este orden y con estas etiquetas: Materiales, Mano de obra, Trabajo de herrería, Extras, Descuento.
   - `total`: ningún renglón.
5. Salvo en `total`: `diferencia = base_mostrada − suma de renglones`. Se reparte entre los renglones **positivos** en proporción a su valor, por el método del resto mayor:
   - `por_repartir = |diferencia|`; para cada renglón positivo `i`: `(cociente_i, residuo_i) = divmod(por_repartir · valor_i, suma de positivos)`;
   - los centavos que falten (`por_repartir − Σ cociente_i`) van, de uno en uno, a los residuos más grandes; en empate, al renglón que aparece primero;
   - a cada renglón se le suma su parte con el signo de la diferencia.
   - Si no hay renglones positivos, queda un solo renglón "Trabajo de herrería" con `base_mostrada`.
6. Resultado: `items` (`nombre`, `valor`), `impuesto` y `total`. Se cumple `Σ items + impuesto = total`.

Las multiplicaciones del paso 5 pueden pasar de 2⁵³: usa enteros de 64 bits o `BigInt`, nunca `double`.

## 8. Calibración

Sirve para que la app aprenda cómo cobra el herrero a partir de trabajos que ya cotizó.

`calibrar(receta, parametro, casos, minimo, maximo)`: cada caso trae la medición de un trabajo pasado, sus datos y el precio cobrado. Busca el valor del parámetro que minimiza `Σ ((suma − cobrado) / cobrado)²`, con `suma` sin redondeo del total.

- Barrido de 200 puntos entre `minimo` y `maximo`, y después refinamiento por sección áurea alrededor del mejor, hasta un ancho de `1e-6` del rango.
- Devuelve el valor, el error por caso (en pesos y en %) y el error medio.
- Los trabajos pasados quedan guardados como **pruebas del usuario**: cada vez que se edita una receta, la app la vuelve a evaluar contra ellos y muestra la diferencia.

Prueba: genera precios con un valor conocido de `tarifa_m2_reja` sobre los trabajos dorados y comprueba que la calibración lo recupera con error menor que `1e-4`.

## 9. Recetas de ejemplo

Están en `test/fixtures/entradas/recetas.json` y se cargan también como semilla, marcadas como EJEMPLO. Son cuatro maneras comunes de cotizar; ninguna es la del herrero hasta que se calibre.

| Receta | Idea | Redondeo |
|---|---|---|
| `despiece` | material comprado más merma, consumibles, pintura, mano de obra por rendimientos, instalación, motor, utilidad, descuento e IVA opcionales | arriba a 50 |
| `por_m2` | tarifa por m² según el tipo de trabajo, más instalación | cercano a 10 |
| `por_kilo` | precio por kilo de acero ya trabajado; herrajes, motor e instalación aparte | arriba a 100 |
| `material_por_factor` | material por un factor que cubre mano de obra y utilidad | arriba a 50 |

## 10. Ejemplo resuelto

Reja de 1.20 × 1.00 m con la receta `despiece` (cantidades en `docs/MOTOR_MEDICION.md` §7; parámetros en `test/fixtures/entradas/parametros.json`).

| Línea | Cuenta | Valor |
|---|---|---|
| `material` | 915.00 × 1.05 | 960.75 |
| `consumibles` | 15.818 kg × 6 | 94.91 |
| `pintura` | 0.9213 m² × 90 | 82.92 |
| `horas` (auxiliar) | (17 × 4 + 34 × 3) / 60 + 0.9213 × 0.5 | 3.294 |
| `mano_obra` | 3.294 × 150 × 1 | 494.10 |
| `instalacion` | 500 + 0 × 12 | 500.00 |
| `costo_directo` | | 2132.68 |
| `utilidad` | 2132.68 × 0.30 | 639.80 |
| `suma` | | 2772.48 |
| `total` | arriba a 50 | 2800.00 |

Con el modo `categorias`, la utilidad, los consumibles y el redondeo (762.23 en total) se reparten: Materiales 1434.06, Mano de obra 678.92, Extras 687.02. Suma 2800.00.

## 11. Pruebas obligatorias

| Qué | Contra qué |
|---|---|
| Léxico, sintaxis, tipos y funciones | `dorados/casos_formulas.json` |
| Validación, ciclos y ajustes inválidos | `dorados/casos_recetas_error.json` |
| Evaluación completa de las cuatro recetas | `esperado.evaluaciones` de cada trabajo dorado |
| Ajustes: parámetros, línea fija y línea extra | `porton_3000x2200.json`: `despiece_iva_descuento` y `despiece_ajustes_manuales` |
| Presentación en los tres modos | `presentaciones` dentro de las evaluaciones que la traen |
| Redondeo de dinero | pruebas propias: 1.005, 2.345, −2.5, 0 y valores grandes |
| Calibración | prueba sintética de la sección 8 |

El dinero se compara exacto, al centavo.
