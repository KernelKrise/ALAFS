#!/bin/bash

# Exit on errors
set -e

# Logging
ilog() {
	echo -e "[*] ${1}"
}

# Variables
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
COMMON_FILE_PATH="${SCRIPT_DIR}/common.sh"
source "${COMMON_FILE_PATH}"
RUNNER_PATH="${SCRIPT_DIR}/alafs.sh"
MCP_CONFIG_NAME="alafs.config"
MCP_CONFIG_PATH="${SCRIPT_DIR}/${MCP_CONFIG_NAME}"
GHIDRA_MCP_DOCKERFILE_PATH="${GHIDRA_MCP_SUBMODULE_PATH}/docker/Dockerfile"
DOCKER_NETWORK_TYPE=bridge
DOCKER_VOLUMES_TYPE=local
GHIDRA_MCP_RUNNER_PATH="${SCRIPT_DIR}/ghidra-mcp.sh"

# Check if buildx available
if docker buildx version &>/dev/null; then
	ilog "Docker buildx available"
	DOCKER_BUILDX="buildx"
fi

# Build docker image
ilog "Building main docker image"
docker ${DOCKER_BUILDX} build \
  -t ${MAIN_DOCKER_IMAGE} \
  .

# Build Ghidra MCP image
ilog "Building Ghidra MCP image"
if [ ! -f "${GHIDRA_MCP_DOCKERFILE_PATH}" ]; then
  ilog "Ghidra MCP submodule not found, fetching..."
  git pull
  git submodule update --init --recursive --remote
fi
docker ${DOCKER_BUILDX} build \
  -t "${GHIDRA_MCP_DOCKER_IMAGE}" \
  -f "${GHIDRA_MCP_DOCKERFILE_PATH}" \
  "${GHIDRA_MCP_SUBMODULE_PATH}"

# Ensure Ghidra MCP volumes
ilog "Ensuring docker volumes"
docker volume inspect "${GHIDRA_MCP_DOCKER_PROJECTS_VOLUME}" >/dev/null 2>&1 || \
  docker volume create \
  --driver "${DOCKER_VOLUMES_TYPE}" \
  "${GHIDRA_MCP_DOCKER_PROJECTS_VOLUME}"

docker volume inspect "${GHIDRA_MCP_DOCKER_DATA_VOLUME}" >/dev/null 2>&1 || \
  docker volume create \
  --driver "${DOCKER_VOLUMES_TYPE}" \
  "${GHIDRA_MCP_DOCKER_DATA_VOLUME}"

docker volume inspect "${GHIDRA_MCP_DOCKER_SHARED_VOLUME}" >/dev/null 2>&1 || \
  docker volume create \
  --driver "${DOCKER_VOLUMES_TYPE}" \
  "${GHIDRA_MCP_DOCKER_SHARED_VOLUME}"

# Ensure Ghidra MCP shared volume writable
ilog "Ensuring Ghidra MCP shared volume is accessible"
docker run \
  --rm \
  -v "${GHIDRA_MCP_DOCKER_SHARED_VOLUME}":"${GHIDRA_MCP_DOCKER_SHARED_VOLUME_INTERNAL_PATH}" \
  alpine:latest sh -c "chmod 777 ${GHIDRA_MCP_DOCKER_SHARED_VOLUME_INTERNAL_PATH}"

# Ensure docker network
ilog "Ensuring docker network"
docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1 || \
  docker network create \
  --driver "${DOCKER_NETWORK_TYPE}" \
  "${DOCKER_NETWORK}"

# Compose MCP config
ilog "Composing MCP config"
cat << EOF > "${MCP_CONFIG_PATH}"
{
  "mcpServers": {
    "alafs": {
      "command": "bash",
      "args": ["${RUNNER_PATH}"]
    },
    "alafs-ghidra-mcp": {
      "command": "bash",
      "args": ["${GHIDRA_MCP_RUNNER_PATH}"]
    }
  }
}
EOF
ilog "MCP config saved at: ${MCP_CONFIG_PATH}"
