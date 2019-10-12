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
credential.

Adding support for a new PostgreSQL major version
-------------------------------------------------

To generate the new powa-archivist files for a new version, simply create the
required "powa-archivist/XY" directory and run "make" in this repository root
directory.  The new files for the version XY will automatically be generated.

Once done, those additional file should get updated too to reference the new
PostgreSQL major version:

- compose/powa_standalone_mode.yml
- powa-archivist-git/Dockerfile
