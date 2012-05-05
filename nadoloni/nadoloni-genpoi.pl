#!/usr/bin/perl -w
#
# Generate POIs from for nadoloni.com dump
#

use utf8;
use Geo::Parse::OSM;

use Text::CSV;

BEGIN { $| = 1; }

binmode STDERR, ':utf8';

my $poifile = shift or die "Usage: $0 poi.csv";

$num = 0;

print "<osm  version='0.6'>\n";

my $csv = Text::CSV->new( { binary => 1, sep_char => ';', escape_char => '%', allow_loose_quotes => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf8)", $poifile or die "$poifile: $!";

$csv->column_names($csv->getline($fh));

while (my $line = $csv->getline_hr($fh)) {
  $numtotal++;

  %poi = ();

  $error = 0;
  $skipname = 0;

  if ($line->{category_id} == 30) { # Cafe & Restaurants
	if ($line->{classifier_en} eq 'Cafe-museum' or $line->{classifier_en} eq 'Сafe-museum') {
	  $poi{'tag'}->{'amenity'} = "cafe";
	  $poi{'tag'}->{'tourism'} = "museum";
	} elsif ($line->{classifier_en} eq 'Cafe-bar') {
	  $poi{'tag'}->{'amenity'} = "cafe";
	} elsif ($line->{classifier_en} eq 'Cafe' or $line->{classifier_en} eq 'Сafe') {
	  $poi{'tag'}->{'amenity'} = "cafe";
	} elsif ($line->{classifier_en} eq 'Bistro') {
	  $poi{'tag'}->{'amenity'} = "cafe";
	} elsif ($line->{classifier_en} eq 'Shop-cafe') {
	  $poi{'tag'}->{'amenity'} = "cafe";
	  $poi{'tag'}->{'shop'} = "convenience";
	} elsif ($line->{classifier_en} eq 'Restaurant') {
	  $poi{'tag'}->{'amenity'} = "restaurant";
	} elsif ($line->{classifier_en} eq 'Ethno-restaurant') {
	  $poi{'tag'}->{'amenity'} = "restaurant";
	  $poi{'tag'}->{'cuisine'} = "regional";
	} elsif ($line->{classifier_en} eq 'Confectionary and Restaurant') {
	  $poi{'tag'}->{'amenity'} = "restaurant";
	  $poi{'tag'}->{'shop'} = "confectionary";
	} elsif ($line->{classifier_en} eq 'Sushi bar' or $line->{classifier_en} eq 'Sushi Bar') {
	  $poi{'tag'}->{'amenity'} = "restaurant";
	  $poi{'tag'}->{'cuisine'} = "sushi";
	} elsif ($line->{classifier_en} eq 'Barbeque') {
	  $poi{'tag'}->{'amenity'} = "restaurant";
	  $poi{'tag'}->{'cuisine'} = "kebab";
	} elsif ($line->{classifier_en} eq 'Pub') {
	  $poi{'tag'}->{'amenity'} = "pub";
	} elsif ($line->{classifier_en} eq 'Pub-restaurant') {
	  $poi{'tag'}->{'amenity'} = "pub";
	} elsif ($line->{classifier_en} eq 'Bar') {
	  $poi{'tag'}->{'amenity'} = "bar";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 32) { # Bars & Pubs
	if ($line->{classifier_en} eq 'Bar') {
	  $poi{'tag'}->{'amenity'} = "bar";
	} elsif ($line->{classifier_en} eq 'Pub') {
	  $poi{'tag'}->{'amenity'} = "pub";
	} elsif ($line->{classifier_en} eq 'Shop-Bar') {
	  $poi{'tag'}->{'amenity'} = "bar";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 39) { # Saunas & Massage
	if ($line->{classifier_en} eq 'Medical Massage Center') {
	  $poi{'tag'}->{'shop'} = "massage";
	} elsif ($line->{classifier_en} eq 'Sauna, Bath') {
	  $poi{'tag'}->{'leisure'} = "sauna";
	} elsif ($line->{classifier_en} eq 'Sauna') {
	  $poi{'tag'}->{'leisure'} = "sauna";
	} elsif ($line->{classifier_en} eq '') {
	  $poi{'tag'}->{'shop'} = "massage";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 12) { # Gas station
	$poi{'tag'}->{'amenity'} = "fuel";
	$poi{'tag'}->{'brand'} = (split / /, $line->{title_ua})[0];
  } elsif ($line->{category_id} == 13) {
	$poi{'tag'}->{'amenity'} = "car_wash";
  } elsif ($line->{category_id} == 14) {
	$poi{'tag'}->{'shop'} = "car";
  } elsif ($line->{category_id} == 16) {
	$poi{'tag'}->{'office'} = "insurance";
  } elsif ($line->{category_id} == 17) {
	$poi{'tag'}->{'amenity'} = "atm";
	$poi{'tag'}->{'operator'} = $line->{title_ua};
  } elsif ($line->{category_id} == 18) {
	$poi{'tag'}->{'amenity'} = "bank";
	$poi{'tag'}->{'operator'} = $line->{title_ua};
  } elsif ($line->{category_id} == 20) {
	$poi{'tag'}->{'amenity'} = "cinema";
  } elsif ($line->{category_id} == 22) {
	$poi{'tag'}->{'amenity'} = "theatre";
  } elsif ($line->{category_id} == 23) {
	if ($line->{title_en} =~ /Mineral/) {
	  $poi{'tag'}->{'natural'} = "spring";
	  $poi{'tag'}->{'amenity'} = "drinking_water";
	} else {
	  $poi{'tag'}->{'amenity'} = "place_of_worship";
	}
  } elsif ($line->{category_id} == 26) {
	$poi{'tag'}->{'sport'} = "pool";
  } elsif ($line->{category_id} == 27) {
	$poi{'tag'}->{'tourism'} = "museum";
  } elsif ($line->{category_id} == 28) {
	$poi{'tag'}->{'amenity'} = "nightclub";
  } elsif ($line->{category_id} == 29) {
	$poi{'tag'}->{'sport'} = "poker";
  } elsif ($line->{category_id} == 34) {
	if ($line->{classifier_en} eq 'Hotel') {
	  $poi{'tag'}->{'tourism'} = "hotel";
	} elsif ($line->{classifier_en} eq 'Villa') {
	  $poi{'tag'}->{'tourism'} = "guest_house";
	} elsif ($line->{classifier_en} eq 'Pension') {
	  $poi{'tag'}->{'amenity'} = "nursery";
	} elsif ($line->{classifier_en} eq 'Cottage') {
	  $poi{'tag'}->{'tourism'} = "guest_house";
	} elsif ($line->{classifier_en} eq 'Recreation complex') {
	  $poi{'tag'}->{'tourism'} = "hotel";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 35) { # Sanatorium
	$poi{'tag'}->{'tourism'} = "hotel";
	$poi{'tag'}->{'amenity'} = "hospital";
  } elsif ($line->{category_id} == 36) {
	$poi{'tag'}->{'tourism'} = "hostel";
  } elsif ($line->{category_id} == 37) {
	$poi{'tag'}->{'office'} = "lawyer";
  } elsif ($line->{category_id} == 40) {
	if ($line->{classifier_en} eq 'Health Centre') {
	  $poi{'tag'}->{'amenity'} = "doctors";
	} elsif ($line->{classifier_en} eq 'Beauty Salon') {
	  $poi{'tag'}->{'shop'} = "beauty";
	} elsif ($line->{classifier_en} eq 'Wellness Cabinet') {
	  $poi{'tag'}->{'shop'} = "beauty";
	} elsif ($line->{classifier_en} eq 'Barbershop') {
	  $poi{'tag'}->{'shop'} = "hairdresser";
	} elsif ($line->{classifier_en} eq 'SPA Center') {
	  $poi{'tag'}->{'amenity'} = "spa";
	} elsif ($line->{classifier_en} eq 'Beauty parlor') {
	  $poi{'tag'}->{'shop'} = "beauty";
	} elsif ($line->{classifier_en} eq '') {
	  $poi{'tag'}->{'shop'} = "beauty";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 41) {
	$poi{'tag'}->{'office'} = "lawyer";
	$poi{'tag'}->{'lawyer'} = "notary";
  } elsif ($line->{category_id} == 42) {
	if ($line->{title_en} =~ /Medical/) {
	  $poi{'tag'}->{'amenity'} = "doctors";
	} else {
	  $poi{'tag'}->{'amenity'} = "hospital";
	}
  } elsif ($line->{category_id} == 43) {
	$poi{'tag'}->{'amenity'} = "veterinary";
  } elsif ($line->{category_id} == 44) {
	$poi{'tag'}->{'amenity'} = "dentist";
  } elsif ($line->{category_id} == 45) {
	$poi{'tag'}->{'amenity'} = "pharmacy";
  } elsif ($line->{category_id} == 49) {
	$poi{'tag'}->{'amenity'} = "car_rental";
  } elsif ($line->{category_id} == 52) {
	$poi{'tag'}->{'office'} = "travel_agent";
  } elsif ($line->{category_id} == 53) {
	$poi{'tag'}->{'shop'} = "outdoor";
  } elsif ($line->{category_id} == 54) {
	$poi{'tag'}->{'office'} = "company";
  } elsif ($line->{category_id} == 55) {
	$poi{'tag'}->{'office'} = "estate_agent";
  } elsif ($line->{category_id} == 56) {
	$poi{'tag'}->{'shop'} = "furniture";
  } elsif ($line->{category_id} == 57) {
	$poi{'tag'}->{'shop'} = "cosmetics";
  } elsif ($line->{category_id} == 58) {
	$poi{'tag'}->{'shop'} = "mall";
  } elsif ($line->{category_id} == 59) {
	$poi{'tag'}->{'shop'} = "doityourself";
  } elsif ($line->{category_id} == 60) {
	if ($line->{classifier_en} eq 'Shop underwear') {
	  $poi{'tag'}->{'shop'} = "clothes";
	  $poi{'tag'}->{'clothes'} = "underwear";
	} elsif ($line->{classifier_en} eq 'Boutique') {
	  $poi{'tag'}->{'shop'} = "boutique";
	} elsif ($line->{classifier_en} eq 'Wedding') {
	  $poi{'tag'}->{'shop'} = "clothes";
	  $poi{'tag'}->{'clothes'} = "wedding";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 61) {
	$poi{'tag'}->{'shop'} = "electronics";
  } elsif ($line->{category_id} == 62) {
	if ($line->{classifier_en} =~ /Grocery store/) {
	  $poi{'tag'}->{'shop'} = "convenience";
	} elsif ($line->{classifier_en} eq 'Coffee shop') {
	  $poi{'tag'}->{'amenity'} = "cafe";
	} elsif ($line->{classifier_en} eq 'Butchery') {
	  $poi{'tag'}->{'shop'} = "butcher";
	} elsif ($line->{classifier_en} eq 'Company store') {
	  $poi{'tag'}->{'shop'} = "beverages";
	} elsif ($line->{classifier_en} eq 'Supermarket' or $line->{classifier_en} eq 'Supermarke') {
	  $poi{'tag'}->{'shop'} = "supermarket";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 63) {
	$poi{'tag'}->{'shop'} = "mobile_phone";
  } elsif ($line->{category_id} == 65) {
	$poi{'tag'}->{'amenity'} = "school";
  } elsif ($line->{category_id} == 66) {
	$poi{'tag'}->{'leisure'} = "sport_centre";
	$poi{'tag'}->{'sport'} = "swimming";
  } elsif ($line->{category_id} == 68) {
	if ($line->{classifier_en} eq 'Fitness club') {
	  $poi{'tag'}->{'amenity'} = "gym";
	} elsif ($line->{classifier_en} eq 'Sport club') {
	  $poi{'tag'}->{'leisure'} = "sport_centre";
	  $poi{'tag'}->{'sport'} = "multi";
	} elsif ($line->{classifier_en} eq '') {
	  $poi{'tag'}->{'leisure'} = "sport_centre";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 79) {
	if ($line->{classifier_en} eq 'Tire Center') {
	  $poi{'tag'}->{'shop'} = "tyres";
	} elsif ($line->{classifier_en} eq 'Auto parts store') {
	  $poi{'tag'}->{'shop'} = "car_repair";
	} elsif ($line->{classifier_en} eq 'Auto Salon') {
	  $poi{'tag'}->{'shop'} = "car";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 80) {
	$poi{'tag'}->{'amenity'} = "driving_school";
  } elsif ($line->{category_id} == 81) {
	$poi{'tag'}->{'amenity'} = "police";
  } elsif ($line->{category_id} == 83) {
	$poi{'tag'}->{'shop'} = "pawnbroker";
  } elsif ($line->{category_id} == 85) {
	$poi{'tag'}->{'leisure'} = "theme_park";
  } elsif ($line->{category_id} == 87) {
	$poi{'tag'}->{'amenity'} = "cafe";
  } elsif ($line->{category_id} == 88) {
	$poi{'tag'}->{'amenity'} = "restaurant";
	$poi{'tag'}->{'cuisine'} = "pizza";
  } elsif ($line->{category_id} == 89) {
	if ($line->{classifier_en} eq 'ISP') {
	  $poi{'tag'}->{'office'} = "isp";
	} elsif ($line->{classifier_en} eq 'Office') {
	  $poi{'tag'}->{'office'} = "isp";
	} else {
	  $poi{'tag'}->{'amenity'} = "wifi";
	}
  } elsif ($line->{category_id} == 90) {
	$poi{'tag'}->{'craft'} = "tailor";
  } elsif ($line->{category_id} == 91) {
	$poi{'tag'}->{'office'} = "translation";
  } elsif ($line->{category_id} == 92) {
	$poi{'tag'}->{'office'} = "advertisement"; #fixme
  } elsif ($line->{category_id} == 93) {
	$poi{'tag'}->{'amenity'} = "post_office";
  } elsif ($line->{category_id} == 94) {
	$poi{'tag'}->{'shop'} = "repair";
  } elsif ($line->{category_id} == 98) {
	$poi{'tag'}->{'amenity'} = "school";
  } elsif ($line->{category_id} == 99) {
	$poi{'tag'}->{'amenity'} = "hospital";
  } elsif ($line->{category_id} == 100) {
	$poi{'tag'}->{'amenity'} = "hospital"; # fixme roddom
  } elsif ($line->{category_id} == 101) {
	$poi{'tag'}->{'amenity'} = "doctors";
  } elsif ($line->{category_id} == 102) {
	if ($line->{title_en} =~ /Bus Station/) {
	  $poi{'tag'}->{'amenity'} = "bus_station";
	} elsif ($line->{title_en} =~ /Station/) {
	  $poi{'tag'}->{'railway'} = "station";
	} elsif ($line->{title_en} =~ 'Airlines') {
	  $poi{'tag'}->{'office'} = "travel_agent";
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 104) {
	$poi{'tag'}->{'shop'} = "chemist";
  } elsif ($line->{category_id} == 106) {
	$poi{'tag'}->{'shop'} = "books";
  } elsif ($line->{category_id} == 107) {
	$poi{'tag'}->{'shop'} = "computer";
  } elsif ($line->{category_id} == 108) {
	$poi{'tag'}->{'shop'} = "gift";
  } elsif ($line->{category_id} == 111) {
	$poi{'tag'}->{'shop'} = "toys";
  } elsif ($line->{category_id} == 112) {
	$poi{'tag'}->{'shop'} = "sports";
  } elsif ($line->{category_id} == 113) {
	$poi{'tag'}->{'shop'} = "jewelry";
  } elsif ($line->{category_id} == 114) {
	$poi{'tag'}->{'leisure'} = "stadium";
  } elsif ($line->{category_id} == 116 or $line->{category_id} == 117 or ($line->{category_id} >= 119 and $line->{category_id} <= 128) or $line->{category_id} == 149) {
	if ($line->{classifier_en} eq 'ATM') {
	  $poi{'tag'}->{'amenity'} = "atm";
	  $poi{'tag'}->{'operator'} = $line->{title_ua};

	  $skipname = 1;
	} else {
	  $error = 1;
	}
  } elsif ($line->{category_id} == 118) {
	if ($line->{classifier_en} eq 'Billboard') {
	  $poi{'tag'}->{'advertising'} = "billboard";
	} elsif ($line->{classifier_en} eq 'City Lite') {
	  $poi{'tag'}->{'advertising'} = "sign";
	} else {
	  $error = 1;
	}
	$poi{'tag'}->{'ref'} = $line->{title_ua};
	$poi{'tag'}->{'operator'} = 'Артішок';

	$skipname = 1;
  } elsif ($line->{category_id} == 151) {
	if ($line->{classifier_en} eq 'Billboard') {
	  $poi{'tag'}->{'advertising'} = "billboard";
	} elsif ($line->{classifier_en} eq 'City Lite') {
	  $poi{'tag'}->{'advertising'} = "sign";
	} else {
	  $error = 1;
	}
	$poi{'tag'}->{'ref'} = $line->{title_ua};
	$poi{'tag'}->{'operator'} = 'Владіс';

	$skipname = 1;
  } else {
	$error = 1;
  }
  
  if ($error) {
	print STDERR "Error: $line->{category_id}, <$line->{classifier_en}> $line->{title_en}\n" if $error == 1;
	next;
  }

  $poi{'tag'}->{'nadoloni:id'} = "poi:$line->{id}";
  $poi{'type'} = 'node';
  $poi{'id'} = -$line->{id};
  $poi{'lat'} = $line->{latitude};
  $poi{'lon'} = $line->{longitude};

  unless ($skipname) {
	$poi{'tag'}->{'name'} = $line->{title_ua};
	$poi{'tag'}->{'name:uk'} = $line->{title_ua};
	$poi{'tag'}->{'name:ru'} = $line->{title_ru};
	$poi{'tag'}->{'name:en'} = $line->{title_en};
  }
  
  print Geo::Parse::OSM::object_to_xml(\%poi);
  
  $num++; 
}

print "</osm>\n";

printf STDERR "$num of $numtotal %.2f%%\n", $num / $numtotal * 100;
