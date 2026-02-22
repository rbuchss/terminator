#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/jenv.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::jenv::__enable__
################################################################################

# bats test_tags=terminator::jenv,terminator::jenv::__enable__
@test "terminator::jenv::__enable__ function-exists" {
  run type -t terminator::jenv::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::jenv,terminator::jenv::__enable__
@test "terminator::jenv::__enable__ when-jenv-not-available" {
  if command -v jenv >/dev/null 2>&1; then
    skip 'jenv is installed — cannot test absence'
  fi

  run terminator::jenv::__enable__

  # Returns early with failure when jenv not found
  assert_failure
}
