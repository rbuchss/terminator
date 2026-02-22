#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/ls.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::ls::__enable__
################################################################################

# bats test_tags=terminator::ls,terminator::ls::__enable__
@test "terminator::ls::__enable__ function-exists" {
  run type -t terminator::ls::__enable__

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::ls::__disable__
################################################################################

# bats test_tags=terminator::ls,terminator::ls::__disable__
@test "terminator::ls::__disable__ function-exists" {
  run type -t terminator::ls::__disable__

  assert_success
  assert_output 'function'
}
