#!/usr/bin/perl -w
#
# Generate street relations for nadoloni.com
#

use utf8;
use Geo::Parse::OSM;
use Data::Dumper;

BEGIN { $| = 1; }

binmode STDERR, ':utf8';

my $numb = 0;

my $dumpname = shift or die "Usage: $0: nadoloni.osm";

my @buildings = ();
my @streets = ();
my @relations = ();

my $processor = sub {
	my $res = 0;

	return unless exists $_[0]->{tag}->{"street:id"};

	if (exists $_[0]->{tag}->{"building"}) {
	  push @{ $buildings[$_[0]->{tag}->{"street:id"}]}, $_[0]->{id};
	  $numb++;

	  unless (defined $streets[$_[0]->{tag}->{"street:id"}]) {
		return;
	  }

	  delete $_[0]->{tag}->{"street:id"};

	  $_[0]->{action} = 'modify';

	  print Geo::Parse::OSM::object_to_xml($_[0]);
	} elsif (exists $_[0]->{tag}->{"type"}) {
	  return if $_[0]->{tag}->{"type"} ne "street" and lc $_[0]->{tag}->{"type"} ne lc "associatedStreet";

	  if (lc $_[0]->{tag}->{"type"} eq lc "associatedStreet") {
		$_[0]->{tag}->{"type"} = "street";

		$_[0]->{action} = 'modify';
	  }

	  if (exists $_[0]->{tag}->{"street:id"}) {
		my $sId = $_[0]->{tag}->{"street:id"};

		if (defined $buildings[$sId]) {
		  $_[0]->{'action'} = 'modify';

		  if ($streets[$sId]->{"replace"} eq "t") {
			$_[0]->{tag}->{'name'} = $streets[$sId]->{"name"};
		  }

		  for my $bld (@{ $buildings[$sId] }) {
			unless (grep { $_->{ref} eq $bld} @{ $_[0]->{members} }) { # Do not put duplicates
			  push @{ $_[0]->{members} }, { 'ref' => $bld, 'type' => 'way', 'role' => 'house' };
			}
		  }

		  undef $buildings[$sId];
		}

		if (exists $_[0]->{action}) {
		  print Geo::Parse::OSM::object_to_xml($_[0]);
		}
	  }
	}
};

open IN, "str.csv";
binmode IN, ':utf8';

$nrel = 1;

while (<IN>) {
  chomp;

  @s = split /;/;

  $streets[$s[1]]->{"name"} = $s[0];
  $streets[$s[1]]->{"replace"} = $s[2];
}

close IN;

print "<osm  version='0.6'>\n";

Geo::Parse::OSM->parse_file($dumpname, $processor);

#print "Buildings: $numb\n";

open IN, "str.csv";
binmode IN, ':utf8';

$nrel = 1;

for $b (0..$#buildings) {
  next unless defined $buildings[$b];
  next unless defined $streets[$b];

  %relation = ();

  $relation{tag}->{name} = $streets[$b]->{name};
  $relation{tag}->{type} = 'street';
  $relation{tag}->{'street:id'} = $b;
  $relation{type} = 'relation';
  $relation{'action'} = 'create';
  $relation{id} = -$nrel;

  $nrel++;

  for $st (@{ $buildings[$b] }) {
	push @{ $relation{members} }, { 'ref' => $st, 'type' => 'way', 'role' => 'house' };
  }

  print Geo::Parse::OSM::object_to_xml(\%relation);
}

close IN;

print "</osm>\n";
