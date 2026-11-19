# Modelo de datos

SQLite en el teléfono, con Drift. Un solo usuario, sin sincronización. Las reglas de la capa están en `.claude/rules/datos.md`.

## 1. Convenciones

- Dinero en centavos enteros (`*_centavos`). Fechas en UTC. Longitudes en mm.
- Las columnas `*_json` guardan documentos con un campo `version`. Se leen con tolerancia: lo que falta toma su valor por defecto.
- `es_ejemplo` marca lo que vino de las semillas y nadie ha confirmado como real.
- Las claves (`clave`) son texto estable, en minúsculas; los `id` son enteros internos.

## 2. Tablas

**`articulos`**: catálogo.

| Columna | Tipo | Nota |
|---|---|---|
| `id` | entero, llave | |
| `clave` | texto, única | `ptr-2x2-c14` |
| `nombre` | texto | como se pide en la tienda |
| `tipo` | texto | `perfil`, `lamina`, `herraje`, `consumible` |
| `familia` | texto, opcional | ver `docs/MOTOR_MEDICION.md` §2.1 |
| `geometria_json` | texto | `{a, b, d, e, cara, fondo}` según la familia |
| `unidad_compra` | texto | `tramo`, `kg`, `m`, `hoja`, `m2`, `pieza`, `litro` |
| `largo_tramo_mm` | real, opcional | perfiles |
| `hoja_ancho_mm`, `hoja_largo_mm` | real, opcional | láminas |
| `peso_kg_m_manual` | real, opcional | peso de tabla del proveedor |
| `precio_centavos` | entero | por unidad de compra |
| `precio_actualizado_en` | fecha | |
| `proveedor`, `notas` | texto, opcional | |
| `es_ejemplo`, `activo` | booleano | un artículo usado no se borra: se desactiva |

**`historial_precios`**: `id`, `articulo_id`, `precio_centavos`, `fecha`. Una fila por cada cambio de precio.

**`parametros`**: tarifas del usuario. `id`, `clave` (única), `nombre`, `tipo` (`numero`, `booleano`), `valor_json`, `unidad`, `descripcion`, `es_ejemplo`.

**`campos_trabajo`**: datos que el usuario quiere capturar en cada trabajo. `id`, `clave` (única), `nombre`, `tipo` (`numero`, `booleano`, `opcion`), `opciones_json`, `defecto_json`, `orden`.

**`recetas`**: formas de cobrar, con versiones. `id`, `clave`, `version`, `nombre`, `documento_json`, `es_ejemplo`, `archivada`, `creada_en`. Única por (`clave`, `version`). Editar crea una fila con la versión siguiente.

**`receta_por_plantilla`**: `plantilla` (llave), `receta_clave`. La forma de cobrar por defecto de cada tipo de trabajo.

**`clientes`**: `id`, `nombre`, `telefono`, `direccion`, `notas`.

**`proyectos`**

| Columna | Tipo | Nota |
|---|---|---|
| `id` | entero, llave | |
| `folio` | texto, único | `2026-0001`, consecutivo por año |
| `titulo` | texto | |
| `tipo_registro` | texto | `trabajo` (real) o `modelo` (simulación o ejemplo reutilizable) |
| `cliente_id` | entero, opcional | |
| `estado` | texto | ver §3; los modelos no tienen estado |
| `direccion_obra`, `notas` | texto, opcional | |
| `opcion_elegida_id` | entero, opcional | |
| `creado_en`, `actualizado_en`, `enviado_en`, `aprobado_en`, `terminado_en` | fecha | |

**`opciones`**: cada alternativa de un proyecto. Un proyecto tiene al menos una.

| Columna | Tipo | Nota |
|---|---|---|
| `id`, `proyecto_id`, `nombre`, `orden` | | "Económica", "Reforzada" |
| `plantilla` | texto | |
| `parametros_json`, `datos_trabajo_json`, `ajustes_json` | texto | entradas del motor |
| `receta_clave`, `receta_version` | | |
| `presentacion` | texto | `total`, `categorias`, `conceptos` |
| `acabado` | texto | acabado elegido para el 3D |
| `congelada` | booleano | |
| `instantanea_json` | texto, opcional | se llena al congelar (§4) |
| `total_centavos` | entero | copia del total para las listas |
| `actualizado_en` | fecha | |

**`fotos`**: `id`, `proyecto_id`, `opcion_id` (opcional), `tipo` (`lugar`, `referencia`, `terminado`, `montaje`, `render`), `ruta` (relativa a la carpeta de la app), `datos_json` (por ejemplo, las cuatro esquinas del montaje), `creada_en`.

**`registros_horas`**: `id`, `proyecto_id`, `fecha`, `horas`, `personas`, `nota`.

**`casos_calibracion`**: trabajos pasados que sirven de prueba para las recetas. `id`, `nombre`, `plantilla`, `parametros_json`, `datos_trabajo_json`, `precio_cobrado_centavos`, `fecha`, `notas`.

**`ajustes_app`**: `clave` (llave), `valor_json`. Datos del negocio, condiciones por defecto, constantes del motor, unidades, tema, modelos de IA elegidos. Las claves de servicios no van aquí: van en el almacenamiento seguro.

## 3. Estados de un trabajo

```
borrador ──▶ enviado ──▶ aprobado ──▶ en_proceso ──▶ terminado
                │            │
                └────────────┴──▶ rechazado
```

| Paso | Qué exige | Qué provoca |
|---|---|---|
| borrador → enviado | al menos una opción sin errores | se congelan todas las opciones |
| enviado → aprobado | una opción elegida | `aprobado_en` |
| enviado o aprobado → rechazado | confirmación | |
| aprobado → en_proceso | | se habilita el registro de horas |
| en_proceso → terminado | | `terminado_en`; se compara lo estimado con lo real |

`terminado` y `rechazado` son finales. Cualquier otro paso es inválido y la función de transición lo rechaza con `transicion_invalida`.

Para cambiar algo de un trabajo ya enviado no se descongela nada: **"Duplicar para modificar"** crea una opción nueva, editable, dentro del mismo proyecto. Al volver a enviar se congela también.

Un `modelo` siempre es editable. "Usar como base" crea un `trabajo` nuevo en borrador con una copia de sus opciones.

## 4. Instantánea

Mientras una opción no está congelada, se recalcula con el catálogo, las tarifas y la receta vigentes. Al congelarse guarda todo lo necesario para reproducirla sin depender de nada más:

```json
{
  "version": 1,
  "congelada_en": "2026-11-13T18:00:00Z",
  "entrada": {
    "plantilla": "porton_abatible",
    "parametros": {},
    "datos_trabajo": {},
    "ajustes": {},
    "receta": {},
    "parametros_usuario": {},
    "catalogo": { "constantes": {}, "articulos": [] }
  },
  "resultado": { "modelo": {}, "medicion": {}, "evaluacion": {} },
  "presentacion": { "modo": "categorias", "items": [], "impuesto": 0, "total": 0 }
}
```

- `receta` es el documento completo, no una referencia. `catalogo.articulos` trae solo los artículos que el trabajo usa, con el precio de ese momento.
- Una opción congelada se muestra, se imprime y se comparte desde `resultado`; nunca se recalcula.
- Pruebas obligatorias: (a) después de congelar, cambiar precios, tarifas y receta no altera lo que se muestra; (b) `calcularPresupuesto(instantanea.entrada)` reproduce `instantanea.resultado` exactamente.

## 5. Documentos JSON

| Documento | Dónde se define |
|---|---|
| Receta | `docs/MOTOR_RECETAS.md` §3 |
| Ajustes del presupuesto | `docs/MOTOR_RECETAS.md` §5 |
| Modelo de piezas | `docs/MOTOR_MEDICION.md` §3 |
| Parámetros de una plantilla | esquema de cada plantilla, `docs/MOTOR_MEDICION.md` §4 |
| Escena 3D | `docs/VISUAL.md` §3 |

## 6. Respaldo

Un archivo `.zip` que el usuario guarda donde quiera:

```
respaldo.json     { "version", "creado_en", "version_app", "tablas": { "<tabla>": [filas] } }
fotos/            los archivos de la tabla fotos
```

- Exportar incluye todas las tablas y todas las fotos. Las claves de servicios no se exportan.
- Importar reemplaza todo, después de pedir confirmación y de hacer un respaldo automático de lo que había.
- Un respaldo de una versión anterior se migra al leerlo. Uno de una versión más nueva se rechaza con un mensaje claro.
- Prueba obligatoria: exportar, borrar la base, importar y comprobar que cada tabla y cada foto quedaron iguales.

## 7. Semillas

Al primer arranque se cargan desde `assets/semillas/`, todo marcado como EJEMPLO:

- catálogo con los perfiles, láminas y herrajes más comunes, con precios de ejemplo;
- tabla de calibres;
- las cuatro recetas de ejemplo y su asignación por plantilla;
- tarifas y campos del trabajo iniciales (los de `test/fixtures/entradas/parametros.json`).

Las semillas de la app pueden cambiar con el tiempo. Los archivos de `test/fixtures/` no: son de las pruebas.
