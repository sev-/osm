#!/usr/bin/perl -w
#
# Extract vuilding ids for nadoloni.com
#
# Usage:
#  perl -CD _sevbot.pl ukraine.osm >_sevbot.osm 2>_sevbot.log
#
# Since the exports on goefabrik not always match it is advised to reapply bounding polygon
#  getbound.pl 60199 -o ukraine.poly
#  osmosis --rx file=ukraine.osm --bp file=ukraine.poly --wx file=ukraine2.osm

use utf8;
use Geo::Parse::OSM;
use Data::Dumper;

BEGIN { $| = 1; }

binmode STDERR, ':utf8';

my @cities = ();

my $numb = 0;
my $nums = 0;

my $dumpname = shift or die "Usage: $0: nadoloni.osm";

my @buildings = ();
my @streets = ();
my @streetnames = ();

my $processor = sub {
	my $res = 0;

	if (exists $_[0]->{tag}->{"addr:housenumber"}) {
		$id = $_[0]->{tag}->{"nadoloni:id"};
		$id =~ s/buildings://;
		if (exists $buildings[$id]) {
			print "$id: $_[0]->{id}\n";
		}

		$buildings[$id] = $_[0]->{id};
		$numb++;

		if (exists $_[0]->{tag}->{type}) {
			print "building: $_[0]->{id}\n";
		}
	} elsif (exists $_[0]->{tag}->{"nadoloni:id"}) {
		$id = $_[0]->{tag}->{"nadoloni:id"};
		if ($id =~ /streets:(\d+)/) {
			push @{ $streets[$1]}, $_[0]->{id};
			$nums++;

			$streetnames[$1] = $_[0]->{tag}->{name};

			if (exists $_[0]->{tag}->{type}) {
				print "street: $_[0]->{id}\n";
			}
		}
	}

	if (0 && exists $_[0]->{tag}->{type}) {
		print Dumper($_[0]);
		print "\n";
	}
};

Geo::Parse::OSM->parse_file($dumpname, $processor);


#print "Streets: $nums\n";
#print "Buildings: $numb\n";

my @relations = ();

open IN, "buildings1.txt";
binmode IN, ':utf8';

@buildstreets = ();

while (<IN>) {
	@s = split /;/;

	$buildstreets[$s[0]] = $s[5];

	if (0 && not exists $relations[$s[5]]) {
		$relations[$s[5]]->{members} = ();
	}

	push @{ $relations[$s[5]]->{members} }, { 'ref' => $buildings[$s[0]], 'type' => 'way', 'role' => 'house' };
}

close IN;

open IN, "streets.txt";
binmode IN, ':utf8';

@streetstreets = ();

while (<IN>) {
	@s = split /;/;

	$streetstreets[$s[0]] = $s[7];

	$relations[$s[7]]{tag}->{name} = $streetnames[$s[7]];
	$relations[$s[7]]{tag}->{type} = 'street';
	$relations[$s[7]]{tag}->{'nadoloni:id'} = "relations:$s[7]";
	$relations[$s[7]]{tag}->{'source'} = "nadoloni.com import";
	$relations[$s[7]]{tag}->{'source_ref'} = "http://nadoloni.com";
	$relations[$s[7]]{type} = 'relation';
	$relations[$s[7]]{id} = -$s[7];

	for $s (@{ $streets[$s[0]] }) {
		push @{ $relations[$s[7]]->{members} }, { 'ref' => $s, 'type' => 'way', 'role' => 'street' };
	}
}

close IN;

print "<osm  version='0.6'>\n";

for $r (@relations) {
	next if not defined $r;
	print Geo::Parse::OSM::object_to_xml($r);
}
print "</osm>\n";
