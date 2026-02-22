#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/rust.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::rust::__enable__
################################################################################

# bats test_tags=terminator::rust,terminator::rust::__enable__
@test "terminator::rust::__enable__ function-exists" {
  run type -t terminator::rust::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::rust,terminator::rust::__enable__
@test "terminator::rust::__enable__ when-rustc-not-available" {
  if command -v rustc >/dev/null 2>&1; then
    skip 'rustc is installed — cannot test absence'
  fi

  run terminator::rust::__enable__

  # Returns early with failure when rustc not found
  assert_failure
}
