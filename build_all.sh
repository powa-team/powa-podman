#!/bin/bash

set -eo pipefail

function usage {
    echo "$0 [ -n ] [ -i image [ -s subver ]][ -p ] [-v ]"
    echo "$0 -h"
    echo ""
    echo " -h                   Show this message"
    echo " -i image             Only build a specific image. Suported values are"
    echo "                      powa-archivist(-git), powa-web(-git) and"
    echo "                      powa-collector(-git)"
    echo " -n                   Don't clean the images"
    echo " -p                   push the image after building"
    echo " -s subversion        Only build a specific subversion for a specific"
    echo "                      image. Requires usage of -i option, and only"
    echo "                      supported for powa-archivist."
    echo " -v                   Verbose mode"
}

DIRNAME="$(dirname $0)"

specific_image=""
specific_subver=
noclean="false"
docker_push="false"
quiet_flag="-q"

while getopts "hi:nps:u:v" name; do
    case "${name}" in
        h)
            usage
            exit 0
            ;;
        i)
            if [[ "$OPTARG" != "powa-archivist" \
                && "$OPTARG" != "powa-archivist-git" \
                && "$OPTARG" != "powa-web-git" \
                && "$OPTARG" != "powa-web" \
                && "$OPTARG" != "powa-collector" \
                && "$OPTARG" != "powa-collector-git" ]]; then
                echo "Image is not supported: ${OPTARG}"
                usage
                exit 1
            fi

            if [[ -z "${specific_image}" ]]; then
                specific_image="${OPTARG}"
            else
                specific_image="${specific_image} ${OPTARG}"
            fi
            ;;
        n)
            noclean="true"
            ;;
        p)
            docker_push="true"
            ;;
        s)
            specific_subver="${OPTARG}"
            ;;
        v)
            quiet_flag=""
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [[ -n "${specific_subver}" && -z "${specific_image}" ]]; then
    echo "-s option requires -i"
    echo
    usage
    exit 1
fi

if [[ -n "${specific_subver}" && "${specific_image}" != "powa-archivist" ]]; then
    echo "-s option is only compatible with powa-archivist image."
    echo
    usage
    exit 1
fi

function should_be_built {
    local target="$1"

    if [[ -z "${target}" ]]; then
        echo "No target specified"
        exit 2
    fi

    # Build all if no image was specified
    if [[ -z "${specific_image}" ]]; then
        return 0
    fi

    # Is the target part of the specified images?  Extra safety is needed here
    # as different targets have a common prefix (eg. powa-web and powa-web-git)
    re="$target( |$)"
    if [[ "${specific_image}" =~ $re ]]; then
        return 0
    fi

    return 1
}

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
if should_be_built  "powa-archivist"; then
    VER_ARCHIVIST="$(curl ${github_user} https://api.github.com/repos/powa-team/powa-archivist/releases/latest | jq -r '.name' | sed 's/version //i')"
fi

if should_be_built "powa-web"; then
    VER_WEB="$(curl ${github_user} https://api.github.com/repos/powa-team/powa-web/releases/latest | jq -r '.name' | sed 's/version //i')"
fi

if should_be_built "powa-collector"; then
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
        echo "Cleaning ${ORG}/${img_name}:latest..."
        rmi "${ORG}/${img_name}:latest"
    fi

    # Update base image
    base_image=$(egrep "^FROM " "${img_dir}/Dockerfile" | sed 's/FROM //')
    echo "Pulling ${base_image}..."
    docker pull "${base_image}"

    for tag in "${img_version}" "latest"; do
        if [[ "${tag}" == "-" ]]; then
            continue
        fi
        echo "Building ${ORG}/${img_name}:${tag}..."
        docker build ${quiet_flag} ${cache_flag} -t ${ORG}/${img_name}:${tag} ${img_dir}
        if [[ "${docker_push}" == "true" ]]; then
            echo "Pushing ${ORG}/${img_name}:${tag}..."
            docker push "${ORG}/${img_name}:${tag}"
        fi
    done
}

echo ""
echo "==================================="
echo "Minor versions to be built:"
echo ""
if should_be_built "powa-archivist"; then
    echo "${ORG}/powa-archivist: ${VER_ARCHIVIST}"
fi
if should_be_built "powa-archivist-git"; then
    echo "${ORG}/powa-archivist-git"
fi
if should_be_built "powa-web"; then
    echo "${ORG}/powa-web:       ${VER_WEB}"
fi
if should_be_built "powa-web-git"; then
    echo "${ORG}/powa-web-git"
fi
if should_be_built "powa-collector"; then
    echo "${ORG}/powa-collector: ${VER_COLLECTOR}"
fi
if should_be_built "powa-collector-git"; then
    echo "${ORG}/powa-collector-git"
fi
if [[ -n "${specific_subver}" ]]; then
    echo "  Subversion: ${specific_subver}"
fi
if [[ "${docker_push}" == "true" ]]; then
    echo
    echo "/!\ Built images will be pushed /!\ "
fi
echo "==================================="
echo ""
echo "Build images ? [y/N]"
read cont

if [ "$cont" != "y" -a "$cont" != "Y" ]; then
    echo "Stopping now"
    exit 1
fi

if should_be_built "powa-archivist"; then
    echo "############################"
    echo "##                         #"
    echo "##     powa-archivist      #"
    echo "##                         #"
    echo "############################"
    echo ""
    if [[ -n "${specific_subver}" ]]; then
        echo "Subversion: ${specific_subver}"
        echo
    fi

    BASEDIR="$DIRNAME/powa-archivist"
    for version in $(ls "$BASEDIR" | egrep '[0-9](+\.[0-9]+)?'); do
        # filter subversion if asked
        if [[ -n "${specific_subver}" && "${specific_subver}" != "${version}" ]]; then
            continue
        fi
        echo "Version $version"
        echo "================"
        echo ""
        # echo "Removing old images... "

        PG_VER=$(echo "$version" | sed 's/\.//')
        CURDIR="$BASEDIR/$version"

        IMGNAME="powa-archivist-${PG_VER}"

        build_image "${IMGNAME}" "${VER_ARCHIVIST}" "${CURDIR}"
    done
fi

if should_be_built "powa-archivist-git"; then
    echo "############################"
    echo "##                         #"
    echo "##    powa-archivist-git   #"
    echo "##                         #"
    echo "############################"
    echo ""
    BASEDIR="${DIRNAME}/powa-archivist-git"

    build_image "powa-archivist-git" "-" "${BASEDIR}"
fi

if should_be_built "powa-web"; then
    echo ""
    echo "############################"
    echo "##                         #"
    echo "##        powa-web         #"
    echo "##                         #"
    echo "############################"
    echo ""

    BASEDIR="${DIRNAME}/powa-web"

    build_image "powa-web" "${VER_WEB}" "${BASEDIR}"
fi

if should_be_built "powa-web-git"; then
    echo ""
    echo "############################"
    echo "##                         #"
    echo "##      powa-web-git       #"
    echo "##                         #"
    echo "############################"
    echo ""

    BASEDIR="${DIRNAME}/powa-web-git"

    build_image "powa-web-git" "-" "${BASEDIR}"
fi

if should_be_built "powa-collector"; then
    echo ""
    echo "############################"
    echo "##                         #"
    echo "##      powa-collector     #"
    echo "##                         #"
    echo "############################"
    echo ""

    BASEDIR="${DIRNAME}/powa-collector"

    build_image "powa-collector" "${VER_COLLECTOR}" "${BASEDIR}"
fi

if should_be_built "powa-collector-git"; then
    echo ""
    echo "############################"
    echo "##                         #"
    echo "##    powa-collector-git   #"
    echo "##                         #"
    echo "############################"
    echo ""

    BASEDIR="${DIRNAME}/powa-collector-git"

    build_image "powa-collector-git" "-" "${BASEDIR}"
fi

echo ""
echo "Done!"
echo ""
echo ""
