#!/usr/bin/perl -w
#
# Extract information from rada dump
#
# Copyright (c) 2010, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#

use Text::CSV;
use utf8;

BEGIN { $| = 1; }

my $radadir = shift(@ARGV) || "rada";
my $outfile = shift(@ARGV) || "rada.csv";

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
$csv->eol("\n");

open $csvf, ">:encoding(utf8)", $outfile or die "$outfile: $!";

my @fields1 = qw(oldname formdate categorydate zipname zip admcenter water areaga aream areakm populationt populationm populations density adminvalue distanceto distancerail distanceroad nearestrail distancenearestrail populationcity populationmiskradat populationmiskradam populationmiskradas);
my @fields2 = qw(amts phone fax rada email site);
my @fields3 = qw(numsil numselrad nummist nummiskrad numsel numsilrad numsel dummy numrayonsmist numrayradmist numrayons nummistobl numrayrad nummistresp);

print $csvf "\"num\",\"name\"";

for my $f (@fields1) {
	print $csvf ",\"$f\"";
}

for my $f (@fields2) {
	print $csvf ",\"$f\"";
}

print $csvf "\n";

for my $f (<${radadir}/*.html>) {
	my %entry = ();
	my $fields1num = -1;
	my $fields2num = -1;
	my $fields3num = -1;

	print "\r$f";

	open $in, "<:encoding(cp1251)", $f;

	$f =~ m"${radadir}/([0-9]+).html";

	$entry{num} = $1;

	while (<$in>) {
		next unless /class="AllNews"/;

		if (/h3 align=center.*AllNews">(.*)<\/h3>/) {
			$entry{name} = $1;
		} elsif (/THEAD3.*AllNews">(.*)<\/td>/) {
			if ($1 =~ /^Колишня назва/) {
				$fields1num = 0;
			} elsif ($1 =~ /^Історична дата утворення/) {
				$fields1num = 1;
			} elsif ($1 =~ /^Дата віднесення до категорії/) {
				$fields1num = 2;
			} elsif ($1 =~ /^Поштове відділення/) {
				$fields1num = 3;
			} elsif ($1 =~ /^Поштовий індекс/) {
				$fields1num = 4;
			} elsif ($1 =~ /^Адміністративний центр/) {
				$fields1num = 5;
			} elsif ($1 =~ /^Річка, озеро/) {
				$fields1num = 6;
			} elsif ($1 =~ /^Територія \(тис.га/) {
				$fields1num = 7;
			} elsif ($1 =~ /^Територія \(тис.кв.м/) {
				$fields1num = 8;
			} elsif ($1 =~ /^Територія \(тис.кв.км/) {
				$fields1num = 9;
			} elsif ($1 =~ /^Населення всього/) {
				$fields1num = 10;
			} elsif ($1 =~ /^Населення міське/) {
				$fields1num = 11;
			} elsif ($1 =~ /^Населення сільське/) {
				$fields1num = 12;
			} elsif ($1 =~ /^Щільність населення/) {
				$fields1num = 13;
			} elsif ($1 =~ /^Адміністративне значення/) {
				$fields1num = 14;
			} elsif ($1 =~ /^Відстань до/) {
				$fields1num = 15;
			} elsif ($1 =~ /^залізницею/) {
				$fields1num = 16;
			} elsif ($1 =~ /^шосейними шляхами/) {
				$fields1num = 17;
			} elsif ($1 =~ /^Найближча залізнична станція/) {
				$fields1num = 18;
			} elsif ($1 =~ /^відстань/) {
				$fields1num = 19;
			} elsif ($1 =~ /^Населення міста \(тис.осіб/) {
				$fields1num = 20;
			} elsif ($1 =~ /^Населення \(міськрада\) всього \(тис.осіб/) {
				$fields1num = 21;
			} elsif ($1 =~ /^Населення \(міськрада\) міське \(тис.осіб/) {
				$fields1num = 22;
			} elsif ($1 =~ /^Населення \(міськрада\) сільське \(тис.осіб/) {
				$fields1num = 23;
			}
		} elsif (/THEAD21.*AllNews">(.*)<\/td>/) {
			if ($fields1num == -1) {
				if ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;сіл&nbsp;/) {
					$fields3num = 0;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;селищних рад&nbsp;/) {
					$fields3num = 1;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;міст районного значення&nbsp;/) {
					$fields3num = 2;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;міських рад&nbsp;/) {
					$fields3num = 3;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;селищ міського типу&nbsp;/) {
					$fields3num = 4;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;сільських рад&nbsp;/) {
					$fields3num = 5;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;селищ&nbsp;/) {
					$fields3num = 6;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;/) {
					$fields3num = 7;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;районів у містах&nbsp;/) {
					$fields3num = 8;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;районних рад у містах&nbsp;/) {
					$fields3num = 9;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;районів&nbsp;/) {
					$fields3num = 10;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;міст обласного значення&nbsp;/) {
					$fields3num = 11;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;районних рад&nbsp;/) {
					$fields3num = 12;
				} elsif ($1 =~ /^/) {
					$fields3num = 13;
				} else {
					die "$f: $_";
				}
			}

			if ($fields3num == -1) {
				my $res = $1;
				$res =~ s/&nbsp;/ /g;
				$res =~ s/^\s+|\s+$//g;

				$entry{$fields1[$fields1num]} = $res;

				$fields1num = -1;
			}
		} elsif (/THEAD21.*topTitle">.*">(.*)<\/a>/) {
			if ($fields3num == -1) {
				die "$f: $_";
			}

			my $res = $1;
			$res =~ s/&nbsp;/ /g;
			$res =~ s/^\s+|\s+$//g;

			$entry{$fields3[$fields3num]} = $res;

			$fields3num = -1;
		} elsif (/THEAD00.*AllNews">(.*)<\/td>/) {
			if ($1 =~ /^Код АМТС/) {
				die "$f: $_" unless $fields2num == -1;
				$fields2num = 0;
			} elsif ($1 =~ /^Телефон/) {
				die "$f: $_" unless $fields2num == 0;
				$fields2num = 1;
			} elsif ($1 =~ /^Факс/) {
				die "$f: $_" unless $fields2num == 1;
				$fields2num = 2;
			} elsif ($1 =~ /^Адреса ради/) {
				die "$f: $_" unless $fields2num == 2;
				$fields2num = 3;
			} elsif ($1 =~ /^E-mail/) {
				die "$f: $_" unless $fields2num == 3;
				$fields2num = 4;
			} elsif ($1 =~ /^Адреса сайту/) {
				die "$f: $_" unless $fields2num == 4;
				$fields2num = 0;
			} elsif ($1 =~ /^Рада, що прийняла/) {
				last;
			} elsif ($1 =~ /^У складі району:/) {
				$fields2num = -1;
			} elsif ($1 =~ /^У системі місцевого самоврядування:/) {
				$fields2num = -1;
			} elsif ($1 =~ /^У складі міста:/) {
				$fields2num = -1;
			} elsif ($1 =~ /^У складі області:/) {
				$fields2num = -1;
			} elsif ($1 =~ /^У складі автономії:/) {
				$fields2num = -1;
			} else {
				die "$f: $_";
			}
		} elsif (/THEAD02.*AllNews">(.*)<\/td>/) {
			if ($fields2num > 5 || $fields2num == -1) {
				die "$f: $_";
			}

			my $res = $1;
			$res =~ s/&nbsp;/ /g;
			$res =~ s/^\s+|\s+$//g;

			$entry{$fields2[$fields2num]} = $res;
			$fields2num++;
		}
	}

	close $in;

	my @cols = ();

	push @cols, $entry{num};
	push @cols, $entry{name};

	for my $f (@fields1) {
		push @cols, $entry{$f}
	}

	for my $f (@fields2) {
		push @cols, $entry{$f}
	}

	for my $f (@fields3) {
		push @cols, $entry{$f}
	}

	$csv->print ($csvf, \@cols);
}

close $csvf;

print "\n";
