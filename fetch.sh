#!/bin/sh

set -e

DIR=`pwd`
DATADIR=${DIR}/data
FILES_CACHE=${DIR}/files-cache

DATASET_ATTRS='*,datatype,category:categories(*)'
GEOGRAPHY_ATTRS='*,subgeographies:parent(*)'

function printline {
	echo -en "\e[1A"
	echo -e "\e[0K\r$1"
}

function curly {
	if ! curl --silent --show-error --fail $@; then
		echo $@
	fi
}

function curlyauth {
	if ! curl --silent --show-error --fail \
		 --header "Authorization: Bearer $TOKEN" \
		 $@; then
		echo $@
	fi
}

function curlyone {
	if ! curl --silent --show-error --fail \
		 --header 'Accept: application/vnd.pgrst.object+json' \
		 $@; then
		echo $@
	fi
}

function curlyauthone {
	if ! curl --silent --show-error --fail \
		 --header "Authorization: Bearer $TOKEN" \
		 --header 'Accept: application/vnd.pgrst.object+json' \
		 $@; then
		echo $@
	fi
}

function store {
	local endpoint=$1

	if [ "$endpoint" = "null" ]; then
		return
	fi

	local fname=`basename $endpoint`
	local fcache="$FILES_CACHE/${fname}"
	local fpath="$DATADIR/files/${fname}"

	printline "    $endpoint"

	if [ ! -e "${fcache}" ]; then
		curly --output "${fcache}" "$endpoint"
	fi

	cp "${fcache}" "${fpath}"

	sleep 0.05
}

function fetch {
	local GID=$1

	curlyauthone "${API}/geographies?select=name&id=eq.${GID}" | jq --raw-output '.name' > /tmp/eae-tmpname
	local FNAME=`cat /tmp/eae-tmpname`;
	local NAME=`cat /tmp/eae-tmpname | sed s/\ /%20/g`

	curlyauthone "${API}/geographies?select=adm&id=eq.${GID}" | jq --raw-output '.adm' > /tmp/eae-tmpadm
	local ADM=`cat /tmp/eae-tmpadm | sed s/\ /%20/g`

	rm -f /tmp/eae-tmpadm /tmp/eae-tmpname

	echo $FNAME - adm $ADM

	echo "    geography"
	curlyauthone --output ${DATADIR}/geographies/${GID} "${API}/geographies?id=eq.${GID}&select=${GEOGRAPHY_ATTRS}"

	echo "    datasets collection"
	curlyauth --output ${DATADIR}/datasets/${GID} "${API}/datasets?select=${DATASET_ATTRS}&geography_id=eq.${GID}&category_name=neq.outline"

	echo "    division datasets"
	while read DATASETID; do
		curlyauthone --output ${DATADIR}/datasets/${DATASETID} "${API}/datasets?select=${DATASET_ATTRS}&id=eq.${DATASETID}"

		sed -i "s;/paver-outputs/;/;g" ${DATADIR}/datasets/${DATASETID}
		sed -i "s;$STORAGE_URL;;g" ${DATADIR}/datasets/${DATASETID}
	done <<EOF
`
curlyauth "${API}/datasets?select=id&geography_id=eq.${GID}&category_name=in.(boundaries,outline)" \
	| jq --raw-output '.[] | .id'
`
EOF

	echo "    processed files"
	echo "    _"
	while read endpoint; do
		store $endpoint
	done <<EOF
`
curlyauth "${API}/datasets?&geography_id=eq.${GID}" \
	| jq --raw-output '.[] | .processed_files | .[] | .endpoint' \
`
EOF

	printline "    csv files"
	echo "    _"
	while read endpoint; do
		if [ "$endpoint" == "" ]; then
			continue
		fi

		store $endpoint
	done <<EOF
`
cat ${DATADIR}/datasets/${GID} \
	| jq --raw-output '.[] | .source_files | .[] | if .func == "csv" then .endpoint else null end' \
`
EOF

	sed -i "s;/paver-outputs/;/;g" ${DATADIR}/datasets/${GID}
	sed -i "s;$STORAGE_URL;;g" ${DATADIR}/datasets/${GID}

	if [ $ADM == "0" ]; then
		printline "    flag"
		curlyone "${WORLD}/countries?select=flag&name=eq.${NAME}" \
			| jq '.flag' \
			| xxd -revert -plain > ${DATADIR}/files/${FNAME}-flag.svg
	else
		printline "    no flag"
	fi
}

if [ "${IDSFILE}" = "" ]; then
	IDSFILE=/dev/null
	IDS=`echo "$@" | tr ' ' ','`
elif [ -e "${IDSFILE}" ]; then
	IDS=`paste -s -d "," ${IDSFILE}`
else
	echo "Could not figure out IDS"
	exit 1
fi

echo "Countries list"
curlyauth --output ${DATADIR}/geographies/all.json "${API}/geographies?adm=eq.0&id=in.(${IDS})&select=${GEOGRAPHY_ATTRS}"

echo "Presets"
curly --output ${DATADIR}/files/presets.csv "${STORAGE_URL}presets.csv"

function f {
	echo ""
	echo $1
	fetch $1
}

for id in "$@"; do
	f $id
done

while read id; do
	f $id
done <${IDSFILE}
