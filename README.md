PoWA images for docker
======================

This repository contains docker images of PoWA.

Those images are not intended for production usage, USE AT YOUR OWN RISK.

The **powa-archivist** contains images for a PostgreSQL cluster with PoWA
installed. All major version supported by PoWA are included.

The **powa-web** directory contains the UI for powa, intended to be used with
one of the **powa-archivist** provided image.

The **powa-collector** directory contains the collector, required for remote
mode in v4.

Those images are also available in "-git" version, which should provide more
recent changes not yet released.

This repository also contains **some docker compose files** to run either a
local or a remote version of PoWA.  UI will be available without providing any
credential, see the next paragraph for more details on how to use them.

Testing PoWA with docker-compose
--------------------------------

Two docker-compose images are provided with this repository:

- powa_standalone_mode.yml
- powa_remote_mode.yml

The first will setup a environment with a single PostgreSQL server storing both
the metrics (using the dedicated bgworker) and any custom data that suits your
needs.  The second one will setup a dedicated repository server to store the
metrics, and two regular remote PostgreSQL servers, configured in streaming
replication, to store any custom data that suits your need.

Those files are intended for doing tests and not for production use.  They're
also mainly thought as template that can be adapted depending on your needs.

If you're not familiar with docker-compose, you can quickly launch the wanted
setup from any directory using the `-f` option of docker-compsoe.  For
instance, if you cloned this repository in `~/powa-doocker` and want to run the
images for a remote mode, simply run:

docker-compose -f ~/powa-docker/composoe/powa_remote_mode.yml up

Please refer to https://docs.docker.com/compose/reference/overview/ for more
details on how to use docker-compose.

The initialization might take a minute or so depending on your machine.  Once
done, the powa-web UI will be available at http://127.0.0.1:8888.

Note that only the powa-web UI port is exposed to your local machine, as most
people using those files are likely to also run their application in docker
containers.  If that's not your case and want to directly connect to the
PostgreSQL server from your host, you can easily doo that by adding a `ports`
section for the wanted instance(s).  You can refer to the official
docker-compose documentation at
https://docs.docker.com/compose/compose-file/compose-file-v2/#ports for more
details.

Adding support for a new PostgreSQL major version
-------------------------------------------------

To generate the new powa-archivist files for a new version, simply create the
required "powa-archivist/XY" directory and run "make" in this repository root
directory.  The new files for the version XY will automatically be generated.

Once done, those additional file should get updated too to reference the new
PostgreSQL major version:

- compose/powa_standalone_mode.yml
- powa-archivist-git/Dockerfile
