#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Oraculo del motor del cotizador de herreria.

Es una implementacion de referencia, en un solo archivo y sin dependencias, de lo que describen
docs/MOTOR_MEDICION.md y docs/MOTOR_RECETAS.md. Con ella se generaron los casos dorados
de test/fixtures/dorados/. El motor real vive en lib/motor/ (Dart) y debe dar lo mismo.

Uso (desde la raiz del repositorio; en Windows el comando suele ser `python`):

    python3 tool/oraculo/oraculo.py --verificar    # recalcula y compara con los dorados
    python3 tool/oraculo/oraculo.py --generar      # reescribe los dorados (ver .claude/rules/pruebas.md)

Si la especificacion y este archivo no coinciden, NO lo arregles a la ligera: sigue el
procedimiento de excepcion de .claude/rules/pruebas.md.
"""
import argparse
import json
import math
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
ENTRADAS = RAIZ / "test" / "fixtures" / "entradas"
DORADOS = RAIZ / "test" / "fixtures" / "dorados"

EPS = 1e-9          # tolerancia para techo/piso y comparaciones de longitud
EMPUJE = 1e-7       # empuje para que 1.005 redondee a 1.01 aunque en binario sea 1.00499999...
MARGEN_EMPATE = 1e-3  # al generar dorados, ningun valor puede quedar a menos de esto de un empate


class ErrorMotor(Exception):
    """Error esperado del motor: lleva un codigo estable en espanol."""

    def __init__(self, codigo, detalle="", posicion=None):
        super().__init__(f"{codigo}: {detalle}")
        self.codigo = codigo
        self.detalle = detalle
        self.posicion = posicion


# ---------------------------------------------------------------------------
# 1. Numeros
# ---------------------------------------------------------------------------

def techo(x):
    return math.ceil(x - EPS)


def piso(x):
    return math.floor(x + EPS)


_estricto = False  # en True, redondear() falla si el valor esta demasiado cerca de un empate


def redondear(x, decimales=0):
    """Redondeo comercial: la mitad se aleja de cero. 2.5 -> 3, -2.5 -> -3, 1.005 -> 1.01."""
    factor = 10 ** decimales
    escalado = abs(x) * factor
    if _estricto:
        fraccion = escalado - math.floor(escalado)
        if abs(fraccion - 0.5) < MARGEN_EMPATE:
            raise AssertionError(f"valor demasiado cerca de un empate de redondeo: {x!r}")
    valor = math.floor(escalado + 0.5 + EMPUJE) / factor
    return -valor if x < 0 else valor


def pesos(x):
    """Dinero a centavos, expresado en pesos con 2 decimales."""
    return redondear(x, 2)


def a_centavos(x):
    return int(round(x * 100))


# ---------------------------------------------------------------------------
# 2. Catalogo: valores derivados de cada articulo
# ---------------------------------------------------------------------------

def derivados(articulo, densidad):
    """Area de seccion, peso por metro, cara visible, fondo y perimetro que se pinta."""
    familia = articulo.get("familia")
    g = articulo.get("geometria", {})
    if familia == "cuadrado":
        area, cara, fondo, perimetro = g["a"] ** 2, g["a"], g["a"], 4 * g["a"]
    elif familia == "redondo":
        area, cara, fondo, perimetro = math.pi * g["d"] ** 2 / 4, g["d"], g["d"], math.pi * g["d"]
    elif familia == "solera":
        area, cara, fondo, perimetro = g["a"] * g["e"], g["a"], g["e"], 2 * (g["a"] + g["e"])
    elif familia == "angulo":
        area, cara, fondo, perimetro = (2 * g["a"] - g["e"]) * g["e"], g["a"], g["a"], 4 * g["a"]
    elif familia == "tubular":
        area = g["a"] * g["b"] - (g["a"] - 2 * g["e"]) * (g["b"] - 2 * g["e"])
        cara, fondo, perimetro = g["a"], g["b"], 2 * (g["a"] + g["b"])
    elif familia == "tubo":
        area = math.pi / 4 * (g["d"] ** 2 - (g["d"] - 2 * g["e"]) ** 2)
        cara, fondo, perimetro = g["d"], g["d"], math.pi * g["d"]
    elif familia == "lamina":
        return {"espesor_mm": g["e"], "peso_kg_m2": g["e"] * densidad / 1000.0}
    else:
        return {}
    peso = articulo.get("peso_kg_m_manual", area * densidad / 1e6)
    return {"area_mm2": area, "peso_kg_m": peso, "cara_mm": cara, "fondo_mm": fondo,
            "perimetro_pintura_mm": perimetro}


class Catalogo:
    def __init__(self, datos):
        self.constantes = datos["constantes"]
        self.articulos = {a["clave"]: a for a in datos["articulos"]}
        self.derivados = {k: derivados(a, self.constantes["densidad_kg_m3"])
                          for k, a in self.articulos.items()}

    def articulo(self, clave):
        if clave not in self.articulos:
            raise ErrorMotor("articulo_desconocido", clave)
        return self.articulos[clave]

    def d(self, clave):
        self.articulo(clave)
        return self.derivados[clave]


# ---------------------------------------------------------------------------
# 3. Plantillas: parametros -> modelo de piezas
# ---------------------------------------------------------------------------

def numero_barrotes(claro, cara, separacion_max):
    """Menor numero de barrotes para que ningun hueco libre pase de separacion_max."""
    return max(0, techo((claro - separacion_max) / (cara + separacion_max)))


def _barra(ident, grupo, articulo, largo, corte, p0, p1, hoja=None):
    return {"id": ident, "grupo": grupo, "articulo": articulo, "largo": largo, "cantidad": 1,
            "corte": corte, "p0": p0, "p1": p1, "hoja": hoja}


def plantilla_reja_ventana(cat, p):
    ancho, alto = p["ancho"], p["alto"]
    c = cat.d(p["marco"])["cara_mm"]
    w = cat.d(p["barrote"])["cara_mm"]
    claro_ancho, claro_alto = ancho - 2 * c, alto - 2 * c
    n = numero_barrotes(claro_ancho, w, p["separacion_max"])
    hueco = (claro_ancho - n * w) / (n + 1)
    t = p["travesanos"]

    piezas = [
        _barra("marco-inf", "marco", p["marco"], ancho, "inglete", [0, c / 2, 0], [ancho, c / 2, 0]),
        _barra("marco-sup", "marco", p["marco"], ancho, "inglete", [0, alto - c / 2, 0], [ancho, alto - c / 2, 0]),
        _barra("marco-izq", "marco", p["marco"], alto, "inglete", [c / 2, 0, 0], [c / 2, alto, 0]),
        _barra("marco-der", "marco", p["marco"], alto, "inglete", [ancho - c / 2, 0, 0], [ancho - c / 2, alto, 0]),
    ]
    centros = []
    for i in range(1, n + 1):
        x = c + hueco * i + w * (i - 0.5)
        centros.append(x)
        piezas.append(_barra(f"barrote-{i}", "barrotes", p["barrote"], claro_alto, "recto",
                             [x, c, 0], [x, alto - c, 0]))
    alturas = []
    if t > 0:
        # la solera de amarre va por detras de los barrotes
        z = -(cat.d(p["barrote"])["fondo_mm"] / 2 + cat.d(p["travesano"])["fondo_mm"] / 2)
        for j in range(1, t + 1):
            y = c + claro_alto * j / (t + 1)
            alturas.append(y)
            piezas.append(_barra(f"travesano-{j}", "travesanos", p["travesano"], claro_ancho, "recto",
                                 [c, y, z], [ancho - c, y, z]))
    for k in range(1, p["anclas"] + 1):
        # las anclas cuentan como material pero no se dibujan (sin posicion)
        piezas.append(_barra(f"ancla-{k}", "anclas", p["ancla"], p["largo_ancla"], "recto", None, None))

    uniones = {"marco": 4, "barrotes": 2 * n, "travesanos": t * (2 + n), "anclas": p["anclas"]}
    return {
        "plantilla": "reja_ventana",
        "caja": {"ancho": ancho, "alto": alto},
        "num_hojas": 0,
        "piezas": piezas, "paneles": [], "herrajes": [],
        "uniones": uniones,
        "extras": {"barrotes": n, "travesanos": t, "anclas": p["anclas"]},
        "detalle": {"claro_ancho_mm": claro_ancho, "claro_alto_mm": claro_alto,
                    "hueco_libre_mm": hueco, "x_centros_barrotes_mm": centros,
                    "y_travesanos_mm": alturas},
        "advertencias": [],
    }


def plantilla_porton_abatible(cat, p):
    ancho, alto, hojas = p["ancho"], p["alto"], p["hojas"]
    ancho_hoja = (ancho - 2 * p["holgura_lateral"] - (hojas - 1) * p["holgura_central"]) / hojas
    alto_hoja = alto - p["holgura_piso"]
    c = cat.d(p["bastidor"])["cara_mm"]
    claro_ancho = ancho_hoja - 2 * c
    y0 = p["holgura_piso"]

    piezas, paneles = [], []
    uniones = {"bastidor": 4 * hojas}
    extras = {"barrotes": 0, "bisagras": 0}
    detalle = {"ancho_hoja_mm": ancho_hoja, "alto_hoja_mm": alto_hoja, "claro_ancho_mm": claro_ancho}

    for h in range(hojas):
        x0 = p["holgura_lateral"] + h * (ancho_hoja + p["holgura_central"])
        pre = f"h{h + 1}"
        piezas += [
            _barra(f"{pre}-bastidor-izq", "bastidor", p["bastidor"], alto_hoja, "inglete",
                   [x0 + c / 2, y0, 0], [x0 + c / 2, y0 + alto_hoja, 0], h),
            _barra(f"{pre}-bastidor-der", "bastidor", p["bastidor"], alto_hoja, "inglete",
                   [x0 + ancho_hoja - c / 2, y0, 0], [x0 + ancho_hoja - c / 2, y0 + alto_hoja, 0], h),
            _barra(f"{pre}-bastidor-inf", "bastidor", p["bastidor"], ancho_hoja, "inglete",
                   [x0, y0 + c / 2, 0], [x0 + ancho_hoja, y0 + c / 2, 0], h),
            _barra(f"{pre}-bastidor-sup", "bastidor", p["bastidor"], ancho_hoja, "inglete",
                   [x0, y0 + alto_hoja - c / 2, 0], [x0 + ancho_hoja, y0 + alto_hoja - c / 2, 0], h),
        ]
        relleno = p["relleno"]
        if relleno in ("mixto", "barrotes"):
            w = cat.d(p["barrote"])["cara_mm"]
            n = numero_barrotes(claro_ancho, w, p["separacion_max"])
            hueco = (claro_ancho - n * w) / (n + 1)
            detalle.update({"hueco_libre_mm": hueco, "barrotes_por_hoja": n})
        if relleno in ("mixto", "lamina"):
            espesor = cat.d(p["lamina"])["espesor_mm"]
            z = cat.d(p["bastidor"])["fondo_mm"] / 2 + espesor / 2  # lamina sobrepuesta por fuera

        if relleno == "mixto":
            # zoclo de lamina abajo, travesano centrado en el borde superior de la lamina, barrotes arriba
            ct = cat.d(p["travesano"])["cara_mm"]
            zoclo = p["alto_zoclo"]
            largo_barrote = alto_hoja - c - zoclo - ct / 2
            piezas.append(_barra(f"{pre}-travesano", "travesanos", p["travesano"], claro_ancho, "recto",
                                 [x0 + c, y0 + zoclo, 0], [x0 + ancho_hoja - c, y0 + zoclo, 0], h))
            for i in range(1, n + 1):
                x = x0 + c + hueco * i + w * (i - 0.5)
                piezas.append(_barra(f"{pre}-barrote-{i}", "barrotes", p["barrote"], largo_barrote, "recto",
                                     [x, y0 + zoclo + ct / 2, 0], [x, y0 + alto_hoja - c, 0], h))
            paneles.append({"id": f"{pre}-zoclo", "grupo": "zoclo", "articulo": p["lamina"],
                            "ancho": ancho_hoja, "alto": zoclo, "cantidad": 1,
                            "origen": [x0, y0, z], "hoja": h})
            puntos = techo(2 * (ancho_hoja + zoclo) / p["paso_punteo"])
            uniones["travesanos"] = uniones.get("travesanos", 0) + 2
            uniones["barrotes"] = uniones.get("barrotes", 0) + 2 * n
            uniones["lamina"] = uniones.get("lamina", 0) + puntos
            extras["barrotes"] += n
            detalle.update({"largo_barrote_mm": largo_barrote, "puntos_lamina_por_hoja": puntos})
        elif relleno == "barrotes":
            # barrotes de bastidor a bastidor, sin lamina ni travesano
            largo_barrote = alto_hoja - 2 * c
            for i in range(1, n + 1):
                x = x0 + c + hueco * i + w * (i - 0.5)
                piezas.append(_barra(f"{pre}-barrote-{i}", "barrotes", p["barrote"], largo_barrote, "recto",
                                     [x, y0 + c, 0], [x, y0 + alto_hoja - c, 0], h))
            uniones["barrotes"] = uniones.get("barrotes", 0) + 2 * n
            extras["barrotes"] += n
            detalle.update({"largo_barrote_mm": largo_barrote})
        elif relleno == "lamina":
            # tablero completo de lamina con un travesano de refuerzo a media altura
            piezas.append(_barra(f"{pre}-travesano", "travesanos", p["travesano"], claro_ancho, "recto",
                                 [x0 + c, y0 + alto_hoja / 2, 0], [x0 + ancho_hoja - c, y0 + alto_hoja / 2, 0], h))
            paneles.append({"id": f"{pre}-tablero", "grupo": "tablero", "articulo": p["lamina"],
                            "ancho": ancho_hoja, "alto": alto_hoja, "cantidad": 1,
                            "origen": [x0, y0, z], "hoja": h})
            puntos = techo(2 * (ancho_hoja + alto_hoja) / p["paso_punteo"])
            uniones["travesanos"] = uniones.get("travesanos", 0) + 2
            uniones["lamina"] = uniones.get("lamina", 0) + puntos
            detalle.update({"puntos_lamina_por_hoja": puntos})
        else:
            raise ErrorMotor("relleno_no_soportado", str(relleno))

    herrajes = []
    por_hoja = 2 if alto_hoja <= 2000 + EPS else 3
    bisagras = por_hoja * hojas
    herrajes.append({"articulo": p["bisagra"], "cantidad": bisagras})
    uniones["bisagras"] = 2 * bisagras
    extras["bisagras"] = bisagras
    if p.get("pasador"):
        herrajes.append({"articulo": p["pasador"], "cantidad": 1})
        uniones["pasador"] = 2
    if p.get("picaporte") and hojas == 2:
        herrajes.append({"articulo": p["picaporte"], "cantidad": 1})
        uniones["picaporte"] = 2

    return {
        "plantilla": "porton_abatible",
        "caja": {"ancho": ancho, "alto": alto},
        "num_hojas": hojas,
        "piezas": piezas, "paneles": paneles, "herrajes": herrajes,
        "uniones": uniones, "extras": extras, "detalle": detalle, "advertencias": [],
    }


def plantilla_libre(cat, p):
    piezas = []
    for i, pz in enumerate(p.get("piezas", []), start=1):
        cat.d(pz["articulo"])
        piezas.append({"id": f"pieza-{i}", "grupo": pz.get("grupo", "piezas"), "articulo": pz["articulo"],
                       "largo": pz["largo"], "cantidad": pz["cantidad"], "corte": pz.get("corte", "recto"),
                       "p0": None, "p1": None, "hoja": None})
    paneles = []
    for i, pn in enumerate(p.get("paneles", []), start=1):
        paneles.append({"id": f"panel-{i}", "grupo": pn.get("grupo", "paneles"), "articulo": pn["articulo"],
                        "ancho": pn["ancho"], "alto": pn["alto"], "cantidad": pn["cantidad"],
                        "origen": None, "hoja": None})
    return {
        "plantilla": "libre",
        "caja": {"ancho": p["ancho"], "alto": p["alto"]},
        "num_hojas": 0,
        "piezas": piezas, "paneles": paneles, "herrajes": list(p.get("herrajes", [])),
        "uniones": {"manual": p.get("uniones", 0)},
        "extras": {}, "detalle": {}, "advertencias": [],
    }


PLANTILLAS = {
    "reja_ventana": plantilla_reja_ventana,
    "porton_abatible": plantilla_porton_abatible,
    "libre": plantilla_libre,
}


# ---------------------------------------------------------------------------
# 4. Optimizador de cortes (primer ajuste decreciente con kerf)
# ---------------------------------------------------------------------------

def partir_en_segmentos(largo, tramo):
    """Una pieza mas larga que el tramo se arma con tramos completos y un resto, unidos por empalmes."""
    if largo <= tramo + EPS:
        return [largo]
    completos = piso(largo / tramo)
    resto = largo - completos * tramo
    return [float(tramo)] * completos + ([resto] if resto > EPS else [])


def optimizar_cortes(largos, tramo, kerf):
    """Devuelve barras (cada una con sus piezas en orden de colocacion), sobrantes y empalmes."""
    segmentos, empalmes = [], 0
    for largo in largos:
        partes = partir_en_segmentos(largo, tramo)
        empalmes += len(partes) - 1
        segmentos += partes
    orden = sorted(range(len(segmentos)), key=lambda i: (-segmentos[i], i))  # mayor primero, estable
    barras = []
    for i in orden:
        largo = segmentos[i]
        for barra in barras:
            # entre cada par de piezas se pierde un kerf
            if sum(barra) + kerf * len(barra) + largo <= tramo + EPS:
                barra.append(largo)
                break
        else:
            barras.append([largo])
    sobrantes = [max(0.0, tramo - sum(b) - kerf * len(b)) for b in barras]
    cortes = sum(1 for s in segmentos if s < tramo - EPS)  # un tramo completo no se corta
    return {"tramos": len(barras), "barras": barras, "sobrantes_mm": sobrantes,
            "segmentos": len(segmentos), "cortes": cortes, "empalmes": empalmes}


# ---------------------------------------------------------------------------
# 5. Medicion: modelo de piezas -> despiece, cortes y cantidades
# ---------------------------------------------------------------------------

def _cabe_en_hoja(ancho, alto, hoja):
    return (min(ancho, alto) <= min(hoja) + EPS) and (max(ancho, alto) <= max(hoja) + EPS)


def medir(cat, modelo):
    k = cat.constantes
    advertencias = list(modelo["advertencias"])

    # despiece agrupado (mismo grupo, articulo, largo y corte), en orden de aparicion
    despiece, indice = [], {}
    for pz in modelo["piezas"]:
        llave = (pz["grupo"], pz["articulo"], round(pz["largo"], 4), pz["corte"])
        if llave not in indice:
            indice[llave] = len(despiece)
            despiece.append({"grupo": pz["grupo"], "articulo": pz["articulo"], "largo": pz["largo"],
                             "cantidad": 0, "corte": pz["corte"]})
        despiece[indice[llave]]["cantidad"] += pz["cantidad"]

    largos_por_articulo = {}
    for pz in modelo["piezas"]:
        largos_por_articulo.setdefault(pz["articulo"], []).extend([pz["largo"]] * pz["cantidad"])

    cortes, por_articulo = {}, {}
    q = dict.fromkeys(["kg_perfiles", "m_perfiles", "m2_pintura", "costo_perfiles_compra",
                       "costo_perfiles_usado", "kg_laminas", "m2_lamina", "costo_laminas_compra",
                       "costo_laminas_usado", "costo_herrajes"], 0.0)
    tramos = hojas_lamina = n_cortes = empalmes = 0

    for clave, largos in largos_por_articulo.items():
        a, d = cat.articulo(clave), cat.d(clave)
        tramo = a["largo_tramo_mm"]
        plan = optimizar_cortes(largos, tramo, k["kerf_mm"])
        if plan["empalmes"]:
            advertencias.append({"codigo": "pieza_mayor_que_tramo", "articulo": clave})
        metros = sum(largos) / 1000.0
        kg = metros * d["peso_kg_m"]
        unidad, precio = a["unidad_compra"], a["precio"]
        if unidad == "tramo":
            compra, usado = plan["tramos"] * precio, metros / (tramo / 1000.0) * precio
        elif unidad == "kg":
            compra, usado = plan["tramos"] * (tramo / 1000.0) * d["peso_kg_m"] * precio, kg * precio
        elif unidad == "m":
            compra = usado = metros * precio
        else:
            raise ErrorMotor("unidad_no_soportada", f"{clave}: {unidad}")
        cortes[clave] = {"tramos": plan["tramos"], "barras": plan["barras"],
                         "sobrantes_mm": plan["sobrantes_mm"], "empalmes": plan["empalmes"]}
        por_articulo[clave] = {"tipo": "perfil", "piezas": len(largos), "metros": metros, "kg": kg,
                               "tramos": plan["tramos"], "m2": 0.0, "hojas": 0, "cantidad": 0,
                               "costo_compra": compra, "costo_usado": usado}
        q["kg_perfiles"] += kg
        q["m_perfiles"] += metros
        q["m2_pintura"] += d["perimetro_pintura_mm"] / 1000.0 * metros
        q["costo_perfiles_compra"] += compra
        q["costo_perfiles_usado"] += usado
        tramos += plan["tramos"]
        n_cortes += plan["cortes"]
        empalmes += plan["empalmes"]

    m2_por_lamina = {}
    for pn in modelo["paneles"]:
        a = cat.articulo(pn["articulo"])
        if not _cabe_en_hoja(pn["ancho"], pn["alto"], a["hoja_mm"]):
            advertencias.append({"codigo": "panel_no_cabe_en_hoja", "articulo": pn["articulo"], "panel": pn["id"]})
        m2_por_lamina.setdefault(pn["articulo"], 0.0)
        m2_por_lamina[pn["articulo"]] += pn["ancho"] * pn["alto"] / 1e6 * pn["cantidad"]
    for clave, m2 in m2_por_lamina.items():
        a, d = cat.articulo(clave), cat.d(clave)
        area_hoja = a["hoja_mm"][0] * a["hoja_mm"][1] / 1e6
        hojas = techo(m2 * (1 + k["desperdicio_lamina"]) / area_hoja)
        kg = m2 * d["peso_kg_m2"]
        unidad, precio = a["unidad_compra"], a["precio"]
        if unidad == "hoja":
            compra, usado = hojas * precio, m2 / area_hoja * precio
        elif unidad == "m2":
            compra, usado = m2 * (1 + k["desperdicio_lamina"]) * precio, m2 * precio
        elif unidad == "kg":
            compra, usado = hojas * area_hoja * d["peso_kg_m2"] * precio, kg * precio
        else:
            raise ErrorMotor("unidad_no_soportada", f"{clave}: {unidad}")
        por_articulo[clave] = {"tipo": "lamina", "piezas": 0, "metros": 0.0, "kg": kg, "tramos": 0,
                               "m2": m2, "hojas": hojas, "cantidad": 0,
                               "costo_compra": compra, "costo_usado": usado}
        q["kg_laminas"] += kg
        q["m2_lamina"] += m2
        q["m2_pintura"] += 2 * m2  # dos caras
        q["costo_laminas_compra"] += compra
        q["costo_laminas_usado"] += usado
        hojas_lamina += hojas

    for h in modelo["herrajes"]:
        a = cat.articulo(h["articulo"])
        costo = h["cantidad"] * a["precio"]
        reg = por_articulo.setdefault(h["articulo"], {"tipo": "herraje", "piezas": 0, "metros": 0.0, "kg": 0.0,
                                                    "tramos": 0, "m2": 0.0, "hojas": 0, "cantidad": 0,
                                                    "costo_compra": 0.0, "costo_usado": 0.0})
        reg["cantidad"] += h["cantidad"]
        reg["costo_compra"] += costo
        reg["costo_usado"] += costo
        q["costo_herrajes"] += costo

    uniones = dict(modelo["uniones"])
    if empalmes:
        uniones["empalmes"] = empalmes
    ancho, alto = modelo["caja"]["ancho"], modelo["caja"]["alto"]
    cantidades = {
        "ancho_m": ancho / 1000.0, "alto_m": alto / 1000.0, "largo_m": ancho / 1000.0,
        "area_m2": ancho * alto / 1e6, "perimetro_m": 2 * (ancho + alto) / 1000.0,
        "num_hojas": modelo["num_hojas"],
        "kg_acero": q["kg_perfiles"] + q["kg_laminas"], "kg_perfiles": q["kg_perfiles"],
        "kg_laminas": q["kg_laminas"], "m_perfiles": q["m_perfiles"], "tramos": tramos,
        "m2_lamina": q["m2_lamina"], "hojas_lamina": hojas_lamina,
        "piezas": sum(pz["cantidad"] for pz in modelo["piezas"]),
        "paneles": sum(pn["cantidad"] for pn in modelo["paneles"]),
        "cortes": n_cortes,
        "ingletes": sum(2 * pz["cantidad"] for pz in modelo["piezas"] if pz["corte"] == "inglete"),
        "uniones": sum(uniones.values()),
        "m2_pintura": q["m2_pintura"],
        "costo_perfiles_compra": q["costo_perfiles_compra"], "costo_perfiles_usado": q["costo_perfiles_usado"],
        "costo_laminas_compra": q["costo_laminas_compra"], "costo_laminas_usado": q["costo_laminas_usado"],
        "costo_herrajes": q["costo_herrajes"],
        "costo_material_compra": q["costo_perfiles_compra"] + q["costo_laminas_compra"] + q["costo_herrajes"],
        "costo_material_usado": q["costo_perfiles_usado"] + q["costo_laminas_usado"] + q["costo_herrajes"],
    }
    for nombre, valor in modelo["extras"].items():
        cantidades[f"x_{nombre}"] = valor
    return {"despiece": despiece, "cortes": cortes, "por_articulo": por_articulo,
            "uniones": uniones, "cantidades": cantidades, "advertencias": advertencias}


CANTIDADES_ESTANDAR = [
    "ancho_m", "alto_m", "largo_m", "area_m2", "perimetro_m", "num_hojas", "kg_acero", "kg_perfiles",
    "kg_laminas", "m_perfiles", "tramos", "m2_lamina", "hojas_lamina", "piezas", "paneles", "cortes",
    "ingletes", "uniones", "m2_pintura", "costo_perfiles_compra", "costo_perfiles_usado",
    "costo_laminas_compra", "costo_laminas_usado", "costo_herrajes", "costo_material_compra",
    "costo_material_usado",
]


# ---------------------------------------------------------------------------
# 6. Lenguaje de formulas: lexico, sintaxis y evaluacion
# ---------------------------------------------------------------------------

OPERADORES_2 = ("<=", ">=", "==", "!=", "&&", "||")
OPERADORES_1 = "+-*/(),<>!"
FUNCIONES = {
    "si", "min", "max", "abs", "redondear", "techo", "piso", "multiplo_arriba", "multiplo_abajo",
    "multiplo_cercano", "art_kg", "art_metros", "art_tramos", "art_m2", "art_hojas", "art_cantidad",
    "art_precio",
}


def _es_digito(ch):
    return "0" <= ch <= "9"


def _es_letra(ch):
    return ("a" <= ch <= "z") or ("A" <= ch <= "Z") or ch == "_"


def tokenizar(texto):
    tokens, i, n = [], 0, len(texto)
    while i < n:
        ch = texto[i]
        if ch in " \t\r\n":
            i += 1
        elif _es_digito(ch):
            j = i
            while j < n and _es_digito(texto[j]):
                j += 1
            if j < n and texto[j] == ".":
                if j + 1 < n and _es_digito(texto[j + 1]):
                    j += 1
                    while j < n and _es_digito(texto[j]):
                        j += 1
                else:
                    raise ErrorMotor("sintaxis", "numero mal escrito", j)
            valor = float(texto[i:j])
            if j < n and texto[j] == "%":  # 30% vale 0.30; el signo va pegado al numero
                valor /= 100.0
                j += 1
            tokens.append(("num", valor, i))
            i = j
        elif _es_letra(ch):
            j = i
            while j < n and (_es_letra(texto[j]) or _es_digito(texto[j])):
                j += 1
            tokens.append(("id", texto[i:j], i))
            i = j
        elif ch in "\"'":
            j = texto.find(ch, i + 1)
            if j < 0:
                raise ErrorMotor("sintaxis", "cadena sin cerrar", i)
            tokens.append(("cad", texto[i + 1:j], i))
            i = j + 1
        elif texto[i:i + 2] in OPERADORES_2:
            tokens.append(("op", texto[i:i + 2], i))
            i += 2
        elif ch in OPERADORES_1:
            tokens.append(("op", ch, i))
            i += 1
        else:
            raise ErrorMotor("sintaxis", f"caracter inesperado {ch!r}", i)
    tokens.append(("fin", None, n))
    return tokens


class Analizador:
    """Descenso recursivo. Precedencia de menor a mayor: || && ==,!= <,<=,>,>= +,- *,/ unarios."""

    def __init__(self, texto):
        self.tokens = tokenizar(texto)
        self.i = 0

    def ver(self):
        return self.tokens[self.i]

    def es_op(self, *ops):
        tipo, valor, _ = self.ver()
        return tipo == "op" and valor in ops

    def avanzar(self):
        tok = self.tokens[self.i]
        self.i += 1
        return tok

    def error(self, detalle):
        raise ErrorMotor("sintaxis", detalle, self.ver()[2])

    def analizar(self):
        nodo = self.expr_o()
        if self.ver()[0] != "fin":
            self.error("sobra texto")
        return nodo

    def _binaria(self, siguiente, ops):
        nodo = siguiente()
        while self.es_op(*ops):
            _, op, pos = self.avanzar()
            nodo = ("bin", op, nodo, siguiente(), pos)
        return nodo

    def expr_o(self):
        return self._binaria(self.expr_y, ("||",))

    def expr_y(self):
        return self._binaria(self.expr_igual, ("&&",))

    def expr_igual(self):
        return self._binaria(self.expr_comp, ("==", "!="))

    def expr_comp(self):
        nodo = self.expr_suma()
        if self.es_op("<", "<=", ">", ">="):
            _, op, pos = self.avanzar()
            nodo = ("bin", op, nodo, self.expr_suma(), pos)
            if self.es_op("<", "<=", ">", ">="):
                self.error("las comparaciones no se encadenan")
        return nodo

    def expr_suma(self):
        return self._binaria(self.expr_prod, ("+", "-"))

    def expr_prod(self):
        return self._binaria(self.expr_unaria, ("*", "/"))

    def expr_unaria(self):
        if self.es_op("-", "!"):
            _, op, pos = self.avanzar()
            return ("un", op, self.expr_unaria(), pos)
        return self.primario()

    def primario(self):
        tipo, valor, pos = self.ver()
        if tipo == "num":
            self.avanzar()
            return ("num", valor)
        if tipo == "cad":
            self.avanzar()
            return ("cad", valor)
        if tipo == "id":
            self.avanzar()
            if valor == "verdadero":
                return ("bool", True)
            if valor == "falso":
                return ("bool", False)
            if self.es_op("("):
                self.avanzar()
                args = []
                if not self.es_op(")"):
                    args.append(self.expr_o())
                    while self.es_op(","):
                        self.avanzar()
                        args.append(self.expr_o())
                if not self.es_op(")"):
                    self.error("falta )")
                self.avanzar()
                return ("fn", valor, args, pos)
            return ("var", valor, pos)
        if self.es_op("("):
            self.avanzar()
            nodo = self.expr_o()
            if not self.es_op(")"):
                self.error("falta )")
            self.avanzar()
            return nodo
        self.error("se esperaba un valor")


def analizar(texto):
    return Analizador(texto).analizar()


def identificadores(nodo, variables=None, funciones=None):
    """Nombres de variables y de funciones que usa una formula."""
    variables = set() if variables is None else variables
    funciones = set() if funciones is None else funciones
    tipo = nodo[0]
    if tipo == "var":
        variables.add(nodo[1])
    elif tipo == "fn":
        funciones.add(nodo[1])
        for a in nodo[2]:
            identificadores(a, variables, funciones)
    elif tipo == "un":
        identificadores(nodo[2], variables, funciones)
    elif tipo == "bin":
        identificadores(nodo[2], variables, funciones)
        identificadores(nodo[3], variables, funciones)
    return variables, funciones


def _es_num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def _num(v, pos):
    if not _es_num(v):
        raise ErrorMotor("tipo", "se esperaba un numero", pos)
    return float(v)


def _bool(v, pos):
    if not isinstance(v, bool):
        raise ErrorMotor("tipo", "se esperaba verdadero o falso", pos)
    return v


def _finito(v, pos):
    if not math.isfinite(v):
        raise ErrorMotor("no_finito", "el resultado no es un numero finito", pos)
    return v


class Contexto:
    """Lo que una formula puede consultar: variables y datos por articulo."""

    def __init__(self, variables, por_articulo=None, precios=None):
        self.variables = variables
        self.por_articulo = por_articulo or {}
        self.precios = precios or {}

    def variable(self, nombre, pos):
        if nombre not in self.variables:
            raise ErrorMotor("variable_desconocida", nombre, pos)
        return self.variables[nombre]

    def articulo(self, clave, campo, pos):
        if clave not in self.precios:
            raise ErrorMotor("articulo_desconocido", clave, pos)
        if campo == "precio":
            return float(self.precios[clave])
        return float(self.por_articulo.get(clave, {}).get(campo, 0))


def evaluar(nodo, ctx):
    tipo = nodo[0]
    if tipo in ("num", "cad", "bool"):
        return nodo[1]
    if tipo == "var":
        return ctx.variable(nodo[1], nodo[2])
    if tipo == "un":
        _, op, operando, pos = nodo
        v = evaluar(operando, ctx)
        return -_num(v, pos) if op == "-" else (not _bool(v, pos))
    if tipo == "bin":
        _, op, izq, der, pos = nodo
        if op == "&&":
            return _bool(evaluar(izq, ctx), pos) and _bool(evaluar(der, ctx), pos)  # corto circuito
        if op == "||":
            return _bool(evaluar(izq, ctx), pos) or _bool(evaluar(der, ctx), pos)
        a, b = evaluar(izq, ctx), evaluar(der, ctx)
        if op in ("==", "!="):
            mismo = (_es_num(a) and _es_num(b)) or (isinstance(a, bool) and isinstance(b, bool)) \
                or (isinstance(a, str) and isinstance(b, str))
            if not mismo:
                raise ErrorMotor("tipo", "no se pueden comparar tipos distintos", pos)
            return (a == b) if op == "==" else (a != b)
        a, b = _num(a, pos), _num(b, pos)
        if op == "+":
            return _finito(a + b, pos)
        if op == "-":
            return _finito(a - b, pos)
        if op == "*":
            return _finito(a * b, pos)
        if op == "/":
            if b == 0:
                raise ErrorMotor("division_entre_cero", "", pos)
            return _finito(a / b, pos)
        return {"<": a < b, "<=": a <= b, ">": a > b, ">=": a >= b}[op]
    if tipo == "fn":
        return _funcion(nodo, ctx)
    raise AssertionError(tipo)


def _funcion(nodo, ctx):
    _, nombre, args, pos = nodo
    if nombre not in FUNCIONES:
        raise ErrorMotor("funcion_desconocida", nombre, pos)

    def exigir(minimo, maximo=None):
        maximo = minimo if maximo is None else maximo
        if not (minimo <= len(args) <= maximo):
            raise ErrorMotor("argumentos", f"{nombre} no acepta {len(args)} argumentos", pos)

    if nombre == "si":  # solo se evalua la rama elegida
        exigir(3)
        return evaluar(args[1] if _bool(evaluar(args[0], ctx), pos) else args[2], ctx)
    if nombre in ("min", "max"):
        exigir(2, 99)
        valores = [_num(evaluar(a, ctx), pos) for a in args]
        return min(valores) if nombre == "min" else max(valores)
    if nombre.startswith("art_"):
        exigir(1)
        clave = evaluar(args[0], ctx)
        if not isinstance(clave, str):
            raise ErrorMotor("tipo", "la clave del articulo va entre comillas", pos)
        return ctx.articulo(clave, nombre[4:], pos)
    if nombre == "redondear":
        exigir(1, 2)
        x = _num(evaluar(args[0], ctx), pos)
        d = _num(evaluar(args[1], ctx), pos) if len(args) == 2 else 0.0
        if d != math.floor(d) or not (0 <= d <= 6):
            raise ErrorMotor("argumentos", "los decimales van de 0 a 6", pos)
        return redondear(x, int(d))
    if nombre in ("abs", "techo", "piso"):
        exigir(1)
        x = _num(evaluar(args[0], ctx), pos)
        return abs(x) if nombre == "abs" else float(techo(x) if nombre == "techo" else piso(x))
    exigir(2)  # multiplo_arriba, multiplo_abajo, multiplo_cercano
    x, m = _num(evaluar(args[0], ctx), pos), _num(evaluar(args[1], ctx), pos)
    if m <= 0:
        raise ErrorMotor("argumentos", "el multiplo debe ser mayor que cero", pos)
    if nombre == "multiplo_arriba":
        return techo(x / m) * m
    if nombre == "multiplo_abajo":
        return piso(x / m) * m
    return piso(x / m + 0.5) * m


# ---------------------------------------------------------------------------
# 7. Recetas: validacion, orden de calculo, agregados, redondeo y presentacion
# ---------------------------------------------------------------------------

CATEGORIAS_DINERO = ["material", "mano_obra", "global", "extra", "utilidad", "descuento", "impuesto"]
CATEGORIAS = CATEGORIAS_DINERO + ["auxiliar"]
AGREGADOS = {
    "total_material": None, "total_mano_obra": None, "total_global": None, "total_extra": None,
    "total_utilidad": None, "total_descuento": None, "total_impuesto": None,
    "costo_directo": ["total_material", "total_mano_obra", "total_global", "total_extra"],
    "subtotal": ["costo_directo", "total_utilidad"],
    "base_impuesto": ["subtotal", "total_descuento"],
    "suma": ["base_impuesto", "total_impuesto"],
}
PALABRAS = {"verdadero", "falso", "tipo"}
RESERVADOS = set(CANTIDADES_ESTANDAR) | set(AGREGADOS) | FUNCIONES | PALABRAS | {"total", "ajuste_redondeo"}


def _clave_valida(clave):
    return (isinstance(clave, str) and clave != "" and "a" <= clave[0] <= "z"
            and all(("a" <= ch <= "z") or _es_digito(ch) or ch == "_" for ch in clave))


def redondear_total(suma, regla):
    modo, m = regla["modo"], regla["multiplo"]
    if modo == "ninguno":
        return suma
    if modo == "arriba":
        return float(techo(suma / m) * m)
    if modo == "abajo":
        return float(piso(suma / m) * m)
    if modo == "cercano":
        return float(piso(suma / m + 0.5) * m)
    raise ErrorMotor("redondeo_invalido", modo)


def evaluar_receta(receta, medicion, cat, parametros, datos_trabajo, tipo, ajustes=None):
    ajustes = ajustes or {}
    conceptos = receta["conceptos"]

    # 1. estructura y nombres
    params = {k: v["valor"] for k, v in parametros.items()}
    claves = []
    for c in conceptos:
        if not _clave_valida(c["clave"]):
            raise ErrorMotor("clave_invalida", str(c["clave"]))
        if c["categoria"] not in CATEGORIAS:
            raise ErrorMotor("categoria_invalida", c["categoria"])
        if c["clave"] in RESERVADOS or c["clave"].startswith("x_"):
            raise ErrorMotor("nombre_reservado", c["clave"])
        if c["clave"] in claves or c["clave"] in params or c["clave"] in datos_trabajo:
            raise ErrorMotor("nombre_duplicado", c["clave"])
        claves.append(c["clave"])
    extras = ajustes.get("lineas_extra", [])
    for e in extras:
        if not _clave_valida(e["clave"]):
            raise ErrorMotor("clave_invalida", str(e["clave"]))
        if e["categoria"] not in CATEGORIAS_DINERO:
            raise ErrorMotor("categoria_invalida", e["categoria"])
        if e["clave"] in RESERVADOS or e["clave"].startswith("x_"):
            raise ErrorMotor("nombre_reservado", e["clave"])
        if e["clave"] in claves or e["clave"] in params or e["clave"] in datos_trabajo:
            raise ErrorMotor("nombre_duplicado", e["clave"])
        claves.append(e["clave"])
    for nombre, valor in ajustes.get("parametros", {}).items():
        if nombre not in params:
            raise ErrorMotor("parametro_desconocido", nombre)
        params[nombre] = valor
    fijas = ajustes.get("lineas_fijas", {})
    claves_concepto = {c["clave"] for c in conceptos}
    for nombre in fijas:
        if nombre not in claves_concepto:
            raise ErrorMotor("linea_fija_desconocida", nombre)

    # 2. sintaxis
    arboles = {}
    for c in conceptos:
        arboles[c["clave"]] = (analizar(c["formula"]),
                               analizar(c["condicion"]) if c.get("condicion") else None)

    # 3. referencias
    conocidos = set(claves) | set(AGREGADOS) | set(CANTIDADES_ESTANDAR) | set(params) \
        | set(datos_trabajo) | {"tipo"}
    dependencias = {}
    for c in conceptos:
        usados, funcs = set(), set()
        if c["clave"] not in fijas:  # una linea fijada a mano ignora su formula y su condicion
            for arbol in arboles[c["clave"]]:
                if arbol is not None:
                    identificadores(arbol, usados, funcs)
        for f in sorted(funcs):
            if f not in FUNCIONES:
                raise ErrorMotor("funcion_desconocida", f)
        for u in sorted(usados):
            if u not in conocidos and not u.startswith("x_"):
                raise ErrorMotor("variable_desconocida", u)
        dependencias[c["clave"]] = {u for u in usados if u in claves or u in AGREGADOS}
    for e in extras:
        dependencias[e["clave"]] = set()
    categoria_de = {c["clave"]: c["categoria"] for c in conceptos}
    categoria_de.update({e["clave"]: e["categoria"] for e in extras})
    for nombre, partes in AGREGADOS.items():
        if partes is None:
            cat_nombre = nombre[len("total_"):]
            dependencias[nombre] = {k for k, v in categoria_de.items() if v == cat_nombre}
        else:
            dependencias[nombre] = set(partes)

    # 4. orden de calculo (Kahn); si sobra algo, hay un ciclo
    orden, pendientes = [], dict(dependencias)
    nodos_en_orden = claves + list(AGREGADOS)
    while pendientes:
        listos = [n for n in nodos_en_orden if n in pendientes and not (pendientes[n] & set(pendientes))]
        if not listos:
            raise ErrorMotor("ciclo", ", ".join(sorted(pendientes)))
        for n in listos:
            orden.append(n)
            del pendientes[n]

    # 5. evaluacion
    variables = dict(medicion["cantidades"])
    variables.update(datos_trabajo)
    variables.update(params)
    variables["tipo"] = tipo
    precios = {k: a["precio"] for k, a in cat.articulos.items()}
    ctx = Contexto(variables, medicion["por_articulo"], precios)
    por_clave = {c["clave"]: c for c in conceptos}
    por_extra = {e["clave"]: e for e in extras}
    lineas = {}
    for nodo in orden:
        if nodo in AGREGADOS:
            variables[nodo] = pesos(sum(variables[d] for d in dependencias[nodo]))
            continue
        if nodo in por_extra:
            e = por_extra[nodo]
            valor = pesos(e["valor"])
            lineas[nodo] = {"clave": nodo, "nombre": e["nombre"], "categoria": e["categoria"],
                            "valor": valor, "aplica": True, "origen": "extra", "visible_cliente": True}
            variables[nodo] = valor
            continue
        c = por_clave[nodo]
        formula, condicion = arboles[nodo]
        aplica, origen = True, "formula"
        if nodo in fijas:
            valor, origen = pesos(fijas[nodo]) if c["categoria"] != "auxiliar" else float(fijas[nodo]), "fijo"
        else:
            if condicion is not None:
                aplica = evaluar(condicion, ctx)
                if not isinstance(aplica, bool):
                    raise ErrorMotor("tipo", f"la condicion de {nodo} debe dar verdadero o falso")
            if aplica:
                valor = evaluar(formula, ctx)
                if not _es_num(valor):
                    raise ErrorMotor("tipo", f"la formula de {nodo} debe dar un numero")
                valor = pesos(valor) if c["categoria"] != "auxiliar" else float(valor)
            else:
                valor = 0.0
        lineas[nodo] = {"clave": nodo, "nombre": c["nombre"], "categoria": c["categoria"],
                        "valor": valor, "aplica": aplica, "origen": origen,
                        "visible_cliente": c.get("visible_cliente", True)}
        variables[nodo] = valor

    suma = variables["suma"]
    regla = receta.get("redondeo_total", {"modo": "ninguno", "multiplo": 1})
    total = redondear_total(suma, regla)
    return {
        "lineas": [lineas[k] for k in claves],
        "agregados": {k: variables[k] for k in AGREGADOS},
        "suma": suma,
        "ajuste_redondeo": pesos(total - suma),
        "total": total,
    }


ETIQUETAS_CATEGORIA = [("material", "Materiales"), ("mano_obra", "Mano de obra"),
                       ("global", "Trabajo de herreria"), ("extra", "Extras"), ("descuento", "Descuento")]


def presentar(resultado, modo):
    """Lo que ve el cliente: lo oculto se reparte entre lo visible y la suma siempre da el total."""
    total = a_centavos(resultado["total"])
    impuesto = a_centavos(resultado["agregados"]["total_impuesto"])
    base = a_centavos(resultado["agregados"]["base_impuesto"])
    if impuesto != 0:
        tasa = impuesto / base
        base_mostrada = int(redondear(total / (1 + tasa)))
    else:
        base_mostrada = total
    impuesto_mostrado = total - base_mostrada

    visibles = [l for l in resultado["lineas"]
                if l["categoria"] in dict(ETIQUETAS_CATEGORIA) and l["aplica"] and l["visible_cliente"]
                and a_centavos(l["valor"]) != 0]
    if modo == "conceptos":
        items = [[l["nombre"], a_centavos(l["valor"])] for l in visibles]
    elif modo == "categorias":
        items = []
        for categoria, etiqueta in ETIQUETAS_CATEGORIA:
            monto = sum(a_centavos(l["valor"]) for l in visibles if l["categoria"] == categoria)
            if monto != 0:
                items.append([etiqueta, monto])
    elif modo == "total":
        items = []
    else:
        raise ErrorMotor("presentacion_invalida", modo)

    if modo != "total":
        positivos = [i for i, it in enumerate(items) if it[1] > 0]
        if not positivos:
            items = [["Trabajo de herreria", base_mostrada]]
        else:
            diferencia = base_mostrada - sum(it[1] for it in items)
            signo, por_repartir = (-1 if diferencia < 0 else 1), abs(diferencia)
            peso_total = sum(items[i][1] for i in positivos)
            partes = [divmod(por_repartir * items[i][1], peso_total) for i in positivos]
            sobrante = por_repartir - sum(c for c, _ in partes)
            # resto mayor: los centavos que sobran van a los residuos mas grandes; empate -> el primero
            ganadores = sorted(range(len(positivos)), key=lambda j: (-partes[j][1], j))[:sobrante]
            for j, i in enumerate(positivos):
                items[i][1] += signo * (partes[j][0] + (1 if j in ganadores else 0))
    return {"modo": modo,
            "items": [{"nombre": n, "valor": v / 100.0} for n, v in items],
            "impuesto": impuesto_mostrado / 100.0,
            "total": total / 100.0}


# ---------------------------------------------------------------------------
# 8. Generacion y verificacion de los casos dorados
# ---------------------------------------------------------------------------

def leer(nombre):
    with open(ENTRADAS / nombre, encoding="utf-8") as f:
        return json.load(f)


def limpiar(obj, decimales=6):
    """Redondea los flotantes para que los archivos sean estables y legibles."""
    if isinstance(obj, bool):
        return obj
    if isinstance(obj, float):
        valor = round(obj, decimales)
        return 0.0 if valor == 0 else valor
    if isinstance(obj, dict):
        return {k: limpiar(v, decimales) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [limpiar(v, decimales) for v in obj]
    return obj


def construir_dorados():
    global _estricto
    cat = Catalogo(leer("catalogo.json"))
    parametros = leer("parametros.json")["parametros"]
    recetas = {r["clave"]: r for r in leer("recetas.json")["recetas"]}
    salida = {}

    salida["catalogo_derivados.json"] = {
        "nota": "Valores derivados esperados para cada articulo del catalogo de prueba.",
        "tolerancia_abs": 1e-5,
        "articulos": {k: cat.derivados[k] for k in cat.articulos},
    }

    casos = []
    for caso in leer("casos_cortes.json")["casos"]:
        casos.append({**caso, "esperado": optimizar_cortes(caso["largos"], caso["tramo_mm"], caso["kerf_mm"])})
    salida["casos_cortes.json"] = {"nota": "Resultado esperado del optimizador de cortes.", "casos": casos}

    datos = leer("casos_formulas.json")
    precios = {k: v["precio"] for k, v in datos["articulos"].items()}
    casos = []
    for caso in datos["casos"]:
        registro = {"formula": caso["formula"]}
        try:
            valor = evaluar(analizar(caso["formula"]), Contexto(datos["variables"], datos["articulos"], precios))
            registro["esperado"] = valor
        except ErrorMotor as e:
            registro["error"] = e.codigo
            if e.codigo == "sintaxis":
                registro["posicion"] = e.posicion
        casos.append(registro)
    salida["casos_formulas.json"] = {
        "nota": "Resultado esperado de cada formula. 'error' es el codigo; 'posicion' solo en errores de sintaxis.",
        "tolerancia_abs": 1e-6,
        "variables": datos["variables"], "articulos": datos["articulos"], "casos": casos,
    }

    trabajos = {t["id"]: t for t in leer("trabajos.json")["trabajos"]}
    mediciones = {}
    for ident, t in trabajos.items():
        modelo = PLANTILLAS[t["plantilla"]](cat, t["parametros"])
        medicion = medir(cat, modelo)
        mediciones[ident] = medicion
        evaluaciones = {}
        _estricto = True
        for ev in t["evaluaciones"]:
            res = evaluar_receta(recetas[ev["receta"]], medicion, cat, parametros, t["datos_trabajo"],
                                 t["plantilla"], ev.get("ajustes"))
            reg = {"receta": ev["receta"], "ajustes": ev.get("ajustes", {}), **res}
            if ev.get("presentaciones"):
                reg["presentaciones"] = {m: presentar(res, m) for m in ev["presentaciones"]}
            evaluaciones[ev["id"]] = reg
        _estricto = False
        salida[f"{ident}.json"] = {
            "id": ident, "nombre": t["nombre"],
            "nota": "Caso dorado. Longitudes en mm, pesos en kg, areas en m2, dinero en pesos con 2 decimales.",
            "tolerancias": {"cantidad_abs": 1e-5, "dinero": 0},
            "entrada": {"plantilla": t["plantilla"], "parametros": t["parametros"],
                        "datos_trabajo": t["datos_trabajo"]},
            "esperado": {
                "modelo": {k: modelo[k] for k in ("plantilla", "caja", "num_hojas", "piezas", "paneles",
                                                  "herrajes", "uniones", "extras", "detalle",
                                                  "advertencias")},
                "despiece": medicion["despiece"], "cortes": medicion["cortes"],
                "por_articulo": medicion["por_articulo"], "uniones": medicion["uniones"],
                "cantidades": medicion["cantidades"], "advertencias": medicion["advertencias"],
                "evaluaciones": evaluaciones,
            },
        }

    casos = []
    base = trabajos["reja_1200x1000"]
    for caso in leer("casos_recetas_error.json")["casos"]:
        receta = {"clave": caso["id"], "nombre": caso["id"], "version": 1, "conceptos": caso["conceptos"]}
        registro = {"id": caso["id"], "conceptos": caso["conceptos"], "ajustes": caso.get("ajustes", {})}
        try:
            res = evaluar_receta(receta, mediciones["reja_1200x1000"], cat, parametros,
                                 base["datos_trabajo"], base["plantilla"], caso.get("ajustes"))
            registro["esperado"] = {"total": res["total"],
                                    "lineas": {l["clave"]: l["valor"] for l in res["lineas"]}}
        except ErrorMotor as e:
            registro["error"] = e.codigo
        casos.append(registro)
    salida["casos_recetas_error.json"] = {
        "nota": "Se evaluan con el trabajo reja_1200x1000. 'error' es el codigo esperado; los casos 'valida_*' no fallan.",
        "casos": casos,
    }
    return {nombre: limpiar(contenido) for nombre, contenido in salida.items()}


def texto_json(contenido):
    return json.dumps(contenido, ensure_ascii=False, indent=2) + "\n"


def main():
    ap = argparse.ArgumentParser(description="Oraculo del motor del cotizador de herreria")
    grupo = ap.add_mutually_exclusive_group(required=True)
    grupo.add_argument("--verificar", action="store_true", help="compara lo calculado con los dorados")
    grupo.add_argument("--generar", action="store_true", help="reescribe los dorados")
    args = ap.parse_args()

    dorados = construir_dorados()
    if args.generar:
        DORADOS.mkdir(parents=True, exist_ok=True)
        for nombre, contenido in dorados.items():
            with open(DORADOS / nombre, "w", encoding="utf-8", newline="\n") as f:
                f.write(texto_json(contenido))
        print(f"Se escribieron {len(dorados)} archivos en {DORADOS}")
        return 0

    fallas = 0
    for nombre, contenido in dorados.items():
        ruta = DORADOS / nombre
        if not ruta.exists():
            print(f"FALTA   {nombre}")
            fallas += 1
            continue
        with open(ruta, encoding="utf-8") as f:
            guardado = json.load(f)
        if guardado != json.loads(texto_json(contenido)):
            print(f"DIFIERE {nombre}")
            fallas += 1
        else:
            print(f"ok      {nombre}")
    return 1 if fallas else 0


if __name__ == "__main__":
    sys.exit(main())
