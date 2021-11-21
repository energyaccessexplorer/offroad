os ?= linux

BINARY = runme

.if ${os} == "windows"
BINARY = ${BINARY}.exe
.endif

.ifndef idsfile
	@echo "I need idsfile=<somefile>"
	@exit
.endif

gobuild:
	rm -f ${BINARY}*
	GOOS=${os} go build -o ${BINARY}

projects:
	git clone --quiet "https://github.com/energyaccessexplorer/website";
	git clone --quiet "https://github.com/energyaccessexplorer/tool";

	sed -ri \
		'/\/(get-involved|subscribe|login)/d' \
		website/routes.tsv

	sed -ri \
		'/\/(get-involved)/,+4d' \
		website/templates/nav.mustache

	. ./patches

	(cd website; \
		rm -rf .git; \
		go mod tidy; \
		bmake build; \
		bmake deps; \
		mv dist ../sources; \
		mv assets/lib ../sources/)

	(cd tool; \
		rm -rf .git; \
		bmake deps; \
		bmake reconfig env=local; \
		bmake build; \
		mv dist ../sources/tool)

bundle:
	bmake clean

	mkdir -p data/{geographies,files,datasets}

	bmake gobuild

	bmake projects

	bmake fetch

	bmake zip os=${os}

fetch:
	WORLD=https://world.energyaccessexplorer.org \
	API=https://api.energyaccessexplorer.org \
	STORAGE_URL=https://wri-public-data.s3.amazonaws.com/EnergyAccess/ \
	IDSFILE=${idsfile} \
		./fetch.sh

zip:
	zip -q -r energyaccessexplorer-${os}.zip sources data runme*

clean:
	-rm -Rf website tool sources runme*
