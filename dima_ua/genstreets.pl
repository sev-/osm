#!/usr/bin/perl -w
#
# Generate street relations for nadoloni.com
#

use utf8;
use Geo::Parse::OSM;
use Data::Dumper;

BEGIN { $| = 1; }

binmode STDERR, ':utf8';

my @cities = ();

my $numb = 0;

my $dumpname = shift or die "Usage: $0: nadoloni.osm";

my $processor = sub {
	my $res = 0;

	if (exists $_[0]->{tag}->{"street:id"}) {
	  push @{ $buildings[$_[0]->{tag}->{"street:id"}]}, $_[0]->{id};
	  $numb++;

	  delete $_[0]->{tag}->{"street:id"};

	  $_[0]->{action} = 'modify';

	  print Geo::Parse::OSM::object_to_xml($_[0]);
	}
};

print "<osm  version='0.6'>\n";

Geo::Parse::OSM->parse_file($dumpname, $processor);

#print "Buildings: $numb\n";

open IN, "str.csv";
binmode IN, ':utf8';

$nrel = 1;

while (<IN>) {
  chomp;

	@s = split /;/;

	next if not defined $buildings[$s[3]];

	%relation = ();

	$relation{tag}->{name} = $s[1];
	$relation{tag}->{type} = 'street';
	$relation{tag}->{'street:id'} = $s[3];
	$relation{type} = 'relation';
	$relation{'action'} = 'create';
	$relation{id} = -$nrel;

	$nrel++;

	for $st (@{ $buildings[$s[3]] }) {
		push @{ $relation{members} }, { 'ref' => $st, 'type' => 'way', 'role' => 'house' };
	}

	#print Geo::Parse::OSM::object_to_xml(\%relation);
}

close IN;

print "</osm>\n";
