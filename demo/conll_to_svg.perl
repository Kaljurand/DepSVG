# Converts CoNLL-formatted data into SVG for visualization.
# Author: Kaarel Kaljurand

# Usage:
#
# perl -I ../src/ conll_to_svg.perl --dir img < treebank.tsv
#
# As a result, a directory 'img' is created into the current directory and
# the SVG image files (1.svg, 2.svg, ...) are created into this new directory.

use strict;
use warnings;
use Getopt::Long;
use DepSVG;

my $dir = ".";
my $verbosity = 0;
my $help = "";
my $version = "";

my $getopt_result = GetOptions(
	"dir=s"        => \$dir,
	"verbosity=i"  => \$verbosity,
	"help"         => \$help,
	"version"      => \$version
);

if($version) { &show_version(); exit; }
if(!$getopt_result || $help) { &show_help(); exit; }

# Datastructures holding all the required information gathered from the input.
my $properties = {};
my $relations = {};

my $sentstart = 1;
my $linecount = 0;
my $debug = 0;
my $sid = 1;


print "Parsing input data... " if $verbosity > 0;

while(<STDIN>) {

	chomp;

	$linecount++;

	# Sentences are separated by an empty line.
	if(/^$/) {
		$sentstart = 1;
		$sid++;
		next;
	}

	# If we are in the sentence...
	if($sentstart) {

		my ($loc, $token, $lemma, $tag, $etag, $morph, $head, $type, $nhead, $ntype) = split "\t+";

		# BUG: do more serious error checking
		if(!defined($head)) {
			warn "Syntax error in corpus on line: $linecount\n";
			next;
		}

		$properties->{$sid}->{$loc}->{"LOC"} = $loc;
		$properties->{$sid}->{$loc}->{"token"} = $token;
		$properties->{$sid}->{$loc}->{"lemma"} = $lemma;
		$properties->{$sid}->{$loc}->{"tag"} = $tag;
		$properties->{$sid}->{$loc}->{"etag"} = $etag;

		### BUG: comment back in if you want to see the morph
	###	$properties->{$sid}->{$loc}->{"morph"} = $morph;

		$relations->{$sid}->{$head}->{$loc}->{$type} = 1;

		if($ntype ne "_" && $nhead ne "_" && ($type ne $ntype || $head != $nhead)) {
			$relations->{$sid}->{$nhead}->{$loc}->{$ntype} = 2;
		}
	}
}
print "done.\n" if $verbosity > 0;


print "Generating SVG... " if $verbosity > 0;

&sentences_to_svg($properties, $relations);

print "done.\n" if $verbosity > 0;

exit;


###
# This is where we access the DepSVG library. &get_svg() takes the following arguments:
# 1. A complex hash containing the properties of the nodes.
# 2. A complex hash containing the dependency relations between the nodes.
# 3. An array of property types which determines the order in which the properties are printed.
# 4. (Set to 0 for the time being.)
# 5. Height of the SVG image.
# 6. Width of the SVG image.
# 7. A string to be output along with an error message if the graph contains a loop.
###
sub sentences_to_svg
{
	my $properties = shift;
	my $relations = shift;

	foreach my $sid (keys %{$relations}) {

		my $svg = &get_svg($properties->{$sid}, $relations->{$sid},
						["token", "tag", "etag", "lemma", "morph", "LOC"],
						0, 1000, 1000, $sid);	


		&output_sentence($dir, $sid, $svg);

	}
}


###
#
###
sub output_sentence
{
	my $dir = shift;
	my $sid = shift;
	my $svg = shift;

	mkdir $dir;

	my $filename = $dir . "/" . $sid . "." . "svg";

	open(OUT, "> $filename") or die "conll_to_svg.perl: fatal error: open $filename: $!\n";
	print OUT $svg;
	close OUT or die "conll_to_svg.perl: fatal error: close $filename: $!\n";
}


###
# Output the version number
###
sub show_version
{
print <<EOF;
conll_to_svg.perl, ver 0.03 (2008-05-18)
Kaarel Kaljurand (kaljurand\@gmail.com)
EOF
}


###
# Output the help message
###
sub show_help
{
print <<EOF;
usage: conll_to_svg.perl OPTION...
OPTIONS:
	--dir=<directory name>  (where the SVG is saved) (defaults to .)
	--verbosity=<integer>	(defaults to 0)
	--version: print version information
	--help: this help message
EOF
}
