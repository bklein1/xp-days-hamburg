#!/bin/bash

# Exit 1 if any script fails.
set -e

# Add logstash as command if needed
if [[ "${1:0:1}" = '-' ]]; then
    set -- logstash "$@"
fi

# Change the ownership of the mounted volumes to user logstash at docker container runtime
chown -R logstash:logstash ${LS_CONFIG_VOL} ${LS_LOG_VOL}

LS_ENV_PATH=$( find "${LS_CONFIG_VOL}" -maxdepth 3 -iname "${LS_ENV}" )

# Get LS_CONF
LS_CONF_JINJA=$( find "${LS_CONFIG_VOL}" -maxdepth 3 -iname "${LS_CONF}.j2" )
echo "${LS_CONF_JINJA}"

echo "python ${JINJA_SCRIPT} --verbose -f "${LS_ENV_PATH}" -e "LS_CONFIG_VOL" "LS_LOG_VOL" -t "${LS_CONF_JINJA}""
python ${JINJA_SCRIPT} --verbose -f "${LS_ENV_PATH}" -e "LS_CONFIG_VOL" "LS_LOG_VOL" -t "${LS_CONF_JINJA}"

LS_CONF_PATH=$( find "${LS_CONFIG_VOL}" -maxdepth 3 -iname "${LS_CONF}" )


# Start logstash agent
printf "\n\n%s\n\n" "=== Start logstash agent with logstash conf [${LS_CONF}] ==="
set -- gosu logstash "$@"

# As argument is not related to logstash,
# then assume that user wants to run his own process,
# for example a `bash` shell to explore this image
exec "$@"
