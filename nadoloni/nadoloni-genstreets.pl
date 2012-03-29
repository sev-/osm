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
my $nums = 0;

my $dumpname = shift or die "Usage: $0: nadoloni.osm";

my @buildings = ();
my @streets = ();
my %streetnames = ();

my $processor = sub {
	my $res = 0;

	if (exists $_[0]->{tag}->{"addr:housenumber"}) {
		$id = $_[0]->{tag}->{"nadoloni:id"};
		$id =~ s/buildings://;

		$buildings[$id] = $_[0]->{id};
		$numb++;
	} elsif (exists $_[0]->{tag}->{"nadoloni:id"}) {
		$id = $_[0]->{tag}->{"nadoloni:id"};
		if ($id =~ /streets:(\d+)$/) {
			if (exists $_[0]->{tag}->{name}) {
			  $s = $1;
			  push @{ $streets[$s]}, $_[0]->{id};
			  $nums++;

			  $streetnames{$_[0]->{id}} = $_[0]->{tag}->{name};
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

open IN, "buildings.csv";
binmode IN, ':utf8';

while (<IN>) {
	@s = split /;/;

	
	$n = "$s[2] $s[1]";
	
	if ($buildings[$s[0]] < 10000000) {
	  push @{ $relations{$n}->{members} }, { 'ref' => $buildings[$s[0]], 'type' => 'relation', 'role' => 'house' };
	} else {
	  push @{ $relations{$n}->{members} }, { 'ref' => $buildings[$s[0]], 'type' => 'way', 'role' => 'house' };
	}
}

close IN;

open IN, "streets.csv";
binmode IN, ':utf8';

$nrel = 1;

while (<IN>) {
	@s = split /;/;

	if ($s[2] =~ 'drogobych') {
	  $city = 'Дрогобич';
	} elsif ($s[2] =~ 'truskavets') {
	  $city = 'Трускавець';
	} elsif ($s[2] =~ 'stebnyk') {
	  $city = 'Стебник';
	} elsif ($s[2] =~ 'boryslav') {
	  $city = 'Борислав';
	} elsif ($s[2] =~ 'shidnycia') {
	  $city = 'Східниця';
	} elsif ($s[2] =~ 'stanylya') {
	  $city = 'Станиля';
	} elsif ($s[2] =~ 'dobrohostiv') {
	  $city = 'Доброгостів';
	} elsif ($s[2] =~ 'modrychi') {
	  $city = 'Модричі';
	} elsif ($s[2] =~ 'ranevychi') {
	  $city = 'Раневичі';
	} else {
	  print STDERR "Error: $s[2]\n";
	}

	$n = "$s[2] $s[1]";

	next if not defined $streets[$s[0]];

	$relations{$n}{tag}->{name} = $streetnames{$streets[$s[0]][0]};
	$relations{$n}{tag}->{type} = 'street';
	$relations{$n}{tag}->{'nadoloni:id'} = "relations:$nrel";
	$relations{$n}{tag}->{'addr:city'} = $city;
	$relations{$n}{type} = 'relation';
	$relations{$n}{action} = 'create';
	$relations{$n}{id} = -$nrel;

	$nrel++;

	for $st (@{ $streets[$s[0]] }) {
		push @{ $relations{$n}->{members} }, { 'ref' => $st, 'type' => 'way', 'role' => 'street' };
	}
}

close IN;

print "<osm  version='0.6'>\n";

for $r (keys %relations) {
	next if not defined $r;
	print Geo::Parse::OSM::object_to_xml($relations{$r});
}
print "</osm>\n";
