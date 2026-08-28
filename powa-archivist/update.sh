#!/bin/bash

set -eo pipefail

cur_dir="$(dirname $0)"
template="${cur_dir}/Containerfile.template"
sh="setup_powa-archivist.sh"
sql="install_all_powa_ext.sql"
API_URL="https://api.github.com"

if [[ -n "${GITHUB_USERNAME}" && -n "${GITHUB_TOKEN}" ]]; then
    API_AUTH="--user ${GITHUB_USERNAME}:${GITHUB_TOKEN}"
fi

function get_version {
    _repo="$1"

    if [[ "${_repo}" == "" ]]; then
        >&2 echo "No repo passed"
        exit 1
    fi

    _url="${API_URL}/repos/${_repo}/releases/latest"

    _version=$(curl -L ${API_AUTH} ${_url}|jq -r '.tag_name')
    if [[ "${_version}" == "null" ]]; then
        >&2 echo "Error fetching version for ${_repo}"
        exit 1
    fi

    echo "${_version}"
}

echo "###########################"
echo "#                         #"
echo "# Updating Containerfiles #"
echo "# for powa-archivist      #"
echo "#                         #"
echo "###########################"

echo "Retrieving extension versions..."
POWA_VERSION=$(get_version "powa-team/powa-archivist")
PGQS_VERSION=$(get_version "powa-team/pg_qualstats")
PGSK_VERSION=$(get_version "powa-team/pg_stat_kcache")
HYPOPG_VERSION=$(get_version "hypopg/hypopg")
PGTS_VERSION=$(get_version "rjuju/pg_track_settings")
PGWS_VERSION=$(get_version "postgrespro/pg_wait_sampling")

echo "powa-archivist: ${POWA_VERSION}"
echo "pg_qualstats: ${PGQS_VERSION}"
echo "pg_stat_kcache: ${PGSK_VERSION}"
echo "hypopg: ${HYPOPG_VERSION}"
echo "pg_track_settings: ${PGTS_VERSION}"
echo "pg_wait_sampling: ${PGWS_VERSION}"

# Source debian_versions.sh to declare the versions array
source "${cur_dir}/debian_versions.sh"

get_debian_version() {
    local pg_version="$1"
    if [[ -n "${DEBIAN_VERSIONS_MAP[$pg_version]}" ]]; then
        echo "${DEBIAN_VERSIONS_MAP[$pg_version]}"
    else
        echo "Error: No Debian version found for PostgreSQL $pg_version. Update debian_versions.sh with the mapping." >&2
        exit 1
    fi
}

for pg_version in $(ls "${cur_dir}"| grep -E '[0-9]+(\.[0-9]+)?'); do
    echo "Setting up powa-archivist-${pg_version}..."
    echo ""

    full_path="${cur_dir}/${pg_version}"
    containerfile="${full_path}/Containerfile"
    debian_version=$(get_debian_version "$pg_version")

    # clean everything in the X.Y directory
    rm -f "${full_path}/*"

    # create new Containerfile
    sed "s/%%PG_VER%%/${pg_version}/g" "$template" > "${containerfile}"
    sed -i "s/%%DEBIAN_VER%%/${debian_version}/g" "${containerfile}"
    # Set the download URL
    sed -i "s/%%POWA_VER%%/${POWA_VERSION}/g" "${containerfile}"
    sed -i "s/%%PGQS_VER%%/${PGQS_VERSION}/g" "${containerfile}"
    sed -i "s/%%PGSK_VER%%/${PGSK_VERSION}/g" "${containerfile}"
    sed -i "s/%%HYPOPG_VER%%/${HYPOPG_VERSION}/g" "${containerfile}"
    sed -i "s/%%PGTS_VER%%/${PGTS_VERSION}/g" "${containerfile}"
    sed -i "s/%%PGWS_VER%%/${PGWS_VERSION}/g" "${containerfile}"

    # add the needed resources
    cp "${cur_dir}/${sh}" "${full_path}/${sh}"
    cp "${cur_dir}/${sql}" "${full_path}/${sql}"
done
echo "Done"
echo ""
