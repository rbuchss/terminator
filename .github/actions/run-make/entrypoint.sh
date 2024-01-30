#!/usr/bin/env bash

# This fixes the git error - fatal: detected dubious ownership in repository
git config --global --add safe.directory "${PWD}"

echo "Args: $*"
echo "PWD: ${PWD}"
echo "COVERAGE_REPORT_BASE_SHA: ${COVERAGE_REPORT_BASE_SHA}"
echo "COVERAGE_REPORT_HEAD_SHA: ${COVERAGE_REPORT_HEAD_SHA}"
echo "COVERAGE_REPORT_OUTPUT: ${COVERAGE_REPORT_OUTPUT}"

target="${1:?}"
with_coverage="${2}"

case "${target}:${with_coverage}" in
  test:true) make test-with-coverage ;;
  *) make "${target}" ;;
esac
