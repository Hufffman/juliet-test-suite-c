#!/bin/sh

# the first parameter specifies the CWE ID
# the second parameter specifies a non-default timeout duration

# this script will run all good and bad tests in the bin subdirectory and write
# the names of the tests and their return codes into the files "good.run" and
# "bad.run". all tests are run with a timeout so that tests requiring input
# terminate quickly with return code 124.

ulimit -c 0

SCRIPT_DIR=$(dirname $(realpath "$0"))
CWDID=""
TIMEOUT="1s"
INPUT_FILE="/home/juliet-test-suite-c/in.txt"
INPUT_FILE_124_127="/home/juliet-test-suite-c/in_124_127.txt"

if [ $# -ge 2 ]
then
  CWDID="$1"
  TIMEOUT="$2"
fi

# parameter 1: the CWE directory corresponding to the tests
# parameter 2: the type of tests to run (should be "good" or "bad")
run_tests()
{
  local CWE_DIRECTORY="$1"
  local TEST_TYPE="$2"
  local TYPE_PATH="${CWE_DIRECTORY}/${TEST_TYPE}"

  local PREV_CWD=$(pwd)
  cd "${CWE_DIRECTORY}" # change directory in case of test-produced output files

  echo "========== STARTING TEST ${TYPE_PATH} $(date) ==========" >> "${TYPE_PATH}.run"
  for TESTCASE in $(ls -1 "${TYPE_PATH}"); do
    if echo "$TESTCASE" | grep -q "socket"
    then continue
    fi

    if echo "$TESTCASE" | grep -q "rand"
    then continue
    fi

    if echo "$TESTCASE" | grep -q "CWE170"
    then continue
    fi

    local TESTCASE_PATH="${TYPE_PATH}/${TESTCASE}"

    if [ "$CWDID" = "124" ] || [ "$CWDID" = "127" ]
    then
      timeout "${TIMEOUT}" "${TESTCASE_PATH}" < "${INPUT_FILE_124_127}"
    else
      timeout "${TIMEOUT}" "${TESTCASE_PATH}" < "${INPUT_FILE}"
    fi

    echo "${TESTCASE_PATH} $?" >> "${TYPE_PATH}.run"
  done

  cd "${PREV_CWD}"
}

export ASAN_OPTIONS=detect_leaks=0${ASAN_OPTIONS:+:$ASAN_OPTIONS}

run_tests "${SCRIPT_DIR}/CWE$CWDID" "good"
run_tests "${SCRIPT_DIR}/CWE$CWDID" "bad"
