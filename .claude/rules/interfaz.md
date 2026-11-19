---
paths:
  - "lib/ui/**"
  - "lib/app/**"
  - "test/ui/**"
---

# Interfaz

- Quien usa la app es un herrero, de pie, en la obra o en el taller, a veces con guantes y bajo el sol. Texto grande, alto contraste, zonas de toque de 48 px o más, pocos pasos.
- Los widgets no calculan. Piden el resultado a un controlador, y este a `calcularPresupuesto`. Ningún widget multiplica precios ni suma líneas.
- Las pantallas usan los componentes de `lib/ui/componentes/` (botones, campos de medida, tarjetas, listas). El estilo se decide ahí, en un solo lugar; es Cupertino mientras Lino no diga otra cosa en `docs/PENDIENTES_LINO.md`.
- Tema claro y oscuro. Sigue al sistema y se puede forzar en Ajustes.
- Textos en español de México, reunidos en `lib/ui/textos.dart`. Sin jerga de programador: "receta" es "forma de cobrar", "parámetro" es "tarifa".
- Dinero con formato `$12,345.00`. Medidas en metros con dos decimales por defecto; los perfiles se nombran en pulgadas y calibre, como en la tienda.
- Cada pantalla resuelve cuatro estados: cargando, vacío (con una acción para empezar), con datos y error (con un mensaje claro y qué hacer).
- Los formularios de medidas se generan desde el esquema de la plantilla. No se escribe una pantalla por plantilla.
- Lo que borra o no se puede deshacer pide confirmación.
- Modo cliente: nunca muestra costos internos, utilidad, rastro de fórmulas ni datos marcados como EJEMPLO sin su etiqueta.
- Cada capacidad del teléfono (micrófono, cámara, compartir, almacenamiento seguro) se usa a través de una interfaz propia con un doble para pruebas. Si la plataforma no la tiene, la función se desactiva con un aviso; la app no se cae.
- Etiquetas de accesibilidad en botones de solo icono. La app debe poder usarse con el tamaño de letra del sistema al 130 %.
- Cada pantalla tiene pruebas de widget de su comportamiento principal.
