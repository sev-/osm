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

my $num = 0;

my $noMatches = 0;

my $processor = sub {
	$place = $_[0]->{tag}->{place};

	if ($place eq 'city' || $place eq 'town' || $place eq 'village' || $place eq 'hamlet') {
		$_[0]->{action} = 'modify';

		my $res = processCity($_[0]);

		#print Geo::Parse::OSM->to_xml($res);
		$num++;
	}
};

my $csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf8)", $citiesname or die "$citiesname: $!";

$csv->column_names($csv->getline($fh));

while (my $line = $csv->getline_hr($fh)) {
	($line->{lat}, $line->{lon}) = processCoords($line->{coords});

	if ($line->{lat} == 0 || $line->{lon} == 0) {
		print "$line->{num} $line->{name_ua} $line->{lat}, $line->{lon}\n";
	}
	$line->{orignum} = $#cities;
	$line->{name_ua} =~ s/^\s+|\s+$//g;
	$line->{name_ru} =~ s/^\s+|\s+$//g;

	push @cities, $line;
}

$csv->eof or $csv->error_diag();
close $fh;

print "Loaded $#cities cities\n";

print "<osm  version='0.6'>\n";
Geo::Parse::OSM->parse_file($ukrname, $processor);
print "</osm>\n";

print "No matches: $noMatches\n";

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

	for $c (@cities) {
		my $d = ($c->{lat} - $lat) * ($c->{lat} - $lat) + ($c->{lon} - $lon) * ($c->{lon} - $lon);
		
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
		# Sounds good
	} else {
		# Okay, we're in trouble. No match.

		calcDistances($entry->{lat}, $entry->{lon});

		@citS = sort {$a->{dist} <=> $b->{dist}} @cities; # This is slow

		# Perhaps it is one of first three?
		my $match = 0;
		my $i = 0;

		while ($citS[$i]->{dist} < 0.003 || $i == 0) {
			if ($citS[$i]->{name_ua} eq $entry->{tag}->{name} || 
				$citS[$i]->{name_ru} eq $entry->{tag}->{name} ||
				(exists $entry->{tag}->{"name:ua"} && $citS[$i]->{name_ua} eq $entry->{tag}->{"name:ua"}) ||
				(exists $entry->{tag}->{"name:ru"} && $citS[$i]->{name_ru} eq $entry->{tag}->{"name:ru"}) ||
				(exists $entry->{tag}->{koatuu} && $citS[$i]->{koatuu} eq $entry->{tag}->{koatuu})) {
				$match = 1;

				$min = $citS[$i]->{orignum};
			}
			$i++;
		}

		if (!$match) {
			# Absoultely no match. Show first three entries then
			print "$entry->{tag}->{name} $entry->{lat}, $entry->{lon}\n";
	
			my $i = 0;
			while ($citS[$i]->{dist} < 0.003 || $i == 0) {
				print "  $citS[$i]->{num} $citS[$i]->{name_ua} $citS[$i]->{lat}, $citS[$i]->{lon} [$citS[$i]->{dist}]\n";

				$i++;
			}

			$noMatches++;
		}
	}
}

sub calcDistances($$) {
	my $lat = shift;
	my $lon = shift;

	for $c (@cities) {
		$c->{dist} = ($c->{lat} - $lat) * ($c->{lat} - $lat) + ($c->{lon} - $lon) * ($c->{lon} - $lon);
	}
}
