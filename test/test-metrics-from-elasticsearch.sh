#!/bin/bash
# Test metrics of elasticsearch: ES_TEMPLATE and documents at ES_INDEX.

# Set flag for exit error.
EXIT_ERROR=0

# Print info.
printf "\n%s\n" "=== Test logstash data metrics from elasticsearch ${ES_HOSTS} ==="

# Path to elasticsearch template and logstash input test sample.
[[ "${LS_CONFIG}" ]] || { echo "ERROR: LS_CONFIG is not set"; exit 1; }
[[ "${ES_TEMPLATE}" ]] && ES_TEMPLATE_PATH="${LS_CONFIG}/${ES_TEMPLATE}" \
  || { [[ $LS_OUTPUT == *"elasticsearch"* || $LS_OUTPUT == *"template"* ]] \
    && { echo "ERROR: ES_TEMPLATE is not set"; exit 1; } }
[[ "${LS_LOG}" ]] || { echo "ERROR: LS_LOG is not set"; exit 1; }
[[ "${TEST_LOG}" ]] && LS_INPUT_PATH="${LS_LOG}/${TEST_LOG}" \
  || { [[ $LS_OUTPUT == *"elasticsearch"* || $LS_OUTPUT == *"documents"* ]] \
    && { echo "ERROR: TEST_LOG is not set"; exit 1; } }

# Check elasticsearch connection details.
[[ "${ES_HOSTS}" ]] || { echo "ERROR: ES_HOSTS is not set"; exit 1; }
[[ "${ES_USER}" ]] || { echo -e "\nINFO: ES_USER is optional and not set. Check if hosts ${ES_HOSTS} use auth."; }
[[ "${ES_PASSWORD}" ]] || { echo -e "\nINFO: ES_PASSWORD is optional and not set. Check if hosts ${ES_HOSTS} use auth."; }

# Set ES_HOSTS as hosts array.
declare -a HOSTS=`echo ${ES_HOSTS} | tr '[]' '()' | tr ',' ' '`

############
# Template #
############

# Fetch templates from all hosts.
[[ $LS_OUTPUT == *"elasticsearch"* || $LS_OUTPUT == *"template"* ]] && {
  printf "\n%s\n" "=== Fetch templates from elasticsearch index [${ES_INDEX}] ==="
  ES_TEMPLATE_COUNTER=0
  for host in "${HOSTS[@]}";
  do
    printf "\n%s\n\n" "--- Following template count fetched: ${host}/_template/${ES_INDEX}"
    ES_TEMPLATE_COUNTER=$((ES_TEMPLATE_COUNTER \
      + `curl --silent -u ${ES_USER}:${ES_PASSWORD} -XGET "${host}/_template/${ES_INDEX}?pretty" \
      | wc --words`))
  done
  # + `wget -t 5 -qO- "${host}/_template/${ES_INDEX}?pretty" --user="${ES_USER}" --password="${ES_PASSWORD}" --auth-no-challenge \
  # Collect metrics.
  printf "%s\n" "=== Test metrics for elasticsearch template ==="
  ES_TEMPLATE_PUSHED_COUNT=`wc --words < ${ES_TEMPLATE_PATH}`
  ES_TEMPLATES_FETCHED_COUNT_AVG=`expr ${ES_TEMPLATE_COUNTER} / ${#HOSTS[@]}`

  # Print metrics.
  printf "\n%s\n" "--- Count of words from pushed template (${ES_TEMPLATE_PUSHED_COUNT}) should be less than fetched average from all hosts (${ES_TEMPLATES_FETCHED_COUNT_AVG})."

  # Test metrics.
  test "${ES_TEMPLATE_PUSHED_COUNT}" -lt "${ES_TEMPLATES_FETCHED_COUNT_AVG}" || EXIT_ERROR=1
}

#############
# Documents #
#############

# Fetch documents from all hosts.
[[ $LS_OUTPUT == *"elasticsearch"* || $LS_OUTPUT == *"documents"* ]] && {
  printf "\n%s\n" "=== Fetch documents from elasticsearch index [${ES_INDEX}] ==="
  ES_DOCUMENT_COUNTER=0
  for host in "${HOSTS[@]}";
  do
    printf "\n%s\n\n" "--- Following document count fetched: ${host}/${ES_INDEX}"
    ES_DOCUMENT_COUNTER=$((ES_DOCUMENT_COUNTER \
      + `curl --silent -u ${ES_USER}:${ES_PASSWORD} -XGET "${host}/${ES_INDEX}/_count?pretty" \
      | grep -E '.*count.*' | grep -E -o '[0-9]{1,}'`))
  done

  # Collect metrics.
  printf "%s\n" "=== Test metrics for elasticsearch documents ==="
  LS_INPUT_COUNT_LINES=`wc -l < ${LS_INPUT_PATH}`
  ES_DOCUMENT_COUNT_AVG=`expr ${ES_DOCUMENT_COUNTER} / ${#HOSTS[@]}`

  # Print metrics.
  printf "\n%s\n" "--- Count of lines from input log (${LS_INPUT_COUNT_LINES}) and average documents from all hosts (${ES_DOCUMENT_COUNT_AVG}) should be equal."

  # Test metrics.
  test "${LS_INPUT_COUNT_LINES}" -eq "${ES_DOCUMENT_COUNT_AVG}" || EXIT_ERROR=1
}

# Use exit error flag.
exit "${EXIT_ERROR}"
