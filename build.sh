#!/bin/bash

# Exit 1 if any script fails.
set -e

DOCKER_IMAGE_NAME="logstash"
DOCKER_IMAGE_TAG="latest"

printf "\n%s\n\n" "=== Build docker image [${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}] ==="

docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} `dirname "$0"`
