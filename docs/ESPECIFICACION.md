# Especificación

## 1. Para quién y para qué

Un herrero visita a un cliente, toma medidas y hoy tarda horas o días en dar precio: tiene que hacer el despiece, ver precios del acero y calcular mano de obra. Mientras tanto el cliente no sabe cuánto costará ni cómo se verá.

La app acorta eso a minutos, ahí mismo: el herrero dice o captura las medidas, la app calcula con **su** forma de cobrar y le enseña al cliente el precio y una imagen del trabajo terminado.

Es de uso personal: un solo usuario, un solo teléfono, sin cuentas ni servidor propio. Lino la construye y la mantiene.

## 2. Principios

1. **Rápida en la obra.** Un presupuesto común se arma en menos de un minuto, con una mano.
2. **Cobra como él cobra.** La forma de cotizar se configura; la app no impone la suya.
3. **Lo que se ve es lo que se cobra y lo que se fabrica.** Precio, plano, lista de corte e imagen salen del mismo modelo.
4. **Explicable.** Cada número dice de dónde salió.
5. **Sin conexión.** La obra no siempre tiene señal.
6. **La voz ayuda, no decide.** La app confirma lo que entendió antes de calcular.

## 3. Secciones

Barra inferior con cinco pestañas:

| Pestaña | Contenido |
|---|---|
| **Inicio** | botón grande "Nuevo presupuesto", botón de micrófono, pendientes recientes y aviso de precios viejos |
| **Proyectos** | tres vistas: Pendientes, Opciones y Anteriores |
| **Catálogo** | materiales y precios |
| **Formas de cobrar** | recetas, tarifas y campos del trabajo |
| **Ajustes** | datos del negocio, condiciones, voz e IA, unidades, tema, respaldo |

**Proyectos**, las tres vistas que pidió Lino:

- **Pendientes**: trabajos reales en estado borrador, enviado, aprobado o en proceso.
- **Opciones**: modelos y simulaciones guardados para enseñar o reutilizar (sin cliente ni compromiso), y los presupuestos que tienen varias alternativas por decidir. Desde aquí se comparan lado a lado.
- **Anteriores**: trabajos terminados y rechazados, con sus fotos, lo cobrado y las horas reales. Sirven de portafolio y de base para simular trabajos nuevos.

## 4. Flujos

### 4.1 Cotizar con una plantilla

1. "Nuevo presupuesto" → elegir tipo de trabajo (tarjetas con dibujo: reja, portón, trabajo libre…).
2. Formulario de medidas generado desde la plantilla. Arriba, el plano se redibuja con cada cambio. Teclado numérico grande; los materiales se eligen del catálogo.
3. El total aparece desde el primer momento y cambia en vivo. Los errores de medidas se explican junto al campo.
4. Pantalla de resultado: total grande, forma de cobrar usada (se puede cambiar), desglose, y pestañas **Plano**, **3D**, **Foto**, **Materiales** y **Cortes**.
5. Acciones: guardar, agregar opción, ajustar, enseñar al cliente, compartir.

### 4.2 Cotizar hablando

1. Mantener presionado el micrófono y describir: "Reja para ventana de uno veinte por uno, con cuadrado de media, separación de doce, con instalación".
2. Aparece la **tarjeta de confirmación** con lo entendido, en palabras y medidas. Se confirma, se corrige a mano o se vuelve a hablar.
3. Si falta algo indispensable, la app lo pregunta, en voz y en pantalla.
4. Al confirmar se calcula y la app dice el total en voz alta.
5. Después se pueden dar órdenes: "hazla de uno cincuenta de ancho", "otra opción con redondo", "quítale la instalación", "¿cuánto es de material?".

### 4.3 Cotizar desde una foto

El cliente enseña la foto de un diseño que le gusta, o el herrero toma una del croquis. La app propone plantilla y parámetros aproximados en la tarjeta de confirmación. El herrero ajusta las medidas reales.

### 4.4 Trabajo libre

Para lo que no cabe en una plantilla: se capturan a mano (o por voz) las piezas, láminas, herrajes y uniones. No hay dibujo automático, pero el precio, la lista de compra y la de cortes sí.

### 4.5 Enseñar al cliente

**Modo cliente**: pantalla completa y limpia con la imagen (plano, 3D o montaje sobre la foto de su casa), el total y, si hay varias, las opciones para comparar. No muestra costos internos, utilidad ni fórmulas. Se sale con un gesto deliberado.

**Montaje sobre la foto**: se toma la foto del lugar, se marcan las cuatro esquinas del vano y la app coloca el dibujo en perspectiva. Funciona sin conexión.

### 4.6 Enviar

PDF o imagen para WhatsApp con: datos del negocio, cliente, imagen del trabajo, descripción, precio en el nivel de detalle elegido (solo total, por categorías o por conceptos), condiciones (anticipo, vigencia, tiempo de entrega, garantía) y folio. Al enviar, el presupuesto se congela.

### 4.7 Ajustar un presupuesto

Sin tocar la forma de cobrar: cambiar una tarifa solo para este trabajo, fijar una línea a mano, agregar una línea extra, dar descuento, activar IVA.

### 4.8 Seguir el trabajo

Estados: borrador → enviado → aprobado → en proceso → terminado, o rechazado. En proceso se registran horas reales (también por voz) y fotos. Al terminar, la app compara lo estimado con lo real.

### 4.9 Mantener precios

Catálogo con búsqueda. Cada artículo muestra su precio y hace cuánto se actualizó. Actualizar es rápido, también por voz ("el PTR de dos calibre catorce subió a seiscientos cincuenta"). Los presupuestos enviados conservan el precio que tenían.

### 4.10 Enseñarle a la app cómo cobra

Asistente de calibración: se capturan de 3 a 5 trabajos ya cotizados con el precio cobrado; el herrero explica cómo calculó; la app propone una forma de cobrar, la prueba contra esos trabajos y muestra la diferencia en cada uno. Se ajusta hasta que cuadre. Los trabajos quedan como pruebas para cambios futuros.

## 5. Requisitos

| ID | Requisito | Fase |
|---|---|---|
| R-01 | Presupuesto con plantilla, formulario generado y cálculo en vivo | 4 |
| R-02 | Trabajo libre | 1, 4 |
| R-03 | Catálogo con precios, fecha del precio e historial | 3, 4 |
| R-04 | Tarifas y campos del trabajo definidos por el usuario | 3, 4 |
| R-05 | Formas de cobrar configurables, con editor simple y avanzado, validación y vista previa | 2, 4 |
| R-06 | Desglose con el origen de cada número | 2, 4 |
| R-07 | Ajustes por presupuesto | 2, 4 |
| R-08 | Proyectos con estados y las vistas Pendientes, Opciones y Anteriores | 3, 4 |
| R-09 | Opciones de un mismo trabajo, lado a lado | 8 |
| R-10 | Un presupuesto enviado no cambia aunque cambien precios o recetas | 3 |
| R-11 | Plano 2D con cotas | 5 |
| R-12 | 3D interactivo con acabados | 6 |
| R-13 | Montaje sobre la foto del lugar | 5 |
| R-14 | PDF e imagen para compartir, en tres niveles de detalle | 5 |
| R-15 | Modo cliente | 5 |
| R-16 | Lista de compra y lista de cortes | 4 |
| R-17 | Cotizar hablando, con confirmación y respuesta en voz | 7 |
| R-18 | Órdenes de voz sobre el presupuesto, los precios y las horas | 7 |
| R-19 | Propuesta a partir de una foto o croquis | 7 |
| R-20 | Calibración con trabajos pasados y pruebas del usuario | 2, 8 |
| R-21 | Horas reales contra estimadas | 8 |
| R-22 | Simular a partir de un trabajo anterior y buscar similares | 8 |
| R-23 | Portafolio de trabajos terminados | 8 |
| R-24 | Respaldo y restauración completos | 3, 12 |
| R-25 | Todo lo anterior, salvo R-17 a R-19, funciona sin conexión | todas |
| R-26 | Render fotorrealista y armonización del montaje | 10 |
| R-27 | Datos del negocio y condiciones en el PDF | 4, 5 |
| R-28 | Plantillas: reja, portón abatible y libre; después puerta, corredizo, barandal, techumbre, escalera recta y base de tinaco | 1, 9 |
| R-29 | Conversación de voz en tiempo real (opcional) | 11 |
| R-30 | Realidad aumentada (opcional) | 11 |

## 6. Calidad

- **Exactitud**: el motor coincide con los casos dorados al centavo.
- **Velocidad**: recalcular un trabajo típico tarda menos de 50 ms; abrir la app, menos de 2 s en un teléfono de gama media.
- **Uso en campo**: letra grande, alto contraste, botones amplios, tema claro y oscuro.
- **Datos seguros**: nada se pierde al cerrar la app a medias; respaldo manual a un archivo.
- **Privacidad**: los datos de clientes no salen del teléfono. Las fotos y descripciones solo se envían a un servicio de IA cuando el usuario usa esa función.
- **Honestidad**: lo que es ejemplo se marca como ejemplo; lo que es ilustrativo, como ilustrativo.

## 7. Fuera de alcance

Cuentas de usuario y sincronización entre equipos, facturación fiscal, cobros, tienda de materiales, cálculo estructural y uso por varios herreros a la vez. El precio que da la app es un presupuesto, no un dictamen de ingeniería.

## 8. Terminado

La app está terminada cuando las fases 0 a 10 y la 12 de `docs/PLAN.md` están cerradas, cada requisito R-01 a R-28 tiene su prueba o su verificación manual anotada, y Lino la instaló en el teléfono y cotizó con ella un trabajo real. La fase 11 es opcional.
