DepSVG
======

DepSVG is a dependency tree and predicate-argument structure visualizer which
is implemented in Perl and saves into Scalable Vector Graphics (SVG).

Read more at http://kaljurand.github.com/DepSVG/


Usage
-----

DepSVG is a library. `demo/conll_to_svg.perl` is its example front-end that
enables the visualization of CoNLL-formatted treebanks, e.g.

    perl -I src demo/conll_to_svg.perl --dir img < demo/treebank.tsv

visualizes each tree in `demo/treebank.tsv` and saves it as
an SVG file into the directory `img`.


License
-------

DepSVG is free software licensed under the GNU Lesser General Public Licence (see
http://www.gnu.org/licenses/lgpl.html).
