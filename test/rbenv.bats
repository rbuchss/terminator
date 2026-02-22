#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/rbenv.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::rbenv::__enable__
################################################################################

# bats test_tags=terminator::rbenv,terminator::rbenv::__enable__
@test "terminator::rbenv::__enable__ function-exists" {
  run type -t terminator::rbenv::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::rbenv,terminator::rbenv::__enable__
@test "terminator::rbenv::__enable__ when-rbenv-not-available" {
  if command -v rbenv >/dev/null 2>&1; then
    skip 'rbenv is installed — cannot test absence'
  fi

  run terminator::rbenv::__enable__

  # Returns early with failure when rbenv not found
  assert_failure
}
