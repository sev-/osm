#!/usr/bin/perl -w
#
# Bot for automatic processing of Ukraine territory
#
# Ukraine extracts are available at
#  http://download.geofabrik.de/osm/europe/
#
# Copyright (c) 2010, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#

use utf8;
use Geo::Parse::OSM;

BEGIN { $| = 1; }

sub processHighway($);
sub checkIfRussian($);
sub checkRussianSyntax($);
sub fixRussian($);
sub fixUkrainian($);
sub checkUkrainianSyntax($);
sub transliterate($);


binmode STDOUT, ':utf8';

my @cities = ();

my $ukrname = shift or die "Usage: $0: ukraine.osm";

my $processor = sub {
	if (exists $_[0]->{tag}->{highway}) {
		$hw = $_[0]->{tag}->{highway};

		if ($hw eq 'primary' || $hw eq 'secondary' || $hw eq 'tertiary' || $hw eq 'residential') {
			my $res = processHighway($_[0]);

			if ($res != 0) {
				print Geo::Parse::OSM->to_xml($res);
			}
		}
	}
};

print "<osm  version='0.6'>\n";
Geo::Parse::OSM->parse_file($ukrname, $processor);
print "</osm>\n";

exit;

use utf8;

sub processHighway($) {
	my $entry = shift;
	my $modified = 0;

	# First check that there are no illegal characters
	# in English translation
	if (exists $entry->{tag}->{"name:en"}) {
		my $name = $entry->{tag}->{"name:en"};

		if ($name =~ /[АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюяіІїЇґҐєЄ]/) {
			print STDERR "WARN: Cyrillic characters in name:en ($name)\n";
		}
	}

	# Check that we do not have Latin characters
	if (exists $entry->{tag}->{"name"}) {
		my $name = $entry->{tag}->{"name"};

		if ($name =~ /[A-Z][a-z]/) {
			print STDERR "WARN: Latin characters in name ($name)\n";
		}
	}

	# Now check that name tag does not contain Russian
	if (exists $entry->{tag}->{"name"}) {
		my $name = $entry->{tag}->{"name"};

		my $rus = checkIfRussian $name;
		if ($rus) {
			# First, fix typical errors
			$new = fixRussian $name;
			if ($new ne $name) {
				print STDERR "LOG: Fixed Russian $name -> $new\n";

				$name = $new;
				$entry->{tag}->{"name"} = $new;

				$modified = 1;
			}

			if (checkRussianSyntax $name) {
				print STDERR "WARN: Illegal syntax in Russian ($name)\n";
			}

			# Perhaps there is name in Ukrainian, then we may
			# swap it
			if (exists $entry->{tag}->{"name:uk"}) {
				# Do not overwrite existing tag
				if (not exists $entry->{tag}->{"name:ru"}) {
					$entry->{tag}->{"name:ru"} = $name;
				}
				$entry->{tag}->{"name"} = $entry->{tag}->{"name:uk"};

				print STDERR "LOG: Overwrote name with Ukrainian ($name --> $entry->{tag}->{'name:uk'})\n";

				$modified = 1;
			} else {
				print STDERR "WARN: Russian in name ($name)\n";
			}
		} else {
			# OK, it seems it is Ukrainian

			# Fix typical errors
			$new = fixUkrainian $name;
			if ($new ne $name) {
				print STDERR "LOG: Fixed Ukrainian $name -> $new\n";

				$name = $new;
				$entry->{tag}->{"name"} = $new;

				$modified = 1;
			}

			if (checkUkrainianSyntax $name) {
				print STDERR "WARN: Illegal syntax in Ukrainian ($name)\n";
			}
		}
	}

	if ($modified) {
		return $entry;
	} else {
		return 0;
	}
}

sub checkIfRussian($) {
	$_ = shift;

	return 1 if /[ыЫэЭъЪёЁ]/;

	return 0 if /[іІєЄґҐїЇ]/;

	return 1 if /^ул/;
	return 1 if / ул\./;

	return 1 if /кая\s+/;
	return 1 if /ная\s+/;
	return 1 if /яя\s+/;
	return 1 if /cкий\s+/;
	return 1 if /кое\s+/;

	return 1 if /кая$/;
	return 1 if /ная$/;
	return 1 if /яя$/;
	return 1 if /cкий$/;
	return 1 if /кое$/;

	return 1 if /(улица|спуск|набережная|шоссе|переулок|площадь|пер\.|линия)/i;

	return 0;
}

sub fixRussian($) {
	$_ = shift;

	if (/^(?:ул\.|улица|у\.)\s+(.*)/i) {
		return "$1 улица";
	}

	if (/(.*)\s+(?:ул\.|у\.)$/i) {
		return "$1 улица";
	}

	s/пр-т/проспект/i;
	s/туп\./тупик/i;
	s/наб\./набережная/i;
	s/пер\./переулок/i;
	s/пр\./проспект/i;
	s/просп\./проспект/i;
	s/пл\./площадь/i;
	s/дор\./дорога/i;
	s/б-р/бульвар/i;
	s/подъем/подъём/i;

	if (/^(проспект|проезд|переулок|спуск|въезд|тупик|дорога|площадь|бульвар|шоссе|подъём|линия)\s+(.*)/) {
		$_ = "$2 $1";
	}

	# Some streets are named "Набережная Ленина улица"
	if (/^набережная\s+/i) {
		unless (/^набережная\s+улица$/i) {
			m/^набережная\s+(.*)/i;
			$_ = "$1 набережная";
		}
	}

	# lc the toponym
	s/(проспект|проезд|переулок|набережная|спуск|въезд|тупик|дорога|площадь|бульвар|шоссе|подъём|линия)$/lc $1/ie;

	return $_;
}

sub fixUkrainian($) {
	$_ = shift;

	if (/^(?:вул\.|вулица|вулиця|в\.|вул)\s+(.*)/i) {
		return "$1 вулиця";
	}

	if (/(.*)\s+(?:вул\.|в\.|в|вул)$/i) {
		return "$1 вулиця";
	}

	# Replace apostrophe
	s/'/’/g;

	# Common toponym abbreviation
	s/пр-т/проспект/i;
	s/наб\./набережна/i;
	s/пров\./провулок/i;
	s/провул\./провулок/i;
	s/пр\./проспект/i;
	s/просп\./проспект/i;
	s/пл\./площа/i;
	s/дор\./дорога/i;
	s/б-р/бульвар/i;
	s/бул\./бульвар/i;
	s/туп\./тупик/i;

	# misspellings
	s/перевулок/провулок/i;
	s/тупік/тупик/i;
	s/([1-9])й/$1-й/;
	s/([1-9])а/$1-а/;

	if (/^(проспект|проїзд|провулок|узвіз|в’їзд|тупик|дорога|площа|бульвар|шосе|підйом|лінія)\s+(.*)/i) {
		$_ = "$2 $1";
	}

	if (/^набережна\s+/i) {
		unless (/^набережна\s+вулиця$/i) {
			m/^набережна\s+(.*)/i;
			$_ = "$1 набережна";
		}
	}

	if (/^([0-9]-й)\s+провулок\s+(.*)/i) {
		$_ = "$1 $2 провулок";
	}

	# lc the toponym
	s/(проспект|проїзд|провулок|набережна|узвіз|в’їзд|тупик|дорога|площа|бульвар|шосе|підйом|лінія)$/lc $1/ie;

	return $_;
}

sub checkRussianSyntax($) {
	$_ = shift;

	unless (/(проспект|проезд|переулок|спуск|въезд|набережная|тупик|дорога|улица|площадь|бульвар|шоссе|аллея|подъём|подъем|линия)$/) {
		return 1;
	}

	return 0;
}

sub checkUkrainianSyntax($) {
	$_ = shift;

	unless (/(проспект|проїзд|провулок|узвіз|в’їзд|набережна|тупик|дорога|вулиця|площа|бульвар|шосе|лея|підйом|лінія)$/) {
		return 1;
	}

	return 0;
}

sub transliterate($) {
	$_ = shift;

	s/ої/oi/g;
	s/иї/yi/g;
	s/ьо/yo/g;
	s/зг/zgh/g;
	s/х/kh/g;
	s/ц/ts/g;
	s/ь//g;
	s/'//g;
	s/ є/ ye/g;
	s/є/ie/g;
	s/ ї/ yi/g;
	s/ й/ y/g;
	s/ж/zh/g;
	s/ц/ts/g;
	s/ч/ch/g;
	s/ш/sh/g;
	s/щ/sch/g;
	s/ ю/ yu/g;
	s/ю/iu/g;
	s/ я/ ya/g;
	s/я/ia/g;
	tr/абвгґдезийiїклмнопрстуф/abvhgdezyiiiklmnoprstuf/;

	s/зг/Zgh/g;
	s/Х/Kh/g;
	s/Ц/Ts/g;
	s/Є/Ye/g;
	s/Ї/Yi/g;
	s/Ж/Zh/g;
	s/Ц/Ts/g;
	s/Ч/Ch/g;
	s/Ш/Sh/g;
	s/Щ/Sch/g;
	s/Ю/Yu/g;
	s/Я/Ya/g;
	tr/АБВГҐДЕЗИІЙКЛМНОПРСТУФ/ABVHGDEZYIYKLMNOPRSTUF/;
	s/yy/y/g;

	s/ ([a-z])/" ".uc($1)/ge;

	s/K=/k=/;
	s/V=/v=/;

	return $_;
}
