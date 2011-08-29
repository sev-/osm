#!bash

radadate=`date "+%d.%m.%Y"`

if test -z "$2" ; then
	mkdir rada-${radadate}

	for i in `seq 0 8`; do
		from=`expr $i \* 5000`
		bash $0 $from fork &
	done

	exit 0
fi

from=$1
to=`expr $1 + 5000`

for i in `seq $from $to`; do
	if test -f rada.stop; then
		echo Stopped
		exit 0
	fi
	echo $i
	wget -o /dev/null -O rada-${radadate}/$i.html "http://w1.c1.rada.gov.ua/pls/z7502/A005?rdat1=${radadate}&rf7571=${i}"
done

exit 0



