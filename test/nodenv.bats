#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/nodenv.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::nodenv::__enable__
################################################################################

# bats test_tags=terminator::nodenv,terminator::nodenv::__enable__
@test "terminator::nodenv::__enable__ function-exists" {
  run type -t terminator::nodenv::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::nodenv,terminator::nodenv::__enable__
@test "terminator::nodenv::__enable__ when-nodenv-not-available" {
  if command -v nodenv >/dev/null 2>&1; then
    skip 'nodenv is installed — cannot test absence'
  fi

  run terminator::nodenv::__enable__

  # Returns early with failure when nodenv not found
  assert_failure
}
