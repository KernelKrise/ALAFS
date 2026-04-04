#!/bin/bash

# Exit on error
set -e

# Logging
ilog() {
	echo -e "[*] ${1}" >&2
}

# Variables
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
COMMON_FILE_NAME="common.sh"
COMMON_FILE_PATH="${SCRIPT_DIR}/${COMMON_FILE_NAME}"
SHARED_DIR_NAME="shared"
SHARED_DIR_PATH="${SCRIPT_DIR}/${SHARED_DIR_NAME}"
SHARED_DIR_PERM=777
SHARED_DIR_INT_PATH="/${SHARED_DIR_NAME}"

# Include common variables
source "${COMMON_FILE_PATH}"

# Create new shared dir
ilog "Creating new shared directory: ${SHARED_DIR_PATH}"
mkdir -p "${SHARED_DIR_PATH}"

# Change shared directory permissions
ilog "Fixing shared directory permissions to: ${SHARED_DIR_PERM}"
chmod "${SHARED_DIR_PERM}" "${SHARED_DIR_PATH}"

# Start docker container
ilog "Starting docker container"
docker run \
	--rm \
	-i \
	-v "${SHARED_DIR_PATH}":"${SHARED_DIR_INT_PATH}" \
	"${DOCKER_IMAGE_NAME}"
