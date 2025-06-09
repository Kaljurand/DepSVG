"""Utility functions for DepSVG ported from Perl."""

from typing import Dict, Set


def strip_space(text: str) -> str:
    return text.strip()


def get_dep2heads(r: Dict[int, Dict[int, Dict[str, int]]]) -> Dict[int, Dict[int, int]]:
    h: Dict[int, Dict[int, int]] = {}
    for head, deps in r.items():
        for dep in deps:
            h.setdefault(dep, {})[head] = 1
    return h


def get_head2deps(r: Dict[int, Dict[int, Dict[str, int]]]) -> Dict[int, Dict[int, int]]:
    h: Dict[int, Dict[int, int]] = {}
    for head, deps in r.items():
        for dep in deps:
            h.setdefault(head, {})[dep] = 1
    return h


def get_deepest_depth(d: Dict[int, int]) -> int:
    return max(d.values()) if d else 0


def get_props(w: Dict[int, Dict[str, str]]) -> Set[str]:
    props: Set[str] = set()
    for node in w.values():
        props.update(node.keys())
    return props


def get_depths(h: Dict[int, Dict[int, int]], tag: str) -> Dict[int, int]:
    d: Dict[int, int] = {}
    for i in h:
        d[i] = get_maxdepth(h, i, {i: 1}, tag)
    return d


def get_maxdepth(
    h: Dict[int, Dict[int, int]], i: int, seen: Dict[int, int], tag: str
) -> int:
    maxdepth = 0
    for j in h.get(i, {}):
        if j in seen:
            print(f"depparse: warning: cycle in graph: node {j} ({tag})")
        else:
            md = get_maxdepth(h, j, {**seen, j: 1}, tag) + 1
            if maxdepth < md:
                maxdepth = md
    return maxdepth
