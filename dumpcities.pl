#!/usr/bin/perl -w
#
# Dump all cities from OSM extract
#
# Copyright (c) 2010, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#

use utf8;
use Geo::Parse::OSM;

BEGIN { $| = 1; }

my $ukrname = (shift or "ukraine.osm.bz2");

my $addname = sub {
	if (exists $_[0]->{tag}->{place}) {

		my $place = $_[0]->{tag}->{place};
		
		if ($_[0]->{type} eq 'node') {
			if ($place eq 'city' || $place eq 'town' || $place eq 'village' || $place eq 'hamlet') {
				print Geo::Parse::OSM::object_to_xml($_[0]);
			}
		}
	}
};

print "<osm  version='0.6'>\n";
my $osm = Geo::Parse::OSM->new($ukrname);

$osm->parse($addname,  only => 'node');

print "</osm>\n";
