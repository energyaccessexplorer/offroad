.include ".env"

os ?= linux

BINARY = runme

.if ${os} == "windows"
BINARY = runme.exe
.endif

gobuild:
	rm -f ${BINARY}*
	GOOS=${os} go build -o ${BINARY}

website:
	mkdir -p build

	test -d website || \
		git clone --quiet "https://github.com/energyaccessexplorer/website"

	sed -r -i.orig \
		'/\/(get-involved|subscribe|login)/d' \
		website/routes.tsv

	sed -r -i.orig \
		'/\/(get-involved)/,+4d' \
		website/templates/nav.mustache

	(cd website; \
		git reset --hard; \
		git pull;)

	cp website.mk website/.env

	patch -p1 <website.diff

	(cd website; \
		go mod tidy; \
		bmake build; \
		bmake deps; \
		cp -r dist/* ../build/; \
		cp -r assets/lib ../build/;)

	./images.sh

tool:
	mkdir -p build

	test -d tool || \
		git clone --quiet "https://github.com/energyaccessexplorer/tool"

	(cd tool; \
		git reset --hard; \
		git pull;)

	cp tool.mk tool/.env

	patch -p1 <tool.diff

	(cd tool; \
		bmake deps; \
		bmake reconfig env=local; \
		bmake build; \
		cp -r dist/* ../build/tool;)

all: clean gobuild website tool fetch zip os=${os}

bundle: gobuild fetch zip success os=${os}

fetch:
	mkdir -p data/{geographies,files,datasets}

	@ echo "Running fetch.sh"

	@ TOKEN=${OFFROAD_TOKEN} \
	WORLD=https://world.energyaccessexplorer.org \
	API=https://api.energyaccessexplorer.org \
	STORAGE_URL=https://wri-public-data.s3.amazonaws.com/EnergyAccess/ \
	IDSFILE=${IDSFILE} \
	./fetch.sh ${ids}

zip:
.ifdef ID
	zip -q -r energyaccessexplorer-${ID}.zip build data runme*
.else
	zip -q -r energyaccessexplorer-${os}.zip build data runme*
.endif

success:
.ifdef ID
	@ echo "Download build at https://paver.energyaccessexplorer.org/departer/builds/energyaccessexplorer-${ID}.zip"
.endif

clean:
	-rm -Rf build data runme*

deploy:
	rsync -OPrv --checksum \
		--files-from=.RSYNC-INCLUDE \
		./ ${EAE_PAVER}:/var/cache/offroad

.PHONY: website tool
