#!/usr/bin/perl -w
#
# Update OSM data with extract from Wikipedia
#
# Copyright (c) 2010-12, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#

use utf8;
use Geo::Parse::OSM;
use Text::CSV;

BEGIN { $| = 1; }

sub latBucket($);
sub lonBucket($);
sub processCity($);
sub processCoords($);
sub updateCity($$);
sub transliterate($);

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf8)", "lviv-stops-translations.txt" or die "trans: $!";

$csv->column_names($csv->getline($fh));

my %stopsru;
my %stopsuk;

while (my $line = $csv->getline_hr($fh)) {
	next if ($line->{lang} eq 'en');

	$line->{translation} =~ s/^\s+|\s+$//g;
	$line->{translation} =~ s/'/’/g;

	if ($line->{lang} eq 'ru') {
	  $stopsru{$line->{trans_id}} = $line->{translation};
	} elsif ($line->{lang} eq 'uk') {
	  $stopsuk{$line->{trans_id}} = $line->{translation};
	} else {
	  die "Bad format";
	}
}

$csv->eof or $csv->error_diag();
close $fh;

open $fh, "<:encoding(utf8)", "lviv-stops.txt" or die "trans: $!";

$csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();

$csv->column_names($csv->getline($fh));

print "<?xml version='1.0' encoding='UTF-8'?>
<osm version='0.6' upload='true' generator='JOSM'>
";

while (my $line = $csv->getline_hr($fh)) {
  if (not exists $stopsru{$line->{stop_name}}) {
	warn "No RU stop name for $line->{stop_name}";
  }

  if (not exists $stopsuk{$line->{stop_name}}) {
	warn "No UK stop name for $line->{stop_name}";
  }

  $st = $line->{stop_name};
  $st =~ s/'/&apos;/g;

print "  <node id='-$line->{stop_id}' action='create' visible='true' lat='$line->{stop_lat}' lon='$line->{stop_lon}'>
    <tag k='bus' v='yes' />
    <tag k='highway' v='bus_stop' />
    <tag k='name' v='$stopsuk{$line->{stop_name}}' />
    <tag k='name:en' v='$st' />
    <tag k='name:uk' v='$stopsuk{$line->{stop_name}}' />
    <tag k='name:ru' v='$stopsru{$line->{stop_name}}' />
    <tag k='public_transport' v='stop_position' />
  </node>
";
}

print "</osm>\n";

$csv->eof or $csv->error_diag();
close $fh;

