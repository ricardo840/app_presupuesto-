import 'package:flutter_test/flutter_test.dart';
import 'package:linforge/motor/catalogo/articulo.dart';
import 'package:linforge/motor/catalogo/catalogo.dart';
import 'package:linforge/motor/error_motor.dart';
import 'package:linforge/motor/medicion/modelo.dart';
import 'package:linforge/motor/plantillas/plantilla.dart';
import 'package:linforge/motor/plantillas/validacion.dart';
import 'package:linforge/motor/problema.dart';

import '../../soporte/fixtures.dart';

class _Prueba implements Plantilla {
  int llamadasReglas = 0;
  List<Problema> reglas = const [];
  ErrorMotor? falla;

  @override
  String get id => 'prueba';
  @override
  String get nombre => 'Prueba';

  @override
  List<ParametroDef> get esquema => const [
    ParametroDef(
      clave: 'ancho',
      etiqueta: 'Ancho',
      tipo: TipoParametro.longitud,
      defecto: 1000,
      min: 300,
      max: 2000,
    ),
    ParametroDef(
      clave: 'travesanos',
      etiqueta: 'Travesaños',
      tipo: TipoParametro.entero,
      defecto: 0,
      min: 0,
      max: 5,
    ),
    ParametroDef(
      clave: 'relleno',
      etiqueta: 'Relleno',
      tipo: TipoParametro.opcion,
      defecto: 'barrotes',
      opciones: ['barrotes', 'lamina', 'mixto'],
      codigoOpcionInvalida: 'relleno_no_soportado',
    ),
    ParametroDef(
      clave: 'doble',
      etiqueta: 'Doble',
      tipo: TipoParametro.booleano,
      defecto: false,
    ),
    ParametroDef(
      clave: 'marco',
      etiqueta: 'Marco',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.perfil},
      familias: {Familia.tubular, Familia.cuadrado},
    ),
    ParametroDef(
      clave: 'pasador',
      etiqueta: 'Pasador',
      tipo: TipoParametro.articulo,
      tiposArticulo: {TipoArticulo.herraje},
      requerido: false,
    ),
    ParametroDef(
      clave: 'travesano',
      etiqueta: 'Perfil de travesaño',
      tipo: TipoParametro.articulo,
      requeridoSi: SiMayorQue('travesanos', 0),
    ),
    ParametroDef(
      clave: 'alto_lamina',
      etiqueta: 'Alto de lámina',
      tipo: TipoParametro.longitud,
      min: 100,
      requeridoSi: SiEsOpcion('relleno', ['lamina', 'mixto']),
    ),
    ParametroDef(
      clave: 'piezas',
      etiqueta: 'Piezas',
      tipo: TipoParametro.lista,
      requerido: false,
      campos: [
        ParametroDef(
          clave: 'largo',
          etiqueta: 'Largo',
          tipo: TipoParametro.longitud,
          min: 10,
        ),
        ParametroDef(
          clave: 'cantidad',
          etiqueta: 'Cantidad',
          tipo: TipoParametro.entero,
          min: 1,
        ),
        ParametroDef(
          clave: 'corte',
          etiqueta: 'Corte',
          tipo: TipoParametro.opcion,
          defecto: 'recto',
          opciones: ['recto', 'ingletes'],
        ),
        ParametroDef(
          clave: 'grupo',
          etiqueta: 'Grupo',
          tipo: TipoParametro.texto,
          defecto: 'piezas',
        ),
      ],
    ),
  ];

  @override
  List<Problema> validarReglas(Map<String, Object?> p, Catalogo c) {
    llamadasReglas++;
    return reglas;
  }

  @override
  ModeloPiezas generar(Map<String, Object?> p, Catalogo c) {
    if (falla != null) throw falla!;
    return ModeloPiezas(
      plantilla: id,
      caja: (ancho: p['ancho']! as double, alto: 1000),
      numHojas: 1,
    );
  }
}

void main() {
  final catalogo = Catalogo.fromJson(cargarEntrada('catalogo'));
  const base = <String, Object?>{'marco': 'ptr-2x2-c14'};

  ResultadoValidacion valida(
    Map<String, Object?> extra, {
    _Prueba? p,
    bool sinBase = false,
  }) => validarParametros(p ?? _Prueba(), {
    if (!sinBase) ...base,
    ...extra,
  }, catalogo);

  group('validarParametros', () {
    test('sin problemas aplica defectos y descarta claves desconocidas', () {
      final r = valida({'basura': 7});
      expect(r.problemas, isEmpty);
      expect(r.hayErrores, false);
      expect(r.parametros['ancho'], 1000.0);
      expect(r.parametros['travesanos'], 0);
      expect(r.parametros['relleno'], 'barrotes');
      expect(r.parametros['doble'], false);
      expect(r.parametros.containsKey('basura'), false);
    });

    test('un null explícito también toma el defecto', () {
      expect(valida({'ancho': null}).parametros['ancho'], 1000.0);
    });

    test('parametro_faltante cuando es requerido y no hay defecto', () {
      final r = valida({}, sinBase: true);
      expect(
        r.problemas,
        contains(const Problema('parametro_faltante', parametro: 'marco')),
      );
    });

    test('requerido:false acepta null sin problema', () {
      final r = valida({'pasador': null});
      expect(r.problemas, isEmpty);
      expect(r.parametros['pasador'], isNull);
    });

    test('valor_invalido por tipo equivocado', () {
      for (final e in <String, Object?>{
        'ancho': 'mucho',
        'travesanos': 2.5,
        'relleno': 3,
        'doble': 'si',
        'marco': 4,
        'piezas': 'x',
      }.entries) {
        final r = valida({'travesano': 'cuadrado-1-2', e.key: e.value});
        expect(
          r.problemas.single,
          Problema('valor_invalido', parametro: e.key, detalle: '${e.value}'),
          reason: e.key,
        );
      }
      expect(
        valida({'ancho': double.nan}).problemas.single.codigo,
        'valor_invalido',
      );
      expect(
        valida({
          'piezas': [3],
        }).problemas.single.codigo,
        'valor_invalido',
      );
    });

    test('fuera_de_rango y sus bordes', () {
      expect(valida({'ancho': 300}).problemas, isEmpty);
      expect(valida({'ancho': 2000}).problemas, isEmpty);
      expect(valida({'ancho': 300 - 5e-10}).problemas, isEmpty);
      expect(valida({'ancho': 2000 + 5e-10}).problemas, isEmpty);
      expect(
        valida({'ancho': 300 - 1e-6}).problemas.single,
        Problema(
          'fuera_de_rango',
          parametro: 'ancho',
          detalle: '${300 - 1e-6}',
        ),
      );
      expect(valida({'ancho': 2001}).problemas.single.codigo, 'fuera_de_rango');
      expect(
        valida({'travesanos': 6, 'travesano': 'cuadrado-1-2'})
            .problemas
            .single
            .codigo,
        'fuera_de_rango',
      );
      expect(
        valida({'travesanos': -1}).problemas.single.codigo,
        'fuera_de_rango',
      );
    });

    test('un entero 3.0 se normaliza a int 3', () {
      final r = valida({'travesanos': 3.0, 'travesano': 'cuadrado-1-2'});
      expect(r.problemas, isEmpty);
      expect(r.parametros['travesanos'], isA<int>());
      expect(r.parametros['travesanos'], 3);
    });

    test('una longitud entera se normaliza a double', () {
      expect(valida({'ancho': 800}).parametros['ancho'], isA<double>());
    });

    test('la opción inválida usa su código propio', () {
      expect(
        valida({'relleno': 'vidrio'}).problemas.single,
        const Problema(
          'relleno_no_soportado',
          parametro: 'relleno',
          detalle: 'vidrio',
        ),
      );
    });

    test('artículo desconocido', () {
      expect(
        valida({'marco': 'no-existe'}).problemas.single,
        const Problema(
          'articulo_desconocido',
          parametro: 'marco',
          detalle: 'no-existe',
        ),
      );
    });

    test('familia_no_permitida por tipo y por familia', () {
      // herraje donde se pide perfil (por tipo; además no tiene familia)
      expect(
        valida({'marco': 'bisagra-tejuelo'}).problemas.single.codigo,
        'familia_no_permitida',
      );
      // lámina: de otro tipo
      expect(
        valida({'marco': 'lamina-c18'}).problemas.single.codigo,
        'familia_no_permitida',
      );
      // perfil pero de otra familia
      expect(
        valida({'marco': 'redondo-1-2'}).problemas.single,
        const Problema(
          'familia_no_permitida',
          parametro: 'marco',
          detalle: 'redondo-1-2',
        ),
      );
      expect(valida({'marco': 'cuadrado-1-2'}).problemas, isEmpty);
      // perfil donde se pide herraje
      expect(
        valida({'pasador': 'ptr-2x2-c14'}).problemas.single.codigo,
        'familia_no_permitida',
      );
      expect(valida({'pasador': 'pasador-portacandado'}).problemas, isEmpty);
    });

    test('requeridoSi cumplido exige el parámetro', () {
      expect(
        valida({'travesanos': 2}).problemas.single,
        const Problema('parametro_faltante', parametro: 'travesano'),
      );
      expect(
        valida({'relleno': 'mixto'}).problemas.single,
        const Problema('parametro_faltante', parametro: 'alto_lamina'),
      );
    });

    test('requeridoSi no cumplido no exige ni valida', () {
      final r = valida({'travesano': 'no-existe', 'alto_lamina': 'x'});
      expect(r.problemas, isEmpty);
      expect(r.parametros['travesano'], 'no-existe');
      expect(r.parametros['alto_lamina'], 'x');
    });

    test('requeridoSi cumplido sí valida el valor', () {
      expect(
        valida({'relleno': 'lamina', 'alto_lamina': 50})
            .problemas
            .single
            .codigo,
        'fuera_de_rango',
      );
      expect(
        valida({'relleno': 'lamina', 'alto_lamina': 500}).problemas,
        isEmpty,
      );
    });

    test('lista: valida cada elemento con ruta indexada y defectos', () {
      final r = valida({
        'piezas': [
          {'largo': 500, 'cantidad': 2},
          {'largo': 5, 'cantidad': 1},
          {'cantidad': 1},
          {'largo': 100, 'cantidad': 1, 'corte': 'curvo'},
        ],
      });
      expect(r.problemas, [
        const Problema(
          'fuera_de_rango',
          parametro: 'piezas[1].largo',
          detalle: '5',
        ),
        const Problema('parametro_faltante', parametro: 'piezas[2].largo'),
        const Problema(
          'fuera_de_rango',
          parametro: 'piezas[3].corte',
          detalle: 'curvo',
        ),
      ]);
    });

    test('lista: normaliza elementos, aplica defectos y descarta extras', () {
      final r = valida({
        'piezas': [
          {'largo': 500, 'cantidad': 2.0, 'otra': 1},
        ],
      });
      expect(r.problemas, isEmpty);
      expect(r.parametros['piezas'], [
        {'largo': 500.0, 'cantidad': 2, 'corte': 'recto', 'grupo': 'piezas'},
      ]);
    });

    test('texto: se recorta; vacío o no texto es valor_invalido', () {
      Map<String, Object?> con(Object? grupo) => {
        'piezas': [
          {'largo': 500, 'cantidad': 1, 'grupo': grupo},
        ],
      };
      final ok = valida(con('  marco  '));
      expect(ok.problemas, isEmpty);
      expect(
        ((ok.parametros['piezas']! as List).first as Map)['grupo'],
        'marco',
      );
      // null toma el defecto
      expect(valida(con(null)).problemas, isEmpty);
      for (final malo in <Object>['', '   ', 5]) {
        expect(
          valida(con(malo)).problemas.single,
          Problema(
            'valor_invalido',
            parametro: 'piezas[0].grupo',
            detalle: '$malo',
          ),
        );
      }
    });

    test('validarReglas solo se llama sin errores de esquema', () {
      final p = _Prueba()..reglas = const [Problema('claro_insuficiente')];
      final r = valida({}, p: p);
      expect(p.llamadasReglas, 1);
      expect(r.problemas, [const Problema('claro_insuficiente')]);
      expect(r.hayErrores, true);

      final q = _Prueba();
      valida({'ancho': 1}, p: q);
      expect(q.llamadasReglas, 0);
    });

    test('una advertencia de las reglas no cuenta como error', () {
      final p = _Prueba()
        ..reglas = const [
          Problema('hoja_ancha', gravedad: Gravedad.advertencia),
        ];
      final r = valida({}, p: p);
      expect(r.problemas, hasLength(1));
      expect(r.hayErrores, false);
    });
  });

  group('aplicarPlantilla', () {
    test('devuelve el modelo cuando todo es válido', () {
      final r = aplicarPlantilla(_Prueba(), {...base, 'ancho': 800}, catalogo);
      expect(r.problemas, isEmpty);
      expect(r.modelo!.caja.ancho, 800.0);
    });

    test('devuelve los problemas y no genera si hay errores', () {
      final p = _Prueba()..falla = const ErrorMotor('no_debe_llamarse');
      final r = aplicarPlantilla(p, {...base, 'ancho': 1}, catalogo);
      expect(r.modelo, isNull);
      expect(r.problemas.single.codigo, 'fuera_de_rango');
    });

    test('un error de las reglas propias también impide generar', () {
      final p = _Prueba()..reglas = const [Problema('claro_insuficiente')];
      final r = aplicarPlantilla(p, base, catalogo);
      expect(r.modelo, isNull);
      expect(r.problemas.single.codigo, 'claro_insuficiente');
    });

    test('un ErrorMotor de generar se convierte en problema', () {
      final p = _Prueba()
        ..falla = const ErrorMotor('articulo_desconocido', detalle: 'x');
      final r = aplicarPlantilla(p, base, catalogo);
      expect(r.modelo, isNull);
      expect(
        r.problemas.single,
        const Problema('articulo_desconocido', detalle: 'x'),
      );
    });
  });
}
