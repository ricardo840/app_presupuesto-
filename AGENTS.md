# Cotizador de herrería

App móvil en Flutter, de uso personal, para que un herrero cotice al momento y le muestre al cliente cómo quedará el trabajo. Funciona sin conexión. Un solo modelo paramétrico produce el precio, el despiece, la lista de corte y la imagen, así que nunca se contradicen.

El dueño del proyecto es Lino. Todo va en español: código de dominio, comentarios, commits, documentos y textos de la app.

Estas instrucciones son para el agente de programación que trabaje en este repositorio, sea cual sea la herramienta.

## Cómo trabajar

1. Al empezar lee `docs/PROGRESO.md` (las dos últimas entradas), la sección "Correcciones de Lino" de `docs/PENDIENTES_LINO.md` y la fase en curso de `docs/PLAN.md`.
2. Atiende primero las correcciones de Lino. Después toma la primera tarea sin marcar de la fase en curso. Una a la vez y en orden.
3. Antes de programar lee las secciones que la tarea cita. Lo que está especificado no se improvisa.
4. Escribe primero las pruebas que la tarea pide, después el código, después ejecuta el procedimiento `verify`.
5. Con todo en verde: commit, marca la casilla en `docs/PLAN.md`, agrega una entrada a `docs/PROGRESO.md` y pasa a la siguiente tarea. No preguntes si continúas.
6. Al terminar una fase sigue el procedimiento `cierre-de-fase` y continúa con la siguiente.

## Procedimientos

Están en `.claude/skills/<nombre>/SKILL.md`. En Claude Code se invocan como `/<nombre>`. En cualquier otra herramienta, abre el archivo y sigue sus pasos. Cuando un documento diga `/verify` o `/continuar`, se refiere a estos.

| Procedimiento | Para qué |
|---|---|
| `continuar` | tomar la siguiente tarea del plan y llevarla hasta el commit; es el ciclo normal de trabajo |
| `verify` | formato, análisis, pruebas y casos dorados; obligatorio antes de cada commit |
| `nueva-plantilla` | agregar una plantilla paramétrica o cambiar las reglas de una |
| `cierre-de-fase` | cerrar una fase y preparar la siguiente |
| `estado` | resumirle a Lino cómo va el proyecto |

## Qué leer antes de tocar cada cosa

| Vas a trabajar en | Documento | Reglas de la carpeta |
|---|---|---|
| Plantillas, despiece, cortes, cantidades (`lib/motor/`) | `docs/MOTOR_MEDICION.md` | `.claude/rules/motor.md` |
| Fórmulas, recetas, dinero, presentación al cliente (`lib/motor/recetas/`) | `docs/MOTOR_RECETAS.md` | `.claude/rules/motor.md` |
| Tablas, repositorios, instantáneas, respaldo (`lib/datos/`) | `docs/MODELO_DE_DATOS.md` | `.claude/rules/datos.md` |
| Pantallas y flujos (`lib/ui/`, `lib/app/`) | `docs/ESPECIFICACION.md` | `.claude/rules/interfaz.md` |
| Plano 2D, 3D, PDF, montaje sobre foto (`lib/visual/`, `assets/visor3d/`) | `docs/VISUAL.md` | `.claude/rules/visual.md` |
| Voz, intérprete, proveedores de IA (`lib/ia/`, `lib/voz/`) | `docs/IA_Y_VOZ.md` | `.claude/rules/ia.md` |
| Servidor de render (`servidor_render/`) | `docs/VISUAL.md` §6 | `.claude/rules/servidor-render.md` |
| Cualquier prueba (`test/`, `tool/oraculo/`) | — | `.claude/rules/pruebas.md` |
| Carpetas, capas, dependencias | `docs/ARQUITECTURA.md` | — |
| Palabras del oficio | `docs/GLOSARIO.md` | — |
| Repartir trabajo entre modelos para gastar menos | `docs/DIRECCION.md` | — |

En Claude Code las reglas de carpeta se cargan solas al abrir archivos de esa carpeta. En otra herramienta, léelas tú antes de tocarla.

## Reglas que no se negocian

1. **La IA propone, el motor calcula, el usuario confirma.** Ninguna medida calculada ni cantidad de dinero sale de un modelo de lenguaje.
2. **`lib/motor/` es Dart puro**: sin Flutter, sin `dart:io`, sin `dart:ui`, sin reloj, sin azar. Misma entrada, misma salida.
3. **Unidades internas**: longitudes en mm, pesos en kg, áreas en m², dinero en centavos enteros. Se convierte solo en los bordes (pantalla, PDF, voz).
4. **Dinero**: solo se redondea con las funciones de `docs/MOTOR_RECETAS.md` §1.
5. **Un solo punto de cálculo**: la interfaz y la IA obtienen precios únicamente de `calcularPresupuesto` (`lib/motor/presupuesto.dart`).
6. **Un presupuesto enviado no cambia**: guarda una instantánea de precios, parámetros, receta y resultado.
7. **Los dorados mandan**: `test/fixtures/` y `tool/oraculo/` no se editan para hacer pasar una prueba. La única excepción está en `.claude/rules/pruebas.md`.
8. **Sin conexión primero**: todo lo que no sea IA en la nube o render remoto funciona sin red.
9. **Sin secretos en el repositorio.** Las claves se capturan en Ajustes y viven en el almacenamiento seguro del teléfono.
10. **Nada inventado como real**: los datos de ejemplo llevan la marca EJEMPLO en pantalla y en el PDF.
11. **Solo este repositorio.** No uses las cuentas ni los servicios personales de Lino (Drive, notas, correo, calendario) ni escribas fuera de esta carpeta, salvo que él lo pida en ese momento.

## Comandos

```
flutter pub get
dart format .
flutter analyze
flutter test                      # todo
flutter test test/motor           # solo el motor
dart run build_runner build --delete-conflicting-outputs   # después de cambiar tablas de Drift
python tool/oraculo/oraculo.py --verificar                 # en Linux y macOS: python3
```

El equipo de Lino es Windows. Los comandos y scripts deben funcionar ahí: nada de scripts `.sh`; si hace falta una herramienta, va en Dart dentro de `tool/`.

## Convenciones

- Comentarios en español, breves, que expliquen el porqué y no repitan el código.
- Nombres del dominio en español, sin acentos ni ñ: `Pieza`, `travesano`, `evaluarReceta`. Lo propio de Dart y Flutter se queda en inglés: `Widget`, `build`, `toJson`.
- Archivos en `snake_case`. Las pruebas reflejan la ruta de `lib/`: `lib/motor/medicion/cortes.dart` → `test/motor/medicion/cortes_test.dart`.
- Modelos inmutables. Sin `dynamic` fuera de la lectura de JSON. Sin `print`.
- Los errores esperados del motor son `ErrorMotor` con un `codigo` estable, el mismo de la especificación. La interfaz los traduce a mensajes para el usuario.
- La lógica vive en funciones puras que se prueban sin interfaz; los widgets solo muestran y piden.
- Un `TODO` solo es válido si cita una tarea del plan: `// TODO(F9-T2): ...`.

## Dependencias y APIs

- Tu memoria de paquetes y APIs puede estar vieja. Antes de agregar una dependencia abre su página en pub.dev y revisa versión, plataformas, fecha de la última publicación y licencia. Antes de usar la API de un proveedor (IA, voz, imágenes) lee su documentación vigente.
- Usa la versión estable más reciente de Flutter. Desde Flutter 3.47 los widgets de diseño vienen en los paquetes `cupertino_ui` y `material_ui`; confirma en la documentación oficial cómo importarlos al crear el proyecto.
- Cada dependencia nueva se anota en `docs/DECISIONES.md` con una línea que diga por qué.
- Los candidatos ya evaluados están en `docs/ARQUITECTURA.md` §6.

## Cuándo detenerte

Sigue trabajando por tu cuenta salvo en estos casos:

- **No hay con qué verificar.** Falta `flutter`, o el proyecto no compila por el entorno. Explica qué falta y detente. No escribas código que no puedas probar.
- **Tres intentos distintos fallaron en la misma tarea.** Descarta los cambios con `git restore .`, anota en `docs/PROGRESO.md` qué probaste y por qué falló, regístralo en "Bloqueos" de `docs/PENDIENTES_LINO.md` y pasa a la siguiente tarea que no dependa de esa. Si no hay ninguna, detente.
- **Falta algo que solo Lino puede dar** y `docs/PENDIENTES_LINO.md` no trae un valor por defecto. Si lo trae, úsalo y sigue.
- **Algo irreversible o hacia afuera**: `git push`, publicar, borrar datos que no creaste, llamar a un servicio de pago. Pide confirmación.
- **Un dorado contradice a la especificación.** Sigue `.claude/rules/pruebas.md`.

Si la sesión se alarga y empiezas a perder detalle, termina la tarea en curso, deja todo en un commit y detente con un resumen. La siguiente sesión retoma con el procedimiento `continuar`.

## Git

- Rama `main`. Al menos un commit por tarea, con su identificador: `F1-T3: optimizador de cortes`.
- Etiqueta `fase-N` al cerrar cada fase.
- Sin `git push` salvo que Lino lo pida. Sin reescribir historia: nada de `rebase`, `--amend` sobre commits etiquetados ni `reset --hard`.
- No subas claves, `key.properties`, almacenes de llaves ni fotos de clientes.

## Una tarea está terminada cuando

- cumple cada punto de su "Hecho cuando" en `docs/PLAN.md`;
- tiene pruebas nuevas que fallarían sin el cambio;
- el procedimiento `verify` termina en verde;
- los documentos reflejan cualquier contrato que haya cambiado;
- está en un commit, con la casilla marcada y la entrada en `docs/PROGRESO.md`.

Nunca marques como hecho algo que no verificaste. Lo que no se puede probar sin un teléfono (micrófono, cámara, compartir) se anota en `docs/PROGRESO.md` bajo "Sin verificar en dispositivo".
