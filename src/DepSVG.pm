# Turns a dependency parse into a SVG picture.
# Kaarel Kaljurand
# 2006-03-03

package DepSVG;

use strict;
use warnings;
use DepUtils;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	$VERSION = 0.95;

	@ISA = qw(Exporter);
	@EXPORT = qw(&get_svg);
	%EXPORT_TAGS = ();
	@EXPORT_OK = ();
}

my $encoding = "UTF-8";

# BUG: get rid of those constants by calculating
# some automatically and moving some to CSS

my $letter_width = 9;
# We can use variable width font, but we can't calculate the exact span
# of the strings. We calculate the span as if the font was monospace.
# This results in more whitespace between strings than needed.
my $fontFamily = "sans-serif";
#my $fontFamily = "monospace";

my $letterSpacing = "0px";
my $wordSpacing = "0px";

# BUG: this gives better results, strange
my $half_letter_width = $letter_width / 3;

#my $strokeWidth = $letter_width / 4;
my $strokeWidth = "1px";

my $depth_unit = 4 * $letter_width;
my $fontSize = 1 * $letter_width . "px";

my $highlightColor = "red";
my $arcColor = "#f80";
my $arcColorSpecial = "olive";
#my $arcColorSpecial = "#afa";
my $arcTextColor = "navy";
my $arrowColor = "#800";

END { }

###
#
###
sub xcoord
{
	my $i = shift;
	my $xcoord = shift;

	if(defined($xcoord->{$i})) {
		return $xcoord->{$i};
	}
	else {
		return 0;
	}
}

###
# Map node labels to y-coordinates
###
sub ycoord
{
	my $i = shift;
	my $dep2depths = shift;

	if(defined($dep2depths->{$i})) {
		return $dep2depths->{$i} * $depth_unit;
	}
	# If the node is not a dependent of any other node
	else {
		return 0;
	}
}

###
#
###
sub get_arrow
{
return <<EOF;
<marker id="a" viewbox="0 0 8 4" refX="8" refY="2" markerUnits="strokeWidth"
markerWidth="8" markerHeight="4" orient="auto">
<path d="M 0 0 L 8 2 L 0 4 Z" fill='$arrowColor'/>
</marker>
EOF
}

###
#
###
sub get_longest_prop
{
	my $h = shift;

	my $maxlen = 0;
	my $unit = undef;

	foreach my $p (keys %{$h}) {
		my $len = length($h->{$p});
		if ($len > $maxlen) {
			$maxlen = $len;
			$unit = $p;
		}
	}

	return $unit;
}

###
# Calculates the x-coordinate for each word, i.e. the distance
# from the edge of the window.
###
sub make_word_distance
{
	my $w = shift;

	my $xcoord = {};
	my $prev_unit = "";
	my $prev_index = "";

	my $x = 0;

	foreach my $index (sort {$a <=> $b} keys %{$w}) {

		my $unit = &get_longest_prop($w->{$index});

		if($index == 1) {
			$x = length($w->{$index}->{$unit}) * $half_letter_width;
		}
		else {
			my $prev_len = length($w->{$prev_index}->{$prev_unit});
			my $curr_len = length($w->{$index}->{$unit});
			$x = $x + ($prev_len + $curr_len) * $half_letter_width;
		}	

		$xcoord->{$index} = $x;

		$prev_unit = $unit;
		$prev_index = $index;
	}

	my $lastx = $x + length($w->{$prev_index}->{$prev_unit}) * $half_letter_width;
	return ($xcoord, $lastx);
}

###
#
###
sub get_svg
{
	my $w = shift;
	my $r = shift;
	my $props = shift;
	my $fixwin = shift;
	my $xwin = shift;
	my $ywin = shift;
	my $tag = shift;

	my $svg = "";

	my ($xcoord, $viewboxx) = &make_word_distance($w);

	my $dep2heads = &get_dep2heads($r);
	my $head2deps = &get_head2deps($r);
	my $dep2depths = &get_depths($dep2heads, $tag);

# BUG: remove those soon, use unittesting for that
#	print "---\n";
#	&print_depths($dep2depths);
#	print "---\n";
#	&print_set_of_sets($head2deps);
#	print "---\n";
#	&print_set_of_sets($dep2heads);
#	print "---\n";

	my $max_depth = &get_deepest_depth($dep2depths);

	my $textdepth = ($#{$props} + 1) * $letter_width;
	my $textline = $max_depth * $depth_unit + $letter_width;
	my $viewboxy = $textline + $textdepth;


	if($fixwin) {
		$svg = $svg . &make_svg_header($xwin, $ywin, $viewboxx, $viewboxy, $encoding);
	}
	else {
		$svg = $svg . &make_svg_header($viewboxx, $viewboxy, $viewboxx, $viewboxy, $encoding);
	}


	$svg = $svg . "<g stroke-width='0' fill='black'>\n";

	# Print the nodes (words)
	foreach my $i (sort {$a <=> $b} keys %{$w}) {

		my $x = $xcoord->{$i};
		my $y = &ycoord($i, $dep2depths);

		my $fill = "";

		# In case the node is somebody's dependent or somebody's head
		if(defined $dep2heads->{$i} || defined $head2deps->{$i}) {
		}
		# Otherwise highlight it
		else {
			$fill = " fill='$highlightColor'";
		}

		#$svg = $svg . &print_text($w, $i, $x, $textline, $fill, $props);
		$svg = $svg . &print_text_svgtiny($w, $i, $x, $textline, $fill, $props);
	}

	$svg = $svg . "</g>\n";

	$svg = $svg . "<g stroke='silver' stroke-dasharray='4'>\n";

	foreach my $i (sort {$a <=> $b} keys %{$w}) {

		my $x = $xcoord->{$i};
		my $y = &ycoord($i, $dep2depths);

		my $fontColor = "black";

		# In case the node is somebody's dependent or somebody's head
		if(defined $dep2heads->{$i} || defined $head2deps->{$i}) {
			$svg = $svg . &print_line($x, $x, $y, $textline);
		}
	}
	$svg = $svg . "</g>\n";


	$svg = $svg . "<g stroke='$arcColor' fill='none'>\n";

	# Print the arcs
	foreach my $rel (keys %{$r}) {


		foreach my $head (keys %{$r->{$rel}}) {
			foreach my $dep (keys %{$r->{$rel}->{$head}}) {

				my $color = undef;

				if($r->{$rel}->{$head}->{$dep} == 2) {
					$color = $arcColorSpecial;
				}
		

				# BUG: we don't need the ID
				#my $id = &make_id($rel, $head, $dep);

				my $x1 = &xcoord($head, $xcoord);
				my $y1 = &ycoord($head, $dep2depths);

				my $x2 = &xcoord($dep, $xcoord);
				my $y2 = &ycoord($dep, $dep2depths);

				$svg = $svg . &draw_arc($x1, $x2, $y1, $y2, $dep2heads->{$head}->{$dep}, $color);
			}
		}
	}

	$svg = $svg . "</g>\n";

	$svg = $svg . "<g stroke-width='0' fill='$arcTextColor'>\n";

	# Print the arcs
	foreach my $rel (keys %{$r}) {
		foreach my $head (keys %{$r->{$rel}}) {
			foreach my $dep (keys %{$r->{$rel}->{$head}}) {

				# BUG: we don't need the ID
				#my $id = &make_id($rel, $head, $dep);

				my $x1 = &xcoord($head, $xcoord);
				my $y1 = &ycoord($head, $dep2depths);

				my $x2 = &xcoord($dep, $xcoord);
				my $y2 = &ycoord($dep, $dep2depths);

				$svg = $svg . &draw_arctext($rel, $x1, $x2, $y1, $y2, $dep2heads->{$head}->{$dep});
			}
		}
	}

	$svg = $svg . "</g>\n";

	$svg = $svg . &make_svg_footer();

	return $svg;
}

###
#
###
sub print_text_svgtiny
{
	my $w = shift;
	my $i = shift;
	my $x = shift;
	my $textline = shift;
	my $fill = shift;
	my $props = shift;

	my $text = "";
	my $y = $textline;

	foreach my $tag (@{$props}) {

		$y = $y + $letter_width;

		if(defined $w->{$i}->{$tag}) {

			my $content = $w->{$i}->{$tag};

			foreach ($content) {
				s/\&/\&amp;/g;
				s/</\&lt;/g;
				s/>/\&gt;/g;
				s/'/\&apos;/g;
				s/"/\&quot;/g;
			}

			$text = $text . "<text x='$x' y='$y'$fill>$content</text>\n";
		}
		else {
			$text = $text . "<text x='$x' y='$y'$fill>-</text>\n";
		}
	}

	return $text;
}

###
#
###
sub print_text
{
	my $w = shift;
	my $i = shift;
	my $x = shift;
	my $textline = shift;
	my $fill = shift;
	my $props = shift;

	my $text = "<text x='$x' y='$textline'$fill>\n";

	foreach my $tag (@{$props}) {

		if(defined $w->{$i}->{$tag}) {
			$text = $text . &print_tspan($w->{$i}->{$tag}, $tag, $x);
		}
		else {
			$text = $text . &print_tspan("-", "-", $x);
		}

	}

	$text = $text . "</text>\n";

	return $text;
}

###
#
###
sub print_tspan
{
	my $content = shift;
	my $class = shift;
	my $x1 = shift;

	my $dystr = "1em";

	my $textLength = length($content) * $letter_width . "px";

	foreach ($class, $content) {
		s/\&/\&amp;/g;
		s/</\&lt;/g;
		s/>/\&gt;/g;
		s/'/\&apos;/g;
		s/"/\&quot;/g;
	}

# BUG: currently we don't output the class attribute
#<tspan class='$class' x='$x1' dy='$dystr'>$content</tspan>
#<tspan textLength="$textLength">$content</tspan>
return <<TSPAN;
<tspan x='$x1' dy='$dystr'>$content</tspan>
TSPAN
}

###
#
###
sub draw_arc
{
	my $x1 = shift;
	my $x2 = shift;
	my $y1 = shift;
	my $y2 = shift;
	my $on_loop = shift;
	my $color = shift;

	my $linestr = "";

	if($on_loop) {

		my $tx = $x1 + ($x2 - $x1)/2;
		my $ty = $y1 + ($y2 - $y1)/2;

		my ($bx, $by) = &get_vertex($tx, $ty, $x2, $y2);

		$linestr = "M" . $x1 . " " . $y1 . " C" . $bx . " " . $by . " " . $bx . " " . $by . " " . $x2 . " " . $y2;
	}

	else {
		$linestr = "M" . $x1 . " " . $y1 . " " . $x2 . " " . $y2;
	}

if(defined $color) {
return <<EOF;
<path d='$linestr' marker-end="url(#a)" stroke="$color"/>
EOF
}
else {
return <<EOF;
<path d='$linestr' marker-end="url(#a)"/>
EOF
}
}

###
#
###
sub draw_arctext
{
	my $type = shift;
	my $x1 = shift;
	my $x2 = shift;
	my $y1 = shift;
	my $y2 = shift;
	my $on_loop = shift;

	my $tx = $x1 + ($x2 - $x1)/2;
	my $ty = $y1 + ($y2 - $y1)/2;

	if($on_loop) {

		($tx, $ty) = &get_vertex($tx, $ty, $x2, $y2);
	}

	# BUG: move into a function
	foreach ($type) {
		s/\&/\&amp;/g;
		s/</\&lt;/g;
		s/>/\&gt;/g;
		s/'/\&apos;/g;
		s/"/\&quot;/g;
	}


return <<EOF;
<text x="$tx" y="$ty">$type</text>
EOF
}

###
# Returns the 3rd vertex of a right triangle, based on the 2
# vertexes given as input.
# This problem has two solutions, but we're happy with the first
# solution found.
# Copied from:
# http://answers.google.com/answers/threadview?id=419874
###
sub get_vertex
{
	my $tx = shift;
	my $ty = shift;
	my $x2 = shift;
	my $y2 = shift;

	my $height = 10;

	my $C = sqrt( ($x2 - $tx) ** 2 + ($y2 - $ty) ** 2 );

	my $bx = $tx + $height * ($y2 - $ty) / $C;
	my $by = $ty + $height * ($tx - $x2) / $C;

	return ($bx, $by);
}

###
# Prints an SVG line
# We actually use the path-element which takes smaller amount bytes.
# BUG: is it a good idea?
###
sub print_line
{
	my ($x1, $x2, $y1, $y2) = @_;

#<line x1='$x1' y1='$y1' x2='$x2' y2='$y2'/>
return <<LINE;
<path d='M$x1 $y1 $x2 $y2'/>
LINE
}

###
#
###
sub make_svg_header
{
	my $sizex = shift;
	my $sizey = shift;
	my $viewx = shift;
	my $viewy = shift;

	my $encoding = shift;
	
	my $arrow = &get_arrow();

# BUG: stylesheet could be added here
#<?xml-stylesheet href="dependencies.css" type="text/css"?>

# BUG: we currently don't use XLink namespace and probably never will.
# Links can be added to the picture by XSLT, which knows which resource it wants to link to.
# xmlns:xlink="http://www.w3.org/1999/xlink"

return <<EOF;
<?xml version="1.0" encoding="$encoding"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox='0 0 $viewx $viewy' width='$sizex' height='$sizey'>

<title>.</title>
<defs>$arrow</defs>

<g stroke-width='$strokeWidth' stroke-linecap='butt' font-family='$fontFamily' font-size='$fontSize' text-anchor='middle' dominant-baseline='central' word-spacing='$wordSpacing' letter-spacing='$letterSpacing'>
EOF
}

###
#
###
sub make_svg_footer
{
return <<EOF;
</g>
</svg>
EOF
}

###
# BUG: currently not used
###
sub make_id
{
	my $rel = shift;
	my $head = shift;
	my $dep = shift;

	return $rel . "-" . $head . "-" . $dep;
}

1;
