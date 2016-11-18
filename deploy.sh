#!/bin/bash

# Exit 1 if any script fails.
set -e

# Set script directory path
export SCRIPT_DIR=$(dirname "$0")

# Stop running instance.
${SCRIPT_DIR}/stop.sh

# Start new instance.
${SCRIPT_DIR}/start.sh

sleep 60

# Stop running instance.
${SCRIPT_DIR}/stop.sh
