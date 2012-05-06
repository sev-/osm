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
use Data::Dumper;

BEGIN { $| = 1; }

sub processPOI($);

#binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $osmname = shift or die "Usage: $0: nadoloni.osm poi.csv";
my $csvname = shift or die "Usage: $0: nadoloni.osm poi.csv";

my $processor = sub {
	return unless exists $_[0]->{tag}->{"nadoloni:id"};
	return unless $_[0]->{tag}->{"nadoloni:id"} =~ /^poi:/;

	$_[0]->{action} = 'modify';

	my $res = processPOI($_[0]);

	print Geo::Parse::OSM::object_to_xml($res) if $res;
};

my $csv = Text::CSV->new( { binary => 1, sep_char => ';', escape_char => '%', allow_loose_quotes => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf8)", $csvname or die "$csvname: $!";

$csv->column_names($csv->getline($fh));

my @poi = ();

my $n = 0;
while (my $line = $csv->getline_hr($fh)) {
  if ('' ne $line->{phone_code1} or '' ne $line->{phone_number1} or
	  '' ne $line->{phone_code2} or '' ne $line->{phone_number2} or
	  '' ne $line->{phone_code3} or '' ne $line->{phone_number3} or
	  '' ne $line->{phone_code4} or '' ne $line->{phone_number4} or
	  '' ne $line->{url} or
	  '' ne $line->{email}) {
	$poi[$line->{id}] = $line;
	$n++;
  }
}

print STDERR "$n POIs\n"; 

$csv->eof or $csv->error_diag();
close $fh;

print "<osm  version='0.6'>\n";
Geo::Parse::OSM->parse_file($osmname, $processor);
print "</osm>\n";

exit;

sub processPOI($) {
	my $entry = shift;

	$entry->{tag}->{"nadoloni:id"} =~ /poi:(.*)/;

	my $poinum = $1;

	return 0 if (not defined $poi[$poinum]);

	my $line = $poi[$poinum];

	if ('' ne $line->{phone_code1} or '' ne $line->{phone_number1}) {
	  $entry->{'tag'}->{'phone'} = "($line->{phone_code1})$line->{phone_number1}";
	}
	if ('' ne $line->{phone_code2} or '' ne $line->{phone_number2}) {
	  $entry->{'tag'}->{'phone2'} = "($line->{phone_code2})$line->{phone_number2}";
	}
	if ('' ne $line->{phone_code3} or '' ne $line->{phone_number3}) {
	  $entry->{'tag'}->{'phone3'} = "($line->{phone_code3})$line->{phone_number3}";
	}
	if ('' ne $line->{phone_code4} or '' ne $line->{phone_number4}) {
	  $entry->{'tag'}->{'phone4'} = "($line->{phone_code4})$line->{phone_number4}";
	}
	if ('' ne $line->{url}) {
	  if ($line->{url} !~ /^http:/) {
		$line->{url} = "http://$line->{url}/";
	  }
	  $entry->{'tag'}->{'website'} = "$line->{url}";
	}
	if ('' ne $line->{email}) {
	  $entry->{'tag'}->{'contact:email'} = "$line->{email}";
	}

	return $entry;
}
