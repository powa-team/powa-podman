#!/bin/bash

DIR="/usr/local/src/powa_demo"

function get_psql {
    local _db="$1"
    local _query="$2"

    if [[ -z "${_db}" || -z ${_query} ]]; then
        echo "Not enough arguments provided!"
        sleep 1
        exit 1
    fi

    local _res=$(psql -AXtc "${_query}" "${_db}")
    if [[ $? -ne 0 || ${_res} == "" ]]; then
        echo "Execution error on ${_db} - ${_query}"
        sleep 1
        exit 1
    fi

    echo "${_res}"
}

function check_db {
    local _db="$1"

    echo "Checking if ${_db} exists..."
    nb=$(get_psql "postgres" "SELECT COUNT(*) FROM pg_database WHERE datname = '${_db}'")
    if [[ "$nb" == "0" ]]; then
        echo "Database ${_db} does not exist"
        echo "Creating database ${_db}"
        createdb ${_db}
        if [[ $? -ne 0 ]]; then
            echo "Error trying to create database!"
            sleep 1
            exit 1
        fi
    else
        echo "Database ${_db} already exists"
    fi
}

function check_nb_tables {
    local _db="$1"

    nb=$(get_psql "${_db}" "SELECT COUNT(*) FROM pg_class c JOIN pg_namespace n on c.relnamespace = n.oid WHERE nspname = 'public' AND relkind = 'r'")

    echo "${nb}"
}

# we try to connect to db powa as the server may restart before that point
echo "Checking if PoWA is setup..."
get_psql "powa" "SELECT 1"

# Make sure pg_qualstats sample quals quickly enough
psql -c "ALTER SYSTEM SET pg_qualstats.sample_rate = 1" postgres
psql -c "SELECT pg_reload_conf()" postgres

check_db "tpc"
check_db "obvious"

echo "Checking tpc tables..."
nb=$(check_nb_tables "tpc")
if [[ "$nb" == "0" ]]; then
    echo "No table in tpc"
    echo "Waiting a bit and initializing data"
    sleep 5
    pg_restore -d tpc --no-privileges --no-owner ${DIR}/tpc/tpc.dump
    if [[ $? -ne 0 ]]; then
        echo "Error trying to initialize data!"
        sleep 1
        exit 1
    fi
elif [[ "${nb}" != "9" ]]; then
    echo "Missing tables (found ${nb}, expected 9), starting from scratch"
    dropdb tpc
    sleep 1
    exit 1
fi

echo "Checking obvious tables..."
nb=$(check_nb_tables "obvious")
if [[ "${nb}" == "0" ]]; then
    echo "No table in obvious"
    echo "Waiting a bit and initializing data"
    sleep 5
    psql -f ${DIR}/scripts/init.sql obvious
    if [[ $? -ne 0 ]]; then
        echo "Error trying to initialize data!"
        sleep 1
        exit 1
    fi
elif [[ "$nb" != "4" ]]; then
    echo "Missing tables (found ${nb}, expected 4), starting from scratch"
    dropdb obvious
    sleep 1
    exit 1
fi

while [[ true ]]; do
    # Set work_mem globally to a sensible random value, to generate some
    # activity for pg_track_settings
    w_m=$((5000 + $RANDOM % 5000))
    psql -c "ALTER SYSTEM SET work_mem = $w_m" postgres
    psql -c "SELECT pg_reload_conf()" postgres

    echo "running tpc scripts..."
    pgbench -d tpc -T ${BENCH_TIME:-10} -n -c1 -j1 -f ${DIR}/tpc/bench_v3.sql >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Error running pgbench!"
        sleep 1
        exit 1
    fi

    sleep 2

    echo "running obvious scripts..."
    pgbench -d obvious -T ${BENCH_TIME:-5} -n -c1 -j1 -f ${DIR}/scripts/commmand_price.sql >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Error running pgbench!"
        sleep 1
        exit 1
    fi
    pgbench -d obvious -T ${BENCH_TIME:-5} -n -c1 -j1 -f ${DIR}/scripts/returned.sql >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Error running pgbench!"
        sleep 1
        exit 1
    fi

    echo "Sleeping for ${BENCH_SLEEP_TIME:-30}"
    sleep ${BENCH_SLEEP_TIME:-30}
done
