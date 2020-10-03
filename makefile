os ?= linux

build:
	rm -f ./runme
	go build -o runme
	./runme

bundle: pre-bundle
	mkdir -p data/{geographies,files,datasets,boundaries}

	GOOS=${os} go build -o runme

#	REPOS
	git clone --quiet "https://github.com/energyaccessexplorer/website"
	git clone --quiet "https://github.com/energyaccessexplorer/tool"

#	HACKS

	sed -ri \
		'/\/(get-involved|subscribe|login)/d' \
		website/routes.tsv

	sed -ri \
		'/\/(get-involved)/,+4d' \
		website/templates/nav.mustache

#	BUILD
	(cd website; \
		make build; \
		make deps; \
		mv dist ../sources)

	(cd tool; \
		make deps; \
		make reconfig env=local; \
		make build; \
		mv dist ../sources/tool)

	WORLD=https://world.carajo.no/api \
	API=http://eaapi.localhost \
	STORAGE_URL=https://wri-public-data.s3.amazonaws.com/EnergyAccess \
	IDSFILE=${idsfile} \
	./fetch.sh

	make zip os=${os}

	make post-bundle

zip:
	zip -q -r energyaccessexplorer-${os}.zip sources data runme*

post-bundle:
	-rm -rf geoid-*

pre-bundle:
	-rm -rf website tool sources data runme* geoid-*
