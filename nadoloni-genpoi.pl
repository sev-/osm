#!/usr/bin/perl -w
#
# Generate POIs from for nadoloni.com dump
#

use utf8;
use Geo::Parse::OSM;
use Data::Dumper;

sub transliterate($);

BEGIN { $| = 1; }

binmode STDERR, ':utf8';

open IN, "companies.csv";
binmode IN, ':utf8';

$num = 0;

print "<osm  version='0.6'>\n";

while (<IN>) {
	@s = split /\t/;

	$numtotal++;

	%poi = ();

        if ($s[12] =~ /drogobych/) {
		$city = 'Дрогобич';
        } elsif ($s[12] =~ /truskavets/) {
		$city = 'Трускавець';
        } elsif ($s[12] =~ /stebnyk/) {
		$city = 'Стебник';
	} elsif ($s[12] =~ /boryslav/) {
		$city = 'Борислав';
        } else {
                print STDERR "Error: <$s[12]>\n";
        }

	$error = 0;

	if ($s[3] == 30) { # Cafe & Restaurants
	    if ($s[4] eq 'Cafe-museum' or $s[4] eq 'Сafe-museum') {
		$poi{'tag'}->{'amenity'} = "cafe";
		$poi{'tag'}->{'tourism'} = "museum";
	    } elsif ($s[4] eq 'Cafe-bar') {
		$poi{'tag'}->{'amenity'} = "cafe";
	    } elsif ($s[4] eq 'Cafe' or $s[4] eq 'Сafe') {
		$poi{'tag'}->{'amenity'} = "cafe";
	    } elsif ($s[4] eq 'Bistro') {
		$poi{'tag'}->{'amenity'} = "cafe";
	    } elsif ($s[4] eq 'Shop-cafe') {
		$poi{'tag'}->{'amenity'} = "cafe";
		$poi{'tag'}->{'shop'} = "convenience";
	    } elsif ($s[4] eq 'Restaurant') {
		$poi{'tag'}->{'amenity'} = "restaurant";
	    } elsif ($s[4] eq 'Ethno-restaurant') {
		$poi{'tag'}->{'amenity'} = "restaurant";
		$poi{'tag'}->{'cuisine'} = "regional";
	    } elsif ($s[4] eq 'Confectionary and Restaurant') {
		$poi{'tag'}->{'amenity'} = "restaurant";
		$poi{'tag'}->{'shop'} = "confectionary";
	    } elsif ($s[4] eq 'Sushi bar' or $s[4] eq 'Sushi Bar') {
		$poi{'tag'}->{'amenity'} = "restaurant";
		$poi{'tag'}->{'cuisine'} = "sushi";
	    } elsif ($s[4] eq 'Barbeque') {
		$poi{'tag'}->{'amenity'} = "restaurant";
		$poi{'tag'}->{'cuisine'} = "kebab";
	    } elsif ($s[4] eq 'Pub') {
		$poi{'tag'}->{'amenity'} = "pub";
	    } elsif ($s[4] eq 'Pub-restaurant') {
		$poi{'tag'}->{'amenity'} = "pub";
	    } elsif ($s[4] eq 'Bar') {
		$poi{'tag'}->{'amenity'} = "bar";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 32) { # Bars & Pubs
	    if ($s[4] eq 'Bar') {
		$poi{'tag'}->{'amenity'} = "bar";
	    } elsif ($s[4] eq 'Pub') {
		$poi{'tag'}->{'amenity'} = "pub";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 39) { # Saunas & Massage
	    if ($s[4] eq 'Medical Massage Center') {
		$poi{'tag'}->{'shop'} = "massage";
	    } elsif ($s[4] eq 'Sauna, Bath') {
		$poi{'tag'}->{'leisure'} = "sauna";
	    } elsif ($s[4] eq 'Sauna') {
		$poi{'tag'}->{'leisure'} = "sauna";
	    } elsif ($s[4] eq '') {
		$poi{'tag'}->{'shop'} = "massage";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 12) { # Gas station
	    $poi{'tag'}->{'amenity'} = "fuel";
	    $poi{'tag'}->{'brand'} = (split / /, $s[7])[0];
	} elsif ($s[3] == 13) {
	    $poi{'tag'}->{'amenity'} = "car_wash";
	} elsif ($s[3] == 14) {
	    $poi{'tag'}->{'shop'} = "car";
	} elsif ($s[3] == 16) {
	    $poi{'tag'}->{'office'} = "insurance";
	} elsif ($s[3] == 17) {
	    $poi{'tag'}->{'amenity'} = "atm";
	    $poi{'tag'}->{'operator'} = $s[7];
	} elsif ($s[3] == 18) {
	    $poi{'tag'}->{'amenity'} = "bank";
	    $poi{'tag'}->{'operator'} = $s[7];
	} elsif ($s[3] == 20) {
	    $poi{'tag'}->{'amenity'} = "cinema";
	} elsif ($s[3] == 22) {
	    $poi{'tag'}->{'amenity'} = "theatre";
	} elsif ($s[3] == 23) {
	    if ($s[9] =~ /Mineral/) {
		$poi{'tag'}->{'natural'} = "spring";
		$poi{'tag'}->{'amenity'} = "drinking_water";
	    } else {
		$poi{'tag'}->{'amenity'} = "place_of_worship";
	    }
	} elsif ($s[3] == 26) {
	    $poi{'tag'}->{'sport'} = "pool";
	} elsif ($s[3] == 27) {
	    $poi{'tag'}->{'tourism'} = "museum";
	} elsif ($s[3] == 28) {
	    $poi{'tag'}->{'amenity'} = "nightclub";
	} elsif ($s[3] == 29) {
	    $poi{'tag'}->{'sport'} = "poker";
	} elsif ($s[3] == 34) {
	    if ($s[4] eq 'Hotel') {
		$poi{'tag'}->{'tourism'} = "hotel";
	    } elsif ($s[4] eq 'Villa') {
		$poi{'tag'}->{'tourism'} = "guest_house";
	    } elsif ($s[4] eq 'Pension') {
		$poi{'tag'}->{'amenity'} = "nursery";
	    } elsif ($s[4] eq 'Cottage') {
		$poi{'tag'}->{'tourism'} = "guest_house";
	    } elsif ($s[4] eq 'Recreation complex') {
		$poi{'tag'}->{'tourism'} = "hotel";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 35) { # Sanatorium
	    $poi{'tag'}->{'tourism'} = "hotel";
	    $poi{'tag'}->{'amenity'} = "hospital";
	} elsif ($s[3] == 36) {
	    $poi{'tag'}->{'tourism'} = "hostel";
	} elsif ($s[3] == 37) {
	    $poi{'tag'}->{'office'} = "lawyer";
	} elsif ($s[3] == 40) {
	    if ($s[4] eq 'Health Centre') {
		$poi{'tag'}->{'amenity'} = "doctors";
	    } elsif ($s[4] eq 'Beauty Salon') {
		$poi{'tag'}->{'shop'} = "beauty";
	    } elsif ($s[4] eq 'Wellness Cabinet') {
		$poi{'tag'}->{'shop'} = "beauty";
	    } elsif ($s[4] eq 'Barbershop') {
		$poi{'tag'}->{'shop'} = "hairdresser";
	    } elsif ($s[4] eq 'SPA Center') {
		$poi{'tag'}->{'amenity'} = "spa";
	    } elsif ($s[4] eq 'Beauty parlor') {
		$poi{'tag'}->{'shop'} = "beauty";
	    } elsif ($s[4] eq '') {
		$poi{'tag'}->{'shop'} = "beauty";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 41) {
	    $poi{'tag'}->{'office'} = "lawyer";
	    $poi{'tag'}->{'lawyer'} = "notary";
	} elsif ($s[3] == 42) {
	    if ($s[9] =~ /Medical/) {
		$poi{'tag'}->{'amenity'} = "doctors";
	    } else {
		$poi{'tag'}->{'amenity'} = "hospital";
	    }
	} elsif ($s[3] == 43) {
	    $poi{'tag'}->{'amenity'} = "veterinary";
	} elsif ($s[3] == 44) {
	    $poi{'tag'}->{'amenity'} = "dentist";
	} elsif ($s[3] == 45) {
	    $poi{'tag'}->{'amenity'} = "pharmacy";
	} elsif ($s[3] == 49) {
	    $poi{'tag'}->{'amenity'} = "car_rental";
	} elsif ($s[3] == 52) {
	    $poi{'tag'}->{'office'} = "travel_agent";
	} elsif ($s[3] == 53) {
	    $poi{'tag'}->{'shop'} = "outdoor";
	} elsif ($s[3] == 54) {
	    $poi{'tag'}->{'office'} = "company";
	} elsif ($s[3] == 55) {
	    $poi{'tag'}->{'office'} = "estate_agent";
	} elsif ($s[3] == 56) {
	    $poi{'tag'}->{'shop'} = "furniture";
	} elsif ($s[3] == 57) {
	    $poi{'tag'}->{'shop'} = "cosmetics";
	} elsif ($s[3] == 58) {
	    $poi{'tag'}->{'shop'} = "mall";
	} elsif ($s[3] == 59) {
	    $poi{'tag'}->{'shop'} = "doityourself";
	} elsif ($s[3] == 60) {
	    if ($s[4] eq 'Shop underwear') {
		$poi{'tag'}->{'shop'} = "clothes";
		$poi{'tag'}->{'clothes'} = "underwear";
	    } elsif ($s[4] eq 'Boutique') {
		$poi{'tag'}->{'shop'} = "boutique";
	    } elsif ($s[4] eq 'Wedding') {
		$poi{'tag'}->{'shop'} = "clothes";
		$poi{'tag'}->{'clothes'} = "wedding";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 61) {
	    $poi{'tag'}->{'shop'} = "electronics";
	} elsif ($s[3] == 62) {
	    if ($s[4] =~ /Grocery store/) {
		$poi{'tag'}->{'shop'} = "convenience";
	    } elsif ($s[4] eq 'Coffee shop') {
		$poi{'tag'}->{'amenity'} = "cafe";
	    } elsif ($s[4] eq 'Butchery') {
		$poi{'tag'}->{'shop'} = "butcher";
	    } elsif ($s[4] eq 'Company store') {
		$poi{'tag'}->{'shop'} = "beverages";
	    } elsif ($s[4] eq 'Supermarket' or $s[4] eq 'Supermarke') {
		$poi{'tag'}->{'shop'} = "supermarket";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 63) {
	    $poi{'tag'}->{'shop'} = "mobile_phone";
	} elsif ($s[3] == 65) {
	    $poi{'tag'}->{'amenity'} = "school";
	} elsif ($s[3] == 66) {
	    $poi{'tag'}->{'leisure'} = "sport_centre";
	    $poi{'tag'}->{'sport'} = "swimming";
	} elsif ($s[3] == 68) {
	    if ($s[4] eq 'Fitness club') {
		$poi{'tag'}->{'amenity'} = "gym";
	    } elsif ($s[4] eq 'Sport club') {
		$poi{'tag'}->{'leisure'} = "sport_centre";
		$poi{'tag'}->{'sport'} = "multi";
	    } elsif ($s[4] eq '') {
		$poi{'tag'}->{'leisure'} = "sport_centre";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 79) {
	    if ($s[4] eq 'Tire Center') {
		$poi{'tag'}->{'shop'} = "tyres";
	    } elsif ($s[4] eq 'Auto parts store') {
		$poi{'tag'}->{'shop'} = "car_repair";
	    } elsif ($s[4] eq 'Auto Salon') {
		$poi{'tag'}->{'shop'} = "car";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 80) {
	    $poi{'tag'}->{'amenity'} = "driving_school";
	} elsif ($s[3] == 81) {
	    $poi{'tag'}->{'amenity'} = "police";
	} elsif ($s[3] == 83) {
	    $poi{'tag'}->{'shop'} = "pawnbroker";
	} elsif ($s[3] == 85) {
	    $poi{'tag'}->{'leisure'} = "theme_park";
	} elsif ($s[3] == 87) {
	    $poi{'tag'}->{'amenity'} = "cafe";
	} elsif ($s[3] == 88) {
	    $poi{'tag'}->{'amenity'} = "restaurant";
	    $poi{'tag'}->{'cuisine'} = "pizza";
	} elsif ($s[3] == 89) {
	    if ($s[4] eq 'ISP') {
		$poi{'tag'}->{'office'} = "isp";
	    } elsif ($s[4] eq 'Office') {
		$poi{'tag'}->{'office'} = "isp";
	    } else {
		$poi{'tag'}->{'amenity'} = "wifi";
	    }
	} elsif ($s[3] == 90) {
	    $poi{'tag'}->{'craft'} = "tailor";
	} elsif ($s[3] == 92) {
	    $poi{'tag'}->{'office'} = "advertisement"; #fixme
	} elsif ($s[3] == 93) {
	    $poi{'tag'}->{'amenity'} = "post_office";
	} elsif ($s[3] == 94) {
	    $poi{'tag'}->{'shop'} = "repair";
	} elsif ($s[3] == 98) {
	    $poi{'tag'}->{'amenity'} = "school";
	} elsif ($s[3] == 99) {
	    $poi{'tag'}->{'amenity'} = "hospital";
	} elsif ($s[3] == 100) {
	    $poi{'tag'}->{'amenity'} = "hospital"; # fixme roddom
	} elsif ($s[3] == 101) {
	    $poi{'tag'}->{'amenity'} = "doctors";
	} elsif ($s[3] == 102) {
	    if ($s[9] =~ /Bus Station/) {
		$poi{'tag'}->{'amenity'} = "bus_station";
	    } elsif ($s[9] =~ /Station/) {
		$poi{'tag'}->{'railway'} = "station";
	    } elsif ($s[9] =~ 'Airlines') {
		$poi{'tag'}->{'office'} = "travel_agent";
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 104) {
	    $poi{'tag'}->{'shop'} = "chemist";
	} elsif ($s[3] == 106) {
	    $poi{'tag'}->{'shop'} = "books";
	} elsif ($s[3] == 107) {
	    $poi{'tag'}->{'shop'} = "computer";
	} elsif ($s[3] == 108) {
	    $poi{'tag'}->{'shop'} = "gift";
	} elsif ($s[3] == 111) {
	    $poi{'tag'}->{'shop'} = "toys";
	} elsif ($s[3] == 112) {
	    $poi{'tag'}->{'shop'} = "sports";
	} elsif ($s[3] == 113) {
	    $poi{'tag'}->{'shop'} = "jewelry";
	} elsif ($s[3] == 114) {
	    $poi{'tag'}->{'leisure'} = "stadium";
	} elsif ($s[3] == 116 or $s[3] == 117 or ($s[3] >= 119 and $s[3] <= 128) or $s[3] == 149) {
	    if ($s[4] eq 'ATM') {
		$poi{'tag'}->{'amenity'} = "atm";
		$poi{'tag'}->{'operator'} = $s[7];
	    } else {
		$error = 1;
	    }
	} elsif ($s[3] == 118) {
	    if ($s[4] eq 'Billboard') {
		$poi{'tag'}->{'advertising'} = "billboard";
	    } elsif ($s[4] eq 'City Lite') {
		$poi{'tag'}->{'advertising'} = "sign";
	    } else {
		$error = 1;
	    }
	} else {
	    $error = 1;
	}

	if ($error) {
	    print STDERR "Error: $s[3], <$s[4]> $s[5] -- $s[7] $s[9]\n" if $error == 1;
	    next;
	}

	$poi{'tag'}->{'nadoloni:id'} = "poi:$s[0]";
	$poi{'tag'}->{'addr:city'} = $city;
	$poi{'type'} = 'node';
	$poi{'id'} = -$s[0];
	$poi{'lat'} = $s[1];
	$poi{'lon'} = $s[2];
	$poi{'tag'}->{'name'} = $s[7];
	$poi{'tag'}->{'name:uk'} = $s[7];
	$poi{'tag'}->{'name:ru'} = $s[8];
	$poi{'tag'}->{'name:en'} = transliterate $s[7];

	print Geo::Parse::OSM::object_to_xml(\%poi);

	$num++
}

close IN;

print "</osm>\n";

printf STDERR "$num of $numtotal %.2f%%\n", $num / $numtotal * 100;

exit 0;

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
