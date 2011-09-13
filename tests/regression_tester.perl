#!/usr/bin/perl

# Converts the CONLL data into SVG for visualization.
# @author Kaarel Kaljurand
# @version 2008-05-17

# Usage:
#
# cat in.txt | perl -I ../src/ regression_tester.perl > out.txt

use strict;
use warnings;
use Getopt::Long;
use DepSVG;

# Datastructures holding all the required information gathered from the input.
my $properties = {};
my $relations = {};

my $sentstart = 1;
my $linecount = 0;
my $debug = 0;
my $sid = 1;


while(<STDIN>) {

	chomp;

	$linecount++;

	# Sentences are separated by an empty line.
	if (/^$/) {
		$sentstart = 1;
		$sid++;
		next;
	}

	# If we are in the sentence...
	if ($sentstart) {

		my ($loc, $token, $lemma, $tag, $etag, $morph, $head, $type, $nhead, $ntype) = split "\t+";

		# BUG: do more serious error checking
		if (!defined($head)) {
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

		if ($ntype ne "_" && $nhead ne "_" && ($type ne $ntype || $head != $nhead)) {
			$relations->{$sid}->{$nhead}->{$loc}->{$ntype} = 2;
		}
	}
}

&sentences_to_svg($properties, $relations);

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

		print $svg;
	}
}
