# Progreso

Bitácora del proyecto. La escribe el agente al terminar cada tarea. La entrada más reciente va **al final**. Al empezar una sesión se leen solo las dos últimas.

Formato de una entrada:

```
## AAAA-MM-DD · F1-T3 · Optimizador de cortes
- Hecho: qué se construyó, en una o dos líneas.
- Verificación: resultado de verify (número de pruebas) y commit.
- Decisiones: lo que se eligió y no estaba escrito. Si fue una decisión de fondo, va también a DECISIONES.md.
- Sin verificar en dispositivo: lo que necesita un teléfono para probarse.
- Para revisar por Lino: cambios a dorados, supuestos del oficio, cosas raras.
- Sigue: la siguiente tarea.
```

Solo se incluyen los renglones que tengan algo que decir. Al cerrar una fase se agrega una entrada "Cierre de fase N" con el resumen y la lista "Para probar en el teléfono".

---

## 2026-11-13 · Kit inicial

- Hecho: reglas, especificación, plan, casos dorados y oráculo. Todavía no existe el proyecto de Flutter.
- Verificación: `python tool/oraculo/oraculo.py --verificar` da `ok` en los 9 archivos de `test/fixtures/dorados/`.
- Para revisar por Lino: las decisiones de `docs/PENDIENTES_LINO.md`. Las más urgentes son P-01 (nombre e identificador), P-03 (estilo) y P-04 (qué significa "Opciones").
- Sigue: F0-T1.

## 2026-11-19 · F0-T1 · Entorno

- Hecho: revisión del entorno. El repositorio ya existía (en GitHub, `origin`).
- Versiones: Flutter 3.47.1 estable (Dart 3.13.1, DevTools 2.60.0); Git 2.49.0.windows.1; Python 3.11.9; Windows 11 26H2.
- Plataformas según `flutter doctor`: listas Windows (como sistema), Chrome y Edge para web; Android con avisos (SDK 36.1.0 instalado, pero faltan `cmdline-tools` y no se han aceptado las licencias); escritorio Windows no está listo (falta Visual Studio con "Desktop development with C++"), así que no se agrega esa plataforma.
- Verificación: `python tool/oraculo/oraculo.py --verificar` da `ok` en los 9 dorados.
- Para revisar por Lino: para instalar en el teléfono hará falta, desde Android Studio, instalar "Android SDK Command-line Tools" y después correr `flutter doctor --android-licenses`. No bloquea las pruebas.
- Sigue: F0-T2.

## 2026-11-19 · F0-T2 · Proyecto de Flutter

- Hecho: `flutter create --project-name linforge --org mx.lino --platforms android .`; la app de ejemplo se sustituyó por una pantalla mínima con el nombre LinForge, hecha con `cupertino_ui`; la prueba de ejemplo se borró y la reemplaza `test/main_test.dart`.
- Verificación: `git status` solo mostró archivos nuevos (el kit quedó intacto); `dart format` sin cambios; `flutter analyze` limpio; `flutter test` 1 prueba en verde; `flutter build apk --debug` compila (`app-debug.apk`, unos 3.5 min). Todavía no existe el procedimiento `verify` completo: llega con F0-T3.
- Decisiones: D-022, `cupertino_ui` 1.1.7 en lugar de `package:flutter/cupertino.dart`, y solo Android como plataforma.
- Sigue: F0-T3.

## 2026-11-19 · F0-T3 · Análisis, estructura y soporte de pruebas

- Hecho: `analysis_options.yaml` estricto (`strict-casts`, `strict-inference`, `strict-raw-types`, sin `print`, tipos de retorno declarados y otras reglas). `test/soporte/arquitectura.dart` revisa las capas de `docs/ARQUITECTURA.md` §2 y lo usa `test/arquitectura_test.dart`. `test/soporte/fixtures.dart` carga entradas y dorados. `test/soporte/comparadores.dart` compara JSON con las tolerancias de las reglas de pruebas: enteros exactos, decimales con 1e-5 y la ruta de la primera diferencia.
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 22 pruebas en verde. Las pruebas demuestran que el verificador rechaza importaciones prohibidas (motor→datos, relativas entre capas, Flutter, `dart:io` y `dart:ui` en el motor, reloj y azar) y que el cargador lee los 9 dorados. Un archivo temporal con `print`, sin tipo de retorno y con `List` sin tipo dio 6 avisos del análisis; se borró.
- Decisiones: D-023, `main.dart` y `app/` pueden importar cualquier capa.
- Sigue: F0-T4 (al implementador).

## 2026-11-19 · F0-T4 · Números y errores del motor

- Hecho: `lib/motor/numeros.dart` (`eps`, `techo`, `piso`, `cabe`, `redondear`, `centavos`, con el empuje de 1e-7 de `docs/MOTOR_RECETAS.md` §1) y `lib/motor/error_motor.dart` (`ErrorMotor(codigo, detalle:, posicion:)` con igualdad por valor). Lo programó el implementador; el director fijó el contrato y revisó el diff completo.
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 47 pruebas en verde (24 nuevas: todos los casos del plan, cero y valores de 1e9); oráculo `ok` en los 9 dorados.
- Decisiones: la constante se llama `eps` (no `EPS`) por la convención de nombres de Dart; `redondear` nunca devuelve -0.0.
- Sigue: cierre de la fase 0.

## 2026-11-19 · Cierre de fase 0

- Hecho: proyecto de Flutter `linforge` (`mx.lino.linforge`, solo Android) con una pantalla mínima que dice "LinForge"; análisis estricto; prueba que vigila las capas de la arquitectura; cargador de dorados y comparadores con tolerancia; números y errores base del motor.
- Verificación: `verify` completo en verde (47 pruebas, oráculo `ok` en los 9 dorados); `flutter build apk --debug` compila.
- Requisitos de `docs/ESPECIFICACION.md` §5: la fase 0 no cubre ninguno en particular (R-25, "sin conexión", aplica a todas y por ahora no hay nada que use la red).
- Decisiones por defecto: D-022 (`cupertino_ui` en lugar de la importación vieja de Flutter; solo Android) y D-023 (`main.dart` y `app/` pueden importar cualquier capa).
- Pendiente: nada de la fase 0. El plan de la fase 1 no necesitó cambios.
- Para Lino, antes o durante la fase 1: nada bloquea. Siguen abiertas P-04 a P-09 y lo que hace falta de Hugo (H-01 a H-04), pero tienen valor por defecto y no se necesitan hasta fases posteriores. Para instalar en el teléfono conviene instalar en Android Studio "Android SDK Command-line Tools" y aceptar las licencias (`flutter doctor --android-licenses`).

### Para probar en el teléfono — fase 0

1. Copia al teléfono Android el archivo `build/app/outputs/flutter-apk/app-debug.apk` (por cable o subiéndolo a tu correo) y ábrelo. Android pedirá permiso para instalar apps de origen desconocido: acéptalo solo para este archivo. → Se instala sin error.
2. Busca la app en el cajón de aplicaciones. → Aparece con el nombre **LinForge** (por ahora con el ícono genérico de Flutter).
3. Ábrela. → Se ve una barra arriba con "LinForge" y al centro el texto "Cotizador de herrería".
4. Activa el modo avión y vuelve a abrirla. → Abre igual: no necesita internet.
5. Cambia el teléfono a tema oscuro y ábrela. → Abre sin errores (el tema oscuro bien hecho llega en la fase 4).
6. Gira el teléfono. → El texto sigue centrado y legible.
7. Desinstálala cuando termines si quieres; la siguiente versión se instala igual.

## 2026-11-19 · F1-T1 · Catálogo y derivados

- Hecho: `lib/motor/catalogo/` con `Articulo` (lectura y validación del JSON), `Catalogo`, `Constantes` y los derivados por familia (`DerivadosPerfil`, `DerivadosLamina`, `SinDerivados`), incluida la familia `otro` y el peso manual. Lo programó el implementador; el director fijó el contrato, leyó el código completo y lo pasó por el revisor, que confirmó las fórmulas contra §2.1 y el oráculo. Hubo una ronda de correcciones: un herraje con `familia` tronaba con un error interno, y faltaba exigir medidas mayores que cero.
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 121 pruebas en verde; los derivados de los 11 artículos coinciden con `dorados/catalogo_derivados.json`; oráculo `ok`.
- Decisiones: D-024, código `articulo_invalido` (agregado a `docs/MOTOR_MEDICION.md` §2) y `collection` como dependencia directa del motor.
- Sigue: F1-T2.

## 2026-11-19 · F1-T2 · Calibres y pulgadas

- Hecho: `lib/motor/catalogo/calibres.dart` (tabla de calibres por defecto y consulta con tabla propia) y `lib/motor/catalogo/pulgadas.dart` (`pulgadasAMm` y `mmATextoPulgadas` en dieciseisavos). Lo programó el implementador; el director revisó el código y corrigió un número con demasiados dígitos que no daba `medida_invalida`.
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 148 pruebas en verde; oráculo `ok`.
- Decisiones: código `medida_invalida` y formato del texto en pulgadas, agregados a `docs/MOTOR_MEDICION.md` §2.2. Una fracción suelta impropia (`3/2`) se acepta; en la forma mixta la fracción debe ser propia; `1 - 1/2`, con espacios alrededor del guion, se rechaza.
- Sigue: F1-T3.

## 2026-11-19 · F1-T3 · Optimizador de cortes

- Hecho: `lib/motor/medicion/cortes.dart` con `optimizarCortes` (primer ajuste decreciente con kerf y empalmes) y `PlanCortes`. Lo programó el implementador. El director leyó el código y el revisor lo comparó línea por línea con el oráculo, probando los bordes: no hay diferencias. El director agregó pruebas de esos bordes (ruido en el largo del tramo, doble exacto del tramo, kerf solo entre piezas, empates estables).
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 169 pruebas en verde; los 10 casos de `dorados/casos_cortes.json` coinciden; resultado determinista; oráculo `ok`.
- Decisiones: entradas imposibles (tramo ≤ 0, kerf negativo, largo ≤ 0) dan `ArgumentError`, porque son errores de programación: las plantillas validan antes.
- Sigue: F1-T4.

## 2026-11-19 · F1-T4 · Modelo de piezas

- Hecho: `lib/motor/medicion/modelo.dart` con `ModeloPiezas`, `Pieza`, `Panel`, `Herraje`, `Advertencia`, `Punto3` y `TipoCorte`, inmutables y con JSON escrito a mano. Lo programó el implementador; el director fijó el contrato y leyó el código completo.
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 178 pruebas en verde; para los 5 trabajos dorados, `fromJson(toJson(x)) == x` y el JSON coincide con el dorado en claves, orden y nulos; oráculo `ok`.
- Decisiones: una advertencia es un código con datos libres (`articulo`, `panel`…), escrita como JSON plano; `detalle` conserva los enteros como enteros para que la ida y vuelta sea exacta.
- Sigue: F1-T5.

## 2026-11-19 · F1-T5 · Medición

- Hecho: `lib/motor/medicion/medir.dart` con `medir(modelo, catalogo)`: despiece agrupado, planes de corte, resumen por artículo con costo de compra y usado según la unidad, uniones con empalmes, las 26 cantidades de las recetas y las advertencias `pieza_mayor_que_tramo` y `panel_no_cabe_en_hoja`. Lo programó el implementador. El director leyó el código completo y el revisor lo comparó línea por línea con el oráculo: no hay diferencias. El revisor también comprobó las cuentas a mano de las pruebas.
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 233 pruebas en verde; los 5 trabajos dorados coinciden en despiece, cortes, por artículo, uniones, cantidades y advertencias; unidades de compra `kg`, `m` y `m2` (y `tramo` y `hoja`) con cuentas a mano; oráculo `ok`.
- Decisiones: si una pieza usa un artículo que no es perfil (o un panel uno que no es lámina, o un herraje uno que no es herraje), la medición da `familia_no_permitida`; el oráculo no lo revisa, pero las plantillas ya lo impiden.
- Para revisar por Lino (técnico, no urge): el oráculo suma con la versión de Python instalada (3.11.9). Si algún día se regeneran los dorados con Python 3.12 o más nuevo, la suma cambia de método y podría mover el último decimal.
- Sigue: F1-T6.

## 2026-11-19 · F1-T6 · Plantillas: interfaz, esquema, validación y registro

- Hecho: el director escribió la interfaz (`Plantilla`, `ParametroDef`, condiciones de `requerido_si`, `Problema`). El implementador programó la validación genérica desde el esquema (`validarParametros`, `aplicarPlantilla`), el registro (`RegistroPlantillas`) y `numeroBarrotes`. El director leyó el código completo.
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 265 pruebas en verde. Una plantilla de prueba da cada error genérico desde su esquema (`parametro_faltante`, `valor_invalido`, `fuera_de_rango`, `articulo_desconocido`, `familia_no_permitida`, código propio de opción) y el registro devuelve plantillas por id o `plantilla_desconocida`. Oráculo `ok`.
- Decisiones: D-025 (tipos `texto` y `lista`, orden de la validación, códigos `valor_invalido` y `plantilla_desconocida`, advertencias dentro del modelo).
- Sigue: F1-T7.

## 2026-11-19 · F1-T7 · Plantilla `libre`

- Hecho: `lib/motor/plantillas/libre.dart` (`PlantillaLibre`): esquema con listas de piezas, paneles y herrajes, defectos de grupo y corte, y generación del modelo sin posiciones. Lo programó el implementador; el director revisó el código.
- Verificación: formato sin cambios; `flutter analyze` limpio; `flutter test` 274 pruebas en verde; `dorados/libre_barandal_7500.json` coincide de punta a punta (modelo y medición), con su advertencia de empalme; oráculo `ok`.
- Decisiones: rangos del esquema, que la especificación no fijaba (medidas de 1 a 50 000 mm, cantidad de 1 a 10 000, uniones de 0 a 100 000), anotados en `docs/MOTOR_MEDICION.md` §4.3.
- Sigue: F1-T8.
