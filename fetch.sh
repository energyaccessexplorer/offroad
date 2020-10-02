#!/bin/sh

set -e

function printline {
	echo -en "\e[1A"
	echo -e "\e[0K\r$1"
}

function curly {
	curl --silent --show-error --fail $@
}

function curlyone {
	curl --silent --show-error --fail --header 'Accept: application/vnd.pgrst.object+json' $@
}

GEOGRAPHY_ATTRS='*'
DATASET_ATTRS='*,category:categories(*),df:_datasets_files(*,file:files(*))'

DIR=`pwd`

if [ ! -f "${IDSFILE}" ]; then
	echo "'${IDSFILE}' file does not exist."
	exit 1
fi

function fetch {
	GEOID=$1

	echo "Getting CCA3 for ${GEOID} ..."
	curlyone "${API}/geographies?select=cca3&id=eq.${GEOID}" \
		| jq '.cca3' | sed 's/"//g' > geoid-${GEOID}

	CCA3=`cat geoid-${GEOID}`

	echo "Fetching geography ${CCA3} ..."
	curlyone --output data/geographies/${GEOID} \
		 "${API}/geographies?select=${GEOGRAPHY_ATTRS}&id=eq.${GEOID}"

	echo "Fetching geography_boundaries ${CCA3} ..."
	curlyone --output data/boundaries/${GEOID} \
		 "${API}/geography_boundaries?&geography_id=eq.${GEOID}"

	BID=`cat data/boundaries/${GEOID} | jq '.id' | sed 's/"//g'`

	echo "Fetching boundaries ${CCA3} ..."
	curlyone --output data/datasets/${BID} \
		 "${API}/datasets?select=${DATASET_ATTRS}&id=eq.${BID}"

	echo "Fetching datasets for ${CCA3} ..."
	curly --output data/datasets/${GEOID} \
		 "${API}/datasets?select=${DATASET_ATTRS}&geography_id=eq.${GEOID}"

	cd data/files/${GEOID}

	while read file; do
		url=$STORAGE_URL$file
		printline "Fetching $url ..."
		curly -O $url
	done <<EOF
`
cat ${DIR}/data/datasets/${GEOID} \
	| jq '.[] | .df' \
	| grep endpoint \
	| sed -r 's/\s+"endpoint": "([^"]*)",/\1/'
`
EOF

	printline "Done."

	cd $DIR/data/files
	ln -s ${GEOID} ${CCA3}
	# mkdir data/files/${CCA3} # should be GEOID

	cd $DIR

	echo "Fetching flag ${CCA3} ..."
	curlyone "${WORLD}/countries?select=flag&cca3=eq.${CCA3}" \
		| jq '.flag' | xxd -r -p > data/files/${GEOID}/flag.svg

	curlyone "${WORLD}/countries?select=geojson&cca3=eq.${CCA3}" \
		| jq '.geojson' | xxd -r -p > data/files/${GEOID}/flag.geojson
}

GEOIDS=`paste -s -d "," ${IDSFILE}`

curly "${API}/geographies?online=eq.true&adm=eq.0&id=in.($GEOIDS)" \
	 > data/geographies/all.json

while read id; do
	cd $DIR
	mkdir data/files/${id}
	fetch $id
done <${IDSFILE}
