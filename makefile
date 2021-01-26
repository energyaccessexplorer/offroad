os ?= linux

build:
	rm -f ./runme
	go build -o runme
	./runme

bundle:
.ifndef idsfile
	@echo "I need idsfile=<somefile>"
	@exit
.endif

	bmake pre-bundle

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
		bmake build; \
		bmake deps; \
		mv dist ../sources)

	(cd tool; \
		bmake deps; \
		bmake reconfig env=local; \
		bmake build; \
		mv dist ../sources/tool)

	WORLD=https://world.carajo.no/api \
	API=http://eaapi.localhost \
	STORAGE_URL=https://wri-public-data.s3.amazonaws.com/EnergyAccess \
	IDSFILE=${idsfile} \
		./fetch.sh

	bmake zip os=${os}

	bmake post-bundle

zip:
	zip -q -r energyaccessexplorer-${os}.zip sources data runme*

post-bundle:
	-rm -rf geoid-*

pre-bundle:
	-rm -rf website tool sources data runme* geoid-*
