# Use official Logstash image.
FROM logstash:2.1.0

############
# Timezone #
############

ENV TZ="Europe/Berlin"
RUN echo "${TZ}" | tee /etc/timezone && \
  dpkg-reconfigure --frontend noninteractive tzdata

##########################################
# Install packages and templating script #
##########################################

ENV \
  JINJA_SCRIPT="render_jinja_template.py" \
  REPO_PROD_BRANCH="master"

# Install packages and clean-up.
RUN apt-get update && apt-get install -y \
  curl \
  python-setuptools && \
  easy_install Jinja2 && \
  apt-get -y clean && \
  rm -rf /var/lib/apt/lists/*

# Add Jinja templating script from repo epages-infra.
COPY ${JINJA_SCRIPT} ./
RUN \
  chown logstash:logstash ${JINJA_SCRIPT} && \
  chmod +x ${JINJA_SCRIPT}

######################
# Configure Logstash #
######################

ENV \
  LS_CONFIG_VOL="/usr/share/logstash/config" \
  LS_LOG_VOL="/usr/share/logstash/log"

# Create config and log dir
RUN mkdir -p ${LS_CONFIG_VOL} ${LS_LOG_VOL}

# Copy whole config dir to config vol
COPY config/ ${LS_CONFIG_VOL}/

# Change ownership to logstash
RUN chown -R logstash:logstash ${LS_CONFIG_VOL} ${LS_LOG_VOL}

# Set volume mount points
VOLUME ["${LS_CONFIG_VOL}", "${LS_LOG_VOL}"]

# Remove inherited offical entrypoint script
RUN rm /docker-entrypoint.sh

# Use our own entrypoint script that changes file ownerships and renders jinja templates
COPY docker-entrypoint.sh /
RUN \
  chown logstash:logstash /docker-entrypoint.sh && \
  chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

# Set default command and default option suffix
CMD ["logstash", "agent"]
