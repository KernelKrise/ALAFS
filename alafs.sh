#!/bin/bash

# Exit on error
set -e

# Logging
ilog() {
	echo -e "[*] ${1}" >&2
}

# Argparser
while [[ $# -gt 0 ]]; do
    case "${1}" in
        -d|--debug)
            DEBUG=ON
            shift
            ;;
        -h|--help)
            ilog "Usage: ${0} [-d --debug]"
            exit 0
            ;;
        *)
            ilog "Unknown argument: ${1}"
            exit 1
            ;;
    esac
done

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

# Compose environment variables
if [[ -v DEBUG ]]; then
	DOCKER_ARGS="-e DEBUG=ON -t"
fi

# Start docker container
ilog "Starting docker container"
docker run \
	--rm \
	-i \
	-v "${SHARED_DIR_PATH}":"${SHARED_DIR_INT_PATH}" \
	${DOCKER_ARGS} \
	"${DOCKER_IMAGE_NAME}"
