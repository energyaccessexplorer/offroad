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
		git reset --hard; \
		git pull;)

	touch website.diff
	patch -p1 <website.diff

	(cd website; \
		go mod tidy; \
		bmake build; \
		bmake deps; \
		mv dist ../build; \
		cp -r assets/lib/* ../build/lib;)

	./images.sh

tool:
	test -d tool || \
		git clone --quiet "https://github.com/energyaccessexplorer/tool"

	(cd tool; \
		git reset --hard; \
		git pull;)

	touch tool.diff
	patch -p1 <tool.diff

	(cd tool; \
		bmake deps; \
		bmake reconfig env=local; \
		bmake build; \
		mv dist ../build/tool)

all: clean gobuild website tool fetch zip

bundle: clean gobuild fetch zip

fetch:
	mkdir -p data/{geographies,files,datasets}

	WORLD=https://world.energyaccessexplorer.org \
	API=https://api.energyaccessexplorer.org \
	STORAGE_URL=https://wri-public-data.s3.amazonaws.com/EnergyAccess/ \
	IDSFILE=${IDSFILE} \
	./fetch.sh ${ids}

zip:
	zip -q -r energyaccessexplorer-${os}.zip build data runme*

clean:
	-rm -Rf build data runme*

.PHONY: website tool
