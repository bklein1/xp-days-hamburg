#!/bin/bash

# Exit 1 if any script fails.
set -e

# The docker container name has a default value.
DOCKER_CONTAINER_NAME="logstash-indexer";

# Get docker container states.
DOCKER_CONTAINER_RUNS=`docker ps | grep -q ${DOCKER_CONTAINER_NAME} && echo true || echo false`
DOCKER_CONTAINER_EXISTS=`docker ps -a | grep -q ${DOCKER_CONTAINER_NAME} && echo true || echo false`

# Stop container if running.
if $DOCKER_CONTAINER_RUNS; then {
  printf "\n%s\n\n" "=== Stop running docker container [${DOCKER_CONTAINER_NAME}] ==="; \
  docker stop ${DOCKER_CONTAINER_NAME}; ! docker ps | grep -q ${DOCKER_CONTAINER_NAME};
} else {
  printf "\n%s\n" "=== No need to stop not running docker container [${DOCKER_CONTAINER_NAME}] ===";
} fi

# Remove container if exists and if no circleci environment.
if test -z "${CIRCLECI}"; then {
  if $DOCKER_CONTAINER_EXISTS; then {
    printf "\n%s\n\n" "=== Remove existing docker container [${DOCKER_CONTAINER_NAME}] ===";
    docker rm -f ${DOCKER_CONTAINER_NAME}; ! docker ps -a | grep -q ${DOCKER_CONTAINER_NAME};
  } else {
    printf "\n%s\n" "=== No need to remove not existing docker container [${DOCKER_CONTAINER_NAME}] ===";
  } fi
} fi
