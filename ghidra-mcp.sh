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
    -d \
    -p "${GHIDRA_MCP_PORT}:${GHIDRA_MCP_PORT}" \
    -v "${GHIDRA_MCP_DOCKER_DATA_VOLUME}:/data" \
    -v "${GHIDRA_MCP_DOCKER_PROJECTS_VOLUME}:/projects" \
    -v "${GHIDRA_MCP_DOCKER_SHARED_VOLUME}":"${GHIDRA_MCP_DOCKER_SHARED_VOLUME_INTERNAL_PATH}" \
    -e "GHIDRA_MCP_PORT=${GHIDRA_MCP_PORT}" \
    -e "JAVA_OPTS=-Xmx8g -XX:+UseG1GC" \
    --network "${DOCKER_NETWORK}" \
    "${GHIDRA_MCP_DOCKER_IMAGE}" >&2

# Start Ghidra MCP bridge
ilog "Starting Ghidra MCP bridge"
GHIDRA_MCP_URL="${GHIDRA_MCP_PROTO}://127.0.0.1:${GHIDRA_MCP_PORT}" python3 "${GHIDRA_MCP_BRIDGE_PATH}" --transport stdio
