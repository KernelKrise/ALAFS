#!/bin/bash

# Logging
ilog() {
	echo -e "[*] ${1}"
}

# Variables
COMMON_VARS_FILE="common.sh"

# Import common variables
source "${COMMON_VARS_FILE}"

# Build docker image
ilog "Building docker image"
docker buildx build -t "${DOCKER_IMAGE_NAME}" .

