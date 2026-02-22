#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/ag.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::ag::invoke
################################################################################

# bats test_tags=terminator::ag,terminator::ag::invoke
@test "terminator::ag::invoke function-exists" {
  run type -t terminator::ag::invoke

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::ag::__enable__
################################################################################

# bats test_tags=terminator::ag,terminator::ag::__enable__
@test "terminator::ag::__enable__ function-exists" {
  run type -t terminator::ag::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::ag,terminator::ag::__enable__
@test "terminator::ag::__enable__ when-ag-not-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 1; }

  run terminator::ag::__enable__

  assert_failure
}

# bats test_tags=terminator::ag,terminator::ag::__enable__
@test "terminator::ag::__enable__ when-ag-available" {
  # shellcheck disable=SC2317 # invoked indirectly
  function terminator::command::exists { return 0; }

  run terminator::ag::__enable__

  assert_success
}
