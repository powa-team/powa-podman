#vim: set ft=dockerfile
FROM postgres:9.5
MAINTAINER Julien Rouhaud <rjuju123@gmail.com>

WORKDIR /usr/local/src

RUN apt-get update && apt-get install -y \
    gcc \
    jq \
    make \
    postgresql-contrib-9.5 \
    postgresql-server-dev-9.5 \
    wget \
    && wget -O- $(wget -O- https://api.github.com/repos/powa-team/powa-archivist/releases/latest|jq -r '.tarball_url') | tar -xzf - \
    && wget -O- $(wget -O- https://api.github.com/repos/powa-team/pg_qualstats/releases/latest|jq -r '.tarball_url') | tar -xzf - \
    && wget -O- $(wget -O- https://api.github.com/repos/powa-team/pg_stat_kcache/releases/latest|jq -r '.tarball_url') | tar -xzf - \
    && wget -O- $(wget -O- https://api.github.com/repos/hypopg/hypopg/releases/latest|jq -r '.tarball_url') | tar -xzf - \
    && wget -O- $(wget -O- https://api.github.com/repos/rjuju/pg_track_settings/releases/latest|jq -r '.tarball_url') | tar -xzf - \
    && wget -O- $(wget -O- https://api.github.com/repos/postgrespro/pg_wait_sampling/releases/latest|jq -r '.tarball_url') | tar -xzf - \
    && for f in $(ls); do cd $f; make USE_PGXS=1 install; cd ..; rm -rf $f; done \
    && apt-get purge -y --auto-remove gcc jq make postgresql-server-dev-9.5 wget \
    && rm -rf /var/lib/apt/lists/*

# configure powa-archivist and all supported extensions
ADD setup_powa-archivist.sh /docker-entrypoint-initdb.d/
ADD install_all_powa_ext.sql /usr/local/src/
