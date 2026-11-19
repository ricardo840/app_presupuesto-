/// Plantilla `libre`: despiece capturado a mano
/// (`docs/MOTOR_MEDICION.md` §4.3). Longitudes en mm.
library;

import '../catalogo/articulo.dart';
import '../catalogo/catalogo.dart';
import '../medicion/modelo.dart';
import '../problema.dart';
import 'plantilla.dart';

/// Trabajo libre: el usuario o la IA dan la lista de piezas, paneles y herrajes.
class PlantillaLibre implements Plantilla {
  const PlantillaLibre();

  @override
  String get id => 'libre';

  @override
  String get nombre => 'Trabajo libre';

  @override
  List<ParametroDef> get esquema => const [
    ParametroDef(
      clave: 'ancho',
      etiqueta: 'Ancho',
      tipo: TipoParametro.longitud,
      min: 1,
      max: 50000,
      ayuda: 'Ancho general del trabajo en mm; sirve para calcular el área.',
    ),
    ParametroDef(
      clave: 'alto',
      etiqueta: 'Alto',
      tipo: TipoParametro.longitud,
      min: 1,
      max: 50000,
      ayuda: 'Alto general del trabajo en mm; sirve para calcular el área.',
    ),
    ParametroDef(
      clave: 'piezas',
      etiqueta: 'Piezas',
      tipo: TipoParametro.lista,
      defecto: <Object?>[],
      ayuda: 'Lista de barras de perfil que se cortan, cada una con su largo.',
      campos: [
        ParametroDef(
          clave: 'grupo',
          etiqueta: 'Grupo',
          tipo: TipoParametro.texto,
          defecto: 'piezas',
          ayuda: 'Nombre del conjunto de la pieza, por ejemplo postes.',
        ),
        ParametroDef(
          clave: 'articulo',
          etiqueta: 'Artículo',
          tipo: TipoParametro.articulo,
          tiposArticulo: {TipoArticulo.perfil},
          ayuda: 'Clave del perfil del catálogo con el que se hace la pieza.',
        ),
        ParametroDef(
          clave: 'largo',
          etiqueta: 'Largo',
          tipo: TipoParametro.longitud,
          min: 1,
          max: 50000,
          ayuda: 'Largo de corte de la pieza en mm.',
        ),
        ParametroDef(
          clave: 'cantidad',
          etiqueta: 'Cantidad',
          tipo: TipoParametro.entero,
          min: 1,
          max: 10000,
          ayuda: 'Cuántas piezas iguales se necesitan.',
        ),
        ParametroDef(
          clave: 'corte',
          etiqueta: 'Corte',
          tipo: TipoParametro.opcion,
          defecto: 'recto',
          opciones: ['recto', 'inglete'],
          ayuda: 'Recto es a escuadra; inglete es a 45 grados en los extremos.',
        ),
      ],
    ),
    ParametroDef(
      clave: 'paneles',
      etiqueta: 'Paneles',
      tipo: TipoParametro.lista,
      defecto: <Object?>[],
      ayuda: 'Lista de rectángulos de lámina que se cortan.',
      campos: [
        ParametroDef(
          clave: 'grupo',
          etiqueta: 'Grupo',
          tipo: TipoParametro.texto,
          defecto: 'paneles',
          ayuda: 'Nombre del conjunto del panel, por ejemplo hojas.',
        ),
        ParametroDef(
          clave: 'articulo',
          etiqueta: 'Artículo',
          tipo: TipoParametro.articulo,
          tiposArticulo: {TipoArticulo.lamina},
          ayuda: 'Clave de la lámina del catálogo con la que se hace el panel.',
        ),
        ParametroDef(
          clave: 'ancho',
          etiqueta: 'Ancho',
          tipo: TipoParametro.longitud,
          min: 1,
          max: 50000,
          ayuda: 'Ancho del panel en mm.',
        ),
        ParametroDef(
          clave: 'alto',
          etiqueta: 'Alto',
          tipo: TipoParametro.longitud,
          min: 1,
          max: 50000,
          ayuda: 'Alto del panel en mm.',
        ),
        ParametroDef(
          clave: 'cantidad',
          etiqueta: 'Cantidad',
          tipo: TipoParametro.entero,
          min: 1,
          max: 10000,
          ayuda: 'Cuántos paneles iguales se necesitan.',
        ),
      ],
    ),
    ParametroDef(
      clave: 'herrajes',
      etiqueta: 'Herrajes',
      tipo: TipoParametro.lista,
      defecto: <Object?>[],
      ayuda: 'Lista de herrajes que se compran por pieza.',
      campos: [
        ParametroDef(
          clave: 'articulo',
          etiqueta: 'Artículo',
          tipo: TipoParametro.articulo,
          tiposArticulo: {TipoArticulo.herraje},
          ayuda: 'Clave del herraje del catálogo.',
        ),
        ParametroDef(
          clave: 'cantidad',
          etiqueta: 'Cantidad',
          tipo: TipoParametro.entero,
          min: 1,
          max: 10000,
          ayuda: 'Cuántas piezas del herraje se necesitan.',
        ),
      ],
    ),
    ParametroDef(
      clave: 'uniones',
      etiqueta: 'Uniones',
      tipo: TipoParametro.entero,
      defecto: 0,
      min: 0,
      max: 100000,
      ayuda: 'Número de uniones soldadas, contadas a mano.',
    ),
  ];

  @override
  List<Problema> validarReglas(
    Map<String, Object?> parametros,
    Catalogo catalogo,
  ) => const [];

  @override
  ModeloPiezas generar(Map<String, Object?> parametros, Catalogo catalogo) {
    List<Map<String, Object?>> lista(String k) =>
        (parametros[k]! as List<Object?>).cast<Map<String, Object?>>();
    final piezas = lista('piezas');
    final paneles = lista('paneles');
    final herrajes = lista('herrajes');
    return ModeloPiezas(
      plantilla: id,
      caja: (
        ancho: (parametros['ancho']! as num).toDouble(),
        alto: (parametros['alto']! as num).toDouble(),
      ),
      numHojas: 0,
      piezas: [
        for (var i = 0; i < piezas.length; i++)
          Pieza(
            id: 'pieza-${i + 1}',
            grupo: piezas[i]['grupo']! as String,
            articulo: piezas[i]['articulo']! as String,
            largo: (piezas[i]['largo']! as num).toDouble(),
            cantidad: piezas[i]['cantidad']! as int,
            corte: TipoCorte.values.byName(piezas[i]['corte']! as String),
          ),
      ],
      paneles: [
        for (var i = 0; i < paneles.length; i++)
          Panel(
            id: 'panel-${i + 1}',
            grupo: paneles[i]['grupo']! as String,
            articulo: paneles[i]['articulo']! as String,
            ancho: (paneles[i]['ancho']! as num).toDouble(),
            alto: (paneles[i]['alto']! as num).toDouble(),
            cantidad: paneles[i]['cantidad']! as int,
          ),
      ],
      herrajes: [
        for (final h in herrajes)
          Herraje(
            articulo: h['articulo']! as String,
            cantidad: h['cantidad']! as int,
          ),
      ],
      uniones: {'manual': parametros['uniones']! as int},
    );
  }
}
