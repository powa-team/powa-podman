#!/bin/bash

set -eo pipefail

function usage {
    echo "$0 [ -n ] [ -i image ][ -u github_username ] | -h] "
    echo ""
    echo " -h                   Show this message"
    echo " -i image             Only build a specific image. Suported values are"
    echo "                      powa-archivist, powa-web, powa-collector"
    echo " -n                   Don't clean the images"
    echo " -u github_username   User to use when calling github API"
}

DIRNAME="$(dirname $0)"

specific_image=
noclean="false"
github_user=

while getopts "hi:nu:" name; do
    case "${name}" in
        h)
            usage
            exit 0
            ;;
        i)
            if [[ "$OPTARG" != "powa-archivist" && "$OPTARG" != "powa-web" && "$OPTARG" != "powa-collector" ]]; then
                echo "Image is not supported: ${OPTARG}"
                usage
                exit 1
            fi

            specific_image="${OPTARG}"
            ;;
        n)
            noclean="true"
            ;;
        u)
            github_user="-u ${OPTARG}"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

echo "######################"
echo "#                    #"
echo "#  Build script for  #"
echo "#    powa            #"
echo "#                    #"
echo "######################"

ORG="powateam"

# get a X.Y.Z information from the latest release name, which should be
# "version X.Y.Z". The release name can be easily edited, so this should be
# more reliable than using the release tags.
if [[ -z ${specific_image} || "${specific_image}" == "powa-archivist" ]]; then
    VER_ARCHIVIST="$(curl ${github_user} https://api.github.com/repos/powa-team/powa-archivist/releases/latest | jq -r '.name' | sed 's/version //i')"
fi

if [[ -z ${specific_image} || "${specific_image}" == "powa-web" ]]; then
    VER_WEB="$(curl ${github_user} https://api.github.com/repos/powa-team/powa-web/releases/latest | jq -r '.name' | sed 's/version //i')"
fi

if [[ -z ${specific_image} || "${specific_image}" == "powa-collector" ]]; then
    VER_COLLECTOR="$(curl ${github_user} https://api.github.com/repos/powa-team/powa-collector/releases/latest | jq -r '.name' | sed 's/version //i')"
fi

function rmi {
    local image="$1"

    if [[ -z $image ]]; then
        echo "Error!"
        exit 1
    fi

    nb=$(docker images $image |wc -l)
    if [[ $nb -eq 2 ]]; then
        docker rmi --force $image
    fi
}

function build_image {
    local img_name="$1"
    local img_version="$2"
    local img_dir="$3"

    local cache_flag=""

    if [[ -z ${img_name} ]]; then
        echo "Error, no image name!"
        exit 1
    fi

    if [[ -z ${img_version} ]]; then
        echo "Error, no image version!"
        exit 1
    fi

    if [[ -z ${img_dir} ]]; then
        echo "Error, no image directory!"
        exit 1
    fi

    if [[ "${noclean}" == "false" ]]; then
        cache_flag="--no-cache"
        echo "Cleaning ${ORG}/${img_name}..."
        rmi "${ORG}/${img_name}:${img_version}"
        echo "Cleaning ${ORG}/latest..."
        rmi "${ORG}/${img_name}:latest"
    fi

    echo "Building ${ORG}/${img_name}:${img_version}..."
    docker build -q ${cache_flag} -t ${ORG}/${img_name}:${img_version} ${img_dir}
    echo "Updating ${ORG}/${img_name}:latest..."
    docker build -q -t ${ORG}/${img_name}:latest ${img_dir}
}

echo ""
echo "=================================="
echo "Minor versions to be built:"
echo ""
if [[ -z ${specific_image} || "${specific_image}" == "powa-archivist" ]]; then
    echo "${ORG}/powa-archivist: ${VER_ARCHIVIST}"
fi
if [[ -z ${specific_image} || "${specific_image}" == "powa-web" ]]; then
    echo "${ORG}/powa-web:       ${VER_WEB}"
fi
if [[ -z ${specific_image} || "${specific_image}" == "powa-collector" ]]; then
    echo "${ORG}/powa-collector: ${VER_COLLECTOR}"
fi
echo "=================================="
echo ""
echo "Build images ? [y/N]"
read cont

if [ "$cont" != "y" -a "$cont" != "Y" ]; then
    echo "Stopping now"
    exit 1
fi

if [[ -z ${specific_image} || "${specific_image}" == "powa-archivist" ]]; then
    echo "############################"
    echo "##                         #"
    echo "##     powa-archivist      #"
    echo "##                         #"
    echo "############################"
    echo ""

    BASEDIR="$DIRNAME/powa-archivist"
    for version in $(ls "$BASEDIR" | egrep '[0-9](+\.[0-9]+)?'); do
        echo "Version $version"
        echo "================"
        echo ""
        # echo "Removing old images... "

        PG_VER=$(echo "$version" | sed 's/\.//')
        CURDIR="$BASEDIR/$version"

        IMGNAME="powa-archivist-${PG_VER}"

        build_image "${IMGNAME}" "${VER_ARCHIVIST}" "${CURDIR}"

        # rmi "${IMGNAME}:latest"
        # rmi "${IMGNAME}:${VER_ARCHIVIST}"

        # echo "Building powa-archivist tag ${VER_ARCHIVIST}..."
        # docker build -q --no-cache -t ${IMGNAME}:${VER_ARCHIVIST} ${CURDIR}
        # echo "Updating powa-archivist:latest..."
        # docker build -q -t ${IMGNAME}:latest ${CURDIR}
    done
fi

if [[ -z ${specific_image} || "${specific_image}" == "powa-web" ]]; then
    echo ""
    echo "############################"
    echo "##                         #"
    echo "##        powa-web         #"
    echo "##                         #"
    echo "############################"
    echo ""
    # echo "Removing old images..."

    BASEDIR="${DIRNAME}/powa-web"

    build_image "powa-web" "${VER_WEB}" "${BASEDIR}"

    # rmi "${ORG}/powa-web:latest"
    # rmi "${ORG}/powa-web:${VER_WEB}"
    #
    # echo "Building powa-web tag ${VER_WEB}..."
    # docker build -q --no-cache -t ${NAME_WEB}:${VER_WEB} ${BASEDIR}
    # echo "Updating powa-web:latest..."
    # docker build -q -t ${NAME_WEB}:latest ${BASEDIR}
fi

if [[ -z ${specific_image} || "${specific_image}" == "powa-collector" ]]; then
    echo ""
    echo "############################"
    echo "##                         #"
    echo "##      powa-collector     #"
    echo "##                         #"
    echo "############################"
    echo ""
    # echo "Removing old images..."

    BASEDIR="${DIRNAME}/powa-collector"

    build_image "powa-collector" "${VER_COLLECTOR}" "${BASEDIR}"

    # rmi "${ORG}/powa-collector:latest"
    # rmi "${ORG}/powa-collector:${VER_COLLECTOR}"
    #
    # echo "Building powa-collector tag ${VER_COLLECTOR}..."
    # docker build -q --no-cache -t ${NAME_COLLECTOR}:${VER_COLLECTOR} ${BASEDIR}
    # echo "Updating powa-collector:latest..."
    # docker build -q -t ${NAME_COLLECTOR}:latest ${BASEDIR}
fi

echo ""
echo "Done!"
echo ""
echo ""
