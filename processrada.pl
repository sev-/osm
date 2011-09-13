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
my @fields2 = qw(amts phone fax rada email site type parentname parentref);
my @fieldsp = qw(radapriynyala priynaladate priynalanum priynyalazmist priynalavru priynyalapubdate priynyalapubstor priynyalatype radapriynyala2 priynaladate2 priynalanum2 priynyalazmist2 priynalavru2 priynyalapubdate2 priynyalapubstor2 priynyalatype2);
my @fields3 = qw(numsil numsilw numselrad numselradw nummistray nummistrayw nummiskrad nummiskradw numsel numselw numsilrad numsilradw numsel numselw dummy dummyw numrayonsmist numrayonmistw numrayradmist numrayradmistw numrayons numrayonsw nummistobl nummistoblw numrayrad numrayradw nummistresp nummistrespw);

print $csvf "\"num\",\"name\"";

for my $f (@fields1) {
	print $csvf ",\"$f\"";
}

for my $f (@fields2) {
	print $csvf ",\"$f\"";
}

for my $f (@fieldsp) {
	print $csvf ",\"$f\"";
}

for my $f (@fields3) {
	print $csvf ",\"$f\"";
}

print $csvf "\n";

for my $f (<${radadir}/*.html>) {
	my %entry = ();
	my $fields1num = -1;
	my $fields2num = -1;
	my $fieldspnum = -1;
	my $fieldspcoeff = 0;
	my $fields3num = -1;

	print "\r$f";

	open $in, "<:encoding(cp1251)", $f;

	$f =~ m"${radadir}/([0-9]+).html";

	$entry{num} = $1;

	my $fields2val = "";
	my $fields2priynyala = 0;
	my $inpriynyala = 0;

	while (<$in>) {
		if ($fields2priynyala == 2 and $fieldspnum == 4 and $inpriynyala) {
			if (/<\/td>/) {
				$inpriynyala = 0;
				next;
			}
			chomp;
			$entry{$fieldsp[$fieldspnum - 1 + 8 * $fieldspcoeff]} .= " $_";
			next;
		}

		next unless /class="AllNews"/ or /class="topTitle"/;

		if (/h3 align=center.*AllNews">(.*)<\/h3>/) {
			$entry{name} = $1;
		} elsif (/THEAD3.*align=right\s+width="2%".*AllNews">(.*)<\/td>/) {
			# Just skip it
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
			} else {
				die "$f: Unknown field: $1 <$_> at $.";
			}
		} elsif (/THEAD21.*AllNews">(.*)<\/td>/) {
			if ($fields1num == -1) {
				my $p = $fields3num;

				if ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;сіл&nbsp;/) {
					$fields3num = 0;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;селищних рад&nbsp;/) {
					$fields3num = 2;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;міст районного значення&nbsp;/) {
					$fields3num = 4;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;міських рад&nbsp;/) {
					$fields3num = 6;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;селищ міського типу&nbsp;/) {
					$fields3num = 8;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;сільських рад&nbsp;/) {
					$fields3num = 10;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;селищ&nbsp;/) {
					$fields3num = 12;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$/) {
					$fields3num = 14;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;районів у містах&nbsp;/) {
					$fields3num = 16;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;районних рад у містах&nbsp;/) {
					$fields3num = 18;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;районів&nbsp;/) {
					$fields3num = 20;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;міст обласного значення&nbsp;/) {
					$fields3num = 22;
				} elsif ($1 =~ /^&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;районних рад&nbsp;/) {
					$fields3num = 24;
				} else {
					die "$f:(3) $_  at $.";
				}

				if ($fields3num <= $p) {
					die "$f: Wrong field seq: $_  at $.";
				}
				$fields2priynyala = 0;
			}

			if ($fields3num == -1) {
				die "$f: Bad field composition: $_ at $." if $fields1num == -1;

				my $res = $1;
				$res =~ s/&nbsp;/ /g;
				$res =~ s/^\s+|\s+$//g;

				$entry{$fields1[$fields1num]} = $res;

				$fields1num = -1;
			}
		} elsif (/THEAD21.*topTitle"><a href="(.*)">(.*)<\/a>/) {
			if ($fields3num == -1) {
				die "$f: unknown thead21 $_ at $.";
			}

			my $res = $1;
			my $res2 = $2;
			$res =~ s/&nbsp;/ /g;
			$res =~ s/^\s+|\s+$//g;
			$res2 =~ s/&nbsp;/ /g;
			$res2 =~ s/^\s+|\s+$//g;

			$entry{$fields3[$fields3num]} = $res;
			$entry{$fields3[$fields3num+1]} = $res2;

			$fields3num = -1;
		} elsif (/THEAD21.*topTitle">/) {
			die "$f: Bad format: $_ at $." unless $fields3num == 14;
		} elsif (/THEAD00.*AllNews">(.*)<\/td>/) {
			if ($1 =~ /^Код АМТС/) {
				die "$f: bad thead00 seq ($fields2num) $_ at $." unless ($fields2num == 6 or $fields2num == -1);
				$fields2num = 0;
			} elsif ($1 =~ /^Телефон/) {
				die "$f: bad thead00 seq $_ at $." unless $fields2num == 0;
				$fields2num = 1;
			} elsif ($1 =~ /^Факс/) {
				die "$f: bad thead00 seq $_ at $." unless $fields2num == 1;
				$fields2num = 2;
			} elsif ($1 =~ /^Адреса ради/) {
				die "$f: bad thead00 seq $_ at $." unless $fields2num == 2;
				$fields2num = 3;
			} elsif ($1 =~ /^E-mail/) {
				die "$f: bad thead00 seq $_ at $." unless $fields2num == 3;
				$fields2num = 4;
			} elsif ($1 =~ /^Адреса сайту/) {
				die "$f: bad thead00 seq $_ at $." unless $fields2num == 4;
				$fields2num = 0;
			} elsif ($1 =~ /^У складі району:/) {
				die "$f: doubled type: $_ at $." if $fields2val ne "";

				$fields2num = 6;
				$fields2val = "rayon";
			} elsif ($1 =~ /^У системі місцевого самоврядування:/) {
			} elsif ($1 =~ /^У складі міста:/) {
				die "$f: doubled type: $_ at $." if $fields2val ne "";
				$fields2num = 6;
				$fields2val = "misto";
			} elsif ($1 =~ /^У складі області:/) {
				die "$f: doubled type: $_ at $." if $fields2val ne "";
				$fields2num = 6;
				$fields2val = "oblast";
			} elsif ($1 =~ /^У складі автономії:/) {
				die "$f: doubled type: $_ at $." if $fields2val ne "";
				$fields2num = 6;
				$fields2val = "avtonomia";
			} elsif ($1 =~ /^Рада, що прийняла<br>рішення/) {
				die "$f: Priynyala: $_ at $." if $fields2priynyala;

				$fields2priynyala = 1;
				$fieldspnum = 0;
			} elsif ($1 =~ /^Дата<br>рішення/) {
				die "$f: Priynyala: $_ at $." if $fields2priynyala != 1 or $fieldspnum != 0;

				$fieldspnum = 1;
			} elsif ($1 =~ /^№<br>рішення/) {
				die "$f: Priynyala: $_ at $." if $fields2priynyala != 1 or $fieldspnum != 1;

				$fieldspnum = 2;
			} elsif ($1 =~ /^Зміст рішення/) {
				die "$f: Priynyala: $_ at $." if $fields2priynyala != 1 or $fieldspnum != 2;

				$fieldspnum = 3;
			} elsif ($1 =~ /^Відомості ВРУ/) {
				die "$f: Priynyala: $_ at $." if $fields2priynyala != 1 or $fieldspnum != 3;

				$fieldspnum = 4;
			} else {
				die "$f: Bad typedef $_ at $.";
			}
		} elsif (/THEAD01.*AllNews">(.*)<\/td>/) {
			if ($fields2priynyala < 1 and $fieldspcoeff == 0) {
				die "$f: Unexpected thead01: $_ at $.";
			} elsif ($1 =~ /^Дата<br>опубліку-<br>вання/) {
				die "$f: Priynyala: $_ ($fieldspnum $fieldspcoeff) at $." if $fieldspnum != 4 and $fieldspcoeff == 0;

				$fieldspnum = 5;
				$fields2priynyala = 1;
			} elsif ($1 =~ /^№, стаття<br>\(сторінка\)/) {
				die "$f: Priynyala: $_ at $." if $fieldspnum != 5;

				$fieldspnum = 6;
				$fields2priynyala = 2;
			} else {
				die "$f: Priynyala: $_ ($1) at $.";
			}				
		} elsif (/THEAD02.*AllNews">(.*)<\/td>/ or ($fieldspnum == 3 and /THEAD02.*AllNews">(.*)/)) {
			if ($fields2priynyala == 0) {
				if ($fields2num > 6 || $fields2num == -1) {
					die "$f: bad thead02 num $_ at $.";
				}

				my $res = $1;

				$res = $fields2val if $fields2num == 6;

				$res =~ s/&nbsp;/ /g;
				$res =~ s/^\s+|\s+$//g;

				$entry{$fields2[$fields2num]} = $res;
				$fields2num++;
			} else {
				if ($fieldspnum == 6) {
					if (/Зміна категорії \(статусу\) населеного пункту/) {
						$entry{$fieldsp[7 + 8 * $fieldspcoeff]} = "StatusChange";
						$fieldspnum = 0;
						next;
					} elsif (/Перейменування/) {
						$entry{$fieldsp[7 + 8 * $fieldspcoeff]} = "Rename";
						$fieldspnum = 0;
						next;
					} elsif (/Ліквідація АТО \(зняття з обліку, об'єднання\)/) {
						$entry{$fieldsp[7 + 8 * $fieldspcoeff]} = "Delete";
						$fieldspnum = 0;
						next;
					} elsif (/Зміна центра АТО/) {
						$entry{$fieldsp[7 + 8 * $fieldspcoeff]} = "CentreChange";
						$fieldspnum = 0;
						next;
					} elsif (/Перепідпорядкування/) {
						$entry{$fieldsp[7 + 8 * $fieldspcoeff]} = "ChangeSuper";
						$fieldspnum = 0;
						next;
					} elsif (/Зміна меж АТО/) {
						$entry{$fieldsp[7 + 8 * $fieldspcoeff]} = "BorderChange";
						$fieldspnum = 0;
						next;
					} else {
						die "$f: Bad priynyalatype: $_ at $.";
					}
				} elsif ($fieldspnum > 5 || $fieldspnum < 0) {
					die "$f: bad thead02 num ($fieldspnum) $_ at $.";
				}
				my $res = $1;

				$res =~ s/&nbsp;/ /g;
				$res =~ s/^\s+|\s+$//g;

				if ($fieldspnum == 3) {
					if ($res =~ /<\/td>/i) {
						$res =~ s/<\/td>//i;
					} else {
						$inpriynyala = 1;
					}
				}

				$entry{$fieldsp[$fieldspnum + 8 * $fieldspcoeff]} = $res;
				$fieldspnum++;

				if ($fieldspnum == 6) {
					$fieldspnum = -1;
					$fieldspcoeff++;
					$fields2priynyala = 0;
				}
			}
		} elsif ($fields2num == 4 and (m'THEAD02.*topTitle"><a href="mailto:(.*)\?subject.*">(.*)</a>'i or 
				 m'THEAD02.*topTitle"><a href="http://(.*)">(.*)</a>'i)) {
			my $res = $1;
			my $res2 = $2;

			if ($fields2num != 4) {
				die "$f: Unexpected mailto: $_ at $.";
			}

			$res =~ s/&nbsp;/ /g;
			$res =~ s/^\s+|\s+$//g;
			$res2 =~ s/&nbsp;/ /g;
			$res2 =~ s/^\s+|\s+$//g;
			if ($res ne $res2) {
				die "$f: bad mailto format: $_ at $.";
			}

			$entry{$fields2[$fields2num]} = $res;
			$fields2num++;
		} elsif (/THEAD02.*topTitle"><a href="(.*)">(.*)<\/a><\/td>/) {
			my $res = $1;
			my $res2 = $2;
			$res =~ s/&nbsp;/ /g;
			$res =~ s/^\s+|\s+$//g;
			$entry{parentref} = $res;

			$res2 =~ s/&nbsp;/ /g;
			$res2 =~ s/^\s+|\s+$//g;
			$entry{parentname} = $res2;
		} elsif ($fields2num == 5 and /THEAD02.*topTitle"><a href="(.*)">(.*)<\/a>/i) {
			my $res = $1;

			$res =~ s/&nbsp;/ /g;
			$res =~ s/^\s+|\s+$//g;

			$entry{$fields2[$fields2num]} = $res;
			$fields2num++;
		} elsif (/THEAD02/) {
			die "$f: Unknown thead02 ($fields2num): $_ at $.";
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

	for my $f (@fieldsp) {
		push @cols, $entry{$f}
	}

	for my $f (@fields3) {
		push @cols, $entry{$f}
	}

	$csv->print ($csvf, \@cols);
}

close $csvf;

print "\n";
