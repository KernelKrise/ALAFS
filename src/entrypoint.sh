#!/bin/bash

# Exit on error
set -e

# Logging
ilog() {
    echo -e "[*] ${1}" >&2
}

# Start shell mcp server
ilog "Starting mcp-shell"
mcp-shell
