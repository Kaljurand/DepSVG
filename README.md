DepSVG
======

DepSVG is a dependency tree and predicate-argument structure visualizer which
was originally implemented in Perl and saves into Scalable Vector Graphics
(SVG). A Python port of the tools was created automatically using Codex and is
included in this repository.

Read more at http://kaljurand.github.io/DepSVG/


Usage
-----

DepSVG is a library. `demo/conll_to_svg.perl` is its example front-end that
enables the visualization of CoNLL-formatted treebanks, e.g.

    perl -I src demo/conll_to_svg.perl --dir img < demo/treebank.tsv

visualizes each tree in `demo/treebank.tsv` and saves it as
an SVG file into the directory `img`.

The automatically generated Python script works in the same way:

    PYTHONPATH=. python3 demo/conll_to_svg.py --dir img < demo/treebank.tsv

The `img` directory committed in this repo was generated using the Python
script so that the example output is visible without additional steps.


License
-------

DepSVG is free software licensed under the GNU Lesser General Public Licence (see
http://www.gnu.org/licenses/lgpl.html).
