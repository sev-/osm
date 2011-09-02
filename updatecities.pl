#!/usr/bin/perl -w
#
# Update OSM data with extract from Wikipedia
#
# Copyright (c) 2010, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#

use utf8;
use Geo::Parse::OSM;
use Geo::Coordinates::DecimalDegrees;
use Text::CSV;

BEGIN { $| = 1; }

sub processCity($);
sub processCoords($);
sub calcDistances($$);

binmode STDOUT, ':utf8';

my @cities = ();

my $ukrname = shift or die "Usage: $0: ukraine.osm cities.csv";
my $citiesname = shift or die "Usage: $0: ukraine.osm cities.csv";

my $total = 30715; # Hardcoded number of cities
my $num = 0;

my $noMatches = 0;
my $noMatchesSafe = 0;
my $emptyname = 0;
my $emptynameSafe = 0;
my $renames = 0;

my $processor = sub {
	return unless exists $_[0]->{tag}->{place};

	$place = $_[0]->{tag}->{place};

	if ($_[0]->{type} eq 'node') {
		if ($place eq 'city' || $place eq 'town' || $place eq 'village' || $place eq 'hamlet') {
			$_[0]->{action} = 'modify';

			my $res = processCity($_[0]);

			#print Geo::Parse::OSM->to_xml($res);
			$num++;
		}
	}
};

my $csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf8)", $citiesname or die "$citiesname: $!";

$csv->column_names($csv->getline($fh));

my @cit = ();

while (my $line = $csv->getline_hr($fh)) {
	($line->{lat}, $line->{lon}) = processCoords($line->{coords});

	if ($line->{lat} == 0 || $line->{lon} == 0) {
		print "$line->{num} $line->{name_ua} {$line->{title}} $line->{lat}, $line->{lon}\n";
	}
	$line->{name_ua} =~ s/^\s+|\s+$//g;
	$line->{name_ua} =~ s/́//g;
	$line->{name_ru} =~ s/^\s+|\s+$//g;

	push @cit, $line;
}

$csv->eof or $csv->error_diag();
close $fh;

@cities = sort {$a->{lat} <=> $b->{lat}} @cit;

print "Loaded $#cities cities\n";

print "<osm  version='0.6'>\n";
Geo::Parse::OSM->parse_file($ukrname, $processor);
print "</osm>\n";

print "No matches: $noMatches out of $num ($noMatchesSafe are safe)\n";
print "Renames: $renames\n";
print "Empty: $emptyname ($emptynameSafe are safe)\n";
print "Cities left: " . scalar @cities . "\n";

exit;

sub processCoords($) {
	my $str = shift;

	my @arr = split /\|/, $str;

	return (0, 0) if $#arr < 7;

	my $lat;
	my $lon;
	my $n = 1;
	my $deg;
	my $sec;
	my $min;

	if ($arr[$n+3] eq "N") {
		$deg = $arr[$n] || 0;
		$min = $arr[$n+1] || 0;
		$sec = $arr[$n+2] || 0;
		$lat = dms2decimal($deg, $min, $sec);
		$n = 5;
	} elsif ($arr[$n+2] eq "N") {
		$deg = $arr[$n] || 0;
		$min = $arr[$n+1] || 0;
		$sec = 0;
		$lat = dms2decimal($deg, $min, $sec);
		$n = 4;
	} else {
		print STDERR "Bad coordinates $str\n";
	}

	if ($arr[$n+3] eq "E") {
		$deg = $arr[$n] || 0;
		$min = $arr[$n+1] || 0;
		$sec = $arr[$n+2] || 0;
		$lon = dms2decimal($deg, $min, $sec);
	} elsif ($arr[$n+2] eq "E") {
		$deg = $arr[$n] || 0;
		$min = $arr[$n+1] || 0;
		$sec = 0;
		$lon = dms2decimal($deg, $min, $sec);
	} else {
		print STDERR "Bad coordinates $str\n";
	}

	return ($lat, $lon);
}

sub processCity($) {
	my $entry = shift;

	# First we search for entry with minimal distance
	my $min = 0;
	my $mind = 1e9;
	my $n = 0;
	my $lat = $entry->{lat};
	my $lon = $entry->{lon};
	my $cnd;

	print STDERR "$num " . (sprintf "%02.2f%%", ($num * 100) / $total) ."\r" if ($num % 10 == 0);

	if (not exists $entry->{lat} or not exists $entry->{lon}) {
		print "Wrong entry id: $entry->{id}\n";
		return;
	}

	if ($entry->{user} eq 'osm-ukraine') {
		$cnd = "*Remove*";
	} else {
		$cnd = "";
	}

	if (not exists $entry->{tag}->{name}) {
		$emptyname++;
		$emptynameSafe++ if $cnd ne "";

		print "Weird nameless entry id: $entry->{id} $cnd\n";
		return;
	}

	my $nn = 0;
	for $c (@cities) {
		$c->{orignum} = $nn;
		$nn++;

		if (not exists $c->{lat} or not exists $c->{lon}) {
			$c->{dist} = 1e6;
			next;
		}

		my $d1 = abs($c->{lat} - $lat);
		my $d2 = abs($c->{lon} - $lon);

		my $d = $d1 * $d1 + $d2 * $d2;

		$c->{dist} = $d;
		
		if ($d < $mind) {
			$mind = $d;
			$min = $n;
		}

		$n++;
	}

	if ($cities[$min]->{name_ua} eq $entry->{tag}->{name} || 
		$cities[$min]->{name_ru} eq $entry->{tag}->{name} ||
		(exists $entry->{tag}->{"name:ua"} && $cities[$min]->{name_ua} eq $entry->{tag}->{"name:ua"}) ||
		(exists $entry->{tag}->{"name:ru"} && $cities[$min]->{name_ru} eq $entry->{tag}->{"name:ru"}) ||
		(exists $entry->{tag}->{koatuu} && $cities[$min]->{koatuu} eq $entry->{tag}->{koatuu})) {

		# Sounds good. Remove it
		splice @cities, $min, 1;
	} else {
		# Okay, we're in trouble. No match.

		my @citM = grep { $_->{dist} < 0.003 } @cities;

		if (!scalar @citM) {
			print "$entry->{tag}->{name} $entry->{lat}, $entry->{lon} $cnd $entry->{id}\n";
			print "  No match in Wiki\n";

			$noMatches++;
			$noMatchesSafe++ if $cnd ne "";
			
			return;
		}


		my @citS = sort {$a->{dist} <=> $b->{dist}} @citM; # This is slow

		# Try to find name match
		my $match = 0;

		for my $c (@citS) {
			if ($c->{name_ua} eq $entry->{tag}->{name} || 
				$c->{name_ru} eq $entry->{tag}->{name} ||
				(exists $entry->{tag}->{"name:ua"} && $c->{name_ua} eq $entry->{tag}->{"name:ua"}) ||
				(exists $entry->{tag}->{"name:ru"} && $c->{name_ru} eq $entry->{tag}->{"name:ru"}) ||
				(exists $entry->{tag}->{koatuu} && $c->{koatuu} eq $entry->{tag}->{koatuu})) {
				$match = 1;

				$min = $c->{orignum};
				splice @cities, $min, 1;

				return;
			}
		}

		if (!$match) {
			# Absoultely no match. Show all nearby entries then
			print "$entry->{tag}->{name} $entry->{lat}, $entry->{lon} $cnd\n";

			if ($citS[0]->{dist} < 0.0002) {
				print "  Rename --> $citS[0]->{name_ua}\n";
				$renames++;

				splice @cities, $citS[0]->{orignum}, 1;

				return;
			}
	
			for my $c (@citS) {
				print "  $c->{num} $c->{name_ua} $c->{lat}, $c->{lon} [$c->{dist}]\n";
			}

			$noMatches++;

			$noMatchesSafe++ if $cnd ne "";
		}
	}
}

sub calcDistances($$) {
	my $lat = shift || 0;
	my $lon = shift || 0;

	for $c (@cities) {
		$c->{dist} = ($c->{lat} - $lat) * ($c->{lat} - $lat) + ($c->{lon} - $lon) * ($c->{lon} - $lon);
	}
}
