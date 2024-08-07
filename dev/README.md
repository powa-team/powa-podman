Developer container images
==========================

This repository contains a set of images that can be useful if you want to work
on either **powa-web**, the User Interface of the PoWA project, or
**powa-collector**, the dedicated daemon to perform remote snapshots, without
locally setting up the full environment needed to test PoWA.

Here is the list of available images with their specificities:

- **powa-pyutils**: shell image with required python dependencies to run either
  powa-collector or powa-web

- **powa-collector-dev**: simple image based on powa-pyutils that ships a specific
  powa-web.conf file.  This should be used with a bind mount of your local
  powa-web repository with the changes you want to use.

- **powa-web-dev**: simple image based on powa-pyutils that ships a specific
  powa-collector.conf file.  This should be used with a bind mount of your local
  powa-web repository with the changes you want to use.

- **powa-pgbin**: simple image containing postgres and postgres-client packages.

- **powa-pgbench**: image based on powa-pgbin that can initialize a pgbench
  database and run configurable tests in a loop until the container is stopped.
  The following environment variables can be used:
  - `BENCH_DB`: database name to use.  Default is pgbench.
  - `BENCH_SKIP_INIT`: if empty, a pgbench database will be initialized on the
    target server (pgbench -i)
  - `BENCH_SCALE_FACTOR`: scale factor to use for initialization.  Default is
    10
  - `BENCH_TIME`: Bench run time in seconds.  Default is 60
  - `BENCH_FLAG`: Extra option to pass to pgbench.  For a hot-standby server,
    you should use at least "-n -S"
  - `BENCH_SLEEP_TIME`: Time to sleep between to pgbench occurence, in seconds.
    Default is 10.

On top of that, multiple compose file are also provided.  The main one,
powa-dev.yml will setup a full working PoWA environment based on the -git
version of powa-archivist, with the following setup:

- a *powa-archivist-git* image for the repository server

- two *powa-archivist-git* images in streaming replication

- a powa-web-dev configured with a bind mount of your local powa-web git
  repository that you're working on.  The location of the repository must be
  setup in the environment variable `$POWA_WEB_GIT`.

- a *powa-collector-dev* configured with a bind mount of you local
  powa-collector git repository that you're working on.  The location of the
  repository must be setup in the environment variable `$POWA_COLLECTOR_GIT`.

- two *powa-pgbench* images, that will run pgbench workload on the primary and
  standby instances.

Simply launching this podman-compose should be enough to test most features in
PoWA.

```
POWA_WEB_GIT=/path/to/powa-web POWA_COLLECTOR_GIT=/path/to/powa-collector podman-compose -f powa-dev.yml up
```

Load http://0.0.0.0:8888 in your browser.

The other compose files correspond to other kind of setup, for instance:

- `powa-dev-standalone.yml` will create a standalone environment rather than
  using the remote mode added in Powa 4
- `powa-dev_pgss.yml` and `powa-dev-standby_pgss.yml` will create the same
  environment as respectively `powa-dev.yml` and `powa-dev-standby.yml` but
  won't register any additional extension, so only *pg_stat_statements* (and
  *powa-archivist*) will be used
