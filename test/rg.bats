#!/usr/bin/env bats

load test_helper

setup_with_coverage 'terminator/src/rg.sh'

bats_require_minimum_version 1.5.0

################################################################################
# terminator::rg::invoke
################################################################################

# bats test_tags=terminator::rg,terminator::rg::invoke
@test "terminator::rg::invoke function-exists" {
  run type -t terminator::rg::invoke

  assert_success
  assert_output 'function'
}

################################################################################
# terminator::rg::__enable__
################################################################################

# bats test_tags=terminator::rg,terminator::rg::__enable__
@test "terminator::rg::__enable__ function-exists" {
  run type -t terminator::rg::__enable__

  assert_success
  assert_output 'function'
}

# bats test_tags=terminator::rg,terminator::rg::__enable__
@test "terminator::rg::__enable__ when-rg-not-available" {
  if command -v rg >/dev/null 2>&1; then
    skip 'rg is installed — cannot test absence'
  fi

  run terminator::rg::__enable__

  # Returns early with failure when rg not found
  assert_failure
}
