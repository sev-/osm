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

sub purgeWay($);
sub purgeNode($);
sub processRelation($);
sub processWay($);

my $ukrname = shift or die "Usage: $0: ukraine.osm changeset.xml";
my $changeset = shift or die "Usage: $0: ukraine.osm changeset.xml";

use Data::Dumper;

my %nodes = ();
my %ways = ();

my $processor = sub {
	if ($_[0]->{type} eq 'node') {
		if ($_[0]->{version} != 1 and exists $nodes{$_[0]->{id}}) {
			purgeNode($_[0]->{id});
		}
	} elsif ($_[0]->{type} eq 'way') {
		if (exists $ways{$_[0]->{id}}) {
			if ($_[0]->{version} != 1) {
				purgeWay($_[0]);
			}
		} else {
			processWay($_[0]);
		}
	} elsif ($_[0]->{type} eq 'relation') {
		processRelation($_[0]);
	}
};

my $changesetprocessor = sub {
	if ($_[0]->{type} eq 'node') {
		return unless $_[0]->{version} == 1;

		my %t = %{ $_[0] };

		$nodes{$_[0]->{id}} = \%t;
	} elsif ($_[0]->{type} eq 'way') {
		if ($_[0]->{version} != 1) {
			purgeWay($_[0]);
		} else {
			my %t = %{ $_[0] };
			$ways{$_[0]->{id}} = \%t;
		}
	} else {
		die "Unsupported type ($_[0]->{type})\n";
	}
};

Geo::Parse::OSM->parse_file($changeset, $changesetprocessor);

Geo::Parse::OSM->parse_file($ukrname, $processor);

print "<osm  version='0.6'>\n";

for my $n (sort keys %nodes) {
	$nodes{$n}->{action} = 'delete';
	print Geo::Parse::OSM::object_to_xml($nodes{$n});
}

for my $w (sort keys %ways) {
	$ways{$w}->{action} = 'delete';
	delete $ways{$w}->{tag};
	print Geo::Parse::OSM::object_to_xml($ways{$w});
}

print "</osm>\n";

exit;

sub purgeWay($) {
	my $w = shift;

	# Delete all nodes from the way
	for my $nd (@{$w->{chain}}) {
		if (exists $nodes{$nd}) {
			delete $nodes{$nd};
		}
	}

	delete $ways{$w->{id}};
}

sub purgeNode($) {
	my $id = shift;

	# Check if some way refers to this node, then we cannot
	# remove this way and all its nodes
	for my $w (sort keys %ways) {
		if (grep { $_ == $id } @{$ways{$w}->{chain}}) {
			purgeWay($ways{$w});
		}
	}

	delete $nodes{$id};
}

sub processRelation($) {
	my $r = shift;

	for my $m (@{$r->{members}}) {
		if ($m->{type} eq 'node') {
			if (exists $nodes{$m->{ref}}) {
				purgeNode($m->{ref});
			}
		} elsif ($m->{type} eq 'way') {
			if (exists $ways{$m->{ref}}) {
				purgeWay($ways{$m->{ref}});
			}
		}
	}
}

sub processWay($) {
	my $w = shift;

	# Delete all nodes from the way
	for my $nd (@{$w->{chain}}) {
		if (exists $nodes{$nd}) {
			delete $nodes{$nd};
		}
	}
}
