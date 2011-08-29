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
		if ($id =~ /streets:(\d+)$/) {
			$s = $1;
			push @{ $streets[$s]}, $_[0]->{id};
			$nums++;

			$streetnames{$_[0]->{id}} = $_[0]->{tag}->{name};

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

while (<IN>) {
	@s = split /;/;

	
	if ($s[4] eq 'drogobych') {
		$c = 0;
	} elsif ($s[4] eq 'truskavets') {
		$c = 1000;
	} elsif ($s[4] eq 'stebnyk') {
		$c = 2000;
	} elsif ($s[4] eq 'boryslav') {
		$c = 3000;
	} else {
		print STDERR "Error: $s[4]\n";
	}

	$n = $c + $s[5];
	
	if (0 && not exists $relations[$s[5]]) {
		$relations[$s[5]]->{members} = ();
	}

	push @{ $relations[$n]->{members} }, { 'ref' => $buildings[$s[0]], 'type' => 'way', 'role' => 'house' };
}

close IN;

open IN, "streets.txt";
binmode IN, ':utf8';

while (<IN>) {
	@s = split /;/;

        if ($s[6] eq 'drogobych') {
                $c = 0;
		$city = 'Дрогобич';
        } elsif ($s[6] eq 'truskavets') {
                $c = 1000;
		$city = 'Трускавець';
        } elsif ($s[6] eq 'stebnyk') {
                $c = 2000;
		$city = 'Стебник';
	} elsif ($s[6] eq 'boryslav') {
		$c = 3000;
		$city = 'Борислав';
        } else {
                print STDERR "Error: $s[6]\n";
        }
  
	$n = $c + $s[7];

	$relations[$n]{tag}->{name} = $streetnames{$streets[$s[0]][0]};
	$relations[$n]{tag}->{type} = 'street';
	$relations[$n]{tag}->{'nadoloni:id'} = "relations:$n";
	$relations[$n]{tag}->{'addr:city'} = $city;
	$relations[$n]{type} = 'relation';
	$relations[$n]{id} = -$n;

	for $st (@{ $streets[$s[0]] }) {
		push @{ $relations[$n]->{members} }, { 'ref' => $st, 'type' => 'way', 'role' => 'street' };
	}
}

close IN;

print "<osm  version='0.6'>\n";

for $r (@relations) {
	next if not defined $r;
	print Geo::Parse::OSM::object_to_xml($r);
}
print "</osm>\n";
