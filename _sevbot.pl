#!/usr/bin/perl -w
#
# Bot for automatic processing of Ukraine territory
#
# Ukraine extracts are available at
#  http://download.geofabrik.de/osm/europe/
#  http://downloads.cloudmade.com/europe/ukraine/
#
# Copyright (c) 2010, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#
# Usage:
#  perl -CD _sevbot.pl ukraine.osm.bz2 >_sevbot.osm 2>_sevbot.log
#
# Since the exports on goefabrik not always match it is advised to reapply bounding polygon
#  getbound.pl 60199 -o ukraine.poly
#  osmconvert -v ukraine.osm.pbf -B=ukraine.poly --complete-ways --complex-ways >ukraine.osm

use utf8;
use Geo::Parse::OSM;

BEGIN { $| = 1; }

sub processHighway($);
sub processBuilding($);
sub checkIfRussian($);
sub checkRussianSyntax($);
sub fixRussian($);
sub fixUkrainian($);
sub checkUkrainianSyntax($);
sub tryAutoAddUkrToponym($);
sub tryAutoAddRusToponym($);
sub translateToponym($);
sub transliterate($);

binmode STDERR, ':utf8';

my @cities = ();

my $num = 0;
my $numb = 0;

my $ukrname = shift or die "Usage: $0: ukraine.osm.bz2";

my $processor = sub {
	my $res = 0;

	if (exists $_[0]->{tag}->{highway}) {
		$hw = $_[0]->{tag}->{highway};

		if ($hw eq 'primary' || $hw eq 'secondary' || $hw eq 'tertiary' || $hw eq 'residential') {
			$res = processHighway($_[0]);

			$num++ if $res != 0;
		}
	} elsif (exists $_[0]->{tag}->{"addr:housenumber"}) {
		$res = processBuilding($_[0]);

		$numb++ if $res != 0;
	}

	if ($res != 0) {
		$res->{action} = 'modify';

		print Geo::Parse::OSM::object_to_xml($res);
	}
};

print "<osm  version='0.6'>\n";
Geo::Parse::OSM->parse_file($ukrname, $processor);
print "</osm>\n";

print STDERR "LOG: Modified $num ways\n";
print STDERR "LOG: Modified $numb buildings\n";

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
			print STDERR "WARN: Cyrillic characters in name:en ($name) $entry->{id}\n";

			$new = $name;
			$new =~ s/і/i/g;

			if ($new ne $name) {
				$entry->{tag}->{"name:en"} = $new;

				print STDERR "LOG: Replaced i in name:en ($name) $entry->{id}\n";

				$modified = 1;
			}
		}
	}

	# Check that we do not have Latin characters
	if (exists $entry->{tag}->{"name"}) {
		my $name = $entry->{tag}->{"name"};

		if ($name =~ /[A-Za-z]/) {
			$tmpname = $name;
			$tmpname =~ tr/AIOPCaiopc/АІОРСаіорс/;

			if ($tmpname !~ /[A-Za-z]/) {
				$entry->{tag}->{"name"} = $tmpname;
				$modified = 1;

				print STDERR "LOG: Replaced latin in name ($name) $entry->{id}\n";
			} else {
				print STDERR "WARN: Latin characters in name ($name) $entry->{id}\n";
			}
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
				print STDERR "LOG: Fixed Russian $name -> $new $entry->{id}\n";

				$name = $new;
				$entry->{tag}->{"name"} = $new;

				$modified = 1;
			}

			if (checkRussianSyntax $name) {
				$new = tryAutoAddRusToponym($name);

				if (0 && $new ne $name) {
					print STDERR "LOG: Autoadded Russian $name -> $new $entry->{id}\n";

					$name = $new;
					$entry->{tag}->{"name"} = $new;

					$modified = 1;
				} else {
					print STDERR "WARN: Illegal syntax in Russian ($name) $entry->{id}\n";
				}
			}

			# Perhaps there is name in Ukrainian, then we may
			# swap it
			if (0 && exists $entry->{tag}->{"name:uk"}) {
				# Do not overwrite existing tag
				if (not exists $entry->{tag}->{"name:ru"}) {
					$entry->{tag}->{"name:ru"} = $name;
				}
				$entry->{tag}->{"name"} = $entry->{tag}->{"name:uk"};

				print STDERR "LOG: Overwrote name with Ukrainian ($name --> $entry->{tag}->{'name:uk'}) $entry->{id}\n";

				$modified = 1;
			} else {
				print STDERR "WARN: Russian in name ($name) $entry->{id}\n";
			}
		} else {
			# OK, it seems it is Ukrainian

			# Fix typical errors
			$new = fixUkrainian $name;
			if ($new ne $name) {
				print STDERR "LOG: Fixed Ukrainian $name -> $new $entry->{id}\n";

				$name = $new;
				$entry->{tag}->{"name"} = $new;

				$modified = 1;
			}

			if (checkUkrainianSyntax $name) {
				$new = tryAutoAddUkrToponym($name);

				if (0 && $new ne $name) {
					print STDERR "LOG: Autoadded Ukrainian $name -> $new $entry->{id}\n";

					$name = $new;
					$entry->{tag}->{"name"} = $new;

					$modified = 1;
				} else {
					print STDERR "WARN: Illegal syntax in Ukrainian ($name) $entry->{id}\n";
				}
			} else {
				# Everything seems to be OK, so add English
				# transliteration if there were none

				if (not exists $entry->{tag}->{"name:en"}) {
					my $en = translateToponym $entry->{tag}->{"name"};

					$en = transliterate $en;
					$entry->{tag}->{"name:en"} = $en;

					print STDERR "LOG: Added transliteration ($name -> $en) $entry->{id}\n";

					$modified = 1;
				}
			}
		}
	}

	if (exists $entry->{tag}->{"name:ru"}) {
		my $name = $entry->{tag}->{"name:ru"};

		# Fix typical errors
		$new = fixRussian $name;
		if ($new ne $name) {
			print STDERR "LOG: Fixed Russian in name:ru $name -> $new $entry->{id}\n";

			$name = $new;
			$entry->{tag}->{"name:ru"} = $new;

			$modified = 1;
		}

		if (checkRussianSyntax $name) {
			$new = tryAutoAddRusToponym($name);

			if ($new ne $name) {
				print STDERR "LOG: Autoadded Russian in name:ru $name -> $new $entry->{id}\n";

				$name = $new;
				$entry->{tag}->{"name:ru"} = $new;

				$modified = 1;
			} else {
				print STDERR "WARN: Illegal syntax in Russian in name:ru ($name) $entry->{id}\n";
			}
		}
	}

	if (exists $entry->{tag}->{"name:uk"}) {
		my $name = $entry->{tag}->{"name:uk"};

		# Fix typical errors
		$new = fixUkrainian $name;
		if ($new ne $name) {
			print STDERR "LOG: Fixed Ukrainian in name:uk $name -> $new $entry->{id}\n";

			$name = $new;
			$entry->{tag}->{"name:uk"} = $new;

			$modified = 1;
		}

		if (checkUkrainianSyntax $name) {
			$new = tryAutoAddUkrToponym($name);

			if ($new ne $name) {
				print STDERR "LOG: Autoadded Ukrainian to name:uk $name -> $new $entry->{id}\n";

				$name = $new;
				$entry->{tag}->{"name:uk"} = $new;

				$modified = 1;
			} else {
				print STDERR "WARN: Illegal syntax in Ukrainian in name:uk ($name) $entry->{id}\n";
			}
		}

		
		if (exists $entry->{tag}->{"name"}) {
			if ($name ne $entry->{tag}->{"name"}) {
				print STDERR "WARN: name and name:uk differ ($name <-> $entry->{tag}->{name}) $entry->{id}\n";
			}
		} else {
			$entry->{tag}->{"name"} = $name;

			$modified = 1;
			print STDERR "LOG: Filled in name from name:uk ($entry->{tag}->{name}) $entry->{id}\n";
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
	return 1 if /чая\s+/;
	return 1 if /яя\s+/;
	return 1 if /cкий\s+/;
	return 1 if /кое\s+/;

	return 1 if /кая$/;
	return 1 if /ная$/;
	return 1 if /яя$/;
	return 1 if /cкий$/;
	return 1 if /ского\s+/;
	return 1 if /ской\s+/;
	return 1 if /ского$/;
	return 1 if /ской$/;
	return 1 if /кое$/;

	return 1 if /(улица|спуск|набережная|шоссе|переулок|площадь|пер\.|линия|мост|проезд)/i;

	return 0;
}

sub fixRussian($) {
	$_ = shift;

	if (/^(?:ул\.|улица|у\.|ул)\s+(.*)/i) {
		return "$1 улица";
	}

	if (/(.*)\s+(?:ул\.|у\.)$/i) {
		return "$1 улица";
	}

	if (/^ул\.(.*)/i) {
		return "$1 улица";
	}

	s/пр-т/проспект/i;
	s/туп\./тупик/i;
	s/наб\./набережная/i;
	s/пер\./переулок/i;
	s/пр\./проспект/i;
	s/^пр /проспект /i;
	s/просп\./проспект/i;
	s/пл\./площадь/i;
	s/дор\./дорога/i;
	s/б-р/бульвар/i;
	s/бул\./бульвар/i;
	s/ш\.$/шоссе/i;
	s/подъем/подъём/i;

	# Put toponym to the end
	if ($_ !~ /Линия железной дороги улица/i) {
	  if (/^(проспект|проезд|переулок|спуск|въезд|тупик|дорога|площадь|бульвар|шоссе|подъём|линия|мост)\s+(.*)/i) {
		$_ = "$2 $1";
	  }
	}

	# Some streets are named "Набережная Ленина улица"
	if (/^набережная\s+/i) {
		unless (/^набережная\s+.*улица$/i) {
			m/^набережная\s+(.*)/i;
			$_ = "$1 набережная";
		}
	}

	if ($_ eq "набережная") {
		$_ = "Набережная улица";
	}

	# 1-й переулок Кандинского
	if (/^([0-9]-й)\s+переулок\s+(.*)/i) {
		$_ = "$1 $2 переулок";
	}

	# lc the toponym
	s/(проспект| проезд|переулок|набережная| спуск|въезд| тупик| дорога|площадь| бульвар| шоссе| подъём|линия| мост)$/lc $1/ie;

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

	if (/^вул\.(.*)/i) {
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
	s/бульв\./бульвар/i;
	s/туп\./тупик/i;
	s/^вул\./вулиця /i;

	# Russianisms
	s/ул\./вулиця/i;
	s/шоссе/шосе/i;
	s/пер\./провулок/i;
	s/Ленина/Леніна/i;

	# misspellings
	s/перевулок/провулок/i;
	s/тупік/тупик/i;
	s/([1-9])й/$1-й/;
	s/([1-9])а/$1-а/;

	# Put toponym to the end
	if ($_ !~ /Лінія залізниці вулиця/i) {
	  if (/^(проспект|проїзд|провулок|узвіз|в’їзд|тупик|дорога|площа|бульвар|шосе|підйом|лінія|міст)\s+(.*)/i) {
		$_ = "$2 $1";
	  }
	}

	if (/^набережна\s+/i) {
		unless (/^набережна\s+.*вулиця$/i) {
			m/^набережна\s+(.*)/i;
			$_ = "$1 набережна";
		}
	}

	s/^вулиця\s+вулиця/вулиця/i;

	if ($_ eq "набережна") {
		$_ = "Набережна вулиця";
	}

	# 1-й провулок Кандинського
	if (/^([0-9]-й)\s+провулок\s+(.*)/i) {
		$_ = "$1 $2 провулок";
	}

	# lc the toponym
	s/(проспект|проїзд|провулок|набережна|узвіз|в’їзд|тупик|дорога|площа|бульвар|шосе|підйом|лінія|міст)$/lc $1/ie;

	return $_;
}

sub checkRussianSyntax($) {
	$_ = shift;

	unless (/(проспект|проезд|переулок|спуск|въезд|набережная|тупик|дорога|улица|площадь|бульвар|шоссе|аллея|подъём|подъем|линия|мост)$/) {
		return 1;
	}

	return 0;
}

sub checkUkrainianSyntax($) {
	$_ = shift;

	unless (/(проспект|проїзд|провулок|узвіз|в’їзд|набережна|тупик|дорога|вулиця|площа|бульвар|шосе|лея|підйом|лінія|міст)$/) {
		return 1;
	}

	return 0;
}

sub tryAutoAddUkrToponym($) {
	$_ = shift;

	return $_ if (/[A-Za-z]/); # We have Latin here. Skip

	return $_ if (/ /); # There is more than single word. Skip

	return $_ if (/^[РМТH]-?[0-9]+/); # Road name

	return "$_ вулиця";
}

sub tryAutoAddRusToponym($) {
	$_ = shift;

	return $_ if (/[A-Za-z]/); # We have Latin here. Skip

	return $_ if (/ /); # There is more than single word. Skip

	return $_ if (/^[РМТH]-?[0-9]+/); # Road name

	return "$_ улица";
}

sub translateToponym($) {
	$_ = shift;

	s/проспект$/Avenue/;
	s/проїзд$/Pass/;
	s/провулок$/Lane/;
	s/узвіз$/Descent/;
	s/в’їзд$/Entrance/;
	s/набережна$/Embarkment/;
	s/тупик$/End/;
	s/дорога$/Way/;
	s/вулиця$/Street/;
	s/площа$/Square/;
	s/бульвар$/Boulevard/;
	s/шосе$/Road/;
	s/алея$/Alley/;
	s/підйом$/Ascent/;
	s/лінія$/Line/;
	s/міст$/Bridge/;

	# Title case
	s/ ([a-z])/" ".uc($1)/ge;
	$_ = ucfirst $_;

	return $_;
}


sub transliterate($) {
	$_ = shift;

	s/зг/zgh/g;
	s/х/kh/g;
	s/ц/ts/g;
	s/ь//g;
	s/’//g;
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
	tr/абвгґдезийіїклмнопрстуф/abvhgdezyiiiklmnoprstuf/;

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

sub processBuilding($) {
	my $entry = shift;
	my $modified = 0;
	my $housenumber = lc $entry->{tag}->{"addr:housenumber"};

	$housenumber =~ tr/abki\\/авкі\//;
	$housenumber =~ s/корпус/к/;
	$housenumber =~ s/корп\./к/;

	$housenumber =~ s/^([0-9]+)[- ]+([^0-9]+)/$1$2/;

	$housenumber =~ s/^([0-9]+)\s*к\s*([0-9]+)/$1 к$2/;

	if ($housenumber ne $entry->{tag}->{"addr:housenumber"}) {
		print STDERR "LOG: Fixed housenumber <$entry->{tag}->{'addr:housenumber'}> --> <$housenumber> $entry->{id}\n";

		$entry->{tag}->{"addr:housenumber"} = $housenumber;

		$modified = 1;
	}

	if ($modified) {
		return $entry;
	} else {
		return 0;
	}
}
