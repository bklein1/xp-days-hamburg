#!/bin/bash

# Exit 1 if any script fails.
set -e

############
# logstash #
############

# Default values
export LS_INFO="logstash-info.json";
export LS_ERROR="logstash-error.json";
export LS_CONF="logstash.conf";
export LS_ENV="env.list";
export LS_PATTERN="sample*.json";
export ES_DOCUMENT_TYPE="sample";

##########
# docker #
##########

# The docker configuration has defaults.
DOCKER_LOG_VOL="/usr/share/logstash/log"; # do not change - derived from dockerfile LS_LOG_VOL!
DOCKER_CONFIG_VOL="/usr/share/logstash/config"; # do not change - derived from dockerfile LS_CONFIG_VOL!
DOCKER_IMAGE_NAME="logstash";
DOCKER_IMAGE_TAG="latest";
DOCKER_CONTAINER_NAME="logstash-indexer";

HOST_CONFIG_DIR="${PWD}/config";
HOST_LOG_DIR="${PWD}/log";

DOCKER_RUN_REMOVE='-it'
DOCKER_RUN_DETACH='--detach=false';
DOCKER_RUN_NETWORK='--net="host"';

# Run docker container.
docker run ${DOCKER_RUN_REMOVE} ${DOCKER_RUN_DETACH} \
  --env-file "${HOST_CONFIG_DIR}/${LS_ENV}" \
  -v ${HOST_CONFIG_DIR}:${DOCKER_CONFIG_VOL} \
  -v ${HOST_LOG_DIR}:${DOCKER_LOG_VOL} \
  --name ${DOCKER_CONTAINER_NAME} \
  ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
  logstash -f "${DOCKER_CONFIG_VOL}/${LS_CONF}"

exit $?
