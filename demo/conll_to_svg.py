#!/usr/bin/env python3
"""Convert CoNLL-formatted data into SVG images."""

import argparse
import os
import sys
from typing import Dict

from src.depsvg import get_svg


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Convert CoNLL to SVG")
    p.add_argument("--dir", default=".", help="output directory")
    p.add_argument("--verbosity", type=int, default=0)
    p.add_argument("--version", action="store_true")
    return p.parse_args()


def show_version() -> None:
    print("conll_to_svg.py, ver 0.03 (2008-05-18)")
    print("Kaarel Kaljurand (kaljurand@gmail.com)")


def output_sentence(outdir: str, sid: int, svg: str) -> None:
    os.makedirs(outdir, exist_ok=True)
    filename = os.path.join(outdir, f"{sid}.svg")
    with open(filename, "w", encoding="utf-8") as f:
        f.write(svg)


def sentences_to_svg(
    properties: Dict[int, Dict[int, Dict[str, str]]],
    relations: Dict[int, Dict[int, Dict[int, Dict[str, int]]]],
    outdir: str,
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
        output_sentence(outdir, sid, svg)


def main() -> None:
    args = parse_args()
    if args.version:
        show_version()
        return

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
    if args.verbosity > 0:
        print("Generating SVG...", end=" ")
    sentences_to_svg(properties, relations, args.dir)
    if args.verbosity > 0:
        print("done.")


if __name__ == "__main__":
    main()
