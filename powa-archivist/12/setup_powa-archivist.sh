#!/bin/bash
set -e

if [[ -z "${POWA_ROLE}" ]]; then
    POWA_ROLE="PRIMARY"
fi

if [[ "${POWA_ROLE}" != "PRIMARY" && "${POWA_ROLE}" != "STANDBY" ]]; then
    >&2 echo "invalid POWA_ROLE ${POWA_ROLE}"
    exit 2
fi

if [[ "${POWA_ROLE}" != "PRIMARY" && "${POWA_PRIMARY}"  == "" ]]; then
    >&2 echo "POWA_PRIMARY is not set!"
    exit 2
fi

if [[ -z "${POWA_LOCAL_SNAPSHOT}" ]]; then
    POWA_LOCAL_SNAPSHOT="YES"
fi

# Configure shared_preload_libraries
if [[ "${POWA_ROLE}"  == "PRIMARY" ]]; then
    if [[ "${POWA_LOCAL_SNAPSHOT}"  == "YES" ]]; then
        echo "shared_preload_libraries = 'pg_stat_statements,powa,pg_qualstats,pg_stat_kcache,pg_wait_sampling'" >> ${PGDATA}/postgresql.conf
    else
        echo "shared_preload_libraries = 'pg_stat_statements,pg_qualstats,pg_stat_kcache,pg_wait_sampling'" >> ${PGDATA}/postgresql.conf
    fi
    echo "powa.frequency = 30s" >> ${PGDATA}/postgresql.conf
    echo "listen_addresses = '*'" >> ${PGDATA}/postgresql.conf
    echo "host  replication  all  0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf

    # restart pg
    pg_ctl -D "${PGDATA}" -w stop -m fast
    pg_ctl -D "${PGDATA}" -w start

    psql -f /usr/local/src/install_all_powa_ext.sql
    if [[ -n ${POWA_EXTRA_SQL} ]]; then
        psql -d powa -c "${POWA_EXTRA_SQL}"
    fi
else
    pg_ctl -D "${PGDATA}" -w stop -m immediate
    >&2 echo "Purging old data in ${PGDATA}..."
    rm -rf "${PGDATA}"/*

    # wait for primary to be online, with powa setup
    until psql -h "${POWA_PRIMARY}" -U "postgres" -d powa -c '\q'; do
        >&2 echo "PoWA is not ready yet, sleeping 1s..."
        sleep 1
    done

    pg_basebackup -D ${PGDATA} -R -X stream -c fast -h ${POWA_PRIMARY}
    echo "shared_preload_libraries = 'pg_stat_statements,pg_qualstats,pg_stat_kcache,pg_wait_sampling'" >> ${PGDATA}/postgresql.conf
    pg_ctl -D "${PGDATA}" -w start
fi
