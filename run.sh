#!/bin/bash

# Variables
COMMON_VARS_FILE="common.sh"
PROJECTS_DIR="${HOME}/.alafs"
SHARED_DIR="${PROJECTS_DIR}/$(date +%s)_$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 4)"
SHARED_VOLUME="/shared"
CONTAINER_UID="1000"

# Logging
ilog() {
	echo -e "[*] ${1}"
}
elog() {
	echo -e "[!] ${1}"
}

# Import variables
source "${COMMON_VARS_FILE}"

# Create new project dir
ilog "Creating new shared directory: ${SHARED_DIR}"
mkdir -p "${SHARED_DIR}"

# Parse arguments
if [ "$#" -ne 1 ]; then
    elog "Usage: ${0} <target_apk_filepath>"
    exit 1
fi
target_file="${1}"

# Validate file
if [ ! -f "${target_file}" ]; then
    elog "File ${target_file} does not exist"
	exit 1
fi

# Copy file to project directory
ilog "Copying file to project directory"
cp "${target_file}" "${SHARED_DIR}/target.apk"

# Change target file permissions
ilog "Fixing permissions"
chown "${USER}:${CONTAINER_UID}" "${SHARED_DIR}/target.apk"
chmod 660 "${SHARED_DIR}/target.apk"

# Start docker container
docker run \
	--rm \
	-it \
	-v "${SHARED_DIR}":"${SHARED_VOLUME}" \
	--name "${DOCKER_CONTAINER_NAME}" \
	"${DOCKER_IMAGE_NAME}"
