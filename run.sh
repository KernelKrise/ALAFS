#!/bin/bash

# Variables
COMMON_VARS_FILE="common.sh"

# Logging
ilog() {
	echo -e "[*] ${1}"
}
elog() {
	echo -e "[!] ${1}"
}

# Import variables
source "${COMMON_VARS_FILE}"

# Parse arguments
if [ "$#" -ne 1 ]; then
    elog "Usage: ${0} <apk_file>"
    exit 1
fi

# Start docker container
docker run \
	--rm \
	-it \
	--name "${DOCKER_CONTAINER_NAME}" \
	"${DOCKER_IMAGE_NAME}"
