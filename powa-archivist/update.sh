#!/bin/bash

set -eo pipefail

cur_dir="$(dirname $0)"
template="${cur_dir}/Dockerfile.template"
sh="setup_powa-archivist.sh"
sql="install_all_powa_ext.sql"

echo "########################"
echo "#                      #"
echo "# Updating Dockerfiles #"
echo "# for powa-archivist   #"
echo "#                      #"
echo "########################"
for pg_version in $(ls "${cur_dir}"| egrep '[0-9]+(\.[0-9]+)?'); do
    echo "Setting up powa-archivist-${pg_version}..."
    echo ""

    full_path="${cur_dir}/${pg_version}"
    dockerfile="${full_path}/Dockerfile"

    # clean everything in the X.Y directory
    rm -f "${full_path}/*"

    # create new Dockerfile
    sed "s/%%PG_VER%%/${pg_version}/g" "$template" > "${dockerfile}"

    # add the needed resources
    cp "${cur_dir}/${sh}" "${full_path}/${sh}"
    cp "${cur_dir}/${sql}" "${full_path}/${sql}"
done
echo "Done"
echo ""
