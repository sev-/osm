#!/usr/bin/perl
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

my $addname = sub {
	my $place = $_[0]->{tag}->{place};

	if ($_[0]->{type} eq 'node') {
		if ($place eq 'city' || $place eq 'town' || $place eq 'village' || $place eq 'hamlet') {
			$_[0]->{action} = 'modify';

			print Geo::Parse::OSM->to_xml($_[0]);
		}
	}
};

print "<osm  version='0.6'>\n";
Geo::Parse::OSM->parse_file('ukraine.osm.bz2', $addname);
print "</osm>\n";
