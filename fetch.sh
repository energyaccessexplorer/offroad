#!/bin/sh

WORLD=https://world.carajo.no/api
API=https://api.energyaccessexplorer.org
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
	curl --silent --header 'Accept: application/vnd.pgrst.object+json' \
		 "${API}/geographies?select=cca3&id=eq.${GEOID}" \
		| jq '.cca3' | sed 's/"//g' > geoid-${GEOID}

	CCA3=`cat geoid-${GEOID}`

	mkdir data/files/${CCA3}

	echo "Fetching flag ${CCA3} ..."
	curl --silent --header 'Accept: application/vnd.pgrst.object+json' \
		 "${WORLD}/countries?select=flag&cca3=eq.${CCA3}" \
		| jq '.flag' | xxd -r -p > data/files/${CCA3}/flag.svg

	curl --silent --header 'Accept: application/vnd.pgrst.object+json' \
		 "${WORLD}/countries?select=geojson&cca3=eq.${CCA3}" \
		| jq '.geojson' | xxd -r -p > data/files/${CCA3}/flag.geojson

	echo "Fetching geography ${CCA3} ..."
	curl --silent --header 'Accept: application/vnd.pgrst.object+json' \
		 --output data/geographies/${GEOID} \
		 "${API}/geographies?select=${GEOGRAPHY_ATTRS}&id=eq.${GEOID}"

	echo "Fetching datasets for ${CCA3} ..."
	curl --silent \
		 --output data/datasets/${GEOID} \
		 "${API}/datasets?select=${DATASET_ATTRS}&geography_id=eq.${GEOID}"

	cd data/files/${CCA3}

	while read file; do
		echo "Fetching $file ..."
		curl --progress-bar -O $file
	done <<EOF
`
cat ${DIR}/data/datasets/${GEOID} \
	| jq '.[] | .df' \
	| grep endpoint \
	| sed -r 's/.*"(https.*)",$/\1/'
`
EOF
}

while read id; do
	cd $DIR
	mkdir data/files/${id}
	fetch $id
done <${IDSFILE}
