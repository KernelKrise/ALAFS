#!/bin/bash

# Exit on error
set -e

# Logging
ilog() {
	echo -e "[*] ${1}" >&2
}

# Variables
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
COMMON_FILE_PATH="${SCRIPT_DIR}/common.sh"
source "${COMMON_FILE_PATH}"
GHIDRA_MCP_BRIDGE_PATH="${SCRIPT_DIR}/${GHIDRA_MCP_SUBMODULE_PATH}/bridge_mcp_ghidra.py"
GHIDRA_HEALTHCHECK_TIMEOUT=30

# Signal handler
cleanup() {
    ilog "Cleaning up"
    docker kill "${GHIDRA_MCP_DOCKER_CONTAINER}" >/dev/null 2>&1
    exit 1
}
trap cleanup INT TERM

# Ensure no container conflicts
ilog "Ensuring no conflicting containers"
if docker ps -a --format '{{.Names}}' | grep -q "^${GHIDRA_MCP_DOCKER_CONTAINER}$" 2>&1; then
    ilog "Killing existing container..."
    docker rm -f "${GHIDRA_MCP_DOCKER_CONTAINER}" >/dev/null 2>&1
fi

# Start Ghidra MCP container
ilog "Starting Ghidra MCP container"
docker run \
    --name "${GHIDRA_MCP_DOCKER_CONTAINER}" \
    --hostname "${GHIDRA_MCP_DOCKER_CONTAINER}" \
    --rm \
    -p "${GHIDRA_MCP_PORT}:${GHIDRA_MCP_PORT}" \
    -v "${GHIDRA_MCP_DOCKER_DATA_VOLUME}:/data" \
    -v "${GHIDRA_MCP_DOCKER_PROJECTS_VOLUME}:/projects" \
    -v "${GHIDRA_MCP_DOCKER_SHARED_VOLUME}":"${GHIDRA_MCP_DOCKER_SHARED_VOLUME_INTERNAL_PATH}" \
    -e "GHIDRA_MCP_PORT=${GHIDRA_MCP_PORT}" \
    -e "JAVA_OPTS=-Xmx8g -XX:+UseG1GC" \
    --network "${DOCKER_NETWORK}" \
    "${GHIDRA_MCP_DOCKER_IMAGE}" >/dev/null 2>&1 &

# Wait for Ghidra MCP to start
ilog "Waiting for Ghidra MCP to start"
ready=0
for i in $(seq 1 ${GHIDRA_HEALTHCHECK_TIMEOUT}); do
    if curl -fsSL "${GHIDRA_MCP_URL}/mcp/schema" >/dev/null 2>&1; then
        ilog "Ghidra MCP ready after ${i}s"
        ready=1
        break
    fi
    sleep 1
done
if [ "${ready}" != "1" ]; then
    ilog "Ghidra not ready after ${GHIDRA_HEALTHCHECK_TIMEOUT}s"
    docker logs "${GHIDRA_MCP_DOCKER_CONTAINER}"
    exit 1
fi

# Start Ghidra MCP bridge
ilog "Starting Ghidra MCP bridge"
GHIDRA_MCP_URL="${GHIDRA_MCP_URL}" python3 "${GHIDRA_MCP_BRIDGE_PATH}" --no-lazy --transport stdio
