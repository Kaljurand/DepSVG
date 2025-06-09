"""Python port of DepSVG.pm."""

from typing import Dict, List, Tuple, Optional
from .deputils import (
    get_dep2heads,
    get_head2deps,
    get_depths,
    get_deepest_depth,
)

ENCODING = "UTF-8"
LETTER_WIDTH = 9
FONT_FAMILY = "sans-serif"
LETTER_SPACING = "0px"
WORD_SPACING = "0px"
HALF_LETTER_WIDTH = LETTER_WIDTH / 3
STROKE_WIDTH = "1px"
DEPTH_UNIT = 4 * LETTER_WIDTH
FONT_SIZE = f"{LETTER_WIDTH}px"
HIGHLIGHT_COLOR = "red"
ARC_COLOR = ["#f80", "#f80", "olive", "red", "green"]
ARC_TEXT_COLOR = "navy"
ARROW_COLOR = "#800"


def xcoord(i: int, xcoords: Dict[int, float]) -> float:
    return xcoords.get(i, 0)


def ycoord(i: int, dep2depths: Dict[int, int]) -> float:
    return dep2depths.get(i, 0) * DEPTH_UNIT


def get_arrow() -> str:
    return (
        '<marker id="a" viewbox="0 0 8 4" refX="8" refY="2" '
        'markerUnits="strokeWidth" markerWidth="8" markerHeight="4" orient="auto">'
        f"<path d=\"M 0 0 L 8 2 L 0 4 Z\" fill='{ARROW_COLOR}'/>"
        "</marker>"
    )


def get_longest_prop(h: Dict[str, str]) -> Optional[str]:
    maxlen = 0
    unit = None
    for p, val in h.items():
        if len(val) > maxlen:
            maxlen = len(val)
            unit = p
    return unit


def make_word_distance(w: Dict[int, Dict[str, str]]) -> Tuple[Dict[int, float], float]:
    xcoord_map: Dict[int, float] = {}
    prev_unit = ""
    prev_index = 0
    x = 0.0
    for index in sorted(w.keys()):
        unit = get_longest_prop(w[index]) or ""
        if index == 1:
            x = len(w[index][unit]) * HALF_LETTER_WIDTH
        else:
            prev_len = len(w[prev_index][prev_unit])
            curr_len = len(w[index][unit])
            x += (prev_len + curr_len) * HALF_LETTER_WIDTH
        xcoord_map[index] = x
        prev_unit = unit
        prev_index = index
    lastx = x + len(w[prev_index][prev_unit]) * HALF_LETTER_WIDTH
    return xcoord_map, lastx


def get_svg(
    w: Dict[int, Dict[str, str]],
    r: Dict[int, Dict[int, Dict[str, int]]],
    props: List[str],
    fixwin: int,
    xwin: int,
    ywin: int,
    tag: str,
) -> str:
    svg = ""
    xcoords, viewboxx = make_word_distance(w)
    dep2heads = get_dep2heads(r)
    head2deps = get_head2deps(r)
    dep2depths = get_depths(dep2heads, tag)

    max_depth = get_deepest_depth(dep2depths)

    textdepth = (len(props)) * LETTER_WIDTH
    textline = max_depth * DEPTH_UNIT + LETTER_WIDTH
    viewboxy = textline + textdepth

    if fixwin:
        svg += make_svg_header(xwin, ywin, viewboxx, viewboxy, ENCODING)
    else:
        svg += make_svg_header(viewboxx, viewboxy, viewboxx, viewboxy, ENCODING)

    svg += "<g stroke-width='0' fill='black'>\n"
    for i in sorted(w.keys()):
        x = xcoord(i, xcoords)
        fill = ""
        if i not in dep2heads and i not in head2deps:
            fill = f" fill='{HIGHLIGHT_COLOR}'"
        svg += print_text_svgtiny(w, i, x, textline, fill, props)
    svg += "</g>\n"

    svg += "<g stroke='silver' stroke-dasharray='4'>\n"
    for i in sorted(w.keys()):
        x = xcoord(i, xcoords)
        if i in dep2heads or i in head2deps:
            svg += print_line(x, x, ycoord(i, dep2depths), textline)
    svg += "</g>\n"

    svg += f"<g stroke='{ARC_COLOR[1]}' fill='none'>\n"
    for head, deps in r.items():
        for dep, rels in deps.items():
            for rel, col in rels.items():
                color = ARC_COLOR[col]
                svg += draw_arc(
                    xcoord(head, xcoords),
                    xcoord(dep, xcoords),
                    ycoord(head, dep2depths),
                    ycoord(dep, dep2depths),
                    dep2heads.get(head, {}).get(dep),
                    color,
                )
    svg += "</g>\n"

    svg += f"<g stroke-width='0' fill='{ARC_TEXT_COLOR}'>\n"
    for head, deps in r.items():
        for dep, rels in deps.items():
            svg += draw_arclabels(
                xcoord(head, xcoords),
                xcoord(dep, xcoords),
                ycoord(head, dep2depths),
                ycoord(dep, dep2depths),
                dep2heads.get(head, {}).get(dep),
                rels,
            )
    svg += "</g>\n"

    svg += make_svg_footer()
    return svg


def print_text_svgtiny(
    w: Dict[int, Dict[str, str]],
    i: int,
    x: float,
    textline: float,
    fill: str,
    props: List[str],
) -> str:
    text = ""
    y = textline
    for tag in props:
        y += LETTER_WIDTH
        content = w.get(i, {}).get(tag)
        if content is None:
            text += f"<text x='{x}' y='{y}'{fill}>-</text>\n"
        else:
            content = escape_xml_entities(content)
            text += f"<text x='{x}' y='{y}'{fill}>{content}</text>\n"
    return text


def print_text(
    w: Dict[int, Dict[str, str]],
    i: int,
    x: float,
    textline: float,
    fill: str,
    props: List[str],
) -> str:
    text = f"<text x='{x}' y='{textline}'{fill}>\n"
    for tag in props:
        content = w.get(i, {}).get(tag, "-")
        text += print_tspan(content, tag, x)
    text += "</text>\n"
    return text


def print_tspan(content: str, cls: str, x1: float) -> str:
    dystr = "1em"
    cls, content = escape_xml_entities(cls, content)
    return f"<tspan x='{x1}' dy='{dystr}'>{content}</tspan>"


def draw_arc(
    x1: float,
    x2: float,
    y1: float,
    y2: float,
    on_loop: Optional[int],
    color: Optional[str] = None,
) -> str:
    if on_loop:
        tx = x1 + (x2 - x1) / 2
        ty = y1 + (y2 - y1) / 2
        bx, by = get_vertex(tx, ty, x2, y2)
        line = f"M{x1} {y1} C{bx} {by} {bx} {by} {x2} {y2}"
    else:
        line = f"M{x1} {y1} {x2} {y2}"
    if color is not None:
        return f'<path d=\'{line}\' marker-end="url(#a)" stroke="{color}"/>'
    return f"<path d='{line}' marker-end=\"url(#a)\"/>"


def draw_arclabels(
    x1: float,
    x2: float,
    y1: float,
    y2: float,
    on_loop: Optional[int],
    labels: Dict[str, int],
) -> str:
    tx = x1 + (x2 - x1) / 2
    ty = y1 + (y2 - y1) / 2
    if on_loop:
        tx, ty = get_vertex(tx, ty, x2, y2)
    parts = []
    label_keys = list(labels.keys())
    if len(label_keys) == 1:
        parts.append(escape_xml_entities(label_keys[0]))
    else:
        for idx, lab in enumerate(label_keys):
            color = ARC_COLOR[labels[lab]]
            parts.append(
                f"<tspan fill='{color}'>" + escape_xml_entities(lab) + "</tspan>"
            )
            if idx != len(label_keys) - 1:
                parts.append(" ")
    return f"<text x='{tx}' y='{ty}'>" + "".join(parts) + "</text>"


def get_vertex(tx: float, ty: float, x2: float, y2: float) -> Tuple[float, float]:
    height = 10.0
    C = ((x2 - tx) ** 2 + (y2 - ty) ** 2) ** 0.5
    if C == 0:
        C = 0.001
    bx = tx + height * (y2 - ty) / C
    by = ty + height * (tx - x2) / C
    return bx, by


def print_line(x1: float, x2: float, y1: float, y2: float) -> str:
    return f"<path d='M{x1} {y1} {x2} {y2}'/>"


def make_svg_header(
    sizex: float, sizey: float, viewx: float, viewy: float, encoding: str
) -> str:
    arrow = get_arrow()
    return (
        f"<?xml version='1.0' encoding='{encoding}'?>"
        f"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 {viewx} {viewy}' width='{sizex}' height='{sizey}'>"
        f"<title/>"
        f"<defs>{arrow}</defs>"
        f"<g stroke-width='{STROKE_WIDTH}' stroke-linecap='butt' font-family='{FONT_FAMILY}' font-size='{FONT_SIZE}' text-anchor='middle' dominant-baseline='central' word-spacing='{WORD_SPACING}' letter-spacing='{LETTER_SPACING}'>"
    )


def make_svg_footer() -> str:
    return "</g></svg>"


def escape_xml_entities(*entities: str) -> str:
    replacements = {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "'": "&apos;",
        '"': "&quot;",
    }
    escaped = []
    for ent in entities:
        for k, v in replacements.items():
            ent = ent.replace(k, v)
        escaped.append(ent)
    return escaped[0] if len(escaped) == 1 else tuple(escaped)


def make_id(rel: str, head: int, dep: int) -> str:
    return f"{rel}-{head}-{dep}"
