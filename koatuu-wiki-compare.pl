#!/usr/bin/perl -w
#
# Compare KOATUU DB with Wikipedia extract
#
# Copyright (c) 2010, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#
# Usage: perl -CD koatuu-wiki-compare.pl KOATUU.csv cities.csv
#        where first parameter is CSV conversion of KOATUU.xls
#        file taken from http://www.ukrstat.gov.ua/work/klass200n.htm
#        second parameter is file produced by wikiextract.pl
#

use utf8;
use Text::CSV;

BEGIN { $| = 1; }

binmode STDOUT, ':utf8';

my $koatuuname = shift or die "Usage: $0: koatuu.csv cities.csv";
my $citiesname = shift or die "Usage: $0: koatuu.csv cities.csv";

my $csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", $koatuuname or die "$koatuuname: $!";

$csv->column_names($csv->getline($fh));

my %koatuus = ();

while (my $line = $csv->getline_hr($fh)) {
	$line->{refs} = 0;
	$koatuus{sprintf ("%010.0f", $line->{TE})} = $line;
}

$csv->eof or $csv->error_diag();
close $fh;

undef $csv;

print "Loaded ". (scalar keys %koatuus) . " KOATUUs\n";

my @cities = ();

$csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open $fh, "<:encoding(utf8)", $citiesname or die "$citiesname: $!";

$csv->column_names($csv->getline($fh));

while (my $line = $csv->getline_hr($fh)) {
	$line->{orignum} = $#cities;
	$line->{name_ua} =~ s/^\s+|\s+$//g;
	$line->{name_ru} =~ s/^\s+|\s+$//g;
	$line->{koatuu} =~ s/^\s+|\s+$//g;
	$line->{name_ua} =~ s/́//g;
	if ($line->{koatuu} =~ /^\d+$/) {
	    $line->{koatuu} = sprintf("%010.0f", $line->{koatuu});
	}

	push @cities, $line;
}

$csv->eof or $csv->error_diag();
close $fh;

print "Loaded $#cities cities\n";

$unk = 0;
$mismatch = 0;
$missing = 0;
$nokoatuu = 0;
$dup = 0;
$matches = 0;

for $c (@cities) {
	if ($c->{koatuu} eq "") {
	    #print "No KOATUU: $c->{name_ua}\n";
	    $nokoatuu++;
	    next;
	}

	if (not exists $koatuus{$c->{koatuu}}) {
		$obl = substr($c->{koatuu}, 0, 5)."00000";
		print "Unknown KOATUU: <$c->{name_ua}> {$c->{title}} $c->{koatuu} $obl\n";
		$unk++;
		next;
	}

	my $nm = lc $koatuus{$c->{koatuu}}->{NU};
	unless (exists $c->{name_ua} && $nm eq lc($c->{name_ua}) ||
			exists $c->{name_ru} && $nm eq lc($c->{name_ru})) {
		print "Name mismatch: <$nm> <$c->{name_ua}> {$c->{title}} $c->{koatuu}\n";
		$mismatch++;
	} else {
		$koatuus{$c->{koatuu}}->{refs}++;
		$matches++;
	}
}

print "\n";

for $k (sort keys %koatuus) {
	if ($koatuus{$k}->{refs} > 1) {
		$raion = substr($k, 0, 8)."00";
		$obl = substr($k, 0, 5)."00000";
		print "Duplicated KOATUU: $k ($koatuus{$k}->{refs}) <$koatuus{$k}->{NU}> $obl <$koatuus{$raion}->{NU}> <$koatuus{$obl}->{NU}>\n";

		map { print "  $_->{title}, $_->{oblast}, $_->{raion}, $_->{rada}\n" if ($_->{koatuu} eq $k); } @cities;
		$dup++;
	}
}

print "\n";

for $k (sort keys %koatuus) {
	if ($koatuus{$k}->{refs} == 0 && ($koatuus{$k}->{NP} eq "С" || 
					  $koatuus{$k}->{NP} eq "Щ" ||
					  $koatuus{$k}->{NP} eq "М" ||
					  $koatuus{$k}->{NP} eq "Т")) {
		print "Missing KOATUU: $k <$koatuus{$k}->{NU}>\n";
		$missing++;
	}
}

print "Matches: $matches, Unknown: $unk, Mismatch: $mismatch, Missing: $missing, No KOATUU: $nokoatuu, Dup: $dup\n";
