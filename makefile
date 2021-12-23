os ?= linux

BINARY = runme

.if ${os} == "windows"
BINARY = runme.exe
.endif

gobuild:
	rm -f ${BINARY}*
	GOOS=${os} go build -o ${BINARY}

website:
	test -d website || \
		git clone --quiet "https://github.com/energyaccessexplorer/website"

	sed -ri \
		'/\/(get-involved|subscribe|login)/d' \
		website/routes.tsv

	sed -ri \
		'/\/(get-involved)/,+4d' \
		website/templates/nav.mustache

	(cd website; \
		git pull; \
		go mod tidy; \
		bmake build; \
		bmake deps; \
		mv dist ../build; \
		mv assets/lib ../build/)

tool:
	test -d tool || \
		git clone --quiet "https://github.com/energyaccessexplorer/tool"

	./tool-patches

	(cd tool; \
		git pull; \
		bmake deps; \
		bmake reconfig env=local; \
		bmake build; \
		mv dist ../build/tool)

bundle:
	bmake clean

	bmake gobuild

	bmake website

	bmake tool

	bmake fetch

	bmake zip os=${os}

fetch:
.ifndef ids
	@echo "I need ids=<somefile>"
	@exit
.endif

	mkdir -p data/{geographies,files,datasets}

	WORLD=https://world.energyaccessexplorer.org \
	API=https://api.energyaccessexplorer.org \
	STORAGE_URL=https://wri-public-data.s3.amazonaws.com/EnergyAccess/ \
	IDSFILE=${ids} \
		./fetch.sh

zip:
	zip -q -r energyaccessexplorer-${os}.zip build data runme*

clean:
	-rm -Rf build data runme*

.PHONY: website tool
