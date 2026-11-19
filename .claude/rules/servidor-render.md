---
paths:
  - "servidor_render/**"
---

# Servidor de render

- Servicio pequeño y sin estado en Python: recibe la escena en JSON (la misma del visor) y devuelve una imagen PNG. Ver `docs/VISUAL.md` §6.
- No mide ni cotiza. Si le falta un dato, el dato se agrega a la escena desde el motor.
- Cada petición lleva un token que se lee de una variable de entorno. Sin token configurado, el servidor no arranca.
- Límites en cada petición: tamaño de imagen, número de piezas y tiempo máximo de render.
- Las dependencias van con versión fija en `requirements.txt`. Lee la documentación vigente de Blender antes de usar su API de Python.
- Las pruebas que necesitan Blender se marcan aparte y se pueden saltar donde no esté instalado; la construcción de la escena se prueba sin Blender.
- Incluye un `LEEME.md` con los pasos para correrlo en la PC de Lino (Windows) y en un servidor con GPU.
