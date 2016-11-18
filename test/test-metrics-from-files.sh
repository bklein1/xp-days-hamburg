#!/bin/bash
# Test metrics of logstash files:  LS_ERRORS_FILE, LS_INPUT_FILE, LS_OUTPUT_FILE.

# Set flag for exit error.
EXIT_ERROR=0

# Path to input, output and errors.
[[ "${LS_LOG}" ]] || { echo "ERROR: LS_LOG is not set"; exit 1; }
[[ "${TEST_LOG}" ]] && LS_INPUT_PATH="${LS_LOG}/${TEST_LOG}" || { echo "ERROR: TEST_LOG is not set"; exit 1; }
[[ "${LS_INFO}" ]]  && LS_OUTPUT_PATH="${LS_LOG}/${LS_INFO}" || { echo "ERROR: LS_INFO is not set"; exit 1; }
[[ "${LS_ERROR}" ]] && LS_ERROR_PATH="${LS_LOG}/${LS_ERROR}" || { echo "ERROR: LS_ERROR is not set"; exit 1; }

#########
# Files #
#########

# The input file with esf test results should exist.
printf "\n%s\n" "=== Find logstash input ===";
test -f ${LS_INPUT_PATH} && { printf "\n%s\n\n" "--- Following input log found: ${LS_INPUT_PATH}"; cat ${LS_INPUT_PATH}; } || { printf "\n%s\n" "--- No input found."; EXIT_ERROR=1; }

# The info log with logstash events should exist.
printf "\n%s\n" "=== Find logstash output === ";
test -f ${LS_OUTPUT_PATH} && { printf "\n%s\n\n" "--- Following info log found: ${LS_OUTPUT_PATH}"; cat ${LS_OUTPUT_PATH}; } || { printf "\n%s\n" "--- No output found."; EXIT_ERROR=1; }

# The errors file with incorrectly transformed logstash events should not exist.
printf "\n%s\n" "=== Find logstash errors ===";
test -e ${LS_ERROR_PATH} && { printf "\n%s\n\n" "--- Following error log found: ${LS_ERROR_PATH}"; cat ${LS_ERROR_PATH}; EXIT_ERROR=1; } || { printf "\n%s\n" "--- No errors found."; }

###########
# Metrics #
###########

# The esf test results are transformed to logstash events.
# The esf test results are enriched with jenkins env variables.

# Collect metrics.
printf "\n%s\n" "=== Test metrics from log files ==="
LS_INPUT_LINES=`wc --lines < ${LS_INPUT_PATH}`
LS_INPUT_LENGTH=`wc --max-line-length < ${LS_INPUT_PATH}`
LS_OUTPUT_LINES=`wc --lines < ${LS_OUTPUT_PATH}`
LS_OUTPUT_LENGTH=`wc --max-line-length < ${LS_OUTPUT_PATH}`

# Print metrics.
printf "\n%s\n" "--- Count of lines from input log (${LS_INPUT_LINES}) and output log (${LS_OUTPUT_LINES}) should be equal."
printf "\n%s\n" "--- Maximum length from input log (${LS_INPUT_LENGTH}) should be less than ouput log (${LS_OUTPUT_LENGTH})."

# Test metrics.
test "${LS_INPUT_LINES}" -eq "${LS_OUTPUT_LINES}" || EXIT_ERROR=1
test "${LS_INPUT_LENGTH}" -lt "${LS_OUTPUT_LENGTH}" || EXIT_ERROR=1

# Use exit error flag.
exit "${EXIT_ERROR}"
