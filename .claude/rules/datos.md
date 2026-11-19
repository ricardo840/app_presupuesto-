---
paths:
  - "lib/datos/**"
  - "test/datos/**"
---

# Datos

- SQLite con Drift. Después de cambiar una tabla: `dart run build_runner build --delete-conflicting-outputs`.
- El dinero se guarda en centavos enteros. Las fechas, en UTC.
- Cada cambio de esquema sube `schemaVersion` y trae su migración con prueba. Una migración nunca borra datos del usuario.
- Los documentos JSON guardados en columnas (recetas, parámetros de un trabajo, instantáneas) llevan un campo `version`. Se leen con tolerancia: un campo que falta toma su valor por defecto.
- Los repositorios devuelven modelos del dominio, no filas de Drift. La interfaz no conoce a Drift.
- Una receta no se edita: cada cambio guarda una versión nueva. Los presupuestos apuntan a una versión concreta.
- Una opción en borrador se recalcula con los precios actuales. Al pasar a `enviado` se congela su instantánea y desde entonces solo se lee. Ver `docs/MODELO_DE_DATOS.md` §4.
- Los cambios de estado de un proyecto pasan por una función que valida la transición.
- Las semillas (catálogo, recetas, tarifas) se insertan marcadas como EJEMPLO. El usuario las puede editar o borrar.
- Las fotos se guardan como archivos en la carpeta de la app; la base guarda la ruta relativa.
- Respaldo: exportar e importar todo, con ida y vuelta probada. Ver `docs/MODELO_DE_DATOS.md` §6.
