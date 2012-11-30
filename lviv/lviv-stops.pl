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

#binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf8)", "lviv-stops-translations.txt" or die "trans: $!";

$csv->column_names($csv->getline($fh));

my %stopsru;
my %stopsuk;

while (my $line = $csv->getline_hr($fh)) {
	next if ($line->{lang} eq 'en');

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

while (my $line = $csv->getline_hr($fh)) {
  if (not exists $stopsru{$line->{stop_name}}) {
	die "No RU stop name for $line->{stop_name}";
  }

  if (not exists $stopsuk{$line->{stop_name}}) {
	die "No UK stop name for $line->{stop_name}";
  }
}

$csv->eof or $csv->error_diag();
close $fh;

