# Arquitectura

## 1. Vista general

```
                 ┌──────────────────────────── teléfono (sin conexión) ───────────────────────────┐
  voz / foto ──▶ │  IA: propone acciones ──▶ tarjeta de confirmación                              │
  formulario ──▶ │                                   │                                            │
                 │                                   ▼                                            │
                 │   catálogo, tarifas, receta ──▶ MOTOR (Dart puro) ──▶ resultado del presupuesto │
                 │        (base de datos)          plantilla → piezas → cantidades → precio        │
                 │                                   │                                            │
                 │            ┌──────────┬───────────┼────────────┬──────────────┐                │
                 │            ▼          ▼           ▼            ▼              ▼                │
                 │        desglose    plano 2D     3D (visor)    PDF        listas de compra      │
                 │                                                           y de cortes          │
                 └────────────────────────────────────────────────────────────────────────────────┘
        solo con red:  modelo de lenguaje (interpretar) · servidor de render (Blender) · editor de imagen
```

Todo lo que se muestra sale de un único resultado calculado por el motor. Ninguna capa vuelve a medir o a sumar por su cuenta.

## 2. Capas y carpetas

```
lib/
  main.dart
  app/            arranque, rutas, tema, proveedores globales
  motor/          Dart puro. No conoce nada de lo demás
    numeros.dart       EPS, techo, piso, redondear, centavos
    catalogo/          artículo, derivados, calibres, medidas en pulgadas
    plantillas/        interfaz y esquema, registro, reja_ventana, porton_abatible, libre
    medicion/          modelo de piezas, optimizador de cortes, medir, cantidades
    recetas/           léxico, sintaxis, evaluador, receta, evaluar, presentación, calibración
    presupuesto.dart   calcularPresupuesto: la única puerta de entrada
  datos/          Drift: tablas, repositorios, semillas, instantáneas, respaldo
  ia/             acciones, intérprete, clientes de proveedores, instrucciones
  voz/            transcriptor, locutor, sesión de voz
  visual/         plano 2D, escena 3D, PDF, montaje sobre foto, exportación
  ui/             componentes, pantallas por sección, formularios generados
assets/
  semillas/       catálogo, calibres, recetas y tarifas iniciales (EJEMPLO)
  visor3d/        página del visor y three.js
  fuentes/        fuente para el PDF
servidor_render/  servicio de Blender (fase 10)
test/             espejo de lib/, más fixtures/, soporte/ y arquitectura_test.dart
tool/             utilidades en Dart; oraculo/ en Python
docs/
```

Dependencias permitidas entre capas (una flecha es "puede importar"):

```
ui ──▶ app, visual, voz, ia, datos, motor
visual ──▶ motor
ia, voz ──▶ motor
datos ──▶ motor
motor ──▶ (nada)
```

`test/arquitectura_test.dart` recorre los `import` de `lib/` y falla si alguno rompe estas reglas.

## 3. La puerta de entrada del motor

```dart
ResultadoPresupuesto calcularPresupuesto(EntradaPresupuesto entrada);
```

| `EntradaPresupuesto` | |
|---|---|
| `plantilla`, `parametros` | qué trabajo es y sus medidas |
| `datosTrabajo` | campos del trabajo (`con_instalacion`, `distancia_km`…) |
| `catalogo` | artículos y constantes vigentes, o los de una instantánea |
| `parametrosUsuario` | tarifas |
| `receta`, `ajustes` | forma de cobrar y ajustes de este presupuesto |

| `ResultadoPresupuesto` | |
|---|---|
| `problemas` | errores y advertencias; si hay errores, lo demás puede venir vacío |
| `modelo` | modelo de piezas |
| `medicion` | despiece, cortes, por artículo, cantidades |
| `evaluacion` | líneas, agregados, total, rastro |

Es una función pura y rápida: la interfaz la llama en cada cambio del formulario. Nunca lanza por un dato del usuario; los errores esperados regresan en `problemas` con su código.

## 4. Estado y navegación

- Estado con Riverpod. Un controlador por flujo (presupuesto en edición, catálogo, proyectos). Los controladores hablan con repositorios y con `calcularPresupuesto`.
- Navegación con go_router.
- El borrador en edición se guarda solo en cada cambio: cerrar la app a medias no pierde nada.

## 5. Capacidades del teléfono

Cada capacidad va detrás de una interfaz propia, con una implementación real y un doble para pruebas:

| Interfaz | Para qué |
|---|---|
| `Transcriptor` | voz a texto |
| `Locutor` | texto a voz |
| `SelectorDeFotos` | cámara y galería |
| `Compartidor` | enviar PDF o imagen a otra app |
| `AlmacenSeguro` | claves de servicios |
| `ArchivosDeApp` | carpeta de fotos y respaldos |

Si la plataforma no ofrece una capacidad (por ejemplo, al correr en Windows para probar), la función se desactiva con un aviso.

## 6. Dependencias candidatas

Revisa cada una en pub.dev antes de agregarla y anota la versión en `docs/DECISIONES.md`. Si alguna está abandonada o no soporta la plataforma, elige otra y explica por qué.

| Necesidad | Candidato |
|---|---|
| Widgets | `cupertino_ui` (y `material_ui` si hace falta) |
| Estado | `flutter_riverpod` |
| Rutas | `go_router` |
| Base de datos | `drift`, con su paquete de SQLite para Flutter, `drift_dev` y `build_runner` |
| Rutas de archivos | `path_provider`, `path` |
| Formato de dinero y fechas | `intl` |
| PDF | `pdf`, `printing` |
| Compartir | `share_plus` |
| Fotos | `image_picker` |
| Visor 3D | `webview_flutter` con three.js incluido en `assets/` |
| Claves | `flutter_secure_storage` |
| Voz a texto y texto a voz | `speech_to_text`, `flutter_tts` |
| Red | `http` |
| Respaldo en zip | `archive` |
| Elegir archivo de respaldo | `file_picker` |

El motor solo puede usar `collection` y `meta`.

## 7. Plataformas

- **Objetivo**: Android. Es lo que se puede compilar desde Windows.
- **Desarrollo**: si `flutter doctor` reporta listo el escritorio de Windows, agrégalo como plataforma para probar rápido la interfaz. Lo que no exista ahí se desactiva (§5).
- **iOS**: el código no debe impedirlo, pero no se compila ni se prueba: hace falta una Mac.

## 8. Servicios externos

Ninguno es necesario para cotizar.

| Servicio | Uso | Quién lo llama |
|---|---|---|
| Modelo de lenguaje con herramientas y visión | interpretar voz, texto y fotos; redactar recetas | el teléfono, directo, con la clave del usuario |
| Servidor de render | imagen fotorrealista con Blender | el teléfono, a un servidor propio |
| Editor de imagen | armonizar el montaje sobre la foto | el teléfono, directo |
| Voz en la nube (opcional) | transcripción con vocabulario del oficio; conversación en tiempo real | el teléfono, directo |

No hay servidor propio salvo el de render. Como la app es personal, las claves viven en el almacenamiento seguro del teléfono.

## 9. Errores y registro

- Motor: `ErrorMotor(codigo, detalle, posicion)` y listas de problemas. Nada de textos para el usuario dentro del motor.
- Interfaz: traduce cada código a un mensaje claro en `lib/ui/textos.dart`.
- Registro con niveles, sin datos de clientes ni claves. En depuración va a consola; en producción, a un archivo rotativo pequeño que se puede adjuntar al respaldo.

## 10. Identidad del proyecto

- Paquete de Dart: `cotizador_herreria`.
- Nombre visible e identificador de la app: los de `docs/PENDIENTES_LINO.md` (P-01). El identificador se decide antes de instalar en el teléfono; cambiarlo después obliga a reinstalar y restaurar el respaldo.
