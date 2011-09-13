DepSVG
======

DepSVG is a dependency tree and predicate-argument structure visualizer which
is implemented in Perl and saves into Scalable Vector Graphics (SVG).
There are different ways to visualize dependency trees (e.g. Prague school,
Melchuk, Connexor, Link Grammar, etc). Our inspiration has been the trees
from the papers by Duchier and Debusmann, see e.g. XDG.


Usage
-----

DepSVG is a library. `demo/conll_to_svg.perl` is its example front-end that
enables the visualization of CoNLL-formatted treebanks, e.g.

    perl -I src demo/conll_to_svg.perl --dir img < demo/treebank.tsv

visualizes each tree in `demo/treebank.tsv` and saves it as
an SVG file into the directory `img`.


DepSVG in action
----------------

* [ParZu - The Zurich Dependency Parser for German][1]


License
-------

DepSVG is free software licensed under the GNU Lesser General Public Licence (see
http://www.gnu.org/licenses/lgpl.html).


[1]: http://kitt.cl.uzh.ch/kitt/parzu/
