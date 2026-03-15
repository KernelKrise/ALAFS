#!/bin/bash

# Logging
ilog() {
    echo -e "[*] ${1}"
}
elog() {
    echo -e "[!] ${1}"
}

# Variables
APP_DIRECTORY="/app"
SHARED_DIR="/shared"
TARGET_APK_NAME="target.apk"
TARGET_APK_FILEPATH="${SHARED_DIR}/${TARGET_APK_NAME}"
PROJECT_DIR_NAME="project"
PROJECT_DIRPATH="${APP_DIRECTORY}/${PROJECT_DIR_NAME}"

# Validate file
if [ ! -f "${TARGET_APK_FILEPATH}" ]; then
    elog "File ${TARGET_APK_FILEPATH} does not exist"
	exit 1dock
fi
if [[ "$(file --mime-type -b "${TARGET_APK_FILEPATH}")" != "application/vnd.android.package-archive" ]]; then
    elog "File ${TARGET_APK_FILEPATH} is not an APK file"
    exit 1
fi

# Decompile APK
ilog "Decompiling APK"
apktool d -o "${PROJECT_DIRPATH}" "${TARGET_APK_FILEPATH}"

# DEBUG
bash
