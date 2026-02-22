#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/java.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::java::__enable__
################################################################################

# bats test_tags=terminator::java,terminator::java::__enable__
@test "terminator::java::__enable__ sets-JAVA_TOOL_OPTIONS" {
  unset JAVA_TOOL_OPTIONS

  terminator::java::__enable__

  [[ "${JAVA_TOOL_OPTIONS}" == '-Dlog4j2.formatMsgNoLookups=true' ]]
}

################################################################################
# terminator::java::__disable__
################################################################################

# bats test_tags=terminator::java,terminator::java::__disable__
@test "terminator::java::__disable__ unsets-JAVA_TOOL_OPTIONS" {
  JAVA_TOOL_OPTIONS='test'
  export JAVA_TOOL_OPTIONS

  terminator::java::__disable__

  [[ -z "${JAVA_TOOL_OPTIONS+x}" ]]
}
