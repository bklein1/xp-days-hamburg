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

##########
# docker #
##########

# The docker configuration has defaults.
DOCKER_LOG_VOL="/usr/share/logstash/log" # do not change - derived from dockerfile LS_LOG_VOL!
DOCKER_CONFIG_VOL="/usr/share/logstash/config" # do not change - derived from dockerfile LS_CONFIG_VOL!
DOCKER_IMAGE_NAME="logstash";
DOCKER_IMAGE_TAG="latest";
DOCKER_CONTAINER_NAME="logstash-indexer";
HOST_LOG_DIR="testlog"
HOST_CONFIG_DIR="config"

# Special flags for docker run are always used and can only be ommitted by actively disabling them.
DOCKER_RUN_REMOVE='-it --rm'
DOCKER_RUN_DETACH='--detach=true';
DOCKER_RUN_NETWORK='--net="host"';

# Run docker container.
docker run ${DOCKER_RUN_REMOVE} ${DOCKER_RUN_DETACH} ${DOCKER_RUN_NETWORK} \
  --env-file "${LS_CONFIG}/${LS_ENV}" \
  -v ${HOST_LOG_DIR}:${DOCKER_LOG_VOL} \
  -v ${HOST_CONFIG_DIR}:${DOCKER_CONFIG_VOL} \
  --name ${DOCKER_CONTAINER_NAME} \
  ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
  logstash -f "${DOCKER_CONFIG_VOL}/${LS_CONF}"

exit $?
