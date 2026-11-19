---
paths:
  - "lib/ia/**"
  - "lib/voz/**"
  - "test/ia/**"
  - "test/voz/**"
---

# IA y voz

- El modelo de lenguaje nunca calcula. Traduce lo que dijo el usuario a **acciones** (`docs/IA_Y_VOZ.md` §2). Los totales que se muestran o se leen en voz alta vienen de `calcularPresupuesto`.
- Toda acción que cambia datos pasa por la tarjeta de confirmación antes de aplicarse. El usuario puede corregirla o cancelarla.
- Una acción inválida (plantilla que no existe, parámetro fuera de rango, artículo desconocido) no se aplica: se le devuelve el error al modelo para que corrija o pregunte.
- Cada proveedor vive detrás de una interfaz (`ClienteLlm`, `Transcriptor`, `Locutor`, `EditorDeImagen`, `ServicioDeRender`) con un doble para pruebas. El resto de la app no conoce al proveedor.
- Antes de escribir o cambiar un adaptador, lee la documentación vigente del proveedor. Los identificadores de modelo son configurables en Ajustes; no se dejan fijos en el código.
- Las claves se capturan en Ajustes, se guardan en el almacenamiento seguro y nunca se escriben en registros, pruebas ni mensajes de error.
- Tiempo máximo y un reintento en cada llamada. Sin red o sin clave, la función se desactiva con un mensaje claro y el resto de la app sigue.
- Las instrucciones para el modelo están en archivos versionados dentro de `lib/ia/instrucciones/`, no regadas por el código.
- Al modelo se le manda lo mínimo: el catálogo resumido, los esquemas de plantilla y el borrador actual. Nombres, teléfonos y direcciones de clientes no se envían.
- Una foto solo sale del teléfono cuando el usuario toca una acción que lo dice con claridad.
- Las pruebas usan dobles y respuestas grabadas. Ninguna prueba automática gasta dinero.
