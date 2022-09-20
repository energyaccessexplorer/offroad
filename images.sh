#!/bin/sh

LIST=`mktemp`

mkdir -p logos photos

function printline {
	if [ -t 1 ]; then
		echo -en "\e[1A"
		echo -e "\e[0K\r$1"
	else
		echo "$1"
	fi
}

echo ""

while read file; do
	printline "    $file"

	if [ ! -e "${file}" ]; then
		curl --silent --fail --output $file "https://wri-public-data.s3.amazonaws.com/EnergyAccess/website/$file"
	fi

	sleep 0.05
done <<EOF
`grep -ri 'http://localhost:9876/' build/ \
	| sed -r 's%.*(logos|photos)/(.*).(png|jpg|jpeg|gif|svg).*%\1/\2.\3%g'`
EOF

cp -r logos photos build/

printline "Websites images done!"
