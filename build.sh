#!/bin/bash

# Logging
ilog() {
	echo -e "[*] ${1}"
}

# Variables
source common.sh
BUILD_FLAGS="build -t ${DOCKER_IMAGE_NAME}"
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
RUNNER_NAME="alafs.sh"
RUNNER_PATH="${SCRIPT_DIR}/${RUNNER_NAME}"
MCP_CONFIG_NAME="alafs.config"
MCP_CONFIG_PATH="${SCRIPT_DIR}/${MCP_CONFIG_NAME}"

# Check if buildx available
if docker buildx version &>/dev/null; then
	ilog "Docker buildx available"
	BUILD_FLAGS="buildx ${BUILD_FLAGS}"
fi

# Build docker image
ilog "Building docker image"
docker ${BUILD_FLAGS} .

# Compose MCP config
ilog "Composing MCP config"
cat << EOF > "${MCP_CONFIG_PATH}"
{
  "mcpServers": {
    "alafs": {
      "command": "bash",
      "args": ["${RUNNER_PATH}"]
    }
  }
}
EOF
ilog "MCP config saved at: ${MCP_CONFIG_PATH}"
