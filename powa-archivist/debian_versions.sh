#!/bin/bash

# note that the debian version should not be changed for existing images as it
# would otherwise likely break indexes/constraints on collatable datatype for
# existing users.
# When adding a new postgres major version, you should pick the latest
# available debian version at that time.
declare -A DEBIAN_VERSIONS_MAP=(
    ["9.6"]="bullseye"
    ["10"]="bullseye"
    ["11"]="bullseye"
    ["12"]="bullseye"
    ["13"]="bullseye"
    ["14"]="bullseye"
    ["15"]="bullseye"
    ["16"]="bullseye"
    ["17"]="trixie"
    ["18"]="trixie"
)
