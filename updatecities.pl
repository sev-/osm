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
use Geo::Coordinates::DecimalDegrees;
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

my @cities = ();

my $ukrname = shift or die "Usage: $0: ukraine.osm cities.csv";
my $citiesname = shift or die "Usage: $0: ukraine.osm cities.csv";

my $total = 30715; # Hardcoded number of cities
my $num = 0;

my $noMatches = 0;
my $noMatchesSafe = 0;
my $emptyname = 0;
my $emptynameSafe = 0;
my $renames = 0;

my $processor = sub {
	return unless exists $_[0]->{tag}->{place};

	$place = $_[0]->{tag}->{place};

	if ($_[0]->{type} eq 'node') {
		if ($place eq 'city' || $place eq 'town' || $place eq 'village' || $place eq 'hamlet') {
			$_[0]->{action} = 'modify';

			my $res = processCity($_[0]);

			print Geo::Parse::OSM::object_to_xml($res) if $res;
			$num++;
		}
	}
};

my $csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf8)", $citiesname or die "$citiesname: $!";

$csv->column_names($csv->getline($fh));

my @cit = ();

while (my $line = $csv->getline_hr($fh)) {
	($line->{lat}, $line->{lon}) = processCoords($line->{coords});

	if ($line->{lat} == 0 || $line->{lon} == 0) {
		print STDERR "$line->{num} $line->{name_ua} {$line->{title}} $line->{lat}, $line->{lon}\n";
		next;
	}
	$line->{name_ua} =~ s/^\s+|\s+$//g;
	$line->{name_ua} =~ s/́//g;
	$line->{name_ua} =~ s/'/’/g;
	$line->{wikipedia_ru} = $line->{name_ru};
	$line->{name_ru} =~ s/\(.*\)//;
	$line->{name_ru} =~ s/^\s+|\s+$//g;

	my $ppl = $line->{population};

	$line->{population} =~ s/,(\d) тис\./${1}00/;
	$line->{population} =~ s/,(\d\d) тис\./${1}0/;
	$line->{population} =~ s/,(\d\d\d) тис\./${1}/;

	$line->{population} =~ s/{{збільшення}}|{{зменшення}}|{{стабільно}}|,|\.|&nbsp;| |бл\.|біля|>|<|місто:|~|понад|близько|^-//g;
	$line->{population} =~ s/{{Formatnum:(\d+)}}.*/$1/gi;
	$line->{population} =~ s/.*Останнідані-(\d+).*/$1/g;

	$line->{population} =~ s/^(\d+).*/$1/;

	unless ($line->{population} =~ /^\d+$/) {
	  $line->{population} = "";
	}

	if (exists $line->{zip}) {
	  $line->{zip} =~ s/&nbsp;/ /g;
	  $line->{zip} =~ s/ та /, /g;
	  $line->{zip} =~ s/—/-/g;
	  $line->{zip} =~ s/ - /-/g;
	  $line->{zip} =~ s/^\[\[#Зв'язок\|(.*)/$1/;
	  $line->{zip} =~ s/^([\d ,-]+).*/$1/;
	  $line->{zip} =~ s/^\s+|\s+$//g;
	  $line->{zip} =~ s/^(\d\d)(\d\d\d)-(\d\d\d)$/$1$2-$1$3/g;
	  $line->{zip} =~ s/^(\d\d\d)(\d\d)-(\d\d)$/$1$2-$1$3/g;
	}

	push @cit, $line;
}

$csv->eof or $csv->error_diag();
close $fh;

@cities = sort {$a->{lat} <=> $b->{lat}} @cit;

$citiesLeft = scalar @cities;

print STDERR "Loaded $citiesLeft cities\n";


my @cityBucket = ();

my $nn = 0;
for my $c (@cities) {
	$c->{bucketX} = latBucket $c->{lat};
	$c->{bucketY} = lonBucket $c->{lon};

	push @{$cityBucket[$c->{bucketX}][$c->{bucketY}]}, $nn;
	
	$nn++;
}

print "<osm  version='0.6'>\n";
Geo::Parse::OSM->parse_file($ukrname, $processor);
print "</osm>\n";

print STDERR "No matches: $noMatches out of $num ($noMatchesSafe are safe)\n";
print STDERR "Renames: $renames\n";
print STDERR "Empty: $emptyname ($emptynameSafe are safe)\n";
print STDERR "Cities left: $citiesLeft\n";

exit;

sub latBucket($) {
	my $lat = shift;

	return int(($lat - 44) * 10) + 1;
}

sub lonBucket($) {
	my $lon = shift;

	return int(($lon - 22) * 15) + 1;
}

sub processCoords($) {
	my $str = shift;

	my @arr = split /\|/, $str;

	return (0, 0) if $#arr < 7;

	my $lat;
	my $lon;
	my $n = 1;
	my $deg;
	my $sec;
	my $min;

	if ($arr[$n+3] eq "N" or $arr[$n+4] eq "N") {
		$n++ if ($arr[$n+4] eq "N");

		$deg = $arr[$n] || 0;
		$min = $arr[$n+1] || 0;
		$sec = $arr[$n+2] || 0;
		if ($sec > 100) {
			print STDERR "$sec\n";
			$sec = substr $arr[$n+2], 0, 2;
		}
		$lat = dms2decimal($deg, $min, $sec);
		$n += 4;
	} elsif ($arr[$n+2] eq "N") {
		$deg = $arr[$n] || 0;
		$min = $arr[$n+1] || 0;
		$sec = 0;
		$lat = dms2decimal($deg, $min, $sec);
		$n = 4;
	} else {
		print STDERR "Bad coordinates $str\n";
	}

	if ($arr[$n+3] eq "E") {
		$deg = $arr[$n] || 0;
		$min = $arr[$n+1] || 0;
		$sec = $arr[$n+2] || 0;
		$lon = dms2decimal($deg, $min, $sec);
	} elsif ($arr[$n+2] eq "E") {
		$deg = $arr[$n] || 0;
		$min = $arr[$n+1] || 0;
		$sec = 0;
		$lon = dms2decimal($deg, $min, $sec);
	} else {
		print STDERR "Bad coordinate E $str\n";
	}

	return ($lat, $lon);
}

sub processCity($) {
	my $entry = shift;

	# First we search for entry with minimal distance
	my $min = 0;
	my $mind = 1e9;
	my ($minBpos, $minX, $minY);
	my $n = 0;
	my $lat = $entry->{lat};
	my $lon = $entry->{lon};
	my $latb = latBucket $lat;
	my $lonb = lonBucket $lon;
	my $cnd;

	#print STDERR "$num " . (sprintf "%02.2f%%", ($num * 100) / $total) ."\r" if ($num % 10 == 0);

	if (not exists $entry->{lat} or not exists $entry->{lon}) {
		print STDERR "Wrong entry id: $entry->{id}\n";
		return;
	}

	if ($entry->{user} eq 'osm-ukraine') {
		$cnd = "*Remove*";
	} else {
		$cnd = "";
	}

	if (not exists $entry->{tag}->{name}) {
		$emptyname++;
		$emptynameSafe++ if $cnd ne "";

		print STDERR "Weird nameless entry id: $entry->{id} $cnd\n";
		return;
	}

	my $cnt = 0;
	for my $x ($latb-1..$latb+1) {
		for my $y ($lonb-1..$lonb+1) {
			next if not defined $cityBucket[$x][$y];

			my $nn = -1;
			for my $n (@{$cityBucket[$x][$y]}) {
				$nn++;

				next if not defined $n;

				next if $n == -1;

				$c = $cities[$n];

				if (not exists $c->{lat} or not exists $c->{lon}) {
					$c->{dist} = 1e6;
					next;
				}

				my $d1 = abs($c->{lat} - $lat);
				my $d2 = abs($c->{lon} - $lon);

				my $d = $d1 * $d1 + $d2 * $d2;

				$c->{dist} = $d;
		
				if ($d < $mind) {
					$mind = $d;
					$min = $n;
					$minX = $x;
					$minY = $y;
					$minBpos = $nn;
				}
				$cnt++;
			}
		}
	}

	if (lc $cities[$min]->{name_ua} eq lc $entry->{tag}->{name} || 
		lc $cities[$min]->{name_ru} eq lc $entry->{tag}->{name} ||
		(exists $entry->{tag}->{"name:ua"} && lc $cities[$min]->{name_ua} eq lc $entry->{tag}->{"name:ua"}) ||
		(exists $entry->{tag}->{"name:ru"} && lc $cities[$min]->{name_ru} eq lc $entry->{tag}->{"name:ru"}) ||
		(exists $entry->{tag}->{koatuu} && $cities[$min]->{koatuu} eq $entry->{tag}->{koatuu})) {

		# Sounds good. Remove it
		$citnum = splice @{$cityBucket[$minX][$minY]}, $minBpos, 1;

		$citiesLeft--;

		return updateCity $entry, $citnum;
	} else {
		# Okay, we're in trouble. No match.

		my @citM = ();
		for my $x ($latb-1..$latb+1) {
			for my $y ($lonb-1..$lonb+1) {
				next if not defined $cityBucket[$x][$y];

				for my $n (@{$cityBucket[$x][$y]}) {
					next if not defined $n;
					next if $n == -1;

					push @citM, $n if $cities[$n]->{dist} < 0.003;
				}
			}
		}

		if (!scalar @citM) {
			print STDERR "$entry->{tag}->{name} $entry->{lat}, $entry->{lon} $cnd $entry->{id}\n";
			print STDERR "  No match in Wiki\n";

			$noMatches++;
			$noMatchesSafe++ if $cnd ne "";
			
			return;
		}


		my @citS = sort {$cities[$a]->{dist} <=> $cities[$b]->{dist}} @citM; # This is slow

		# Try to find name match
		my $match = 0;

		for my $n (@citS) {
			my $c = $cities[$n];

			if (lc $c->{name_ua} eq lc $entry->{tag}->{name} || 
				lc $c->{name_ru} eq lc $entry->{tag}->{name} ||
				(exists $entry->{tag}->{"name:ua"} && lc $c->{name_ua} eq lc $entry->{tag}->{"name:ua"}) ||
				(exists $entry->{tag}->{"name:ru"} && lc $c->{name_ru} eq lc $entry->{tag}->{"name:ru"}) ||
				(exists $entry->{tag}->{koatuu} && $c->{koatuu} eq $entry->{tag}->{koatuu})) {
				$match = 1;

				for my $x (0..scalar $cityBucket[$c->{bucketX}][$c->{bucketY}]) {
					if ($cityBucket[$c->{bucketX}][$c->{bucketY}]->[$x] == $n) {
						$citnum = splice @{$cityBucket[$c->{bucketX}][$c->{bucketY}]}, $x, 1;
						$citiesLeft--;

						return updateCity $entry, $citnum;
					}
				}

				return;
			}
		}

		if (!$match) {
			# Absoultely no match. Show all nearby entries then
			print STDERR "$entry->{tag}->{name} $entry->{lat}, $entry->{lon} $cnd\n";

			if ($cities[$citS[0]]->{dist} < 0.0002) {
				print STDERR "  Rename --> $cities[$citS[0]]->{name_ua}\n";
				$renames++;

				my $c = $cities[$citS[0]];
				for my $x (0..scalar @{ $cityBucket[$c->{bucketX}][$c->{bucketY}]}) {
					if ($cityBucket[$c->{bucketX}][$c->{bucketY}]->[$x] == $citS[0]) {
						$citnum = splice @{$cityBucket[$c->{bucketX}][$c->{bucketY}]}, $x, 1;
						$citiesLeft--;

						return updateCity $entry, $citnum;
					}
				}

				return;
			}
	
			for my $n (@citS) {
				my $c = $cities[$n];

				print STDERR "  $c->{num} $c->{name_ua} $c->{lat}, $c->{lon} [$c->{dist}]\n";
			}

			$noMatches++;

			$noMatchesSafe++ if $cnd ne "";
		}
	}

	return;
}

sub updateCity($$) {
  my $entry = shift;
  my $n = shift;
  my %tags = ();

  $tags{"wikipedia"} = "uk:".$cities[$n]->{title};
  $tags{"wikipedia:ru"} = $cities[$n]->{wikipedia_ru} if $cities[$n]->{wikipedia_ru} ne '';
  $tags{"name"} = $cities[$n]->{name_ua};
  $tags{"name:uk"} = $cities[$n]->{name_ua};
  $tags{"name:ru"} = $cities[$n]->{name_ru} if $cities[$n]->{name_ru} ne '';

  $tags{"name:en"} = transliterate $cities[$n]->{name_ua};

  if ($cities[$n]->{koatuu} ne '') {
    if (length $cities[$n]->{koatuu} > 10) { # filter out bad data
    } elsif (length $cities[$n]->{koatuu} == 9) {
      $tags{"koatuu"} = "0".$cities[$n]->{koatuu};
    } else {
      $tags{"koatuu"} = $cities[$n]->{koatuu};
    }
  }
  if ($cities[$n]->{population} ne '') {
    $tags{"population"} = $cities[$n]->{population};

    if ($tags{"population"} > 100000) {
      $tt = 'city'
    } elsif ($tags{"population"} > 10000) {
      $tt = 'town'
    } elsif ($tags{"population"} > 1000) {
      $tt = 'village'
    } elsif ($tags{"population"} != 0) {
      $tt = 'hamlet'
    }
    if ($tt ne $entry->{tag}->{place}) {
      #print STDERR "CLASS: $tags{name}: $tags{place} -> $tt ($tags{population})\n";
    }
  }
  $tags{"addr:postcode"} = $cities[$n]->{zip} if $cities[$n]->{zip} ne '';

  my $modified = 0;

  for my $k (keys %tags) {
	if (not exists $entry->{tag}->{$k} or
		$entry->{tag}->{$k} ne $tags{$k}) {
	  if (exists $entry->{tag}->{$k}) {
		print STDERR "UPD: $entry->{tag}->{name} ($entry->{id}) $k: \"$entry->{tag}->{$k}\" -> \"$tags{$k}\"\n";
	  } else {
		print STDERR "UPD: $entry->{tag}->{name} ($entry->{id}) $k: \"(null)\" -> \"$tags{$k}\"\n";
	  }

	  $entry->{tag}->{$k} = $tags{$k};
	  $modified = 1;
	}
  }

  if ($modified) {
	$entry->{action} = 'modify';
	return $entry;
  }

  return;
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
