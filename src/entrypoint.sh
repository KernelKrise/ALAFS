#!/bin/bash

# Exit on error
set -e

# Logging
ilog() {
    echo -e "[*] ${1}" >&2
}

# Check if debug mode
if [[ -v DEBUG ]]; then
    ilog "Debug mode is ON, spawning shell..."
    bash
    exit 0
fi

# Start shell mcp server
ilog "Starting mcp-shell"
mcp-shell
