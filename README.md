# Energy Access Explorer Offroad

Offroad is a utility for taking snapshots of EAE's
[tool](https://github.com/energyaccessexplorer/tool) and makes this snapshot
usable when there is no internet connection available.

A snapshot is built targeting a specific OS and an executable file will be
generated for such target OS.

Once a snapshot is built it will also contain all datasets and geographies
selected by the **builder**. The builder's selection is restricted to her
read permissions at the time of the build.

The snapshot does not implement any authentication mechanism since it's meant to
be ran offline. **Distribution of a snapshot and the exposure of it's data is
left to the builders discretion**.


## Development

The build tool is written in BSDmake and POSIX shell. The HTTPS server is
written in Go.


## Building a snapshot

Offroad is meant to be run the command line in an Unix-like OS or as a headless
system. Assumptions made:

- standard Unix-like environment (cat, sed, echo, curl, patch, bmake, zip...)
- Go >1.20 programming language installed

There are several steps needed to run this manually:

### Authenticating

To obtain a token, the easiest way is to login into EAE's website on a
web browser, opening the developer tools and running

	localStorage['token']

copy/paste the result and create a `.env` file at the root of the project
with the result from

	OFFROAD_TOKEN="eyJhb...YYYXXX"

### Gather the geography IDs

On a web browser, navigate to each of the geographies intended for the snapshot
and copy the ID from the address bar. Insert the ID into a text file,
e.g. `example-build.dat`, containing Uganda and Tanzania:

	5d137d39-e46d-4abc-bfc9-76254501fa09
	3b4e1f5f-04c9-483f-997b-30be7026d9a3

### Taking a snapshot

Running:

	IDSFILE=example-build.dat bmake bundle os=windows

will generate a zipped snapshot targeted to windows OS.


## License

This project is licensed under MIT. Additionally, you must read the
[attribution page](https://www.energyaccessexplorer.org/attribution)
before using any part of this project.
