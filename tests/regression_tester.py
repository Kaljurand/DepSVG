#!/usr/bin/env python3
"""Regression tester using the Python port."""

import sys
from typing import Dict
from src.depsvg import get_svg


def sentences_to_svg(
    properties: Dict[int, Dict[int, Dict[str, str]]],
    relations: Dict[int, Dict[int, Dict[int, Dict[str, int]]]],
) -> None:
    for sid in relations:
        svg = get_svg(
            properties.get(sid, {}),
            relations[sid],
            ["token", "tag", "etag", "lemma", "morph", "LOC"],
            0,
            1000,
            1000,
            str(sid),
        )
        sys.stdout.write(svg)


def main() -> None:
    properties: Dict[int, Dict[int, Dict[str, str]]] = {}
    relations: Dict[int, Dict[int, Dict[int, Dict[str, int]]]] = {}
    sentstart = True
    linecount = 0
    sid = 1
    for line in sys.stdin:
        linecount += 1
        line = line.rstrip("\n")
        if line == "":
            sentstart = True
            sid += 1
            continue
        if sentstart:
            parts = line.split("\t")
            if len(parts) < 8:
                print(f"Syntax error in corpus on line: {linecount}", file=sys.stderr)
                continue
            loc = int(parts[0])
            token, lemma, tag, etag, morph, head, typ = parts[1:8]
            nhead = parts[8] if len(parts) > 8 else "_"
            ntype = parts[9] if len(parts) > 9 else "_"
            head = int(head)
            if nhead != "_":
                nhead_int = int(nhead)
            else:
                nhead_int = nhead
            properties.setdefault(sid, {}).setdefault(loc, {})
            properties[sid][loc]["LOC"] = str(loc)
            properties[sid][loc]["token"] = token
            properties[sid][loc]["lemma"] = lemma
            properties[sid][loc]["tag"] = tag
            properties[sid][loc]["etag"] = etag
            relations.setdefault(sid, {}).setdefault(head, {}).setdefault(loc, {})[
                typ
            ] = 1
            if ntype != "_" and nhead != "_" and (typ != ntype or head != nhead_int):
                relations[sid].setdefault(nhead_int, {}).setdefault(loc, {})[ntype] = 2
    sentences_to_svg(properties, relations)


if __name__ == "__main__":
    main()
