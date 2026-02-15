#!/bin/bash

set -eo pipefail

cur_dir="$(dirname $0)"
template="${cur_dir}/Containerfile.template"
sh="setup_powa-archivist.sh"
sql="install_all_powa_ext.sql"
API_URL="https://api.github.com"

echo "###########################"
echo "#                         #"
echo "# Updating Containerfiles #"
echo "# for powa-archivist      #"
echo "#                         #"
echo "###########################"

echo "Retrieving extension versions..."

if [[ -n "${GITHUB_USERNAME}" && -n "${GITHUB_TOKEN}" ]]; then
    API_AUTH="--user ${GITHUB_USERNAME}:${GITHUB_TOKEN}"
fi
POWA_VERSION=$(curl -L ${API_AUTH} ${API_URL}/repos/powa-team/powa-archivist/releases/latest|jq -r '.tag_name')
PGQS_VERSION=$(curl -L ${API_AUTH} ${API_URL}/repos/powa-team/pg_qualstats/releases/latest|jq -r '.tag_name')
PGSK_VERSION=$(curl -L ${API_AUTH} ${API_URL}/repos/powa-team/pg_stat_kcache/releases/latest|jq -r '.tag_name')
HYPOPG_VERSION=$(curl -L ${API_AUTH} ${API_URL}/repos/hypopg/hypopg/releases/latest|jq -r '.tag_name')
PGTS_VERSION=$(curl -L ${API_AUTH} ${API_URL}/repos/rjuju/pg_track_settings/releases/latest|jq -r '.tag_name')
PGWS_VERSION=$(curl -L ${API_AUTH} ${API_URL}/repos/postgrespro/pg_wait_sampling/releases/latest|jq -r '.tag_name')

echo "powa-archivist: ${POWA_VERSION}"
echo "pg_qualstats: ${PGQS_VERSION}"
echo "pg_stat_kcache: ${PGSK_VERSION}"
echo "hypopg: ${HYPOPG_VERSION}"
echo "pg_track_settings: ${PGTS_VERSION}"
echo "pg_wait_sampling: ${PGWS_VERSION}"

# Read debian_versions.conf into an array
declare -A DEBIAN_VERSIONS_MAP
while IFS='=' read -r pg_version debian_version; do
    DEBIAN_VERSIONS_MAP["$pg_version"]="$debian_version"
done < "${cur_dir}/debian_versions.conf"

get_debian_version() {
    local pg_version="$1"
    echo "${DEBIAN_VERSIONS_MAP[$pg_version]:-bullseye}" # fallback fails if base image is not published with the release
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
    sed "s/%%PG_VER%%/${pg_version}/g" "$template" | sed "s/%%DEBIAN_VER%%/${debian_version}/g" > "${containerfile}"
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
