build: clean
	GOOS=${goos} go build -o runme

#	REPOS
	git clone "https://github.com/energyaccessexplorer/website"
	git clone "https://github.com/energyaccessexplorer/tool"

#	HACKS
	touch tool/extras.mk

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

	mkdir -p data/{geographies,files,datasets}

	IDSFILE=${idsfile} ./fetch.sh

#	BUNDLE
	zip -r energyaccessexplorer-${goos}.zip sources data runme*

clean:
	-rm -rf website tool sources data runme* geoid-*
