#vim: set ft=dockerfile
FROM postgres:12
MAINTAINER Julien Rouhaud <rjuju123@gmail.com>

WORKDIR /usr/local/src

RUN apt-get update && apt-get install -y \
    gcc \
    make \
    postgresql-contrib-12 \
    postgresql-server-dev-12 \
    git \
    && git clone https://github.com/powa-team/powa-archivist.git \
    && git clone https://github.com/powa-team/pg_qualstats.git \
    && git clone https://github.com/powa-team/pg_stat_kcache.git \
    && git clone https://github.com/hypopg/hypopg.git --branch REL1_STABLE \
    && git clone https://github.com/rjuju/pg_track_settings.git \
    && git clone https://github.com/postgrespro/pg_wait_sampling.git \
    && for f in $(ls); do cd $f; make USE_PGXS=1 install; cd ..; rm -rf $f; done \
    && apt-get purge -y --auto-remove gcc make postgresql-server-dev-12 wget \
    && rm -rf /var/lib/apt/lists/*

# configure powa-archivist and all supported extensions
ADD setup_powa-archivist.sh /docker-entrypoint-initdb.d/
ADD install_all_powa_ext.sql /usr/local/src/
