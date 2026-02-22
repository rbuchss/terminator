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
  if command -v ag >/dev/null 2>&1; then
    skip 'ag is installed — cannot test absence'
  fi

  run terminator::ag::__enable__

  # Returns early with failure when ag not found
  assert_failure
}
