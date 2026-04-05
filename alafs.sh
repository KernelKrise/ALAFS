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
COMMON_FILE_PATH="${SCRIPT_DIR}/common.sh"
source "${COMMON_FILE_PATH}"
SHARED_DIR_NAME="shared"
SHARED_DIR_PATH="${SCRIPT_DIR}/${SHARED_DIR_NAME}"
SHARED_DIR_PERM=777
SHARED_DIR_INT_PATH="/${SHARED_DIR_NAME}"
MAIN_DOCKER_CONTAINER=alafs

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

# Ensure no container conflicts
ilog "Ensuring no conflicting containers"
if docker ps -a --format '{{.Names}}' | grep -q "^${MAIN_DOCKER_CONTAINER}$"; then
    ilog "Killing existing container..."
    docker rm -f "${MAIN_DOCKER_CONTAINER}" >/dev/null 2>&1
fi

# Start docker container
ilog "Starting main docker container"
docker run \
    --name "${MAIN_DOCKER_CONTAINER}" \
	--rm \
	-i \
	-v "${SHARED_DIR_PATH}":"${SHARED_DIR_INT_PATH}" \
    -v "${GHIDRA_MCP_DOCKER_SHARED_VOLUME}":"${GHIDRA_MCP_DOCKER_SHARED_VOLUME_INTERNAL_PATH}" \
    -e "GHIDRA_API_ADDRESS=${GHIDRA_MCP_PROTO}://${GHIDRA_MCP_DOCKER_CONTAINER}:${GHIDRA_MCP_PORT}" \
    --network "${DOCKER_NETWORK}" \
	${DOCKER_ARGS} \
	"${MAIN_DOCKER_IMAGE}"
