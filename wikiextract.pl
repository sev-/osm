#!/usr/bin/perl -w
#
# Extract ukrainian city information from Wikipedia dump
#
# Copyright (c) 2010, Eugene Sandulenko <sev.mail@gmail.com>
#
# This file is provided under GPLv2 license.
#
# Usage: perl -CD wikiextract.pl ukwiki-20101012-pages-articles.xml [cities.csv]
#        where first parameter is bunzip2'ed wiki dump taken from
#        http://download.wikimedia.org/ukwiki/
#        second optional parameter is name for the output file. Default cities.csv
#
# Output:
#        cities.csv -- file containing data extract
#        NNNNN.txt  -- dump of article contents
#        NNNNNn.txt -- dump of article not belonging to cities but which
#                      still uses KOATUU codes (Oblast, Silrada, etc)
#
# Format of cities.csv file:
#    Comma separated list having following fields
#      number:     file number NNNNN (see above)
#      title:      title of Wikipedia document
#      name_ua:    Ukrainian name of the city
#      name_ru:    Russian name of the city (actually it is RU article
#                  reference, so it requires additional processing
#      koatuu:     KOATUU code
#      oblast:     Oblast of the city
#      raion:      Raion of the city
#      rada:       Rada of the city
#      elt:        elevation of the city
#      population: population of the city
#      coords:     coordinates of the city (in form of coord template)
#      zip:        zip code of the city
#      card:       URL of the city card on Verkhovna Rada cite
#
#    All fields are represented as they are in the city template
#    in the article, that is they require processing and data
#    cleansing

use Parse::MediaWikiDump;
use Text::CSV;
use utf8;


BEGIN { $| = 1; }

my $file = shift(@ARGV) or die "must specify a Mediawiki dump file";
my $outfile = shift(@ARGV) || "cities.csv";
my $pages = Parse::MediaWikiDump::Pages->new($file);
my $page;

my $num = 1;
my $art = 0;
my $total = 694200; # Hardcoded number of articles in Ukrainian wikipedia

my @cols = ();

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
$csv->eol("\n");

open $csvf, ">:encoding(utf8)", $outfile or die "$outfile: $!";

print $csvf "\"num\",\"title\",\"name_ua\",\"name_ru\",\"koatuu\",\"oblast\",\"raion\",\"rada\",\"elt\",\"population\",\"coords\",\"zip\",\"card\"\n";

sub putCol {
	my $val = shift;

	if (defined $val) {
		$val =~ s/^\s+|\s+$//g;
	}

	push @cols, $val;
}

while(defined($page = $pages->next)) {
	if (${ $page->text } =~ /од\s+КОАТУУ\s*=/) {

		$pass = "n";
		if ((${ $page->text } =~ /{{(?:Картка:)?([[Сс][еи]ло(?:\s+України)?|[Сс]елище(?:\s+України)?|[Сс]мт(?:\s+України)?|[Мм]істо\s+України)\s*\|/) && ($page->title !~ /Шаблон:/)) {
			$pass = "";

			putCol($page->id);
			putCol($page->title);

			if (${ $page->text } =~ /^\s*\|?\s*назва\s*=\s*(.*)$/m) { putCol($1); } else { putCol(""); }

			if (${ $page->text } =~ /\[\[ru:(.*)\]\]/m) { putCol($1); } else { putCol(""); }

			if (${ $page->text } =~ /^\s*\|\s*код\s*КОАТУУ\s*=(.*)$/m) { putCol($1); } else { putCol(""); }
			if (${ $page->text } =~ /^\s*\|\s*область\s*=(.*)$/m) { putCol($1);
			} else {
				if (${ $page->text } =~ /^\s*\|\s*регіон\s*=(.*)$/m) { putCol($1); } else { putCol(""); }
			}
			if (${ $page->text } =~ /^\s*\|\s*район\s*=(.*)$/m) { putCol($1); } else { putCol(""); }
			if (${ $page->text } =~ /^\s*\|\s*рада\s*=(.*)$/m) { putCol($1); } else { putCol(""); }
			if (${ $page->text } =~ /^\s*\|\s*висота\s*=(.*)$/m) { putCol($1); } else { putCol(""); }
			if (${ $page->text } =~ /^\s*\|\s*населення\s*=(.*)$/m) { putCol($1); } else { putCol(""); }
			if (${ $page->text } =~ /^\s*\|\s*координати\s*=(.*)$/m) { putCol($1); } else { putCol(""); }
			if (${ $page->text } =~ /^\s*\|\s*поштовий\s+індекс\s*=(.*)$/m) { putCol($1);
			} else {
				if (${ $page->text } =~ /^\s*\|\s*поштові\s+індекси\s*=(.*)$/m) { putCol($1); } else { putCol(""); }
			}
			if (${ $page->text } =~ /^\s*\|\s*облікова\s+картка\s*=(.*)$/m) { putCol($1); } else { putCol(""); }

			$csv->print ($csvf, \@cols);
			@cols = ();
		}

		if ($pass ne "") {
			if (${ $page->text } =~ /^\s*\|\s*код\s*КОАТУУ\s*=(.*)$/m) {
				$pass = "q" if $1 !~ /^\s+$/;
			}

			open OUT, sprintf(">%05d${pass}.txt", $page->id);
			print OUT ${ $page->text };
			close OUT;
		}

		$num++;

	}
	$art++;

	print "\r" . $page->id . (sprintf " %02.2f%%", ($art * 100) / $total) if ($art % 1000 == 0);
}

close $csvf;

print "\r" . (sprintf " %02.2f%% ($art)", ($art * 100) / $total) . "\n";
