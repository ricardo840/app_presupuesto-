---
paths:
  - "lib/visual/**"
  - "assets/visor3d/**"
  - "test/visual/**"
---

# Visual

- Lo visual no mide ni calcula: dibuja el modelo de piezas que entrega el motor. Si un dibujo necesita un dato que no está en el modelo, el dato se agrega al motor.
- Cada salida se arma con una función pura que se prueba sin pantalla: `construirPlano` devuelve primitivas, `construirEscena` devuelve la escena en JSON, `calcularHomografia` devuelve una matriz, `construirPdf` devuelve bytes. El `CustomPainter`, el visor y la pantalla solo pintan ese resultado.
- La escena en JSON es la misma para el visor del teléfono y para el servidor de render.
- El visor 3D funciona sin conexión: three.js va dentro de `assets/visor3d/`, con su licencia y la versión anotada en `docs/DECISIONES.md`. Nada se carga desde una red de distribución.
- El JavaScript del visor es tonto: recibe la escena y la muestra. Sin reglas de negocio.
- Las cotas salen de las medidas del modelo y se muestran en las unidades del usuario.
- Lo que ve el cliente es ilustrativo salvo el plano con cotas. Las imágenes generadas o montadas llevan la leyenda "Imagen ilustrativa".
- El PDF usa una fuente incluida en `assets/fuentes/` que tenga acentos, ñ y el signo de pesos.
