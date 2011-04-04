#!/usr/bin/perl -w
#
# Clean revert changeset
# Actually only removes created entities
#
# Ukraine extracts are available at
#  http://download.geofabrik.de/osm/europe/
#  http://downloads.cloudmade.com/europe/ukraine/
#
# Copyright (c) 2011, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#
# Usage:
#  perl -CD revert.pl ukraine.osm changeset.xml >revert.osm

use utf8;
use Geo::Parse::OSM;

BEGIN { $| = 1; }

binmode STDERR, ':utf8';

my @cities = ();

my $num = 0;

my $ukrname = shift or die "Usage: $0: ukraine.osm changeset.xml";
my $changeset = shift or die "Usage: $0: ukraine.osm changeset.xml";

my $processor = sub {
	if (exists $_[0]->{tag}->{highway}) {
		$hw = $_[0]->{tag}->{highway};

		if ($hw eq 'primary' || $hw eq 'secondary' || $hw eq 'tertiary' || $hw eq 'residential') {
			my $res = processHighway($_[0]);

			if ($res != 0) {
				$res->{action} = 'modify';

				print Geo::Parse::OSM->to_xml($res);

				$num++;
			}
		}
	}
};

Geo::Parse

print "<osm  version='0.6'>\n";
Geo::Parse::OSM->parse_file($ukrname, $processor);
print "</osm>\n";

print STDERR "LOG: Modified $num ways\n";

exit;

